#!/usr/bin/env bash
# ============================================================================
#  GHOST CLEANUP — Remove ferramentas instaladas pelo ghost-setup.sh
#  Author : Samuel Ziger
#
#  Remove APENAS o que o ghost-setup registrou no manifest.
#  Mantém: Go runtime, Node.js, npm, Python, build-essential, git, curl, etc.
#
#  Uso:
#    sudo bash ghost-cleanup.sh                     → interativo
#    sudo bash ghost-cleanup.sh --dry-run           → mostra sem remover
#    sudo bash ghost-cleanup.sh --force             → sem confirmações
#    sudo bash ghost-cleanup.sh --cache <dir>       → também remove cache
#    sudo bash ghost-cleanup.sh --log-level debug   → log verboso
# ============================================================================

set -euo pipefail

# ── Cores ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# ── Opções ──────────────────────────────────────────────────────────────────
FORCE=false
DRY_RUN=false
CACHE_DIR=""
LOG_LEVEL="info"   # error | warn | info | debug

# ── Resolver usuário real ───────────────────────────────────────────────────
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
[[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]] && REAL_HOME="$HOME"

TOOLS_DIR="$REAL_HOME/tools"
GOPATH_DIR="$REAL_HOME/go"
INSTALL_MANIFEST="$REAL_HOME/.ghost-manifest"
LOG_FILE="/tmp/ghost-cleanup-$(date +%Y%m%d-%H%M%S).log"

# ── Contadores ──────────────────────────────────────────────────────────────
REMOVED=0
SKIPPED=0
FAILED=0

# ── CLI ─────────────────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)     FORCE=true; shift ;;
            --dry-run)   DRY_RUN=true; shift ;;
            --cache)     CACHE_DIR="${2:?Uso: --cache <dir>}"; shift 2 ;;
            --log-level) LOG_LEVEL="${2:?Uso: --log-level error|warn|info|debug}"; shift 2 ;;
            -h|--help)
                cat << 'HELP'
Uso: sudo bash ghost-cleanup.sh [opções]

Opções:
  --dry-run           Mostra o que seria removido sem executar
  --force             Pula todas as confirmações
  --cache <dir>       Também remove o diretório de cache offline
  --log-level <nível> error | warn | info | debug (padrão: info)
  -h, --help          Mostra esta ajuda
HELP
                exit 0
                ;;
            *) echo "Flag desconhecida: $1"; exit 1 ;;
        esac
    done
}

# ── Log com níveis ──────────────────────────────────────────────────────────
declare -A LOG_PRIORITY=([error]=0 [warn]=1 [info]=2 [debug]=3)

_should_log() {
    local level="$1"
    (( ${LOG_PRIORITY[$level]:-2} <= ${LOG_PRIORITY[$LOG_LEVEL]:-2} ))
}

log()   { _should_log info  && echo -e "${GREEN}[+]${NC} $*" | tee -a "$LOG_FILE"; return 0; }
warn()  { _should_log warn  && echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; return 0; }
err()   { _should_log error && echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"; return 0; }
info()  { _should_log info  && echo -e "${CYAN}[*]${NC} $*" | tee -a "$LOG_FILE"; return 0; }
debug() { _should_log debug && echo -e "${DIM}[D]${NC} $*" | tee -a "$LOG_FILE"; return 0; }
sep()   { echo -e "${BOLD}────────────────────────────────────────────────${NC}"; }

cmd_exists() { command -v "$1" &>/dev/null; }

ask() {
    $FORCE && return 0
    $DRY_RUN && return 0
    local resp
    while true; do
        read -rp "$(echo -e "${YELLOW}[?]${NC} $1 [y/n]: ")" resp
        case "${resp,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) echo "  Responda y ou n." ;;
        esac
    done
}

need_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Execute como root: sudo bash $0"
        exit 1
    fi
}

