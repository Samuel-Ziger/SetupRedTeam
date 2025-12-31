#!/bin/bash

################################################################################
# Reteste Wrapper com OPSEC - Exemplo de uso
# Data: 2025-11-28
# Autor: Samuel Ziger
#
# Este script demonstra como adicionar OPSEC aos retestes existentes
# SEM modificar os scripts originais
################################################################################

# Importar biblioteca OPSEC
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/../../lib/opsec.sh"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Configurações OPSEC
################################################################################
ENABLE_VPN_CHECK=false  # Mude para true para forçar VPN
EXPECTED_VPN_IP=""      # IP esperado da VPN (vazio = qualquer IP público)
RATE_LIMIT_MIN=2        # Delay mínimo entre requests (segundos)
RATE_LIMIT_MAX=5        # Delay máximo entre requests (segundos)
RANDOM_USER_AGENT=true  # Usar User-Agent aleatório

################################################################################
# Wrapper function para curl com OPSEC
################################################################################
safe_curl() {
    # Rate limiting
    rate_limit $RATE_LIMIT_MIN $RATE_LIMIT_MAX
    
    # User-Agent aleatório
    if [ "$RANDOM_USER_AGENT" = true ]; then
        local ua=$(random_user_agent)
        curl -A "$ua" "$@"
    else
        curl "$@"
    fi
}

################################################################################
# Wrapper function para requests Python
################################################################################
create_python_wrapper() {
    cat > /tmp/safe_requests.py << 'PYTHON_EOF'
import requests
import random
import time

# User-Agents
USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36"
]

# Rate limiting
def rate_limit(min_delay=2, max_delay=5):
    time.sleep(random.uniform(min_delay, max_delay))

# Safe GET
def safe_get(url, **kwargs):
    rate_limit()
    headers = kwargs.get('headers', {})
    headers['User-Agent'] = random.choice(USER_AGENTS)
    kwargs['headers'] = headers
    return requests.get(url, **kwargs)

# Safe POST
def safe_post(url, **kwargs):
    rate_limit()
    headers = kwargs.get('headers', {})
    headers['User-Agent'] = random.choice(USER_AGENTS)
    kwargs['headers'] = headers
    return requests.post(url, **kwargs)
PYTHON_EOF

    echo -e "${GREEN}[OPSEC] Wrapper Python criado: /tmp/safe_requests.py${NC}"
}

################################################################################
# Pré-flight checks
################################################################################
preflight_check() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           OPSEC PRE-FLIGHT CHECKS - RETESTE               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # VPN check
    if [ "$ENABLE_VPN_CHECK" = true ]; then
        if ! check_vpn "$EXPECTED_VPN_IP"; then
            echo -e "${RED}[OPSEC] ❌ VPN check falhou! Abortando.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}[OPSEC] ⚠️ VPN check desabilitado${NC}"
    fi
    echo ""
    
    # DNS leak check
    check_dns_leak
    echo ""
    
    # Resource check
    source "$SCRIPT_DIR/../../lib/resource_check.sh"
    check_ram
    check_disk
    echo ""
    
    echo -e "${GREEN}[OPSEC] ✅ Pre-flight checks completos${NC}"
    echo ""
}

################################################################################
# Executar reteste original com wrapping
################################################################################
run_reteste_with_opsec() {
    local reteste_script="$1"
    
    if [ ! -f "$reteste_script" ]; then
        echo -e "${RED}[OPSEC] ❌ Script não encontrado: $reteste_script${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[OPSEC] Executando: $reteste_script${NC}"
    echo -e "${BLUE}[OPSEC] Com proteções:${NC}"
    echo "  - Rate limiting: ${RATE_LIMIT_MIN}-${RATE_LIMIT_MAX}s"
    echo "  - User-Agent: $([ "$RANDOM_USER_AGENT" = true ] && echo "Aleatório" || echo "Padrão")"
    echo "  - VPN check: $([ "$ENABLE_VPN_CHECK" = true ] && echo "Habilitado" || echo "Desabilitado")"
    echo ""
    
    # Export wrapper functions
    export -f safe_curl
    export -f rate_limit
    export -f random_user_agent
    
    # Criar wrapper Python
    create_python_wrapper
    
    # Executar script original
    bash "$reteste_script"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}[OPSEC] ✅ Reteste concluído com sucesso${NC}"
    else
        echo ""
        echo -e "${RED}[OPSEC] ❌ Reteste falhou (exit code: $exit_code)${NC}"
    fi
    
    return $exit_code
}

