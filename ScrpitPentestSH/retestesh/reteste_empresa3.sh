#!/bin/bash

################################################################################
# Script de Reteste - acheumveterano.com.br / app.acheumveterano.com.br
# Data: 2025-11-28
# Autor: Samuel Ziger
# 
# Vulnerabilidades a validar:
# 1. OpenSSH 10.0p2 com CVEs conhecidas (CRÍTICA)
# 2. Arquivos de log expostos (wp-app.log) (ALTA)
# 3. WordPress - endpoints sensíveis expostos (ALTA)
# 4. Ausência de headers anti-clickjacking (MÉDIA)
# 5. Compressão HTTP em endpoints sensíveis - BREACH (MÉDIA)
# 6. TLS - protocolos e certificado (INFO)
################################################################################

TARGET="https://acheumveterano.com.br"
TARGET_APP="https://app.acheumveterano.com.br"
TARGET_IP="72.60.255.201"
REPORT_DIR="./reteste_acheumveterano_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "[+] Iniciando reteste de segurança para acheumveterano.com.br"
echo "[+] IP: $TARGET_IP"
echo "[+] Relatório será salvo em: $REPORT_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# 1. Verificar Versão do SSH e CVEs
################################################################################
echo -e "\n${YELLOW}[1] Verificando versão do OpenSSH...${NC}"
nc -zv -w 3 $TARGET_IP 22 > "$REPORT_DIR/01_ssh_port.txt" 2>&1
if [ $? -eq 0 ]; then
    echo -e "${YELLOW}[!] Porta SSH (22) está ABERTA${NC}"
    
    # Tentar obter banner SSH
    echo "QUIT" | timeout 5 nc $TARGET_IP 22 > "$REPORT_DIR/01_ssh_banner.txt" 2>&1
    if grep -qi "openssh" "$REPORT_DIR/01_ssh_banner.txt"; then
        echo "Banner SSH:"
        cat "$REPORT_DIR/01_ssh_banner.txt"
        
        if grep -qi "openssh.*10\.0" "$REPORT_DIR/01_ssh_banner.txt"; then
            echo -e "${RED}[!] CRÍTICO: OpenSSH 10.0 detectado - vulnerável a CVE-2025-61985, CVE-2025-61984${NC}"
            echo -e "${RED}    Ação recomendada: Atualizar OpenSSH imediatamente${NC}"
        fi
    fi
else
    echo -e "${GREEN}[✓] Porta SSH não acessível ou filtrada${NC}"
fi

################################################################################
# 2. Verificar Redirecionamento para app.acheumveterano.com.br
################################################################################
echo -e "\n${YELLOW}[2] Verificando redirecionamento...${NC}"
curl -s -I "$TARGET" | head -20 > "$REPORT_DIR/02_redirect.txt"
if grep -qi "location:.*app\.acheumveterano" "$REPORT_DIR/02_redirect.txt"; then
    echo -e "${GREEN}[✓] Redirecionamento para app.acheumveterano.com.br confirmado${NC}"
    cat "$REPORT_DIR/02_redirect.txt" | grep -i location
else
    echo "Status de redirecionamento:"
    cat "$REPORT_DIR/02_redirect.txt" | head -5
fi

################################################################################
# 3. Verificar Arquivos de Log Expostos
################################################################################
echo -e "\n${YELLOW}[3] Verificando exposição de arquivos de log...${NC}"
for log_path in "wp-app.log" "wordpress/wp-app.log" "wp-content/debug.log" "error_log" "debug.log"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_APP/$log_path")
    echo "  - /$log_path: HTTP $STATUS"
    if [ "$STATUS" = "200" ]; then
        echo -e "${RED}    [!] CRÍTICO: Arquivo de log acessível publicamente${NC}"
        curl -s "$TARGET_APP/$log_path" | head -20 > "$REPORT_DIR/03_log_$log_path.txt"
    fi
done > "$REPORT_DIR/03_logs_exposed.txt"
cat "$REPORT_DIR/03_logs_exposed.txt"

################################################################################
# 4. Verificar WordPress e Endpoints Sensíveis
################################################################################
echo -e "\n${YELLOW}[4] Verificando endpoints WordPress...${NC}"
curl -s "$TARGET_APP" | grep -i "wordpress" > "$REPORT_DIR/04_wordpress_detection.txt"
if [ -s "$REPORT_DIR/04_wordpress_detection.txt" ]; then
    echo -e "${YELLOW}[!] WordPress detectado${NC}"
fi