# ── Proteção de path — impede rm -rf acidental ─────────────────────────────
safe_rm() {
    local target="$1"

    # Bloquear paths perigosos
    case "$target" in
        /|/home|/root|/usr|/etc|/var|/bin|/sbin|/opt|/tmp)
            err "BLOQUEADO: tentativa de remover path protegido: $target"
            ((FAILED++))
            return 1
            ;;
    esac

    # Garantir que TOOLS_DIR está correto
    if [[ "$target" == "$TOOLS_DIR/"* ]]; then
        if [[ "$TOOLS_DIR" != "$REAL_HOME/tools" ]]; then
            err "BLOQUEADO: TOOLS_DIR inconsistente ($TOOLS_DIR != $REAL_HOME/tools)"
            ((FAILED++))
            return 1
        fi
    fi

    if $DRY_RUN; then
        info "  [DRY-RUN] removeria: $target"
        return 0
    fi

    rm -rf "$target" 2>>"$LOG_FILE" && {
        debug "  rm -rf $target — OK"
        return 0
    } || {
        err "  Falha ao remover: $target"
        ((FAILED++))
        return 1
    }
}

banner() {
cat << 'EOF'

   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
  ██║  ███╗███████║██║   ██║███████╗   ██║
  ██║   ██║██╔══██║██║   ██║╚════██║   ██║
  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║
   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝
      C L E A N U P  —  by Samuel Ziger

EOF
}

# ============================================================================
#  MANIFEST — ler o que o ghost-setup instalou
# ============================================================================
declare -a MANIFEST_GO=()
declare -a MANIFEST_APT=()
declare -a MANIFEST_PIP=()
declare -a MANIFEST_REPO=()
declare -a MANIFEST_EXTRA=()
declare -a MANIFEST_GEM=()
declare -a MANIFEST_FRAMEWORK=()

read_manifest() {
    if [[ ! -f "$INSTALL_MANIFEST" ]]; then
        err "Manifest não encontrado: $INSTALL_MANIFEST"
        err "O ghost-setup.sh não foi executado ou o manifest foi apagado."
        err ""
        err "Sem manifest, o cleanup não sabe o que foi instalado pelo ghost-setup"
        err "e não pode garantir que não vai remover algo que já existia antes."
        exit 1
    fi

    info "Lendo manifest: $INSTALL_MANIFEST"
    debug "Conteúdo do manifest:"

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local type="${line%%:*}"
        local name="${line#*:}"
        debug "  $type → $name"
        case "$type" in
            GO)        MANIFEST_GO+=("$name") ;;
            APT)       MANIFEST_APT+=("$name") ;;
            PIP)       MANIFEST_PIP+=("$name") ;;
            REPO)      MANIFEST_REPO+=("$name") ;;
            EXTRA)     MANIFEST_EXTRA+=("$name") ;;
            GEM)       MANIFEST_GEM+=("$name") ;;
            FRAMEWORK) MANIFEST_FRAMEWORK+=("$name") ;;
            *) debug "  tipo desconhecido: $type ($name)" ;;
        esac
    done < "$INSTALL_MANIFEST"

    log "Manifest carregado: ${#MANIFEST_GO[@]} Go, ${#MANIFEST_APT[@]} APT, ${#MANIFEST_PIP[@]} pip, ${#MANIFEST_REPO[@]} repos, ${#MANIFEST_EXTRA[@]} extras, ${#MANIFEST_GEM[@]} gems, ${#MANIFEST_FRAMEWORK[@]} frameworks"
}

