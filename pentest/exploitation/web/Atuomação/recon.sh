#!/bin/bash

###############################################################################
# recon.sh - Pipeline de Reconhecimento Automatizado para Bug Bounty/Red Team
# Autor: Red Team Automation
# Descrição: Script modular para reconhecimento contínuo de superfícies de ataque
# Uso: ./recon.sh [domain]
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
NC='\033[0m' # No Color

# Diretórios e arquivos
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOMAINS_FILE="${SCRIPT_DIR}/domains.txt"
RECON_DIR="${SCRIPT_DIR}/recon"
LOCKFILE="${SCRIPT_DIR}/.recon.lock"
LOG_DIR="${RECON_DIR}/logs"

# Configurações de ferramentas
SUBFINDER_THREADS=10
AMASS_TIMEOUT=30m
NAABU_RATE=1000
NUCLEI_SEVERITY="info,low,medium,high,critical"
NUCLEI_RATE=150
HTTPX_THREADS=50

# Discord webhook (configure via variável de ambiente ou edite aqui)
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"

# Configuração de crontab
CRON_INTERVAL="0 */6 * * *"  # A cada 6 horas

###############################################################################
# FUNÇÕES AUXILIARES
###############################################################################

# Logging com timestamp
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="${LOG_DIR}/recon.log"
    
    mkdir -p "$(dirname "${log_file}")"
    
    case "$level" in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} [${timestamp}] $message" | tee -a "${log_file}"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} [${timestamp}] $message" | tee -a "${log_file}"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} [${timestamp}] $message" | tee -a "${log_file}"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} [${timestamp}] $message" | tee -a "${log_file}"
            ;;
        *)
            echo "[${timestamp}] $message" | tee -a "${log_file}"
            ;;
    esac
}

# Verificar se comando existe
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log "ERROR" "Comando '$1' não encontrado. Por favor, instale primeiro."
        return 1
    fi
}

# Verificar dependências
check_dependencies() {
    log "INFO" "Verificando dependências..."
    
    local missing=0
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
    
    # Ferramentas opcionais (não críticas)
    local optional_tools=(
        "tlsx"
    )
    
    for tool in "${tools[@]}"; do
        if ! check_command "$tool"; then
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log "ERROR" "${missing} ferramenta(s) faltando. Instale antes de continuar."
        exit 1
    fi
    
    # Verificar ferramentas opcionais
    for tool in "${optional_tools[@]}"; do
        if ! check_command "$tool"; then
            log "WARN" "Ferramenta opcional '$tool' não encontrada. Algumas funcionalidades podem estar limitadas."
        fi
    done
    
    log "SUCCESS" "Todas as dependências estão instaladas."
}

# Verificar lockfile para evitar execuções simultâneas
check_lockfile() {
    if [ -f "${LOCKFILE}" ]; then
        local pid=$(cat "${LOCKFILE}")
        if ps -p "$pid" > /dev/null 2>&1; then
            log "WARN" "Script já em execução (PID: $pid). Abortando..."
            exit 1
        else
            log "WARN" "Lockfile órfão encontrado. Removendo..."
            rm -f "${LOCKFILE}"
        fi
    fi
    
    echo $$ > "${LOCKFILE}"
    trap 'rm -f "${LOCKFILE}"' EXIT INT TERM
}

# Validar domínio
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        log "ERROR" "Domínio inválido: $domain"
        return 1
    fi
    return 0
}

# Notificar Discord via notify
notify_discord() {
    local title="$1"
    local message="$2"
    local color="${3:-5763719}"  # Cinza por padrão
    
    if [ -z "${DISCORD_WEBHOOK}" ]; then
        log "WARN" "DISCORD_WEBHOOK não configurado. Pulando notificação."
        return
    fi
    
    log "INFO" "Enviando notificação Discord: $title"
    
    export DISCORD_WEBHOOK="${DISCORD_WEBHOOK}"
    notify -provider discord -id discord \
        -data "{\"title\":\"${title}\",\"description\":\"${message}\",\"color\":${color}}" \
        &> /dev/null || log "WARN" "Falha ao enviar notificação Discord"
}