# Testar endpoints comuns
for endpoint in "wp-login.php" "wp-admin" "wp-includes" "wp-content" "license.txt" "readme.html" "wp-links-opml.php"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_APP/$endpoint")
    echo "  - /$endpoint: HTTP $STATUS"
    if [ "$STATUS" = "200" ] && [ "$endpoint" = "wp-login.php" ]; then
        echo -e "${YELLOW}    [!] wp-login.php acessível - verificar proteções${NC}"
    fi
    if [ "$STATUS" = "200" ] && [ "$endpoint" = "license.txt" ]; then
        echo -e "${YELLOW}    [!] license.txt exposto - pode revelar versão${NC}"
    fi
done > "$REPORT_DIR/04_wp_endpoints.txt"
cat "$REPORT_DIR/04_wp_endpoints.txt"

################################################################################
# 5. Verificar Headers Anti-Clickjacking
################################################################################
echo -e "\n${YELLOW}[5] Verificando headers anti-clickjacking...${NC}"
curl -s -I "$TARGET_APP" > "$REPORT_DIR/05_headers.txt"

# X-Frame-Options
if grep -qi "x-frame-options" "$REPORT_DIR/05_headers.txt"; then
    XFO=$(grep -i "x-frame-options" "$REPORT_DIR/05_headers.txt")
    echo -e "${GREEN}[✓] X-Frame-Options presente: $XFO${NC}"
else
    echo -e "${RED}[!] VULNERÁVEL: X-Frame-Options ausente (risco de clickjacking)${NC}"
fi

# Content-Security-Policy frame-ancestors
if grep -qi "content-security-policy.*frame-ancestors" "$REPORT_DIR/05_headers.txt"; then
    echo -e "${GREEN}[✓] CSP frame-ancestors presente${NC}"
else
    echo -e "${YELLOW}[!] CSP frame-ancestors ausente${NC}"
fi

################################################################################
# 6. Verificar Compressão HTTP (BREACH)
################################################################################
echo -e "\n${YELLOW}[6] Verificando compressão HTTP em endpoints sensíveis...${NC}"
for endpoint in "" "wp-login.php" "wp-admin"; do
    RESPONSE=$(curl -s -I "$TARGET_APP/$endpoint" -H "Accept-Encoding: gzip, deflate")
    echo "  - /$endpoint:"
    if echo "$RESPONSE" | grep -qi "content-encoding.*\(gzip\|deflate\)"; then
        echo -e "${YELLOW}    [!] Compressão ativa (risco de BREACH em páginas dinâmicas)${NC}"
        echo "$RESPONSE" | grep -i "content-encoding"
    else
        echo -e "${GREEN}    [✓] Sem compressão detectada${NC}"
    fi
done > "$REPORT_DIR/06_compression.txt"
cat "$REPORT_DIR/06_compression.txt"

################################################################################
# 7. Verificar Certificado TLS e Protocolos
################################################################################
echo -e "\n${YELLOW}[7] Verificando certificado TLS...${NC}"
echo | openssl s_client -connect acheumveterano.com.br:443 -servername acheumveterano.com.br 2>/dev/null | \
    openssl x509 -noout -dates -subject -issuer > "$REPORT_DIR/07_tls_cert.txt" 2>&1

if [ -s "$REPORT_DIR/07_tls_cert.txt" ]; then
    echo "Informações do certificado:"
    cat "$REPORT_DIR/07_tls_cert.txt"
    
    # Verificar validade
    NOT_AFTER=$(grep "notAfter" "$REPORT_DIR/07_tls_cert.txt" | cut -d= -f2)
    echo "Válido até: $NOT_AFTER"
else
    echo -e "${YELLOW}[!] Não foi possível obter informações do certificado${NC}"
fi

# Verificar protocolos TLS suportados
echo -e "\n${YELLOW}Testando protocolos TLS...${NC}"
for protocol in tls1 tls1_1 tls1_2 tls1_3; do
    if timeout 5 openssl s_client -connect acheumveterano.com.br:443 -$protocol < /dev/null &>/dev/null; then
        echo -e "  - ${protocol}: ${GREEN}Suportado${NC}"
        if [ "$protocol" = "tls1" ] || [ "$protocol" = "tls1_1" ]; then
            echo -e "${RED}    [!] VULNERÁVEL: Protocolo obsoleto habilitado${NC}"
        fi
    else
        echo -e "  - ${protocol}: Não suportado"
    fi
done > "$REPORT_DIR/07_tls_protocols.txt"
cat "$REPORT_DIR/07_tls_protocols.txt"

################################################################################
# 8. Verificar Headers de Segurança Gerais
################################################################################
echo -e "\n${YELLOW}[8] Verificando headers de segurança gerais...${NC}"

# HSTS
if grep -qi "strict-transport-security" "$REPORT_DIR/05_headers.txt"; then
    HSTS=$(grep -i "strict-transport-security" "$REPORT_DIR/05_headers.txt")
    echo -e "${GREEN}[✓] HSTS configurado: $HSTS${NC}"