# ============================================================================
#  RELATÓRIO — o que será removido (baseado no manifest)
# ============================================================================
show_report() {
    local total=0

    sep
    if $DRY_RUN; then
        echo -e "${YELLOW}${BOLD}  MODO DRY-RUN — nada será removido${NC}"
    else
        echo -e "${BOLD}  O QUE SERÁ REMOVIDO (registrado no manifest):${NC}"
    fi
    sep
    echo ""

    # Go tools
    if (( ${#MANIFEST_GO[@]} > 0 )); then
        echo -e "  ${CYAN}Binários Go:${NC}"
        for tool in "${MANIFEST_GO[@]}"; do
            local locations=""
            [[ -f "/usr/local/bin/$tool" ]] && locations+="/usr/local/bin/$tool "
            [[ -f "$GOPATH_DIR/bin/$tool" ]] && locations+="$GOPATH_DIR/bin/$tool"
            if [[ -n "$locations" ]]; then
                echo -e "    ${RED}✗${NC} $tool  ${DIM}→${NC} $locations"
                ((total++))
            else
                echo -e "    ${DIM}○${NC} $tool  (já removido)"
            fi
        done
        echo ""
    fi

    # Repos
    if (( ${#MANIFEST_REPO[@]} > 0 )); then
        echo -e "  ${CYAN}Repositórios clonados:${NC}"
        for repo in "${MANIFEST_REPO[@]}"; do
            if [[ -d "$TOOLS_DIR/$repo" ]]; then
                local size; size=$(du -sh "$TOOLS_DIR/$repo" 2>/dev/null | awk '{print $1}')
                echo -e "    ${RED}✗${NC} $TOOLS_DIR/$repo  ($size)"
                ((total++))
            else
                echo -e "    ${DIM}○${NC} $repo  (já removido)"
            fi
        done
        echo ""
    fi

    # APT modular
    if (( ${#MANIFEST_APT[@]} > 0 )); then
        echo -e "  ${CYAN}Pacotes APT (instalados pelo ghost-setup):${NC}"
        for pkg in "${MANIFEST_APT[@]}"; do
            if dpkg -l "$pkg" &>/dev/null 2>&1; then
                echo -e "    ${RED}✗${NC} $pkg"
                ((total++))
            else
                echo -e "    ${DIM}○${NC} $pkg  (já removido)"
            fi
        done
        echo ""
    fi

    # Pip
    if (( ${#MANIFEST_PIP[@]} > 0 )); then
        echo -e "  ${CYAN}Pacotes Python (instalados pelo ghost-setup):${NC}"
        for pkg in "${MANIFEST_PIP[@]}"; do
            if pip3 show "$pkg" &>/dev/null 2>&1; then
                echo -e "    ${RED}✗${NC} $pkg"
                ((total++))
            else
                echo -e "    ${DIM}○${NC} $pkg  (já removido)"
            fi
        done
        echo ""
    fi

    # Extras (com verificação de marker)
    if (( ${#MANIFEST_EXTRA[@]} > 0 )); then
        echo -e "  ${CYAN}Diretórios extras:${NC}"
        for path in "${MANIFEST_EXTRA[@]}"; do
            if [[ -e "$path" ]]; then
                local size; size=$(du -sh "$path" 2>/dev/null | awk '{print $1}')
                # Verificar marker para dirs externos
                if [[ "$path" == /opt/* ]] && [[ ! -f "$path/.ghost-installed" ]]; then
                    echo -e "    ${YELLOW}⚠${NC} $path  ($size) — ${YELLOW}sem marker .ghost-installed — PULANDO${NC}"
                    ((SKIPPED++))
                else
                    echo -e "    ${RED}✗${NC} $path  ($size)"
                    ((total++))
                fi
            else
                echo -e "    ${DIM}○${NC} $path  (já removido)"
            fi
        done
        echo ""
    fi

    # Gems
    if (( ${#MANIFEST_GEM[@]} > 0 )); then
        echo -e "  ${CYAN}Ruby gems:${NC}"
        for gem_name in "${MANIFEST_GEM[@]}"; do
            if cmd_exists "$gem_name"; then
                echo -e "    ${RED}✗${NC} $gem_name"
                ((total++))
            else
                echo -e "    ${DIM}○${NC} $gem_name  (já removido)"
            fi
        done
        echo ""
    fi

    # Frameworks
    if (( ${#MANIFEST_FRAMEWORK[@]} > 0 )); then
        echo -e "  ${CYAN}Frameworks:${NC}"
        for fw in "${MANIFEST_FRAMEWORK[@]}"; do
            if cmd_exists msfconsole 2>/dev/null || [[ -d "/opt/metasploit-framework" ]]; then
                echo -e "    ${RED}✗${NC} $fw"
                ((total++))
            else
                echo -e "    ${DIM}○${NC} $fw  (já removido)"
            fi
        done
        echo ""
    fi

    # Cache (se pedido)
    if [[ -n "$CACHE_DIR" ]] && [[ -d "$CACHE_DIR" ]]; then
        local cache_size; cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')
        echo -e "  ${CYAN}Cache offline:${NC}"
        echo -e "    ${RED}✗${NC} $CACHE_DIR  ($cache_size)"
        ((total++))
        echo ""
    fi

    # O que mantém
    sep
    echo -e "${BOLD}  O QUE SERÁ MANTIDO:${NC}"
    sep
    echo ""
    echo -e "    ${GREEN}✔${NC} Go runtime (/usr/local/go)"
    echo -e "    ${GREEN}✔${NC} Node.js + npm"
    echo -e "    ${GREEN}✔${NC} Python3 + pip"
    echo -e "    ${GREEN}✔${NC} build-essential, libpcap-dev"
    echo -e "    ${GREEN}✔${NC} git, curl, wget, jq, tmux, unzip"
    echo -e "    ${GREEN}✔${NC} nmap, whois, dnsutils"
    echo -e "    ${GREEN}✔${NC} Docker (se instalado)"
    echo -e "    ${GREEN}✔${NC} Caido (se instalado)"
    echo -e "    ${GREEN}✔${NC} /etc/profile.d/go-path.sh"
    echo ""

    if (( SKIPPED > 0 )); then
        warn "$SKIPPED item(s) pulados por falta de marker .ghost-installed"
    fi

    if (( total == 0 )); then
        info "Nada a remover — tudo já foi limpo ou nunca foi instalado."
        exit 0
    fi

    info "Total de itens a remover: $total"
    echo ""
}

# ============================================================================
#  REMOÇÃO — apenas o que está no manifest
# ============================================================================
remove_go_tools() {
    (( ${#MANIFEST_GO[@]} == 0 )) && return 0
    info "Removendo binários Go..."

    for tool in "${MANIFEST_GO[@]}"; do
        if [[ -f "/usr/local/bin/$tool" ]] || [[ -L "/usr/local/bin/$tool" ]]; then
            if $DRY_RUN; then
                info "  [DRY-RUN] removeria /usr/local/bin/$tool"
            else
                rm -f "/usr/local/bin/$tool"
                log "  /usr/local/bin/$tool removido"
            fi
            ((REMOVED++))
        fi
        if [[ -f "$GOPATH_DIR/bin/$tool" ]]; then
            if $DRY_RUN; then
                info "  [DRY-RUN] removeria $GOPATH_DIR/bin/$tool"
            else
                rm -f "$GOPATH_DIR/bin/$tool"
                log "  $GOPATH_DIR/bin/$tool removido"
            fi
        fi
    done

    # Go module cache (opcional)
    if [[ -d "$GOPATH_DIR/pkg" ]] && ! $DRY_RUN; then
        if ask "Limpar Go module cache ($GOPATH_DIR/pkg)? Libera espaço mas próximo go install será mais lento"; then
            rm -rf "$GOPATH_DIR/pkg" 2>/dev/null || true
            log "Go module cache limpo"
        fi
    fi
}

remove_repos() {
    (( ${#MANIFEST_REPO[@]} == 0 )) && return 0

    # Guard: TOOLS_DIR deve ser $REAL_HOME/tools
    if [[ "$TOOLS_DIR" != "$REAL_HOME/tools" ]]; then
        err "BLOQUEADO: TOOLS_DIR='$TOOLS_DIR' não é '$REAL_HOME/tools' — abortando remoção de repos"
        ((FAILED++))
        return 1
    fi

    info "Removendo repositórios clonados..."

    for repo in "${MANIFEST_REPO[@]}"; do
        local target="$TOOLS_DIR/$repo"
        if [[ -d "$target" ]]; then
            safe_rm "$target" && {
                ((REMOVED++))
                log "  $target removido"
            }
        fi
    done

    # Symlinks órfãos
    for link in /usr/local/bin/dirsearch /usr/local/bin/searchsploit; do
        if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
            if $DRY_RUN; then
                info "  [DRY-RUN] removeria symlink órfão $link"
            else
                rm -f "$link"
                log "  Symlink órfão $link removido"
            fi
        fi
    done

    # Se ~/tools ficou vazio, remover
    if [[ -d "$TOOLS_DIR" ]] && [[ -z "$(ls -A "$TOOLS_DIR" 2>/dev/null)" ]]; then
        if $DRY_RUN; then
            info "  [DRY-RUN] removeria $TOOLS_DIR (vazio)"
        else
            rmdir "$TOOLS_DIR" 2>/dev/null || true
            log "  $TOOLS_DIR (vazio) removido"
        fi
    fi
}

remove_apt_packages() {
    (( ${#MANIFEST_APT[@]} == 0 )) && return 0

    # Filtrar apenas os realmente instalados
    local to_remove=()
    for pkg in "${MANIFEST_APT[@]}"; do
        if dpkg -l "$pkg" &>/dev/null 2>&1; then
            to_remove+=("$pkg")
        fi
    done

    (( ${#to_remove[@]} == 0 )) && return 0

    info "Removendo pacotes APT: ${to_remove[*]}"
    if $DRY_RUN; then
        for pkg in "${to_remove[@]}"; do
            info "  [DRY-RUN] removeria apt: $pkg"
        done
    else
        apt-get remove -y -qq "${to_remove[@]}" 2>>"$LOG_FILE" || true
        apt-get autoremove -y -qq 2>>"$LOG_FILE" || true
        ((REMOVED += ${#to_remove[@]}))
        log "Pacotes APT removidos"
    fi
}

remove_pip_packages() {
    (( ${#MANIFEST_PIP[@]} == 0 )) && return 0

    info "Removendo pacotes Python..."
    for pkg in "${MANIFEST_PIP[@]}"; do
        if ! pip3 show "$pkg" &>/dev/null 2>&1; then
            debug "  $pkg não instalado via pip — pulando"
            continue
        fi

        # Verificar se foi instalado globalmente (não em venv)
        local pip_location
        pip_location=$(pip3 show "$pkg" 2>/dev/null | grep -i "^location:" | awk '{print $2}')
        debug "  $pkg localizado em: $pip_location"

        if [[ "$pip_location" == *"/venv/"* ]] || [[ "$pip_location" == *"/.virtualenvs/"* ]]; then
            warn "  $pkg está em virtualenv ($pip_location) — pulando para segurança"
            ((SKIPPED++))
            continue
        fi

        if $DRY_RUN; then
            info "  [DRY-RUN] removeria pip: $pkg ($pip_location)"
        else
            pip3 uninstall -y "$pkg" --break-system-packages 2>>"$LOG_FILE" || {
                warn "  Falha ao remover $pkg via pip"
                ((FAILED++))
                continue
            }
            ((REMOVED++))
            log "  $pkg removido"
        fi
    done
}

remove_extras() {
    (( ${#MANIFEST_EXTRA[@]} == 0 )) && return 0

    info "Removendo diretórios extras..."
    for path in "${MANIFEST_EXTRA[@]}"; do
        [[ ! -e "$path" ]] && continue

        # Para dirs em /opt: exigir marker .ghost-installed
        if [[ "$path" == /opt/* ]]; then
            if [[ ! -f "$path/.ghost-installed" ]]; then
                warn "  $path existe mas sem marker .ghost-installed — NÃO foi instalado pelo ghost-setup — PULANDO"
                ((SKIPPED++))
                continue
            fi
        fi

        safe_rm "$path" && {
            ((REMOVED++))
            log "  $path removido"
        }
    done

    # Symlinks órfãos de extras
    if [[ -L "/usr/local/bin/searchsploit" ]] && [[ ! -e "/usr/local/bin/searchsploit" ]]; then
        if ! $DRY_RUN; then
            rm -f "/usr/local/bin/searchsploit"
            log "  Symlink órfão /usr/local/bin/searchsploit removido"
        fi
    fi
}

remove_gems() {
    (( ${#MANIFEST_GEM[@]} == 0 )) && return 0

    info "Removendo Ruby gems..."
    for gem_name in "${MANIFEST_GEM[@]}"; do
        if ! cmd_exists "$gem_name"; then
            debug "  $gem_name não encontrado — pulando"
            continue
        fi
        if $DRY_RUN; then
            info "  [DRY-RUN] removeria gem: $gem_name"
        else
            gem uninstall "$gem_name" -x 2>>"$LOG_FILE" || {
                warn "  Falha ao remover gem $gem_name"
                ((FAILED++))
                continue
            }
            ((REMOVED++))
            log "  $gem_name removido"
        fi
    done
}

remove_frameworks() {
    (( ${#MANIFEST_FRAMEWORK[@]} == 0 )) && return 0

    info "Removendo frameworks..."
    for fw in "${MANIFEST_FRAMEWORK[@]}"; do
        case "$fw" in
            metasploit)
                if ! cmd_exists msfconsole && [[ ! -d "/opt/metasploit-framework" ]]; then
                    debug "  metasploit não encontrado — pulando"
                    continue
                fi
                if $DRY_RUN; then
                    info "  [DRY-RUN] removeria metasploit-framework"
                else
                    if [[ -f "/opt/metasploit-framework/uninstall" ]]; then
                        /opt/metasploit-framework/uninstall 2>>"$LOG_FILE" || true
                    elif dpkg -l metasploit-framework &>/dev/null 2>&1; then
                        apt-get remove -y -qq metasploit-framework 2>>"$LOG_FILE" || true
                    else
                        rm -rf /opt/metasploit-framework 2>/dev/null || true
                        rm -f /usr/local/bin/msfconsole /usr/local/bin/msf* 2>/dev/null || true
                    fi
                    ((REMOVED++))
                    log "  metasploit removido"
                fi
                ;;
            *)
                warn "  Framework desconhecido: $fw — pulando"
                ;;
        esac
    done
}

remove_cache() {
    [[ -z "$CACHE_DIR" ]] && return 0
    [[ ! -d "$CACHE_DIR" ]] && { warn "Cache $CACHE_DIR não encontrado"; return 0; }

    local cache_size
    cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')

    # Confirmação SEPARADA para o cache
    sep
    echo ""
    echo -e "${YELLOW}${BOLD}  ⚠ ATENÇÃO: remoção do cache offline${NC}"
    echo -e "    Path:    $CACHE_DIR"
    echo -e "    Tamanho: $cache_size"
    echo -e "    Isso é irreversível — você precisará re-gerar com --cache"
    echo ""

    if ! ask "Confirmar remoção do cache offline?"; then
        warn "Remoção do cache cancelada."
        return 0
    fi

    if $DRY_RUN; then
        info "  [DRY-RUN] removeria cache: $CACHE_DIR ($cache_size)"
    else
        safe_rm "$CACHE_DIR" && {
            ((REMOVED++))
            log "Cache $CACHE_DIR removido"
        }
    fi
}

remove_manifest() {
    if $DRY_RUN; then
        info "  [DRY-RUN] removeria manifest: $INSTALL_MANIFEST"
        return 0
    fi
    if ask "Remover o manifest ($INSTALL_MANIFEST)? Se sim, próximo cleanup precisará de novo setup"; then
        rm -f "$INSTALL_MANIFEST"
        log "Manifest removido"
    else
        info "Manifest mantido para referência futura"
    fi
}

# ============================================================================
#  VERIFICAÇÃO PÓS-CLEANUP
# ============================================================================
post_check() {
    sep
    echo ""
    if $DRY_RUN; then
        echo -e "${YELLOW}${BOLD}  ● DRY-RUN CONCLUÍDO — nada foi alterado${NC}"
    else
        echo -e "${GREEN}${BOLD}  ✔ CLEANUP FINALIZADO${NC}"
    fi
    echo ""
    info "Log: $LOG_FILE"
    info "Removidos: $REMOVED | Pulados: $SKIPPED | Falhas: $FAILED"
    echo ""

    # Checar resíduos
    if ! $DRY_RUN; then
        echo -e "${BOLD}  Verificação pós-cleanup:${NC}"
        echo ""
        local residue=0

        for tool in "${MANIFEST_GO[@]}"; do
            if cmd_exists "$tool"; then
                echo -e "    ${YELLOW}⚠${NC} $tool ainda detectado"
                ((residue++))
            fi
        done

        for repo in "${MANIFEST_REPO[@]}"; do
            if [[ -d "$TOOLS_DIR/$repo" ]]; then
                echo -e "    ${YELLOW}⚠${NC} $TOOLS_DIR/$repo ainda existe"
                ((residue++))
            fi
        done

        if (( residue == 0 )); then
            echo -e "    ${GREEN}✔${NC} Tudo limpo — nenhum resíduo"
        else
            warn "$residue item(s) ainda presentes — verifique manualmente"
        fi
        echo ""
    fi

    # Dependências base
    echo -e "${BOLD}  Dependências base preservadas:${NC}"
    echo ""
    for dep in go node npm python3 pip3 git curl wget nmap jq tmux docker; do
        if cmd_exists "$dep"; then
            echo -e "    ${GREEN}✔${NC} $dep"
        else
            echo -e "    ${DIM}○${NC} $dep (não instalado)"
        fi
    done
    echo ""
    sep
}

# ============================================================================
#  MAIN
# ============================================================================
main() {
    parse_args "$@"
    banner
    need_root

    $DRY_RUN && echo -e "${YELLOW}${BOLD}  ▸ MODO DRY-RUN ATIVO — nenhuma alteração será feita${NC}" && echo ""

    info "Usuário real:  $REAL_USER ($REAL_HOME)"
    info "Log:           $LOG_FILE"
    info "Log level:     $LOG_LEVEL"
    info "Manifest:      $INSTALL_MANIFEST"
    [[ -n "$CACHE_DIR" ]] && info "Cache a remover: $CACHE_DIR"
    sep

    read_manifest
    show_report

    if ! $DRY_RUN; then
        if ! ask "Prosseguir com a limpeza?"; then
            info "Cancelado pelo usuário."
            exit 0
        fi
    fi

    sep
    $DRY_RUN && info "Simulando limpeza..." || info "Iniciando limpeza..."
    sep
    echo ""

    remove_go_tools
    remove_repos
    remove_apt_packages
    remove_pip_packages
    remove_extras
    remove_gems
    remove_frameworks
    remove_cache
    remove_manifest

    post_check

    echo ""
    if $DRY_RUN; then
        echo -e "${YELLOW}${BOLD}  Execute sem --dry-run para aplicar.${NC}"
    else
        echo -e "${GREEN}${BOLD}  Ambiente limpo. Dependências base intactas.${NC}"
    fi
    echo ""
}

main "$@"