###############################################################################
# FUNÇÕES DE RECONHECIMENTO
###############################################################################

# Criar estrutura de diretórios
setup_domain_dirs() {
    local domain="$1"
    local domain_dir="${RECON_DIR}/${domain}"
    
    mkdir -p "${domain_dir}"/{subs,dns,http,urls,ports,vulns/gf,logs}
    
    echo "${domain_dir}"
}

# 1. Enumeração de subdomínios
enum_subs() {
    local domain="$1"
    local domain_dir="$2"
    local subs_dir="${domain_dir}/subs"
    
    log "INFO" "[$domain] Iniciando enumeração de subdomínios..."
    
    # Subfinder
    log "INFO" "[$domain] Executando subfinder..."
    subfinder -d "$domain" -t "${SUBFINDER_THREADS}" -silent 2>/dev/null | \
        anew "${subs_dir}/subfinder.txt" > /dev/null || true
    
    # Assetfinder
    log "INFO" "[$domain] Executando assetfinder..."
    assetfinder --subs-only "$domain" 2>/dev/null | \
        anew "${subs_dir}/assetfinder.txt" > /dev/null || true
    
    # Amass
    log "INFO" "[$domain] Executando amass..."
    timeout "${AMASS_TIMEOUT}" amass enum -passive -d "$domain" -silent 2>/dev/null | \
        anew "${subs_dir}/amass.txt" > /dev/null || true
    
    # Unificar resultados e calcular diff (novos subdomínios)
    log "INFO" "[$domain] Unificando resultados de subdomínios..."
    cat "${subs_dir}"/{subfinder,assetfinder,amass}.txt 2>/dev/null | \
        sort -u | anew "${subs_dir}/subs_final.txt" > /dev/null || true
    
    # Contar novos subdomínios usando diff com arquivo anterior
    local subs_previous="${subs_dir}/subs_final.txt.previous"
    local subs_new=$(cat "${subs_dir}/subs_final.txt" 2>/dev/null | \
        anew "${subs_previous}" 2>/dev/null | wc -l || echo "0")
    
    # Atualizar arquivo anterior para próxima execução
    [ -f "${subs_dir}/subs_final.txt" ] && \
        cp "${subs_dir}/subs_final.txt" "${subs_previous}" 2>/dev/null || true
    
    local count=$(wc -l < "${subs_dir}/subs_final.txt" 2>/dev/null || echo "0")
    log "SUCCESS" "[$domain] Encontrados ${count} subdomínios únicos (${subs_new} novos)."
    
    # Notificar apenas se houver novos subdomínios
    if [ "$subs_new" -gt 0 ]; then
        notify_discord "🔍 Novos Subdomínios: $domain" \
            "Novos subdomínios encontrados: ${subs_new}\nTotal acumulado: ${count}" \
            3447003  # Azul
    fi
}

# 2. Resolução DNS
resolve_dns() {
    local domain="$1"
    local domain_dir="$2"
    local subs_file="${domain_dir}/subs/subs_final.txt"
    local dns_output="${domain_dir}/dns/dnsx.txt"
    
    if [ ! -s "${subs_file}" ]; then
        log "WARN" "[$domain] Arquivo de subdomínios vazio. Pulando DNS."
        return
    fi
    
    log "INFO" "[$domain] Executando resolução DNS (dnsx)..."
    
    # Resolver A, AAAA, CNAME
    dnsx -l "${subs_file}" -a -aaaa -cname -silent 2>/dev/null | \
        anew "${dns_output}" > /dev/null || true
    
    # Extrair apenas subdomínios válidos (que resolveram)
    cut -d' ' -f1 "${dns_output}" 2>/dev/null | sort -u > "${subs_file}.valid" || true
    
    local valid_count=$(wc -l < "${subs_file}.valid" 2>/dev/null || echo "0")
    log "SUCCESS" "[$domain] ${valid_count} subdomínios com resolução DNS válida."
}