################################################################################
# Menu principal
################################################################################
show_menu() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         RETESTE COM OPSEC - WRAPPER SEGURO                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Configuração atual:"
    echo "  VPN Check: $([ "$ENABLE_VPN_CHECK" = true ] && echo "Habilitado" || echo "Desabilitado")"
    echo "  Rate Limit: ${RATE_LIMIT_MIN}-${RATE_LIMIT_MAX}s"
    echo "  User-Agent: $([ "$RANDOM_USER_AGENT" = true ] && echo "Aleatório" || echo "Fixo")"
    echo ""
    echo "1) Executar reteste_adivisao.sh (com OPSEC)"
    echo "2) Executar reteste_divisaodeelite.sh (com OPSEC)"
    echo "3) Executar reteste_acheumveterano.sh (com OPSEC)"
    echo "4) Executar reteste_idivis.sh (com OPSEC)"
    echo "5) Executar reteste_planodechamadas.sh (com OPSEC)"
    echo "6) Executar TODOS com OPSEC"
    echo "7) Configurar OPSEC"
    echo "8) Pre-flight check apenas"
    echo "9) Sair"
    echo ""
}

################################################################################
# Configurar OPSEC
################################################################################
configure_opsec() {
    echo ""
    echo -e "${BLUE}[CONFIG] Configuração OPSEC${NC}"
    echo ""
    
    read -p "Habilitar VPN check? (s/n): " vpn_check
    if [ "$vpn_check" = "s" ]; then
        ENABLE_VPN_CHECK=true
        read -p "IP esperado da VPN (vazio = qualquer público): " vpn_ip
        EXPECTED_VPN_IP="$vpn_ip"
    else
        ENABLE_VPN_CHECK=false
    fi
    
    read -p "Delay mínimo entre requests (segundos) [2]: " min_delay
    RATE_LIMIT_MIN=${min_delay:-2}
    
    read -p "Delay máximo entre requests (segundos) [5]: " max_delay
    RATE_LIMIT_MAX=${max_delay:-5}
    
    read -p "User-Agent aleatório? (s/n): " ua_random
    if [ "$ua_random" = "s" ]; then
        RANDOM_USER_AGENT=true
    else
        RANDOM_USER_AGENT=false
    fi
    
    echo ""
    echo -e "${GREEN}[CONFIG] ✅ Configuração atualizada${NC}"
}

################################################################################
# Main
################################################################################
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    cd "$SCRIPT_DIR"
    
    # Pre-flight check inicial
    preflight_check
    
    while true; do
        show_menu
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                run_reteste_with_opsec "reteste_adivisao.sh"
                ;;
            2)
                run_reteste_with_opsec "reteste_divisaodeelite.sh"
                ;;
            3)
                run_reteste_with_opsec "reteste_acheumveterano.sh"
                ;;
            4)
                run_reteste_with_opsec "reteste_idivis.sh"
                ;;
            5)
                run_reteste_with_opsec "reteste_planodechamadas.sh"
                ;;
            6)
                echo -e "${BLUE}[OPSEC] Executando todos os retestes...${NC}"
                for script in reteste_*.sh; do
                    if [ "$script" != "reteste_ngrok.sh" ]; then
                        run_reteste_with_opsec "$script"
                        echo ""
                    fi
                done
                ;;
            7)
                configure_opsec
                ;;
            8)
                preflight_check
                ;;
            9)
                echo -e "${BLUE}[OPSEC] Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[OPSEC] Opção inválida${NC}"
                ;;
        esac
        
        echo ""
        read -p "Pressione ENTER para continuar..."
    done
fi
