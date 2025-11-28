#!/bin/bash

################################################################################
# Script de Reteste - idivis.ao / 31.97.27.219
# Data: 2025-11-28
# Autor: Samuel Ziger
# 
# Vulnerabilidades a validar:
# 1. Porta 3000 (Next.js dev) exposta (CRÍTICA)
# 2. Arquivos sensíveis expostos (.mysql_history, .ssh, .bash_history) (CRÍTICA)
# 3. Diretórios de backup expostos (_backup, _db_backups) (CRÍTICA)
# 4. SSH acessível (31.97.27.129:22) (ALTA)
# 5. Ausência de headers de segurança (MÉDIA)
# 6. Porta 3030 filtrada (INFO)
################################################################################

TARGET="https://idivis.ao"
TARGET_IP="31.97.27.219"
TARGET_SSH_IP="31.97.27.129"
REPORT_DIR="./reteste_idivis_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "[+] Iniciando reteste de segurança para idivis.ao"
echo "[+] IP Principal: $TARGET_IP"
echo "[+] IP SSH: $TARGET_SSH_IP"
echo "[+] Relatório será salvo em: $REPORT_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# 1. Verificar Porta 3000 (Next.js Development Server)
################################################################################
echo -e "\n${YELLOW}[1] Verificando porta 3000 (Next.js dev)...${NC}"
nc -zv -w 5 $TARGET_IP 3000 > "$REPORT_DIR/01_port_3000.txt" 2>&1
if [ $? -eq 0 ]; then
    echo -e "${RED}[!] CRÍTICO: Porta 3000 está ABERTA${NC}"
    cat "$REPORT_DIR/01_port_3000.txt"
    
    # Tentar acessar via HTTP
    curl -s -m 10 "http://$TARGET_IP:3000/" -o "$REPORT_DIR/01_port_3000_http.html"
    if [ -s "$REPORT_DIR/01_port_3000_http.html" ]; then
        echo -e "${RED}[!] CRÍTICO: Servidor respondeu na porta 3000${NC}"
        echo "Primeiras linhas da resposta:"
        head -20 "$REPORT_DIR/01_port_3000_http.html"
    fi
else
    echo -e "${GREEN}[✓] Porta 3000 não acessível ou filtrada${NC}"
    cat "$REPORT_DIR/01_port_3000.txt"
fi

################################################################################
# 2. Verificar Arquivos Sensíveis Expostos
################################################################################
echo -e "\n${YELLOW}[2] Verificando arquivos sensíveis expostos...${NC}"
for file in ".mysql_history" ".bash_history" ".ssh/id_rsa" ".ssh/id_rsa.pub" ".ssh/authorized_keys" \
            ".git/config" ".env" ".htpasswd" "config.php" "wp-config.php"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$file")
    echo "  - /$file: HTTP $STATUS"
    if [ "$STATUS" = "200" ]; then
        echo -e "${RED}    [!] CRÍTICO: Arquivo sensível acessível${NC}"
        curl -s "$TARGET/$file" | head -20 > "$REPORT_DIR/02_sensitive_$file.txt"
    fi
done > "$REPORT_DIR/02_sensitive_files.txt"
cat "$REPORT_DIR/02_sensitive_files.txt"

################################################################################
# 3. Verificar Diretórios de Backup Expostos
################################################################################
echo -e "\n${YELLOW}[3] Verificando diretórios de backup...${NC}"
for dir in "_backup" "_backups" "_db_backups" "backup" "backups" "db_backup" \
           "database" "sql" "dump" "old" "temp"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$dir/")
    echo "  - /$dir/: HTTP $STATUS"
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "301" ] || [ "$STATUS" = "403" ]; then
        echo -e "${RED}    [!] CRÍTICO: Diretório de backup existe${NC}"
        
        # Tentar listar conteúdo
        curl -s "$TARGET/$dir/" > "$REPORT_DIR/03_backup_dir_$dir.html"
        if grep -qi "index of\|directory listing" "$REPORT_DIR/03_backup_dir_$dir.html"; then
            echo -e "${RED}    [!] CRÍTICO: Directory listing habilitado${NC}"
        fi
    fi
done > "$REPORT_DIR/03_backup_dirs.txt"
cat "$REPORT_DIR/03_backup_dirs.txt"

################################################################################
# 4. Verificar Porta SSH (22)
################################################################################
echo -e "\n${YELLOW}[4] Verificando porta SSH...${NC}"