# 3. Descoberta de serviços HTTP
discover_http() {
    local domain="$1"
    local domain_dir="$2"
    local subs_file="${domain_dir}/subs/subs_final.txt.valid"
    local http_output="${domain_dir}/http/httpx.txt"
    
    if [ ! -s "${subs_file}" ]; then
        log "WARN" "[$domain] Nenhum subdomínio válido. Pulando HTTP discovery."
        return
    fi
    
    log "INFO" "[$domain] Executando descoberta HTTP (httpx)..."
    
    # HTTPX com status code, título e tecnologia
    # httpx retorna URL primeiro na linha quando usa -sc -title
    httpx -l "${subs_file}" \
        -sc -td -title -tech-detect \
        -threads "${HTTPX_THREADS}" \
        -silent 2>/dev/null | \
        awk '{print $1}' | \
        grep -E '^https?://' | \
        anew "${http_output}" > /dev/null || true
    
    # TLSX para informações TLS (apenas se houver hosts HTTP)
    if [ -s "${http_output}" ]; then
        log "INFO" "[$domain] Executando tlsx..."
        # tlsx usa a lista de hosts HTTP para coletar informações TLS
        if command -v tlsx &> /dev/null; then
            cat "${http_output}" | sed 's|https\?://||' | cut -d'/' -f1 | \
                sort -u | tlsx -silent -json -o "${domain_dir}/http/tlsx.txt" 2>/dev/null || true
        else
            log "WARN" "[$domain] tlsx não encontrado. Pulando coleta de informações TLS."
        fi
    fi
    
    local http_count=$(wc -l < "${http_output}" 2>/dev/null || echo "0")
    
    # Contar novos hosts HTTP usando diff
    local http_previous="${domain_dir}/http/httpx.txt.previous"
    local http_new=$(cat "${http_output}" 2>/dev/null | \
        anew "${http_previous}" 2>/dev/null | wc -l || echo "0")
    
    # Atualizar arquivo anterior para próxima execução
    [ -f "${http_output}" ] && \
        cp "${http_output}" "${http_previous}" 2>/dev/null || true
    
    log "SUCCESS" "[$domain] ${http_count} hosts HTTP descobertos (${http_new} novos)."
    
    # Notificar apenas se houver novos hosts HTTP
    if [ "$http_new" -gt 0 ]; then
        notify_discord "🌐 Novos Hosts HTTP: $domain" \
            "Novos hosts HTTP descobertos: ${http_new}\nTotal acumulado: ${http_count}" \
            3066993  # Verde
    fi
}

