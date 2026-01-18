#!/bin/bash

###############################################################################
# install_tools.sh - Instalação de Ferramentas de Reconhecimento
# Autor: Red Team Automation
# Descrição: Script para instalar todas as ferramentas necessárias para recon.sh
# Uso: ./install_tools.sh
###############################################################################

set -euo pipefail

###############################################################################
# CONFIGURAÇÕES
###############################################################################

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretórios
GOPATH="${GOPATH:-$HOME/go}"
GOBIN="${GOBIN:-$GOPATH/bin}"
GOPRIVATE="${GOPRIVATE:-}"

# Cores para output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $*"
}

###############################################################################
# VERIFICAÇÕES DE PRÉ-REQUISITOS
###############################################################################

check_go() {
    log_info "Verificando Go..."
    if command -v go &> /dev/null; then
        local go_version=$(go version | awk '{print $3}')
        log_success "Go instalado: $go_version"
        return 0
    else
        log_error "Go não encontrado!"
        log_warn "Instale Go primeiro: https://golang.org/doc/install"
        return 1
    fi
}

check_python3() {
    log_info "Verificando Python3..."
    if command -v python3 &> /dev/null; then
        local py_version=$(python3 --version)
        log_success "Python3 instalado: $py_version"
        return 0
    else
        log_error "Python3 não encontrado!"
        log_warn "Instale Python3 primeiro: apt-get install python3 python3-pip"
        return 1
    fi
}

check_system_tools() {
    log_info "Verificando ferramentas do sistema..."
    local missing=0
    
    if ! command -v nmap &> /dev/null; then
        log_warn "nmap não encontrado (opcional, mas recomendado)"
        missing=$((missing + 1))
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "git não encontrado! Necessário para clonar repositórios."
        missing=$((missing + 1))
    fi
    
    if [ $missing -eq 0 ]; then
        log_success "Ferramentas do sistema OK"
        return 0
    else
        return 1
    fi
}

check_prerequisites() {
    log_step "Verificando pré-requisitos..."
    
    local failed=0
    
    check_go || failed=$((failed + 1))
    check_python3 || failed=$((failed + 1))
    check_system_tools || failed=$((failed + 1))
    
    if [ $failed -gt 0 ]; then
        log_error "Alguns pré-requisitos estão faltando. Instale antes de continuar."
        exit 1
    fi
    
    # Adicionar GOBIN ao PATH se necessário
    if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
        log_info "Adicionando $GOBIN ao PATH..."
        export PATH="$GOBIN:$PATH"
        log_warn "Adicione esta linha ao seu ~/.bashrc ou ~/.zshrc:"
        echo -e "${YELLOW}export PATH=\"\$PATH:\$HOME/go/bin\"${NC}"
    fi
    
    log_success "Todos os pré-requisitos estão instalados!"
}

###############################################################################
# INSTALAÇÃO DE FERRAMENTAS GO
###############################################################################

install_go_tool() {
    local tool="$1"
    local package="$2"
    local description="${3:-$tool}"
    
    log_info "Instalando $description..."
    
    if command -v "$tool" &> /dev/null; then
        local version=$("$tool" -version 2>/dev/null | head -1 || echo "instalado")
        log_success "$description já instalado: $version"
        return 0
    fi
    
    # Tentar instalar
    if go install "$package"@latest 2>&1 | tee /tmp/install_${tool}.log; then
        log_success "$description instalado com sucesso!"
        
        # Verificar se o binário foi criado
        if [ -f "$GOBIN/$tool" ]; then
            log_info "Binário criado em: $GOBIN/$tool"
        fi
        return 0
    else
        log_error "Falha ao instalar $description"
        log_warn "Log: /tmp/install_${tool}.log"
        return 1
    fi
}

