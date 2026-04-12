#!/usr/bin/env bash
# ============================================================================
#  GHOST SETUP — Pentesting Environment Bootstrap (Debian)
#  Author : Samuel Ziger
#
#  Modos:
#    sudo bash ghost-setup.sh                  → online (padrão)
#    sudo bash ghost-setup.sh --cache  <dir>   → baixa tudo pro cache
#    sudo bash ghost-setup.sh --offline <dir>  → instala a partir do cache
# ============================================================================

set -euo pipefail

# ── Cores & Helpers ─────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Modo de operação ───────────────────────────────────────────────────────
MODE="online"    # online | cache | offline
CACHE_DIR=""

# ── Resolver usuário real (quem chamou sudo) ────────────────────────────────
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
if [[ -z "$REAL_HOME" ]] || [[ ! -d "$REAL_HOME" ]]; then
    REAL_HOME="$HOME"
fi

TOOLS_DIR="$REAL_HOME/tools"
GOPATH_DIR="$REAL_HOME/go"
LOG_FILE="/tmp/ghost-setup-$(date +%Y%m%d-%H%M%S).log"
INSTALL_MANIFEST="$REAL_HOME/.ghost-manifest"
PARALLEL_PIDS=()
# Perfil escolhido no início: web | wifi | both
GHOST_ATTACK_MODE=""

# ── CLI parsing ─────────────────────────────────────────────────────────────
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cache)
                MODE="cache"
                CACHE_DIR="${2:?Uso: --cache <diretório>}"
                shift 2
                ;;
            --offline)
                MODE="offline"
                CACHE_DIR="${2:?Uso: --offline <diretório>}"
                shift 2
                ;;
            -h|--help)
                echo "Uso: sudo bash $0 [--cache <dir>] [--offline <dir>]"
                echo ""
                echo "  (sem flags)      Instalação online normal"
                echo "  --cache  <dir>   Baixa tudo para o diretório (precisa de internet)"
                echo "  --offline <dir>  Instala a partir do cache (sem internet)"
                exit 0
                ;;
            *)
                echo "Flag desconhecida: $1"; exit 1 ;;
        esac
    done
}

banner() {
cat << 'EOF'

   ██████╗ ██╗  ██╗ ██████╗ ███████╗████████╗
  ██╔════╝ ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝
  ██║  ███╗███████║██║   ██║███████╗   ██║
  ██║   ██║██╔══██║██║   ██║╚════██║   ██║
  ╚██████╔╝██║  ██║╚██████╔╝███████║   ██║
   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝
        S E T U P  —  by Samuel Ziger

EOF
}

log()  { echo -e "${GREEN}[+]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $*" | tee -a "$LOG_FILE"; }
err()  { echo -e "${RED}[✗]${NC} $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${CYAN}[*]${NC} $*" | tee -a "$LOG_FILE"; }
sep()  { echo -e "${BOLD}────────────────────────────────────────────────${NC}"; }

ask() {
    local prompt="$1" resp
    while true; do
        read -rp "$(echo -e "${YELLOW}[?]${NC} ${prompt} [y/n]: ")" resp
        case "${resp,,}" in
            y|yes) return 0 ;;
            n|no)  return 1 ;;
            *) echo "  Responda y ou n." ;;
        esac
    done
}

choose_attack_mode() {
    sep
    echo ""
    echo -e "${BOLD}  Perfil de instalação:${NC}"
    echo -e "    ${CYAN}1)${NC} Web   — base + módulos + repos + Ghost projects (pentest web/recon)"
    echo -e "    ${CYAN}2)${NC} WiFi  — somente ferramentas wireless (sem Fases 1–4 web)"
    echo -e "    ${CYAN}3)${NC} Ambos — perfil Web completo + pacote WiFi ao final"
    echo ""
    local choice
    while true; do
        read -rp "$(echo -e "${YELLOW}[?]${NC} Modo de instalação [1/2/3]: ")" choice
        case "$choice" in
            1)
                GHOST_ATTACK_MODE="web"
                info "Modo Web selecionado."
                break
                ;;
            2)
                GHOST_ATTACK_MODE="wifi"
                info "Modo WiFi selecionado."
                break
                ;;
            3)
                GHOST_ATTACK_MODE="both"
                info "Modo Web + WiFi selecionado."
                break
                ;;
            *) echo "  Responda 1, 2 ou 3." ;;
        esac
    done
    sep
}

need_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Execute como root: sudo bash $0"
        exit 1
    fi
}

check_network() {
    [[ "$MODE" == "offline" ]] && return 0
    info "Verificando conexão com a internet..."
    if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null && \
       ! ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        err "Sem conexão com a internet — impossível continuar."
        err "Use --offline <cache_dir> para instalar sem rede."
        exit 1
    fi
    if command -v host &>/dev/null; then
        host github.com &>/dev/null 2>&1 || {
            err "DNS não resolve github.com — verifique /etc/resolv.conf"
            exit 1
        }
    else
        ping -c 1 -W 5 github.com &>/dev/null || {
            err "Não consegue alcançar github.com — verifique DNS"
            exit 1
        }
    fi
    log "Rede OK"
}

cmd_exists() { command -v "$1" &>/dev/null; }

# ── Manifest de instalação — registra o que o ghost-setup instalou ──────────
# Formato: TIPO:NOME (ex: GO:subfinder, APT:hydra, REPO:Tools, PIP:wafw00f)
ghost_track() {
    local entry="$1"
    # Evita duplicatas
    if ! grep -qxF "$entry" "$INSTALL_MANIFEST" 2>/dev/null; then
        echo "$entry" >> "$INSTALL_MANIFEST"
    fi
}

# Marca diretório externo como instalado pelo ghost-setup
ghost_mark() {
    local dir="$1"
    [[ -d "$dir" ]] && touch "$dir/.ghost-installed"
}