# 4. Coleta de URLs
collect_urls() {
    local domain="$1"
    local domain_dir="$2"
    local http_file="${domain_dir}/http/httpx.txt"
    local urls_dir="${domain_dir}/urls"
    
    if [ ! -s "${http_file}" ]; then
        log "WARN" "[$domain] Nenhum host HTTP. Pulando coleta de URLs."
        return
    fi
    
    log "INFO" "[$domain] Coletando URLs..."
    
    # GAU por domínio (mais eficiente que por URL)
    log "INFO" "[$domain] Executando gau..."
    # GAU por domínio (usa o domínio raiz passado)
    gau --subs "$domain" 2>/dev/null | \
        anew "${urls_dir}/gau.txt" > /dev/null || true
    
    # Filtrar apenas URLs de hosts HTTP ativos
    if [ -s "${urls_dir}/gau.txt" ]; then
        log "INFO" "[$domain] Filtrando gau por hosts ativos..."
        # Extrair domínios dos hosts HTTP ativos
        cat "${http_file}" | sed 's|https\?://||' | cut -d'/' -f1 | sort -u > "${urls_dir}/active_hosts.txt" 2>/dev/null || true
        
        # Filtrar URLs do gau que pertencem aos hosts ativos
        grep -f "${urls_dir}/active_hosts.txt" "${urls_dir}/gau.txt" 2>/dev/null | \
            sort -u > "${urls_dir}/gau_filtered.txt" 2>/dev/null || true
        
        # Substituir gau.txt pelo filtrado
        [ -f "${urls_dir}/gau_filtered.txt" ] && \
            mv "${urls_dir}/gau_filtered.txt" "${urls_dir}/gau.txt" 2>/dev/null || true
    fi
    
    # Katana
    log "INFO" "[$domain] Executando katana..."
    katana -list "${http_file}" -silent -jc -kf 2>/dev/null | \
        anew "${urls_dir}/katana.txt" > /dev/null || true
    
    # Unificar e normalizar com uro
    log "INFO" "[$domain] Normalizando URLs com uro..."
    cat "${urls_dir}"/{gau,katana}.txt 2>/dev/null | \
        uro -q 2>/dev/null | \
        sort -u | \
        anew "${urls_dir}/urls_final.txt" > /dev/null || true
    
    local urls_count=$(wc -l < "${urls_dir}/urls_final.txt" 2>/dev/null || echo "0")
    log "SUCCESS" "[$domain] ${urls_count} URLs coletadas e normalizadas."
}

# 5. Filtragem inteligente com gf
gf_filter() {
    local domain="$1"
    local domain_dir="$2"
    local urls_file="${domain_dir}/urls/urls_final.txt"
    local gf_dir="${domain_dir}/vulns/gf"
    
    if [ ! -s "${urls_file}" ]; then
        log "WARN" "[$domain] Nenhuma URL para filtrar."
        return
    fi
    
    log "INFO" "[$domain] Aplicando filtros gf..."
    
    local patterns=("xss" "sqli" "lfi" "ssrf" "redirect" "rce" "idor")
    
    for pattern in "${patterns[@]}"; do
        cat "${urls_file}" 2>/dev/null | \
            gf "$pattern" 2>/dev/null | \
            anew "${gf_dir}/${pattern}.txt" > /dev/null || true
    done
    
    log "SUCCESS" "[$domain] Filtragem gf concluída."
}

# 6. Port scanning
scan_ports() {
    local domain="$1"
    local domain_dir="$2"
    local subs_file="${domain_dir}/subs/subs_final.txt.valid"
    local ports_dir="${domain_dir}/ports"
    
    if [ ! -s "${subs_file}" ]; then
        log "WARN" "[$domain] Nenhum subdomínio válido. Pulando port scan."
        return
    fi
    
    log "INFO" "[$domain] Executando port scanning..."
    
    # Naabu para descoberta rápida
    log "INFO" "[$domain] Executando naabu..."
    naabu -l "${subs_file}" \
        -rate "${NAABU_RATE}" \
        -silent \
        -o "${ports_dir}/naabu.txt" 2>/dev/null || true
    
    # Nmap apenas nos hosts/ports descobertos por naabu
    if [ -s "${ports_dir}/naabu.txt" ]; then
        log "INFO" "[$domain] Executando nmap (agressivo)..."
        nmap -iL "${ports_dir}/naabu.txt" \
            -sV -sC --script=vuln \
            -oN "${ports_dir}/nmap.txt" \
            --open 2>/dev/null || true
    fi
    
    log "SUCCESS" "[$domain] Port scanning concluído."
}