install_go_tools() {
    log_step "Instalando ferramentas Go..."
    
    # Lista de ferramentas Go (package:binário)
    # Nota: amass não é instalado aqui (via apt/release oficial)
    # Nota: uro pode ser Go ou Python, instalamos Python depois
    declare -A go_tools=(
        ["github.com/projectdiscovery/subfinder/v2/cmd/subfinder"]="subfinder"
        ["github.com/tomnomnom/assetfinder"]="assetfinder"
        ["github.com/tomnomnom/anew"]="anew"
        ["github.com/projectdiscovery/dnsx/cmd/dnsx"]="dnsx"
        ["github.com/projectdiscovery/httpx/cmd/httpx"]="httpx"
        ["github.com/lc/gau/v2/cmd/gau"]="gau"
        ["github.com/projectdiscovery/katana/cmd/katana"]="katana"
        ["github.com/tomnomnom/gf"]="gf"
        ["github.com/projectdiscovery/naabu/v2/cmd/naabu"]="naabu"
        ["github.com/projectdiscovery/nuclei/v3/cmd/nuclei"]="nuclei"
        ["github.com/projectdiscovery/notify/cmd/notify"]="notify"
        ["github.com/projectdiscovery/tlsx/cmd/tlsx"]="tlsx"
    )
    
    local failed=0
    local installed=0
    
    for package in "${!go_tools[@]}"; do
        tool="${go_tools[$package]}"
        
        if install_go_tool "$tool" "$package"; then
            installed=$((installed + 1))
        else
            failed=$((failed + 1))
        fi
    done
    
    log_info "Ferramentas Go: ${installed} instaladas, ${failed} falhas"
    
    # Atualizar nuclei templates e instalar templates customizados
    if command -v nuclei &> /dev/null; then
        log_info "Atualizando templates do nuclei..."
        nuclei -update-templates -silent 2>/dev/null || \
            log_warn "Falha ao atualizar templates do nuclei (pode atualizar manualmente depois)"
    fi
}

###############################################################################
# INSTALAÇÃO DO AMASS (VIA APT OU RELEASE OFICIAL)
###############################################################################

install_amass() {
    log_step "Instalando amass..."
    
    if command -v amass &> /dev/null; then
        local amass_version=$(amass version 2>/dev/null | head -1 || echo "instalado")
        log_success "amass já instalado: $amass_version"
        return 0
    fi
    
    # Tentar via apt primeiro (mais fácil)
    if command -v apt-get &> /dev/null; then
        log_info "Tentando instalar amass via apt..."
        if sudo apt-get update && sudo apt-get install -y amass 2>&1 | tee /tmp/install_amass.log; then
            log_success "amass instalado via apt!"
            return 0
        else
            log_warn "Falha ao instalar via apt. Tentando release oficial..."
        fi
    fi
    
    # Fallback: Download do release oficial do GitHub
    log_info "Baixando amass do release oficial..."
    
    local arch=$(uname -m)
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) arch="amd64" ;;
    esac
    
    local os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local latest_tag=$(curl -s https://api.github.com/repos/owasp-amass/amass/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' || echo "")
    
    if [ -z "$latest_tag" ]; then
        log_error "Não foi possível obter a versão mais recente do amass"
        log_warn "Instale manualmente: https://github.com/owasp-amass/amass/releases"
        return 1
    fi
    
    local download_url="https://github.com/owasp-amass/amass/releases/download/${latest_tag}/amass_${os}_${arch}.zip"
    local temp_dir=$(mktemp -d)
    
    if curl -L -o "${temp_dir}/amass.zip" "$download_url" 2>&1 | tee /tmp/install_amass.log; then
        if unzip -q "${temp_dir}/amass.zip" -d "${temp_dir}" && [ -f "${temp_dir}/amass" ] || [ -f "${temp_dir}/amass_${os}_${arch}/amass" ]; then
            local amass_bin=$(find "${temp_dir}" -name "amass" -type f | head -1)
            if [ -n "$amass_bin" ]; then
                sudo cp "$amass_bin" /usr/local/bin/amass
                sudo chmod +x /usr/local/bin/amass
                log_success "amass instalado do release oficial (${latest_tag})!"
                rm -rf "${temp_dir}"
                return 0
            fi
        fi
    fi
    
    log_error "Falha ao instalar amass"
    log_warn "Instale manualmente: https://github.com/owasp-amass/amass/releases"
    rm -rf "${temp_dir}"
    return 1
}

###############################################################################
# INSTALAÇÃO DE FERRAMENTAS PYTHON
###############################################################################