fix_owner() {
    local target="$1"
    if [[ "$REAL_USER" != "root" ]] && [[ -e "$target" ]]; then
        chown -R "$REAL_USER":"$REAL_USER" "$target" 2>/dev/null || true
    fi
}

run_as_user() {
    if [[ "$REAL_USER" != "root" ]]; then
        su - "$REAL_USER" -c "export PATH='/usr/local/go/bin:$GOPATH_DIR/bin:\$PATH' GOPATH='$GOPATH_DIR'; $*"
    else
        eval "$*"
    fi
}

detect_arch() {
    local arch; arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7*)  echo "armv7" ;;
        *) err "Arquitetura não suportada: $arch"; exit 1 ;;
    esac
}

ARCH=$(detect_arch)

# ============================================================================
#  CACHE — estrutura de diretórios
# ============================================================================
#  ghost-cache/
#  ├── apt/           .deb com dependências
#  ├── go-runtime/    tarball do Go
#  ├── go-bin/        binários compilados das ferramentas Go
#  ├── git/           git bundles (.bundle)
#  ├── pip/           wheels python
#  ├── node/          .deb do nodejs
#  ├── npm-tarballs/  npm pack de cada projeto ghost
#  ├── wifi-apt/      .deb das ferramentas wifi
#  ├── scripts/       instaladores (msf, caido, docker)
#  └── manifest.txt   o que foi cacheado
# ============================================================================

init_cache_dirs() {
    local dirs=(apt go-runtime go-bin git pip node npm-tarballs wifi-apt scripts)
    for d in "${dirs[@]}"; do
        mkdir -p "$CACHE_DIR/$d"
    done
}

validate_cache() {
    if [[ ! -f "$CACHE_DIR/manifest.txt" ]]; then
        err "Cache inválido: $CACHE_DIR/manifest.txt não encontrado"
        err "Gere o cache primeiro: sudo bash $0 --cache $CACHE_DIR"
        exit 1
    fi
    log "Cache validado: $CACHE_DIR"
    cat "$CACHE_DIR/manifest.txt" | while IFS= read -r line; do
        echo -e "    ${CYAN}•${NC} $line"
    done
}

manifest_add() {
    echo "$*" >> "$CACHE_DIR/manifest.txt"
}

# ============================================================================
#  PARALELISMO LEVE
# ============================================================================
run_bg() {
    local label="$1"; shift
    ( "$@" ) >> "$LOG_FILE" 2>&1 &
    PARALLEL_PIDS+=("$!:$label")
}

