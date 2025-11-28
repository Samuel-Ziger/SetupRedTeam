#!/bin/bash

################################################################################
# OPSEC Library - Operational Security Functions
# Data: 2025-11-28
# Autor: Samuel Ziger
#
# Biblioteca de funções para segurança operacional em pentests
# Importar em seus scripts: source lib/opsec.sh
################################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

################################################################################
# Verificação de VPN
################################################################################
check_vpn() {
    local expected_ip="${1:-}"
    
    echo -e "${BLUE}[OPSEC] Verificando conexão VPN...${NC}"
    
    # Pegar IP público atual
    local current_ip=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || curl -s --max-time 5 api.ipify.org 2>/dev/null)
    
    if [ -z "$current_ip" ]; then
        echo -e "${RED}[OPSEC] ❌ ERRO: Não foi possível obter IP público!${NC}"
        echo -e "${YELLOW}[OPSEC] Verifique sua conexão com a internet.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[OPSEC] IP atual: $current_ip${NC}"
    
    # Se IP esperado foi fornecido, validar
    if [ -n "$expected_ip" ]; then
        if [ "$current_ip" = "$expected_ip" ]; then
            echo -e "${GREEN}[OPSEC] ✅ VPN ativa e validada!${NC}"
            return 0
        else
            echo -e "${RED}[OPSEC] ❌ ALERTA: IP não corresponde ao esperado!${NC}"
            echo -e "${YELLOW}[OPSEC] Esperado: $expected_ip${NC}"
            echo -e "${YELLOW}[OPSEC] Atual: $current_ip${NC}"
            return 1
        fi
    fi
    
    # Verificar se é IP privado (indicação de problema)
    if echo "$current_ip" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.|192\.168\.)'; then
        echo -e "${RED}[OPSEC] ❌ ALERTA: IP privado detectado! VPN pode não estar ativa.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[OPSEC] ✅ IP público detectado (assumindo VPN ativa)${NC}"
    return 0
}

################################################################################
# Verificação de DNS Leak
################################################################################
check_dns_leak() {
    echo -e "${BLUE}[OPSEC] Verificando DNS leaks...${NC}"
    
    # Testar servidor DNS
    local dns_server=$(nslookup google.com 2>/dev/null | grep "Server:" | awk '{print $2}')
    
    if [ -z "$dns_server" ]; then
        echo -e "${YELLOW}[OPSEC] ⚠️ Não foi possível verificar servidor DNS${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[OPSEC] Servidor DNS: $dns_server${NC}"
    
    # Verificar se DNS é do provedor local (leak)
    if echo "$dns_server" | grep -qE '^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'; then
        echo -e "${YELLOW}[OPSEC] ⚠️ DNS local detectado - pode ser leak${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[OPSEC] ✅ DNS externo em uso${NC}"
    return 0
}

################################################################################
# Kill Switch - Abortar se VPN cair
################################################################################
vpn_killswitch() {
    local expected_ip="${1:-}"
    
    if ! check_vpn "$expected_ip"; then
        echo -e "${RED}[OPSEC] ❌ KILL SWITCH ATIVADO!${NC}"
        echo -e "${RED}[OPSEC] VPN não detectada ou inválida. Abortando operação.${NC}"
        exit 1
    fi
}

################################################################################
# Rate Limiting - Delay entre requests
################################################################################
rate_limit() {
    local min_delay="${1:-1}"
    local max_delay="${2:-3}"
    
    # Gerar delay aleatório
    local delay=$(shuf -i ${min_delay}-${max_delay} -n 1)
    
    echo -e "${BLUE}[OPSEC] Aguardando ${delay}s (rate limiting)...${NC}"
    sleep "$delay"
}