# 7. Scan de vulnerabilidades com Nuclei
scan_vulns() {
    local domain="$1"
    local domain_dir="$2"
    local http_file="${domain_dir}/http/httpx.txt"
    local vulns_output="${domain_dir}/vulns/nuclei.txt"
    
    if [ ! -s "${http_file}" ]; then
        log "WARN" "[$domain] Nenhum host HTTP. Pulando scan de vulnerabilidades."
        return
    fi
    
    log "INFO" "[$domain] Executando nuclei..."
    
    # Nuclei com templates atualizados
    nuclei -l "${http_file}" \
        -severity "${NUCLEI_SEVERITY}" \
        -rate-limit "${NUCLEI_RATE}" \
        -silent \
        -o "${vulns_output}" 2>/dev/null || true
    
    local vulns_count=$(wc -l < "${vulns_output}" 2>/dev/null || echo "0")
    
    # Contar novas vulnerabilidades usando diff
    local vulns_previous="${domain_dir}/vulns/nuclei.txt.previous"
    local vulns_new=$(cat "${vulns_output}" 2>/dev/null | \
        anew "${vulns_previous}" 2>/dev/null | wc -l || echo "0")
    
    # Atualizar arquivo anterior para próxima execução
    [ -f "${vulns_output}" ] && \
        cp "${vulns_output}" "${vulns_previous}" 2>/dev/null || true
    
    if [ "$vulns_new" -gt 0 ]; then
        log "SUCCESS" "[$domain] ${vulns_new} nova(s) vulnerabilidade(s) encontrada(s)! Total: ${vulns_count}"
        
        # Notificar apenas novas vulnerabilidades
        notify_discord "🚨 Novas Vulnerabilidades: $domain" \
            "Novas vulnerabilidades encontradas: ${vulns_new}\nTotal acumulado: ${vulns_count}\nVerifique: ${vulns_output}" \
            15158332  # Vermelho
    elif [ "$vulns_count" -gt 0 ]; then
        log "INFO" "[$domain] ${vulns_count} vulnerabilidade(s) já conhecida(s) (nenhuma nova)."
    else
        log "INFO" "[$domain] Nenhuma vulnerabilidade encontrada."
    fi
}

# Pipeline completo para um domínio
recon_domain() {
    local domain="$1"
    
    log "INFO" "========================================="
    log "INFO" "Iniciando reconhecimento: $domain"
    log "INFO" "========================================="
    
    # Validar domínio
    if ! validate_domain "$domain"; then
        return 1
    fi
    
    # Criar estrutura de diretórios
    local domain_dir=$(setup_domain_dirs "$domain")
    
    # Executar pipeline
    enum_subs "$domain" "$domain_dir"
    resolve_dns "$domain" "$domain_dir"
    discover_http "$domain" "$domain_dir"
    collect_urls "$domain" "$domain_dir"
    gf_filter "$domain" "$domain_dir"
    scan_ports "$domain" "$domain_dir"
    scan_vulns "$domain" "$domain_dir"
    
    log "SUCCESS" "Reconhecimento concluído para: $domain"
}

###############################################################################
# MAIN
###############################################################################

main() {
    log "INFO" "Iniciando pipeline de reconhecimento..."
    
    # Verificar lockfile
    check_lockfile
    
    # Verificar dependências
    check_dependencies
    
    # Verificar arquivo de domínios
    if [ ! -f "${DOMAINS_FILE}" ]; then
        log "ERROR" "Arquivo ${DOMAINS_FILE} não encontrado!"
        exit 1
    fi
    
    if [ ! -s "${DOMAINS_FILE}" ]; then
        log "ERROR" "Arquivo ${DOMAINS_FILE} está vazio!"
        exit 1
    fi
    
    # Se um domínio foi passado como argumento, processar apenas ele
    if [ $# -eq 1 ]; then
        recon_domain "$1"
    else
        # Processar todos os domínios do arquivo
        while IFS= read -r domain || [ -n "$domain" ]; do
            # Pular linhas vazias e comentários
            [[ -z "$domain" || "$domain" =~ ^[[:space:]]*# ]] && continue
            
            # Remover espaços em branco
            domain=$(echo "$domain" | xargs)
            
            # Validar e processar
            if [ -n "$domain" ]; then
                recon_domain "$domain"
            fi
        done < "${DOMAINS_FILE}"
    fi
    
    log "SUCCESS" "Pipeline de reconhecimento finalizado!"
}

# Executar main
main "$@"