else
    echo -e "${YELLOW}[!] HSTS não configurado${NC}"
fi

# X-Content-Type-Options
if grep -qi "x-content-type-options" "$REPORT_DIR/05_headers.txt"; then
    echo -e "${GREEN}[✓] X-Content-Type-Options presente${NC}"
else
    echo -e "${YELLOW}[!] X-Content-Type-Options ausente${NC}"
fi

# X-XSS-Protection
if grep -qi "x-xss-protection" "$REPORT_DIR/05_headers.txt"; then
    echo -e "${GREEN}[✓] X-XSS-Protection presente${NC}"
else
    echo -e "${YELLOW}[!] X-XSS-Protection ausente${NC}"
fi

# CSP
if grep -qi "content-security-policy:" "$REPORT_DIR/05_headers.txt"; then
    echo -e "${GREEN}[✓] Content-Security-Policy configurado${NC}"
else
    echo -e "${YELLOW}[!] Content-Security-Policy ausente${NC}"
fi

################################################################################
# 9. Verificar Cookies de Sessão
################################################################################
echo -e "\n${YELLOW}[9] Verificando cookies de sessão...${NC}"
curl -s -I "$TARGET_APP/wp-login.php" | grep -i "set-cookie" > "$REPORT_DIR/09_cookies.txt"
if [ -s "$REPORT_DIR/09_cookies.txt" ]; then
    echo "Cookies encontrados:"
    cat "$REPORT_DIR/09_cookies.txt"
    
    if ! grep -qi "httponly" "$REPORT_DIR/09_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag HttpOnly${NC}"
    fi
    if ! grep -qi "secure" "$REPORT_DIR/09_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag Secure${NC}"
    fi
    if ! grep -qi "samesite" "$REPORT_DIR/09_cookies.txt"; then
        echo -e "${YELLOW}[!] Cookie sem flag SameSite${NC}"
    fi
else
    echo -e "${GREEN}[✓] Nenhum cookie retornado${NC}"
fi

################################################################################
# 10. Enumeração de Diretórios Sensíveis
################################################################################
echo -e "\n${YELLOW}[10] Testando diretórios sensíveis...${NC}"
for dir in "backup" "backups" "_backup" "old" "temp" "uploads" "wp-content/uploads" ".git" ".env" "phpinfo.php"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_APP/$dir")
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "301" ] || [ "$STATUS" = "302" ]; then
        echo -e "${RED}[!] /$dir: HTTP $STATUS - ACESSÍVEL${NC}"
    else
        echo -e "${GREEN}[✓] /$dir: HTTP $STATUS${NC}"
    fi
done > "$REPORT_DIR/10_sensitive_dirs.txt"
cat "$REPORT_DIR/10_sensitive_dirs.txt"

################################################################################
# 11. Verificar robots.txt
################################################################################
echo -e "\n${YELLOW}[11] Verificando robots.txt...${NC}"
curl -s "$TARGET_APP/robots.txt" -o "$REPORT_DIR/11_robots.txt"
if [ -s "$REPORT_DIR/11_robots.txt" ]; then
    echo "Conteúdo do robots.txt:"
    cat "$REPORT_DIR/11_robots.txt"
else
    echo -e "${GREEN}[✓] robots.txt não encontrado ou vazio${NC}"
fi

################################################################################
# 12. Verificar Server e Tecnologias Expostas
################################################################################
echo -e "\n${YELLOW}[12] Verificando informações de servidor expostas...${NC}"
grep -iE "(server|x-powered-by|x-generator)" "$REPORT_DIR/05_headers.txt" > "$REPORT_DIR/12_server_info.txt"
if [ -s "$REPORT_DIR/12_server_info.txt" ]; then
    echo "Headers que revelam tecnologias:"
    cat "$REPORT_DIR/12_server_info.txt"
else
    echo -e "${GREEN}[✓] Nenhuma informação sensível de servidor nos headers${NC}"
fi

################################################################################
# Resumo Final
################################################################################
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}RESUMO DO RETESTE${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Alvo: $TARGET / $TARGET_APP"
echo "IP: $TARGET_IP"
echo "Data: $(date)"
echo "Relatórios salvos em: $REPORT_DIR"
echo -e "\nVulnerabilidades Críticas a Verificar:"
echo "  - OpenSSH 10.0p2 (CVE-2025-61985, CVE-2025-61984)"
echo "  - Arquivos de log expostos (wp-app.log)"
echo "  - WordPress endpoints sensíveis"
echo "  - Headers anti-clickjacking"
echo "  - Compressão em endpoints dinâmicos"
echo "  - Protocolos TLS obsoletos (se presentes)"
echo -e "\n${YELLOW}========================================${NC}"