################################################################################
# Random User-Agent Generator
################################################################################
random_user_agent() {
    local agents=(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"
        "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:121.0) Gecko/20100101 Firefox/121.0"
    )
    
    # Selecionar aleatoriamente
    local random_index=$((RANDOM % ${#agents[@]}))
    echo "${agents[$random_index]}"
}

################################################################################
# Verificar se está rodando como root
################################################################################
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}[OPSEC] ❌ Este script precisa de privilégios root!${NC}"
        echo -e "${YELLOW}[OPSEC] Execute com: sudo $0${NC}"
        exit 1
    fi
    echo -e "${GREEN}[OPSEC] ✅ Rodando como root${NC}"
}

################################################################################
# Verificar se ferramentas necessárias estão instaladas
################################################################################
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    echo -e "${BLUE}[OPSEC] Verificando dependências...${NC}"
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[OPSEC] ❌ Dependências faltando: ${missing[*]}${NC}"
        echo -e "${YELLOW}[OPSEC] Instale com: sudo apt install ${missing[*]}${NC}"
        return 1
    fi
    
    echo -e "${GREEN}[OPSEC] ✅ Todas as dependências encontradas${NC}"
    return 0
}

################################################################################
# Sanitizar input para prevenir injection
################################################################################
sanitize_input() {
    local input="$1"
    
    # Remover caracteres perigosos
    echo "$input" | sed 's/[;&|`$()<>]//g'
}

################################################################################
# Verificar se target é válido (domínio ou IP)
################################################################################
validate_target() {
    local target="$1"
    
    # Regex para IP
    local ip_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
    
    # Regex para domínio
    local domain_regex='^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$'
    
    if [[ $target =~ $ip_regex ]] || [[ $target =~ $domain_regex ]]; then
        echo -e "${GREEN}[OPSEC] ✅ Target válido: $target${NC}"
        return 0
    else
        echo -e "${RED}[OPSEC] ❌ Target inválido: $target${NC}"
        return 1
    fi
}

################################################################################
# Checklist completo OPSEC antes de engagement
################################################################################
pre_engagement_check() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           CHECKLIST PRÉ-ENGAGEMENT - OPSEC                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local checks_passed=0
    local checks_total=4
    
    # Check 1: VPN
    if check_vpn; then
        ((checks_passed++))
    fi
    echo ""
    
    # Check 2: DNS
    if check_dns_leak; then
        ((checks_passed++))
    fi
    echo ""
    
    # Check 3: Disk space
    echo -e "${BLUE}[OPSEC] Verificando espaço em disco...${NC}"
    local free_space=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "${BLUE}[OPSEC] Espaço livre: $free_space${NC}"
    if [ $(df / | awk 'NR==2 {print $4}') -gt 5000000 ]; then
        echo -e "${GREEN}[OPSEC] ✅ Espaço em disco suficiente${NC}"
        ((checks_passed++))
    else
        echo -e "${YELLOW}[OPSEC] ⚠️ Pouco espaço em disco disponível${NC}"
    fi
    echo ""
    
    # Check 4: Internet
    echo -e "${BLUE}[OPSEC] Verificando conectividade...${NC}"
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}[OPSEC] ✅ Internet ativa${NC}"
        ((checks_passed++))
    else
        echo -e "${RED}[OPSEC] ❌ Sem internet${NC}"
    fi
    echo ""
    
    # Resultado final
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  RESULTADO: $checks_passed/$checks_total checks passaram${NC}"
    
    if [ $checks_passed -eq $checks_total ]; then
        echo -e "${GREEN}║  ✅ SISTEMA PRONTO PARA OPERAÇÃO${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        return 0
    else
        echo -e "${YELLOW}║  ⚠️ ALGUNS CHECKS FALHARAM - REVISAR ANTES DE CONTINUAR${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        return 1
    fi
}

################################################################################
# Exemplo de uso
################################################################################
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║            OPSEC Library - Teste de Funções              ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Executando checklist completo..."
    echo ""
    
    pre_engagement_check
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "Outras funções disponíveis:"
    echo "  - check_vpn [IP_ESPERADO]"
    echo "  - vpn_killswitch [IP_ESPERADO]"
    echo "  - check_dns_leak"
    echo "  - rate_limit [MIN] [MAX]"
    echo "  - random_user_agent"
    echo "  - check_root"
    echo "  - check_dependencies [TOOL1 TOOL2 ...]"
    echo "  - sanitize_input [STRING]"
    echo "  - validate_target [DOMAIN/IP]"
    echo "════════════════════════════════════════════════════════════"
fi