wait_parallel() {
    [[ ${#PARALLEL_PIDS[@]} -eq 0 ]] && return 0
    info "Aguardando ${#PARALLEL_PIDS[@]} jobs paralelos..."
    local failed=0
    for entry in "${PARALLEL_PIDS[@]}"; do
        local pid="${entry%%:*}" label="${entry#*:}"
        if wait "$pid" 2>/dev/null; then
            log "  $label — OK"
        else
            err "  $label — FALHOU (ver log)"
            ((failed++)) || true
        fi
    done
    PARALLEL_PIDS=()
    if (( failed > 0 )); then
        warn "$failed job(s) falharam — verifique $LOG_FILE"
    fi
}

# ============================================================================
#  VERSIONAMENTO
# ============================================================================
declare -A GO_VERSIONS=(
    [subfinder]="latest"
    [httpx]="latest"
    [dnsx]="latest"
    [ffuf]="latest"
    [gobuster]="latest"
    [amass]="latest"
    [katana]="latest"
    [gau]="latest"
    [nuclei]="latest"
    [gf]="latest"
    [qsreplace]="latest"
    [dalfox]="latest"
)

resolve_version() { echo "${GO_VERSIONS[${1}]:-latest}"; }

# ============================================================================
#  APT HELPERS (online / cache / offline)
# ============================================================================
apt_install() {
    local cache_subdir="${1}"; shift
    local pkgs=("$@")
    case "$MODE" in
        online)
            apt-get install -y -qq "${pkgs[@]}" 2>>"$LOG_FILE"
            ;;
        cache)
            log "Cacheando .debs: ${pkgs[*]}"
            mkdir -p "$CACHE_DIR/$cache_subdir"
            cd "$CACHE_DIR/$cache_subdir"
            apt-get download "${pkgs[@]}" 2>>"$LOG_FILE" || true
            # Também baixar dependências
            for pkg in "${pkgs[@]}"; do
                apt-cache depends --recurse --no-recommends --no-suggests \
                    --no-conflicts --no-breaks --no-replaces --no-enhances \
                    "$pkg" 2>/dev/null \
                    | grep "^\w" \
                    | sort -u \
                    | xargs apt-get download 2>>"$LOG_FILE" || true
            done
            cd - >/dev/null
            manifest_add "APT ($cache_subdir): ${pkgs[*]}"
            # Instalar normalmente também (estamos online no modo cache)
            apt-get install -y -qq "${pkgs[@]}" 2>>"$LOG_FILE"
            ;;
        offline)
            log "Instalando .debs offline de $cache_subdir..."
            if [[ -d "$CACHE_DIR/$cache_subdir" ]] && ls "$CACHE_DIR/$cache_subdir"/*.deb &>/dev/null; then
                dpkg -i "$CACHE_DIR/$cache_subdir"/*.deb 2>>"$LOG_FILE" || true
                # Fix broken deps com o que tiver disponível
                apt-get -f install -y --fix-broken 2>>"$LOG_FILE" || true
            else
                warn "Sem .debs em cache/$cache_subdir — pulando ${pkgs[*]}"
            fi
            ;;
    esac
}

# ============================================================================
#  GO TOOL HELPERS (online / cache / offline)
# ============================================================================
install_go_tool() {
    local name="$1" repo="$2" bin_name="${3:-$1}"
    local ver; ver=$(resolve_version "$name")

    case "$MODE" in
        online)
            cmd_exists "$bin_name" && { warn "$bin_name já instalado — pulando"; return 0; }
            log "Instalando $name@$ver via go install..."
            run_as_user "go install -v '$repo@$ver'" 2>>"$LOG_FILE" || {
                err "Falha ao instalar $name"; return 1
            }
            if [[ -f "$GOPATH_DIR/bin/$bin_name" ]] && [[ ! -f "/usr/local/bin/$bin_name" ]]; then
                ln -sf "$GOPATH_DIR/bin/$bin_name" /usr/local/bin/"$bin_name"
            fi
            ghost_track "GO:$name"
            log "$name@$ver instalado"
            ;;
        cache)
            log "Compilando e cacheando $name@$ver..."
            run_as_user "go install -v '$repo@$ver'" 2>>"$LOG_FILE" || {
                err "Falha ao compilar $name para cache"; return 1
            }
            if [[ -f "$GOPATH_DIR/bin/$bin_name" ]]; then
                cp "$GOPATH_DIR/bin/$bin_name" "$CACHE_DIR/go-bin/$bin_name"
                chmod +x "$CACHE_DIR/go-bin/$bin_name"
                ln -sf "$GOPATH_DIR/bin/$bin_name" /usr/local/bin/"$bin_name" 2>/dev/null || true
                manifest_add "GO: $name@$ver → go-bin/$bin_name"
                ghost_track "GO:$name"
                log "$name cacheado em go-bin/$bin_name"
            fi
            ;;
        offline)
            cmd_exists "$bin_name" && { warn "$bin_name já instalado — pulando"; return 0; }
            if [[ -f "$CACHE_DIR/go-bin/$bin_name" ]]; then
                cp "$CACHE_DIR/go-bin/$bin_name" /usr/local/bin/"$bin_name"
                chmod +x /usr/local/bin/"$bin_name"
                ghost_track "GO:$name"
                log "$name instalado do cache (offline)"
            else
                warn "$name não encontrado no cache — pulando"
            fi
            ;;
    esac
}

install_go_tool_bg() {
    local name="$1" repo="$2" bin_name="${3:-$1}"
    local ver; ver=$(resolve_version "$name")

    case "$MODE" in
        online)
            command -v "$bin_name" &>/dev/null && return 0
            run_as_user "go install -v '$repo@$ver'" || return 1
            [[ -f "$GOPATH_DIR/bin/$bin_name" ]] && [[ ! -f "/usr/local/bin/$bin_name" ]] && \
                ln -sf "$GOPATH_DIR/bin/$bin_name" /usr/local/bin/"$bin_name"
            ghost_track "GO:$name"
            ;;
        cache)
            run_as_user "go install -v '$repo@$ver'" || return 1
            if [[ -f "$GOPATH_DIR/bin/$bin_name" ]]; then
                cp "$GOPATH_DIR/bin/$bin_name" "$CACHE_DIR/go-bin/$bin_name"
                chmod +x "$CACHE_DIR/go-bin/$bin_name"
                ln -sf "$GOPATH_DIR/bin/$bin_name" /usr/local/bin/"$bin_name" 2>/dev/null || true
            fi
            ghost_track "GO:$name"
            ;;
        offline)
            command -v "$bin_name" &>/dev/null && return 0
            if [[ -f "$CACHE_DIR/go-bin/$bin_name" ]]; then
                cp "$CACHE_DIR/go-bin/$bin_name" /usr/local/bin/"$bin_name"
                chmod +x /usr/local/bin/"$bin_name"
                ghost_track "GO:$name"
            fi
            ;;
    esac
}

# ============================================================================
#  GIT HELPERS (online / cache / offline)
# ============================================================================
clone_or_update() {
    local dest="$1" url="$2"
    local bundle_name
    bundle_name=$(basename "$url" .git)

    case "$MODE" in
        online)
            if [[ ! -d "$dest" ]]; then
                git clone --quiet "$url" "$dest"
            else
                git -C "$dest" pull --quiet
            fi
            ;;
        cache)
            # Clone normalmente + gera bundle pro cache
            if [[ ! -d "$dest" ]]; then
                git clone --quiet "$url" "$dest"
            else
                git -C "$dest" pull --quiet
            fi
            log "Gerando bundle de $bundle_name..."
            git -C "$dest" bundle create "$CACHE_DIR/git/${bundle_name}.bundle" --all 2>>"$LOG_FILE"
            manifest_add "GIT: $bundle_name → git/${bundle_name}.bundle"
            ;;
        offline)
            if [[ ! -d "$dest" ]]; then
                local bundle_path="$CACHE_DIR/git/${bundle_name}.bundle"
                if [[ -f "$bundle_path" ]]; then
                    git clone --quiet "$bundle_path" "$dest" 2>>"$LOG_FILE"
                    log "$bundle_name clonado do bundle (offline)"
                else
                    warn "Bundle de $bundle_name não encontrado no cache — pulando"
                    return 1
                fi
            else
                warn "$bundle_name já existe em $dest"
            fi
            ;;
    esac
    fix_owner "$dest"
}

# ============================================================================
#  PIP HELPERS (online / cache / offline)
# ============================================================================
pip_install() {
    local pkg="$1"
    case "$MODE" in
        online)
            pip3 install "$pkg" --break-system-packages 2>>"$LOG_FILE"
            ghost_track "PIP:$pkg"
            ;;
        cache)
            log "Cacheando wheel: $pkg"
            pip3 download "$pkg" -d "$CACHE_DIR/pip/" 2>>"$LOG_FILE" || true
            pip3 install "$pkg" --break-system-packages 2>>"$LOG_FILE"
            manifest_add "PIP: $pkg"
            ghost_track "PIP:$pkg"
            ;;
        offline)
            if ls "$CACHE_DIR/pip/"*.whl &>/dev/null || ls "$CACHE_DIR/pip/"*.tar.gz &>/dev/null; then
                pip3 install --no-index --find-links "$CACHE_DIR/pip/" "$pkg" \
                    --break-system-packages 2>>"$LOG_FILE" || {
                    warn "Falha ao instalar $pkg offline — wheel pode estar faltando"
                    return 1
                }
                ghost_track "PIP:$pkg"
            else
                warn "Sem wheels no cache para $pkg"
            fi
            ;;
    esac
}

# ============================================================================
#  NODE HELPERS (online / cache / offline)
# ============================================================================
install_node_env() {
    log "Verificando Node.js..."
    if cmd_exists node; then
        local node_ver
        node_ver=$(node -v | sed 's/v//' | cut -d. -f1)
        if (( node_ver >= 18 )); then
            log "Node.js $(node -v) OK (>= 18)"
            return 0
        fi
        warn "Node.js $(node -v) < 18 — atualizando..."
    fi

    case "$MODE" in
        online)
            log "Instalando Node.js 22 via NodeSource..."
            curl -fsSL https://deb.nodesource.com/setup_22.x | bash - 2>>"$LOG_FILE"
            apt-get install -y -qq nodejs 2>>"$LOG_FILE"
            ;;
        cache)
            log "Instalando + cacheando Node.js 22..."
            curl -fsSL https://deb.nodesource.com/setup_22.x | bash - 2>>"$LOG_FILE"
            apt-get install -y -qq nodejs 2>>"$LOG_FILE"
            # Cachear o .deb
            cd "$CACHE_DIR/node"
            apt-get download nodejs 2>>"$LOG_FILE" || true
            apt-cache depends --recurse --no-recommends --no-suggests \
                --no-conflicts --no-breaks --no-replaces --no-enhances \
                nodejs 2>/dev/null | grep "^\w" | sort -u | \
                xargs apt-get download 2>>"$LOG_FILE" || true
            cd - >/dev/null
            manifest_add "NODE: nodejs 22"
            ;;
        offline)
            log "Instalando Node.js do cache..."
            if ls "$CACHE_DIR/node/"*.deb &>/dev/null; then
                dpkg -i "$CACHE_DIR/node/"*.deb 2>>"$LOG_FILE" || true
                apt-get -f install -y --fix-broken 2>>"$LOG_FILE" || true
            else
                err "Node.js não encontrado no cache — GHOSTRECON/GHOSTCTF não funcionarão"
                return 1
            fi
            ;;
    esac
    log "Node.js $(node -v) + npm $(npm -v) instalados"
}

setup_node_project() {
    local name="$1" repo="$2"
    local dest="$TOOLS_DIR/$name"

    clone_or_update "$dest" "$repo"

    case "$MODE" in
        online|cache)
            log "Instalando dependências npm de $name..."
            if [[ "$REAL_USER" != "root" ]]; then
                su - "$REAL_USER" -c "cd '$dest' && npm install --production" 2>>"$LOG_FILE"
            else
                cd "$dest" && npm install --production 2>>"$LOG_FILE" && cd - >/dev/null
            fi
            if [[ "$MODE" == "cache" ]]; then
                # Cachear node_modules como tarball
                log "Cacheando node_modules de $name..."
                tar -czf "$CACHE_DIR/npm-tarballs/${name}-node_modules.tar.gz" \
                    -C "$dest" node_modules 2>>"$LOG_FILE"
                manifest_add "NPM: $name → npm-tarballs/${name}-node_modules.tar.gz"
            fi
            ;;
        offline)
            log "Restaurando node_modules de $name do cache..."
            local tarball="$CACHE_DIR/npm-tarballs/${name}-node_modules.tar.gz"
            if [[ -f "$tarball" ]]; then
                tar -xzf "$tarball" -C "$dest" 2>>"$LOG_FILE"
                log "node_modules de $name restaurado"
            else
                warn "Tarball de node_modules de $name não encontrado — tente npm install manual"
            fi
            ;;
    esac

    mkdir -p "$dest/data"
    fix_owner "$dest"
    log "$name pronto!"
}

# ============================================================================
#  SCRIPT/INSTALLER HELPERS (metasploit, caido, docker)
# ============================================================================
cache_script() {
    local name="$1" url="$2" filename="$3"
    log "Cacheando script: $name"
    curl -fsSL "$url" -o "$CACHE_DIR/scripts/$filename" 2>>"$LOG_FILE" || {
        warn "Falha ao cachear $name"
        return 1
    }
    chmod +x "$CACHE_DIR/scripts/$filename"
    manifest_add "SCRIPT: $name → scripts/$filename"
}

# ============================================================================
#  GO RUNTIME (online / cache / offline)
# ============================================================================
install_go_runtime() {
    if cmd_exists go; then
        log "Go já instalado: $(go version | awk '{print $3}')"
        # No modo cache, cachear o tarball mesmo assim
        if [[ "$MODE" == "cache" ]]; then
            local go_ver="1.22.5"
            local go_tar="go${go_ver}.linux-${ARCH}.tar.gz"
            if [[ ! -f "$CACHE_DIR/go-runtime/$go_tar" ]]; then
                wget -q "https://go.dev/dl/${go_tar}" -O "$CACHE_DIR/go-runtime/$go_tar"
                manifest_add "GO-RUNTIME: $go_tar"
            fi
        fi
    else
        local go_ver="1.22.5"
        local go_tar="go${go_ver}.linux-${ARCH}.tar.gz"
        case "$MODE" in
            online)
                log "Instalando Go $go_ver..."
                wget -q "https://go.dev/dl/${go_tar}" -O "/tmp/${go_tar}"
                rm -rf /usr/local/go
                tar -C /usr/local -xzf "/tmp/${go_tar}"
                rm -f "/tmp/${go_tar}"
                ;;
            cache)
                log "Instalando + cacheando Go $go_ver..."
                wget -q "https://go.dev/dl/${go_tar}" -O "/tmp/${go_tar}"
                cp "/tmp/${go_tar}" "$CACHE_DIR/go-runtime/$go_tar"
                rm -rf /usr/local/go
                tar -C /usr/local -xzf "/tmp/${go_tar}"
                rm -f "/tmp/${go_tar}"
                manifest_add "GO-RUNTIME: $go_tar"
                ;;
            offline)
                if [[ -f "$CACHE_DIR/go-runtime/$go_tar" ]]; then
                    log "Instalando Go do cache..."
                    rm -rf /usr/local/go
                    tar -C /usr/local -xzf "$CACHE_DIR/go-runtime/$go_tar"
                else
                    err "Go runtime não encontrado no cache — ferramentas Go não funcionarão online"
                    return 1
                fi
                ;;
        esac
    fi

    export PATH="/usr/local/go/bin:$GOPATH_DIR/bin:$PATH"
    export GOPATH="$GOPATH_DIR"
    cat > /etc/profile.d/go-path.sh << 'GOPATH_SCRIPT'
export GOPATH="$HOME/go"
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
GOPATH_SCRIPT
    log "Go $(go version | awk '{print $3}') OK"
}

# ============================================================================
#  1. BASE OBRIGATÓRIA
# ============================================================================
install_base() {
    sep
    info "FASE 1 — Instalação da base obrigatória"
    sep

    if [[ "$MODE" != "offline" ]]; then
        log "Atualizando repositórios..."
        apt-get update -qq 2>>"$LOG_FILE"
    fi

    local apt_pkgs=(
        nmap whois curl wget git jq tmux unzip
        build-essential python3 python3-pip
        libpcap-dev dnsutils
    )
    apt_install "apt" "${apt_pkgs[@]}"

    install_go_runtime

    # Go tools base — em paralelo
    log "Instalando ferramentas Go base (paralelo)..."
    run_bg "subfinder" install_go_tool_bg "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    run_bg "httpx"     install_go_tool_bg "httpx"     "github.com/projectdiscovery/httpx/cmd/httpx"
    run_bg "dnsx"      install_go_tool_bg "dnsx"      "github.com/projectdiscovery/dnsx/cmd/dnsx"
    run_bg "ffuf"      install_go_tool_bg "ffuf"      "github.com/ffuf/ffuf/v2"
    run_bg "gobuster"  install_go_tool_bg "gobuster"  "github.com/OJ/gobuster/v3"
    wait_parallel
    fix_owner "$GOPATH_DIR"

    sep
    log "Base obrigatória instalada!"
    sep
}

# ============================================================================
#  2. MÓDULOS OPCIONAIS
# ============================================================================
install_modular() {
    sep
    info "FASE 2 — Módulos opcionais"
    sep

    local do_amass=false do_crawler=false do_nuclei=false
    local do_params=false do_dalfox=false do_caido=false
    local do_hydra=false do_dirsearch=false do_msf=false do_hashcat=false

    ask "Instalar enumeração pesada (amass)?"                  && do_amass=true
    ask "Instalar crawler (katana + gau)?"                     && do_crawler=true
    ask "Instalar nuclei (vuln scanner)?"                      && do_nuclei=true
    ask "Instalar ferramentas de parâmetros (gf + qsreplace)?" && do_params=true
    ask "Instalar dalfox (XSS scanner)?"                       && do_dalfox=true
    ask "Instalar Caido (web proxy)?"                          && do_caido=true
    ask "Instalar hydra (brute force)?"                        && do_hydra=true
    ask "Instalar dirsearch (fuzz avançado)?"                  && do_dirsearch=true
    ask "Instalar metasploit-framework?"                       && do_msf=true
    ask "Instalar hashcat (crack/hash)?"                       && do_hashcat=true

    # ── Resumo ──────────────────────────────────────────────────────────────
    sep
    echo ""
    echo -e "${BOLD}  Resumo da instalação modular:${NC}"
    echo -e "    Amass (enum pesada)     : $($do_amass   && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Katana + Gau (crawler)  : $($do_crawler && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Nuclei (vuln scanner)   : $($do_nuclei  && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    gf + qsreplace (params) : $($do_params  && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Dalfox (XSS)            : $($do_dalfox  && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Caido (web proxy)       : $($do_caido   && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Hydra (brute force)     : $($do_hydra   && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Dirsearch (fuzz)        : $($do_dirsearch && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Metasploit              : $($do_msf     && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo -e "    Hashcat (crack)         : $($do_hashcat && echo -e "${GREEN}SIM${NC}" || echo -e "${RED}NÃO${NC}")"
    echo ""

    if ! ask "Confirmar e instalar?"; then
        warn "Instalação modular cancelada."
        return 0
    fi

    sep
    info "Instalando módulos selecionados..."

    # Go tools em paralelo
    $do_amass   && run_bg "amass"     install_go_tool_bg "amass"     "github.com/owasp-amass/amass/v4/cmd/amass" "amass"
    $do_crawler && run_bg "katana"    install_go_tool_bg "katana"    "github.com/projectdiscovery/katana/cmd/katana"
    $do_crawler && run_bg "gau"       install_go_tool_bg "gau"       "github.com/lc/gau/v2/cmd/gau"
    $do_nuclei  && run_bg "nuclei"    install_go_tool_bg "nuclei"    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    $do_params  && run_bg "gf"        install_go_tool_bg "gf"        "github.com/tomnomnom/gf"
    $do_params  && run_bg "qsreplace" install_go_tool_bg "qsreplace" "github.com/tomnomnom/qsreplace"
    $do_dalfox  && run_bg "dalfox"    install_go_tool_bg "dalfox"    "github.com/hahwul/dalfox/v2"

    # APT modular
    local apt_modular=()
    $do_hydra   && apt_modular+=(hydra)
    $do_hashcat && apt_modular+=(hashcat)
    if (( ${#apt_modular[@]} > 0 )); then
        apt_install "apt" "${apt_modular[@]}" &
        PARALLEL_PIDS+=("$!:apt(${apt_modular[*]})")
    fi

    wait_parallel
    fix_owner "$GOPATH_DIR"

    # Registrar APT modulares no manifest
    $do_hydra   && ghost_track "APT:hydra"
    $do_hashcat && ghost_track "APT:hashcat"

    # Pós-install sequencial
    if $do_nuclei && cmd_exists nuclei; then
        log "Atualizando templates do nuclei..."
        if [[ "$MODE" == "cache" ]]; then
            run_as_user "nuclei -update-templates" 2>>"$LOG_FILE" || true
            ghost_track "EXTRA:$REAL_HOME/nuclei-templates"
            # Cachear templates
            local nuclei_tpl="$REAL_HOME/nuclei-templates"
            if [[ -d "$nuclei_tpl" ]]; then
                log "Cacheando nuclei-templates..."
                tar -czf "$CACHE_DIR/git/nuclei-templates.tar.gz" -C "$REAL_HOME" nuclei-templates 2>>"$LOG_FILE"
                manifest_add "NUCLEI-TEMPLATES: nuclei-templates.tar.gz"
            fi
        elif [[ "$MODE" == "offline" ]]; then
            if [[ -f "$CACHE_DIR/git/nuclei-templates.tar.gz" ]]; then
                tar -xzf "$CACHE_DIR/git/nuclei-templates.tar.gz" -C "$REAL_HOME" 2>>"$LOG_FILE"
                fix_owner "$REAL_HOME/nuclei-templates"
                ghost_track "EXTRA:$REAL_HOME/nuclei-templates"
                log "nuclei-templates restaurados do cache"
            fi
        else
            run_as_user "nuclei -update-templates" 2>>"$LOG_FILE" || true
            ghost_track "EXTRA:$REAL_HOME/nuclei-templates"
        fi
    fi

    if $do_params; then
        local gf_dir="$REAL_HOME/.gf"
        if [[ ! -d "$gf_dir" ]]; then
            mkdir -p "$gf_dir"
            case "$MODE" in
                online|cache)
                    git clone --quiet https://github.com/1ndianl33t/Gf-Patterns.git /tmp/gf-patterns 2>>"$LOG_FILE" || true
                    cp /tmp/gf-patterns/*.json "$gf_dir/" 2>/dev/null || true
                    if [[ "$MODE" == "cache" ]]; then
                        cp /tmp/gf-patterns/*.json "$CACHE_DIR/git/gf-patterns/" 2>/dev/null || {
                            mkdir -p "$CACHE_DIR/git/gf-patterns"
                            cp /tmp/gf-patterns/*.json "$CACHE_DIR/git/gf-patterns/" 2>/dev/null || true
                        }
                        manifest_add "GF-PATTERNS: git/gf-patterns/"
                    fi
                    rm -rf /tmp/gf-patterns
                    ;;
                offline)
                    if [[ -d "$CACHE_DIR/git/gf-patterns" ]]; then
                        cp "$CACHE_DIR/git/gf-patterns/"*.json "$gf_dir/" 2>/dev/null || true
                    else
                        warn "gf patterns não encontrados no cache"
                    fi
                    ;;
            esac
            fix_owner "$gf_dir"
            ghost_track "EXTRA:$gf_dir"
            log "gf patterns instalados em $gf_dir"
        fi
    fi

    if $do_caido; then
        if ! cmd_exists caido-cli; then
            case "$MODE" in
                online)
                    log "Instalando Caido..."
                    bash <(curl -fsSL https://storage.caido.io/releases/cli/install.sh) 2>>"$LOG_FILE" || {
                        warn "Falha no install do Caido — tente manual: https://docs.caido.io"
                    }
                    ;;
                cache)
                    cache_script "caido" "https://storage.caido.io/releases/cli/install.sh" "caido-install.sh"
                    bash "$CACHE_DIR/scripts/caido-install.sh" 2>>"$LOG_FILE" || {
                        warn "Falha no install do Caido"
                    }
                    ;;
                offline)
                    if [[ -f "$CACHE_DIR/scripts/caido-install.sh" ]]; then
                        warn "Caido install script requer internet — execute manual após conectar"
                    else
                        warn "Caido não cacheado"
                    fi
                    ;;
            esac
        else
            warn "Caido já instalado"
        fi
    fi

    if $do_dirsearch; then
        if [[ ! -d "$TOOLS_DIR/dirsearch" ]]; then
            mkdir -p "$TOOLS_DIR"
            clone_or_update "$TOOLS_DIR/dirsearch" "https://github.com/maurosoria/dirsearch.git"
            ln -sf "$TOOLS_DIR/dirsearch/dirsearch.py" /usr/local/bin/dirsearch
            ghost_track "REPO:dirsearch"
            log "dirsearch instalado em $TOOLS_DIR/dirsearch"
        else
            warn "dirsearch já presente"
        fi
    fi

    if $do_msf; then
        if ! cmd_exists msfconsole; then
            local msf_url="https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb"
            case "$MODE" in
                online)
                    log "Instalando Metasploit..."
                    curl -fsSL "$msf_url" > /tmp/msfinstall
                    chmod +x /tmp/msfinstall && /tmp/msfinstall 2>>"$LOG_FILE"
                    rm -f /tmp/msfinstall
                    ;;
                cache)
                    cache_script "metasploit" "$msf_url" "msfinstall"
                    cp "$CACHE_DIR/scripts/msfinstall" /tmp/msfinstall
                    chmod +x /tmp/msfinstall && /tmp/msfinstall 2>>"$LOG_FILE"
                    rm -f /tmp/msfinstall
                    ;;
                offline)
                    if [[ -f "$CACHE_DIR/scripts/msfinstall" ]]; then
                        warn "Metasploit installer requer internet — execute manual após conectar:"
                        warn "  bash $CACHE_DIR/scripts/msfinstall"
                    else
                        warn "Metasploit não cacheado"
                    fi
                    ;;
            esac
            cmd_exists msfconsole && ghost_track "FRAMEWORK:metasploit"
        else
            warn "Metasploit já instalado"
        fi
    fi

    sep
    log "Módulos opcionais finalizados!"
    sep
}

# ============================================================================
#  3. FERRAMENTAS PESSOAIS (clones em paralelo)
# ============================================================================
install_personal_tools() {
    sep
    info "FASE 3 — Ferramentas pessoais (GitHub)"
    sep

    mkdir -p "$TOOLS_DIR"

    local do_tools=false do_shannon=false do_pentestgpt=false
    ask "Clonar Samuel-Ziger/Tools?"     && do_tools=true
    ask "Clonar Samuel-Ziger/Shannon?"    && do_shannon=true
    ask "Clonar Samuel-Ziger/PentestGPT?" && do_pentestgpt=true

    $do_tools      && run_bg "Tools"      clone_or_update "$TOOLS_DIR/Tools"      "https://github.com/Samuel-Ziger/Tools.git"
    $do_shannon    && run_bg "Shannon"    clone_or_update "$TOOLS_DIR/shannon"    "https://github.com/Samuel-Ziger/shannon.git"
    $do_pentestgpt && run_bg "PentestGPT" clone_or_update "$TOOLS_DIR/PentestGPT" "https://github.com/Samuel-Ziger/PentestGPT.git"

    wait_parallel
    fix_owner "$TOOLS_DIR"

    # Registrar repos no manifest
    $do_tools      && ghost_track "REPO:Tools"
    $do_shannon    && ghost_track "REPO:shannon"
    $do_pentestgpt && ghost_track "REPO:PentestGPT"

    sep
}

# ============================================================================
#  4. GHOST PROJECTS (GHOSTRECON + GHOSTCTF)
# ============================================================================
install_ghost_projects() {
    sep
    info "FASE 4 — GHOSTRECON & GHOSTCTF"
    sep

    local do_ghostrecon=false do_ghostctf=false
    ask "Instalar GHOSTRECON?" && do_ghostrecon=true
    ask "Instalar GHOSTCTF?"   && do_ghostctf=true

    if ! $do_ghostrecon && ! $do_ghostctf; then
        info "Nenhum Ghost project selecionado — pulando."
        return 0
    fi

    install_node_env

    $do_ghostrecon && setup_node_project "GHOSTRECON" "https://github.com/Samuel-Ziger/GHOSTRECON.git" && ghost_track "REPO:GHOSTRECON"
    $do_ghostctf   && setup_node_project "GHOSTCTF"   "https://github.com/Samuel-Ziger/GHOSTCTF.git" && ghost_track "REPO:GHOSTCTF"

    # Deps obrigatórias dos Ghost projects
    sep
    info "Dependências obrigatórias dos Ghost projects..."
    sep

    for dep in nmap whois curl; do
        cmd_exists "$dep" || apt_install "apt" "$dep"
    done

    log "Go tools dos Ghost projects (paralelo)..."
    run_bg "subfinder-g"  install_go_tool_bg "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    run_bg "httpx-g"      install_go_tool_bg "httpx"     "github.com/projectdiscovery/httpx/cmd/httpx"
    run_bg "ffuf-g"       install_go_tool_bg "ffuf"      "github.com/ffuf/ffuf/v2"
    run_bg "nuclei-g"     install_go_tool_bg "nuclei"    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    run_bg "katana-g"     install_go_tool_bg "katana"    "github.com/projectdiscovery/katana/cmd/katana"
    run_bg "gau-g"        install_go_tool_bg "gau"       "github.com/lc/gau/v2/cmd/gau"
    run_bg "dalfox-g"     install_go_tool_bg "dalfox"    "github.com/hahwul/dalfox/v2"
    run_bg "amass-g"      install_go_tool_bg "amass"     "github.com/owasp-amass/amass/v4/cmd/amass" "amass"
    wait_parallel
    fix_owner "$GOPATH_DIR"

    # Python tools
    cmd_exists wafw00f || { log "Instalando wafw00f..."; pip_install wafw00f || true; }
    cmd_exists arjun   || { log "Instalando arjun...";   pip_install arjun   || true; }

    # searchsploit
    if ! cmd_exists searchsploit; then
        log "Instalando exploitdb (searchsploit)..."
        if [[ ! -d "/opt/exploitdb" ]]; then
            clone_or_update "/opt/exploitdb" "https://gitlab.com/exploit-database/exploitdb.git"
            ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit
            ghost_mark "/opt/exploitdb"
            ghost_track "EXTRA:/opt/exploitdb"
        fi
    fi

    # wpscan
    if ! cmd_exists wpscan; then
        log "Instalando wpscan..."
        apt_install "apt" ruby ruby-dev
        if gem install wpscan 2>>"$LOG_FILE"; then
            ghost_track "GEM:wpscan"
        else
            warn "wpscan falhou — ajuste manual"
        fi
    fi

    # Docker
    if ! cmd_exists docker; then
        if ask "Instalar Docker (para docker build dos Ghost projects)?"; then
            case "$MODE" in
                online)
                    log "Instalando Docker..."
                    curl -fsSL https://get.docker.com | sh 2>>"$LOG_FILE"
                    ;;
                cache)
                    cache_script "docker" "https://get.docker.com" "get-docker.sh"
                    bash "$CACHE_DIR/scripts/get-docker.sh" 2>>"$LOG_FILE"
                    ;;
                offline)
                    if [[ -f "$CACHE_DIR/scripts/get-docker.sh" ]]; then
                        warn "Docker installer requer internet — execute após conectar:"
                        warn "  bash $CACHE_DIR/scripts/get-docker.sh"
                    else
                        warn "Docker não cacheado"
                    fi
                    ;;
            esac
            if cmd_exists docker; then
                usermod -aG docker "$REAL_USER" 2>/dev/null || true
                systemctl enable --now docker 2>>"$LOG_FILE" || true
                log "Docker instalado — $REAL_USER no grupo docker"
            fi
        fi
    else
        warn "Docker já instalado"
    fi

    sep
    log "Ghost projects configurados!"
    sep
}

# ============================================================================
#  5. WIFI ATTACK TOOLS (automático)
# ============================================================================
install_wifi_tools() {
    sep
    info "Instalando ferramentas WiFi (automático)..."
    sep

    local wifi_pkgs=(aircrack-ng iw wireless-tools wifite reaver bully)
    apt_install "wifi-apt" "${wifi_pkgs[@]}"

    for pkg in "${wifi_pkgs[@]}"; do
        ghost_track "APT:$pkg"
    done

    cmd_exists airodump-ng && log "aircrack-ng suite (airodump-ng, aireplay-ng, etc.) OK"
    log "Ferramentas WiFi instaladas!"
}

# ============================================================================
#  RESUMO FINAL
# ============================================================================
show_summary() {
    sep
    echo ""
    echo -e "${GREEN}${BOLD}  ✔ GHOST SETUP FINALIZADO${NC}"
    [[ "$MODE" != "online" ]] && echo -e "${CYAN}     Modo: ${BOLD}${MODE}${NC}"
    echo ""
    info "Usuário real: $REAL_USER ($REAL_HOME)"
    info "Log completo: $LOG_FILE"
    info "Ferramentas em: $TOOLS_DIR"
    [[ -n "$GHOST_ATTACK_MODE" ]] && info "Perfil:       $GHOST_ATTACK_MODE"
    [[ -n "$CACHE_DIR" ]] && info "Cache em: $CACHE_DIR"
    echo ""

    if [[ "$MODE" == "cache" ]]; then
        echo -e "${BOLD}  Conteúdo do cache:${NC}"
        echo ""
        cat "$CACHE_DIR/manifest.txt" | while IFS= read -r line; do
            echo -e "    ${CYAN}•${NC} $line"
        done
        echo ""
        local cache_size
        cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')
        info "Tamanho total do cache: $cache_size"
        echo ""
        info "Para instalar offline:"
        info "  sudo bash $0 --offline $CACHE_DIR"
        echo ""
    fi

    echo -e "${BOLD}  Ferramentas detectadas:${NC}"
    local tools_check=(
        subfinder httpx dnsx ffuf gobuster nmap whois
        curl wget git jq tmux
        amass katana gau nuclei dalfox
        gf qsreplace hydra hashcat
        msfconsole dirsearch wpscan
        wafw00f arjun searchsploit
        aircrack-ng wifite reaver bully
        node npm docker
    )
    local found=0 missing=0
    for t in "${tools_check[@]}"; do
        if cmd_exists "$t"; then
            echo -e "    ${GREEN}✔${NC} $t"
            ((found++))
        else
            echo -e "    ${RED}✗${NC} $t  (não selecionado ou falhou)"
            ((missing++))
        fi
    done
    echo ""
    info "Instalados: $found | Ausentes/opcionais: $missing"

    echo ""
    echo -e "${CYAN}  Diretórios de projetos:${NC}"
    for d in "$TOOLS_DIR"/*/; do
        [[ -d "$d" ]] && echo -e "    📁 $d"
    done

    echo ""
    info "Reinicie o terminal ou execute: source /etc/profile.d/go-path.sh"
    sep
}