# Testar no IP principal
echo "Testando SSH em $TARGET_IP:22"
nc -zv -w 5 $TARGET_IP 22 > "$REPORT_DIR/04_ssh_main.txt" 2>&1
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}[!] Porta SSH aberta em $TARGET_IP${NC}"
    echo "QUIT" | timeout 5 nc $TARGET_IP 22 >> "$REPORT_DIR/04_ssh_main.txt" 2>&1
fi

# Testar no IP secundário
echo "Testando SSH em $TARGET_SSH_IP:22"
nc -zv -w 5 $TARGET_SSH_IP 22 > "$REPORT_DIR/04_ssh_secondary.txt" 2>&1
if [ $? -eq 0 ]; then
    echo -e "${RED}[!] ALTA: Porta SSH aberta em $TARGET_SSH_IP${NC}"
    echo "QUIT" | timeout 5 nc $TARGET_SSH_IP 22 >> "$REPORT_DIR/04_ssh_secondary.txt" 2>&1
    
    # Tentar obter versão SSH
    if grep -qi "openssh" "$REPORT_DIR/04_ssh_secondary.txt"; then
        echo "Banner SSH detectado:"
        cat "$REPORT_DIR/04_ssh_secondary.txt"
    fi
else
    echo -e "${GREEN}[✓] SSH não acessível em $TARGET_SSH_IP${NC}"
fi

################################################################################
# 5. Verificar Headers de Segurança
################################################################################
echo -e "\n${YELLOW}[5] Verificando headers de segurança HTTP...${NC}"
curl -s -I "$TARGET" > "$REPORT_DIR/05_headers.txt"

# Strict-Transport-Security
if grep -qi "strict-transport-security" "$REPORT_DIR/05_headers.txt"; then
    HSTS=$(grep -i "strict-transport-security" "$REPORT_DIR/05_headers.txt")
    echo -e "${GREEN}[✓] HSTS presente: $HSTS${NC}"
else
    echo -e "${RED}[!] VULNERÁVEL: HSTS ausente${NC}"
fi

# Content-Security-Policy
if grep -qi "content-security-policy:" "$REPORT_DIR/05_headers.txt"; then
    echo -e "${GREEN}[✓] CSP configurado${NC}"
else
    echo -e "${YELLOW}[!] CSP ausente${NC}"
fi

# Referrer-Policy
if grep -qi "referrer-policy" "$REPORT_DIR/05_headers.txt"; then
    echo -e "${GREEN}[✓] Referrer-Policy presente${NC}"
else
    echo -e "${YELLOW}[!] Referrer-Policy ausente${NC}"
fi

# Headers presentes no relatório original
echo -e "\nHeaders presentes:"
grep -iE "(x-frame-options|x-xss-protection|x-content-type-options)" "$REPORT_DIR/05_headers.txt"

# Verificar headers ausentes mencionados no relatório
echo -e "\nVerificando headers ausentes mencionados:"
for header in "strict-transport-security" "content-security-policy" "referrer-policy"; do
    if ! grep -qi "$header" "$REPORT_DIR/05_headers.txt"; then
        echo -e "${RED}[!] $header: AUSENTE${NC}"
    fi
done

################################################################################
# 6. Verificar Porta 3030
################################################################################
echo -e "\n${YELLOW}[6] Verificando porta 3030 (mencionada como filtrada)...${NC}"
nc -zv -w 5 $TARGET_IP 3030 > "$REPORT_DIR/06_port_3030.txt" 2>&1
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}[!] Porta 3030 está ABERTA${NC}"
else
    echo -e "${GREEN}[✓] Porta 3030 filtrada ou fechada (esperado)${NC}"
fi
cat "$REPORT_DIR/06_port_3030.txt"