install_python_tools() {
    log_step "Instalando ferramentas Python..."
    
    # uro (pode ser instalado via Go ou Python, vamos usar Python para compatibilidade)
    log_info "Instalando uro..."
    
    if command -v uro &> /dev/null; then
        local uro_version=$(uro --version 2>/dev/null || echo "instalado")
        log_success "uro já instalado: $uro_version"
    elif pip3 install uro 2>&1 | tee /tmp/install_uro.log; then
        log_success "uro instalado com sucesso!"
    else
        log_error "Falha ao instalar uro"
        log_warn "Tente: pip3 install uro"
    fi
}

###############################################################################
# INSTALAÇÃO DE GF PATTERNS
###############################################################################

install_gf_patterns() {
    log_step "Instalando gf patterns..."
    
    local gf_dir="$HOME/.gf"
    local temp_gf_dir=$(mktemp -d)
    
    if [ ! -d "$gf_dir" ]; then
        log_info "Criando diretório gf: $gf_dir"
        mkdir -p "$gf_dir"
    fi
    
    # Clonar repositório em diretório temporário
    log_info "Baixando gf patterns do 1ndianl33t..."
    
    if [ -d "$gf_dir/.git" ]; then
        log_info "Atualizando gf patterns..."
        cd "$gf_dir" && git pull 2>/dev/null || log_warn "Falha ao atualizar patterns via git"
        # Mesmo atualizando, vamos garantir que os .json estão em ~/.gf diretamente
        find "$gf_dir" -name "*.json" -type f -exec cp {} "$gf_dir/" \; 2>/dev/null || true
    else
        # Clonar em diretório temporário primeiro
        if git clone https://github.com/1ndianl33t/Gf-Patterns "$temp_gf_dir" 2>&1 | tee /tmp/install_gf_patterns.log; then
            log_info "Copiando patterns para ~/.gf (garantindo que .json estão direto no diretório)..."
            
            # Copiar todos os .json encontrados (em qualquer subpasta) para ~/.gf diretamente
            find "$temp_gf_dir" -name "*.json" -type f -exec cp {} "$gf_dir/" \; 2>/dev/null || true
            
            # Também copiar arquivos da raiz do repositório (se houver)
            if [ -d "$temp_gf_dir" ]; then
                cp "$temp_gf_dir"/*.json "$gf_dir/" 2>/dev/null || true
            fi
            
            log_success "gf patterns instalados!"
        else
            log_warn "Falha ao clonar patterns (pode instalar manualmente depois)"
            log_warn "Execute: git clone https://github.com/1ndianl33t/Gf-Patterns && find Gf-Patterns -name '*.json' -exec cp {} ~/.gf/ \\;"
        fi
    fi
    
    # Limpar diretório temporário
    rm -rf "${temp_gf_dir}" 2>/dev/null || true
    
    # Instalar xss.json customizado
    install_custom_xss_pattern "$gf_dir"
    
    # Verificar padrões essenciais
    local patterns=("xss" "sqli" "lfi" "ssrf" "redirect" "rce" "idor")
    local found=0
    
    for pattern in "${patterns[@]}"; do
        if [ -f "$gf_dir/${pattern}.json" ]; then
            found=$((found + 1))
        fi
    done
    
    if [ $found -gt 0 ]; then
        log_success "Encontrados ${found} padrões essenciais em $gf_dir/"
    else
        log_warn "Padrões gf não encontrados. Instale manualmente se necessário."
    fi
}

# Instalar xss.json customizado
install_custom_xss_pattern() {
    local gf_dir="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local xss_file="${script_dir}/xss.json"
    
    # Verificar se xss.json customizado existe no diretório do script
    if [ -f "$xss_file" ]; then
        log_info "Instalando xss.json customizado..."
        cp "$xss_file" "$gf_dir/xss.json"
        log_success "xss.json customizado instalado!"
    else
        log_info "Criando xss.json customizado..."
        cat > "$gf_dir/xss.json" << 'EOF'
{
  "flags": "-iE",
  "patterns": [
    "\\?",
    "=",
    "q=",
    "s=",
    "search=",
    "query=",
    "keyword=",
    "term=",
    "lookup=",
    "find=",
    "text=",
    "callback=",
    "cb=",
    "jsonp=",
    "redirect=",
    "redir=",
    "return=",
    "returnto=",
    "next=",
    "continue=",
    "url=",
    "uri=",
    "dest=",
    "destination=",
    "forward=",
    "out=",
    "page=",
    "p=",
    "view=",
    "file=",
    "filename=",
    "path=",
    "folder=",
    "dir=",
    "document=",
    "ref=",
    "reference=",
    "source=",
    "src=",
    "origin=",
    "lang=",
    "locale=",
    "country=",
    "region=",
    "timezone=",
    "msg=",
    "message=",
    "error=",
    "err=",
    "warning=",
    "alert=",
    "notice=",
    "user=",
    "username=",
    "userid=",
    "uid=",
    "account=",
    "profile=",
    "name=",
    "fullname=",
    "firstname=",
    "lastname=",
    "nickname=",
    "email=",
    "mail=",
    "phone=",
    "mobile=",
    "comment=",
    "comments=",
    "feedback=",
    "review=",
    "rating=",
    "bio=",
    "about=",
    "content=",
    "data=",
    "value=",
    "val=",
    "input=",
    "payload=",
    "html=",
    "body=",
    "template=",
    "tpl=",
    "render=",
    "style=",
    "css=",
    "theme=",
    "color=",
    "script=",
    "js=",
    "javascript=",
    "code=",
    "event=",
    "onload=",
    "onerror=",
    "onclick=",
    "id=",
    "item=",
    "key=",
    "token=",
    "auth=",
    "access=",
    "debug=",
    "test=",
    "demo=",
    "sample=",
    "example="
  ]
}
EOF
        log_success "xss.json customizado criado!"
    fi
}

###############################################################################
# INSTALAÇÃO DE TEMPLATES CUSTOMIZADOS DO NUCLEI
###############################################################################

install_custom_nuclei_templates() {
    log_step "Instalando templates customizados do nuclei..."
    
    # Diretório de templates customizados do nuclei
    local custom_templates_dir="$HOME/nuclei-templates"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local sqli_template="${script_dir}/sqli.yaml"
    
    # Criar diretório se não existir
    if [ ! -d "$custom_templates_dir" ]; then
        log_info "Criando diretório de templates customizados: $custom_templates_dir"
        mkdir -p "$custom_templates_dir"
    fi
    
    # Instalar sqli.yaml customizado
    if [ -f "$sqli_template" ]; then
        log_info "Instalando sqli.yaml customizado..."
        cp "$sqli_template" "$custom_templates_dir/sqli.yaml"
        log_success "sqli.yaml customizado instalado em $custom_templates_dir/"
    else
        log_info "Criando sqli.yaml customizado..."
        cat > "$custom_templates_dir/sqli.yaml" << 'EOF'
id: sqli-erro-check

info:
  name: SQL Injection Error Check
  author: ziger
  severity: critical

http:
  - method: GET
    path:
      - "{{BaseURL}}"

    payloads:
      injection:
        - "'"
        - "\""

    stop-at-first-match: true

    fuzzing:
      - part: query
        type: postfix
        mode: single
        fuzz:
          - "{{injection}}"

    matchers-condition: and
    matchers:
      - type: word
        part: body
        words:
          - "SQL syntax"
          - "mysql_fetch_array"
          - "mysql_num_rows"
          - "You have an error in your SQL syntax"
          - "Unclosed quotation mark after the character string"
          - "Microsoft OLE DB Provider for SQL Server"
          - "Oracle Text error"
          - "ORA-01756"
          - "PostgreSQL query failed"
          - "supplied argument is not a valid PostgreSQL result"
          - "Warning: pg_"
          - "invalid input syntax for type"
        case-insensitive: true
EOF
        log_success "sqli.yaml customizado criado em $custom_templates_dir/"
    fi
    
    log_info "Para usar templates customizados do nuclei, adicione -t $custom_templates_dir ao comando"
}

###############################################################################
# INSTALAÇÃO DE FERRAMENTAS DO SISTEMA
###############################################################################

install_system_tools() {
    log_step "Verificando ferramentas do sistema..."
    
    # nmap (geralmente já instalado em Kali/Debian)
    if ! command -v nmap &> /dev/null; then
        log_warn "nmap não encontrado"
        log_info "Para instalar: sudo apt-get install nmap"
    else
        local nmap_version=$(nmap --version | head -1)
        log_success "nmap instalado: $nmap_version"
    fi
}

###############################################################################
# VALIDAÇÃO FINAL
###############################################################################

validate_installations() {
    log_step "Validando instalações..."
    
    local tools=(
        "subfinder"
        "assetfinder"
        "amass"
        "anew"
        "dnsx"
        "httpx"
        "gau"
        "katana"
        "uro"
        "gf"
        "naabu"
        "nmap"
        "nuclei"
        "notify"
    )
    
    local optional_tools=("tlsx")
    
    local installed=0
    local missing=0
    local optional_installed=0
    
    log_info "Verificando ferramentas essenciais..."
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "✓ $tool"
            installed=$((installed + 1))
        else
            log_error "✗ $tool (FALTANDO)"
            missing=$((missing + 1))
        fi
    done
    
    log_info "Verificando ferramentas opcionais..."
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "✓ $tool (opcional)"
            optional_installed=$((optional_installed + 1))
        else
            log_warn "✗ $tool (opcional, não instalado)"
        fi
    done
    
    echo ""
    log_info "Resumo da instalação:"
    echo -e "  ${GREEN}Instaladas:${NC} ${installed}"
    echo -e "  ${RED}Faltando:${NC} ${missing}"
    echo -e "  ${YELLOW}Opcionais:${NC} ${optional_installed}/${#optional_tools[@]}"
    
    if [ $missing -eq 0 ]; then
        echo ""
        log_success "Todas as ferramentas essenciais estão instaladas!"
        return 0
    else
        echo ""
        log_error "${missing} ferramenta(s) essenciais faltando!"
        log_warn "Verifique os logs de instalação em /tmp/install_*.log"
        return 1
    fi
}

###############################################################################
# CONFIGURAÇÃO FINAL
###############################################################################

setup_final() {
    log_step "Configuração final..."
    
    # Verificar PATH
    if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
        log_warn "GOBIN não está no PATH atual"
        echo ""
        echo -e "${YELLOW}Para adicionar permanentemente ao PATH:${NC}"
        echo -e "  ${CYAN}echo 'export PATH=\"\$PATH:\$HOME/go/bin\"' >> ~/.bashrc${NC}"
        echo -e "  ${CYAN}source ~/.bashrc${NC}"
        echo ""
        echo -e "${YELLOW}Ou para zsh:${NC}"
        echo -e "  ${CYAN}echo 'export PATH=\"\$PATH:\$HOME/go/bin\"' >> ~/.zshrc${NC}"
        echo -e "  ${CYAN}source ~/.zshrc${NC}"
        echo ""
    fi
    
    # Verificar nuclei templates
    if command -v nuclei &> /dev/null; then
        log_info "Para atualizar templates do nuclei:"
        echo -e "  ${CYAN}nuclei -update-templates${NC}"
    fi
    
    # Verificar gf patterns
    if [ ! -d "$HOME/.gf" ] || [ -z "$(ls -A $HOME/.gf 2>/dev/null)" ]; then
        log_warn "gf patterns não instalados. Para instalar:"
        echo -e "  ${CYAN}git clone https://github.com/1ndianl33t/Gf-Patterns ~/.gf${NC}"
    fi
}

###############################################################################
# MAIN
###############################################################################

main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   Instalação de Ferramentas de Reconhecimento            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Verificar pré-requisitos
    check_prerequisites
    
    echo ""
    
    # Instalar ferramentas
    install_go_tools
    echo ""
    
    install_python_tools
    echo ""
    
    install_gf_patterns
    echo ""
    
    install_amass
    echo ""
    
    install_custom_nuclei_templates
    echo ""
    
    install_system_tools
    echo ""
    
    # Validar
    validate_installations
    echo ""
    
    # Setup final
    setup_final
    
    echo ""
    log_success "Instalação concluída!"
    log_info "Execute './recon.sh' para testar o pipeline de reconhecimento"
}

# Executar main
main "$@"