# ============================================================================
#  MAIN
# ============================================================================
main() {
    parse_args "$@"
    banner
    need_root

    # Setup do cache
    if [[ "$MODE" == "cache" ]]; then
        mkdir -p "$CACHE_DIR"
        CACHE_DIR="$(cd "$CACHE_DIR" && pwd)"  # path absoluto
        init_cache_dirs
        : > "$CACHE_DIR/manifest.txt"  # limpa manifest
        info "MODO CACHE — salvando tudo em: $CACHE_DIR"
    elif [[ "$MODE" == "offline" ]]; then
        CACHE_DIR="$(cd "$CACHE_DIR" && pwd)"
        validate_cache
        info "MODO OFFLINE — instalando de: $CACHE_DIR"
    fi

    check_network

    # Inicializar manifest de instalação (append, não sobrescreve)
    touch "$INSTALL_MANIFEST"
    fix_owner "$INSTALL_MANIFEST"

    info "Usuário real: $REAL_USER"
    info "Home real:    $REAL_HOME"
    info "Log:          $LOG_FILE"
    info "Manifest:     $INSTALL_MANIFEST"
    info "Arch:         $ARCH"
    info "Modo:         $MODE"
    info "Ferramentas:  $TOOLS_DIR"
    sep

    choose_attack_mode

    case "$GHOST_ATTACK_MODE" in
        web)
            install_base
            install_modular
            install_personal_tools
            install_ghost_projects
            ;;
        wifi)
            if [[ "$MODE" != "offline" ]]; then
                log "Atualizando repositórios..."
                apt-get update -qq 2>>"$LOG_FILE"
            fi
            install_wifi_tools
            ;;
        both)
            install_base
            install_modular
            install_personal_tools
            install_ghost_projects
            install_wifi_tools
            ;;
        *)
            err "Perfil de instalação inválido (interno)."
            exit 1
            ;;
    esac

    show_summary

    echo ""
    echo -e "${GREEN}${BOLD}  Bora caçar. 🎯${NC}"
    echo ""
}

main "$@"