################################################################################
# 7. Testar Endpoints Administrativos
################################################################################
echo -e "\n${YELLOW}[7] Testando endpoints administrativos...${NC}"
for endpoint in "admin" "administrator" "adminpanel" "phpmyadmin" "pma" \
                "adminer" "cpanel" "webmail" "panel"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$endpoint")
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "301" ] || [ "$STATUS" = "302" ] || [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
        echo -e "${RED}[!] /$endpoint: HTTP $STATUS - ENCONTRADO${NC}"
    else
        echo -e "${GREEN}[✓] /$endpoint: HTTP $STATUS${NC}"
    fi
done > "$REPORT_DIR/07_admin_endpoints.txt"
cat "$REPORT_DIR/07_admin_endpoints.txt"

################################################################################
# 8. Verificar Exposição de Tecnologias (Next.js)
################################################################################
echo -e "\n${YELLOW}[8] Verificando fingerprinting Next.js...${NC}"
curl -s -I "$TARGET" | grep -iE "(x-nextjs|x-powered-by)" > "$REPORT_DIR/08_nextjs_headers.txt"
if [ -s "$REPORT_DIR/08_nextjs_headers.txt" ]; then
    echo -e "${YELLOW}[!] Headers revelam uso de Next.js:${NC}"
    cat "$REPORT_DIR/08_nextjs_headers.txt"
else
    echo -e "${GREEN}[✓] Headers de tecnologia não expostos${NC}"
fi

# Verificar meta tags e HTML
curl -s "$TARGET" | grep -iE "(next\.js|_next|__next)" | head -5 > "$REPORT_DIR/08_nextjs_html.txt"
if [ -s "$REPORT_DIR/08_nextjs_html.txt" ]; then
    echo -e "${YELLOW}[!] Referências Next.js encontradas no HTML:${NC}"
    cat "$REPORT_DIR/08_nextjs_html.txt"
fi

################################################################################
# 9. Scan de Portas Comum
################################################################################
echo -e "\n${YELLOW}[9] Scan de portas comuns...${NC}"
echo "Testando portas: 21, 22, 80, 443, 3000, 3030, 8080, 8443"
for port in 21 22 80 443 3000 3030 8080 8443; do
    timeout 3 bash -c "echo > /dev/tcp/$TARGET_IP/$port" 2>/dev/null && \
        echo -e "${YELLOW}[!] Porta $port: ABERTA${NC}" || \
        echo -e "${GREEN}[✓] Porta $port: Fechada/Filtrada${NC}"
done > "$REPORT_DIR/09_port_scan.txt"
cat "$REPORT_DIR/09_port_scan.txt"

################################################################################
# 10. Verificar .htaccess e .htpasswd
################################################################################
echo -e "\n${YELLOW}[10] Verificando arquivos .htaccess e .htpasswd...${NC}"
for file in ".htaccess" ".htpasswd"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$file")
    echo "  - /$file: HTTP $STATUS"
    if [ "$STATUS" = "200" ]; then
        echo -e "${RED}    [!] CRÍTICO: Arquivo acessível${NC}"
        curl -s "$TARGET/$file" > "$REPORT_DIR/10_$file.txt"
    fi
done > "$REPORT_DIR/10_htaccess.txt"
cat "$REPORT_DIR/10_htaccess.txt"

################################################################################
# 11. Verificar APIs Expostas
################################################################################
echo -e "\n${YELLOW}[11] Verificando APIs comuns...${NC}"
for api in "api" "api/v1" "api/v2" "_api" "rest" "graphql"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$api")
    echo "  - /$api: HTTP $STATUS"
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "401" ]; then
        echo -e "${YELLOW}    [!] Endpoint API encontrado${NC}"
    fi
done > "$REPORT_DIR/11_api_endpoints.txt"
cat "$REPORT_DIR/11_api_endpoints.txt"

################################################################################
# 12. Verificar Cloudflare
################################################################################
echo -e "\n${YELLOW}[12] Verificando proteção Cloudflare...${NC}"
curl -s -I "$TARGET" | grep -iE "(cf-|cloudflare)" > "$REPORT_DIR/12_cloudflare.txt"
if [ -s "$REPORT_DIR/12_cloudflare.txt" ]; then
    echo -e "${GREEN}[✓] Cloudflare detectado:${NC}"
    cat "$REPORT_DIR/12_cloudflare.txt"
else
    echo -e "${YELLOW}[!] Cloudflare não detectado nos headers${NC}"
fi

################################################################################
# Resumo Final
################################################################################
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}RESUMO DO RETESTE${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Alvo: $TARGET"
echo "IP Principal: $TARGET_IP"
echo "IP SSH: $TARGET_SSH_IP"
echo "Data: $(date)"
echo "Relatórios salvos em: $REPORT_DIR"
echo -e "\nVulnerabilidades Críticas a Verificar:"
echo "  - Porta 3000 (Next.js dev) exposta"
echo "  - Arquivos sensíveis (.mysql_history, .ssh, .bash_history)"
echo "  - Diretórios de backup (_backup, _db_backups)"
echo "  - SSH acessível em $TARGET_SSH_IP:22"
echo "  - Headers de segurança ausentes (HSTS, CSP, Referrer-Policy)"
echo "  - Endpoints administrativos expostos"
echo -e "\n${YELLOW}========================================${NC}"
