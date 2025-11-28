#!/bin/bash

################################################################################
# Script de Reteste - planodechamadas.com.br / lp.planodechamadas.com.br
# Data: 2025-11-28
# Autor: Samuel Ziger
# 
# Vulnerabilidades a validar:
# 1. Exposição direta do IP (bypass WAF/CDN) (CRÍTICA)
# 2. Next.js sem segurança adicional - SSRF, LFI/RFI (CRÍTICA)
# 3. Headers incomuns revelando tecnologias (ALTA)
# 4. Ausência de HSTS (ALTA)
# 5. Ausência de X-Frame-Options (ALTA)
# 6. Ausência de CSP (ALTA)
# 7. Configuração TLS/SSL (INFO - mas verificar boas práticas)
################################################################################

TARGET="https://planodechamadas.com.br"
TARGET_LP="https://lp.planodechamadas.com.br"
TARGET_IP="31.97.27.219"
REPORT_DIR="./reteste_planodechamadas_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "[+] Iniciando reteste de segurança para planodechamadas.com.br"
echo "[+] IP: $TARGET_IP"
echo "[+] Relatório será salvo em: $REPORT_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# 1. Verificar Acesso Direto por IP (Bypass CDN)
################################################################################
echo -e "\n${YELLOW}[1] Testando acesso direto ao IP (bypass CDN/WAF)...${NC}"
curl -s -I "http://$TARGET_IP" -H "Host: planodechamadas.com.br" > "$REPORT_DIR/01_direct_ip_http.txt"
curl -s -I "https://$TARGET_IP" -H "Host: planodechamadas.com.br" -k > "$REPORT_DIR/01_direct_ip_https.txt"

if grep -qi "200\|301\|302" "$REPORT_DIR/01_direct_ip_http.txt"; then
    echo -e "${RED}[!] CRÍTICO: Servidor acessível diretamente pelo IP via HTTP${NC}"
    head -10 "$REPORT_DIR/01_direct_ip_http.txt"
else
    echo -e "${GREEN}[✓] IP não responde diretamente via HTTP${NC}"
fi

if grep -qi "200\|301\|302" "$REPORT_DIR/01_direct_ip_https.txt"; then
    echo -e "${RED}[!] CRÍTICO: Servidor acessível diretamente pelo IP via HTTPS${NC}"
    head -10 "$REPORT_DIR/01_direct_ip_https.txt"
else
    echo -e "${GREEN}[✓] IP não responde diretamente via HTTPS${NC}"
fi

################################################################################
# 2. Verificar Headers de Segurança (Domínio Principal)
################################################################################
echo -e "\n${YELLOW}[2] Verificando headers de segurança em planodechamadas.com.br...${NC}"
curl -s -I "$TARGET" > "$REPORT_DIR/02_headers_main.txt"

# Strict-Transport-Security (HSTS)
if grep -qi "strict-transport-security" "$REPORT_DIR/02_headers_main.txt"; then
    HSTS=$(grep -i "strict-transport-security" "$REPORT_DIR/02_headers_main.txt")
    echo -e "${GREEN}[✓] HSTS presente: $HSTS${NC}"
else
    echo -e "${RED}[!] CRÍTICO: HSTS ausente${NC}"
fi

# X-Frame-Options
if grep -qi "x-frame-options" "$REPORT_DIR/02_headers_main.txt"; then
    XFO=$(grep -i "x-frame-options" "$REPORT_DIR/02_headers_main.txt")
    echo -e "${GREEN}[✓] X-Frame-Options presente: $XFO${NC}"
else
    echo -e "${RED}[!] CRÍTICO: X-Frame-Options ausente (risco de clickjacking)${NC}"
fi

# Content-Security-Policy
if grep -qi "content-security-policy:" "$REPORT_DIR/02_headers_main.txt"; then
    echo -e "${GREEN}[✓] CSP configurado${NC}"
    grep -i "content-security-policy" "$REPORT_DIR/02_headers_main.txt"
else
    echo -e "${RED}[!] CRÍTICO: CSP ausente${NC}"
fi

# X-Content-Type-Options
if grep -qi "x-content-type-options" "$REPORT_DIR/02_headers_main.txt"; then
    echo -e "${GREEN}[✓] X-Content-Type-Options presente${NC}"
else
    echo -e "${YELLOW}[!] X-Content-Type-Options ausente${NC}"
fi

# Referrer-Policy
if grep -qi "referrer-policy" "$REPORT_DIR/02_headers_main.txt"; then
    echo -e "${GREEN}[✓] Referrer-Policy presente${NC}"
else
    echo -e "${YELLOW}[!] Referrer-Policy ausente${NC}"
fi

################################################################################
# 3. Verificar Headers de Segurança (lp.planodechamadas.com.br)
################################################################################
echo -e "\n${YELLOW}[3] Verificando headers de segurança em lp.planodechamadas.com.br...${NC}"
curl -s -I "$TARGET_LP" > "$REPORT_DIR/03_headers_lp.txt"

echo "Comparando headers do LP:"
echo "HSTS:"
grep -i "strict-transport-security" "$REPORT_DIR/03_headers_lp.txt" || echo -e "${RED}[!] HSTS ausente no LP${NC}"

echo "X-Frame-Options:"
grep -i "x-frame-options" "$REPORT_DIR/03_headers_lp.txt" || echo -e "${RED}[!] X-Frame-Options ausente no LP${NC}"

echo "CSP:"
grep -i "content-security-policy" "$REPORT_DIR/03_headers_lp.txt" || echo -e "${RED}[!] CSP ausente no LP${NC}"

################################################################################
# 4. Verificar Fingerprinting Next.js
################################################################################
echo -e "\n${YELLOW}[4] Verificando exposição de tecnologia Next.js...${NC}"

# Headers
grep -iE "(x-nextjs|x-powered-by|server)" "$REPORT_DIR/02_headers_main.txt" > "$REPORT_DIR/04_nextjs_headers.txt"
if [ -s "$REPORT_DIR/04_nextjs_headers.txt" ]; then
    echo -e "${YELLOW}[!] ATENÇÃO: Headers revelam tecnologias:${NC}"
    cat "$REPORT_DIR/04_nextjs_headers.txt"
else
    echo -e "${GREEN}[✓] Nenhum header sensível de tecnologia${NC}"
fi

# HTML/JavaScript
curl -s "$TARGET" | grep -iE "(_next|__next|next\.js)" | head -5 > "$REPORT_DIR/04_nextjs_html.txt"
if [ -s "$REPORT_DIR/04_nextjs_html.txt" ]; then
    echo -e "${YELLOW}[!] Next.js detectado no HTML/JS:${NC}"
    cat "$REPORT_DIR/04_nextjs_html.txt"
fi

################################################################################
# 5. Testar APIs Comuns do Next.js
################################################################################
echo -e "\n${YELLOW}[5] Testando endpoints de API Next.js...${NC}"
for endpoint in "api" "api/hello" "api/auth" "_next/data" "_next/static" "__nextjs_original-stack-frame"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$endpoint")
    echo "  - /$endpoint: HTTP $STATUS"
    if [ "$STATUS" = "200" ]; then
        echo -e "${YELLOW}    [!] Endpoint acessível${NC}"
    fi
done > "$REPORT_DIR/05_nextjs_api_endpoints.txt"
cat "$REPORT_DIR/05_nextjs_api_endpoints.txt"

################################################################################
# 6. Verificar Certificado TLS/SSL
################################################################################
echo -e "\n${YELLOW}[6] Verificando certificado TLS/SSL...${NC}"

# Certificado do LP (conforme relatório tem Let's Encrypt)
echo "Verificando lp.planodechamadas.com.br:"
echo | openssl s_client -connect lp.planodechamadas.com.br:443 -servername lp.planodechamadas.com.br 2>/dev/null | \
    openssl x509 -noout -dates -subject -issuer > "$REPORT_DIR/06_tls_cert_lp.txt" 2>&1

if [ -s "$REPORT_DIR/06_tls_cert_lp.txt" ]; then
    echo "Informações do certificado LP:"
    cat "$REPORT_DIR/06_tls_cert_lp.txt"
    
    # Verificar validade
    NOT_AFTER=$(grep "notAfter" "$REPORT_DIR/06_tls_cert_lp.txt" | cut -d= -f2-)
    echo "Válido até: $NOT_AFTER"
    
    # Verificar se é Let's Encrypt
    if grep -qi "let's encrypt" "$REPORT_DIR/06_tls_cert_lp.txt"; then
        echo -e "${GREEN}[✓] Certificado Let's Encrypt válido${NC}"
    fi
else
    echo -e "${YELLOW}[!] Não foi possível obter certificado${NC}"
fi

################################################################################
# 7. Verificar Protocolos TLS Suportados
################################################################################
echo -e "\n${YELLOW}[7] Testando protocolos TLS suportados...${NC}"

# TLS 1.2 e 1.3 devem estar ativos (conforme relatório)
for protocol in tls1 tls1_1 tls1_2 tls1_3; do
    if timeout 5 openssl s_client -connect lp.planodechamadas.com.br:443 -$protocol < /dev/null &>/dev/null; then
        if [ "$protocol" = "tls1_2" ] || [ "$protocol" = "tls1_3" ]; then
            echo -e "  - ${protocol}: ${GREEN}Suportado (esperado)${NC}"
        else
            echo -e "  - ${protocol}: ${RED}Suportado (VULNERÁVEL - protocolo obsoleto)${NC}"
        fi
    else
        if [ "$protocol" = "tls1" ] || [ "$protocol" = "tls1_1" ]; then
            echo -e "  - ${protocol}: ${GREEN}Não suportado (esperado)${NC}"
        else
            echo -e "  - ${protocol}: Não suportado"
        fi
    fi
done > "$REPORT_DIR/07_tls_protocols.txt"
cat "$REPORT_DIR/07_tls_protocols.txt"

################################################################################
# 8. Verificar Cipher Suites
################################################################################
echo -e "\n${YELLOW}[8] Verificando cipher suites...${NC}"
echo | openssl s_client -connect lp.planodechamadas.com.br:443 -cipher 'ALL' 2>/dev/null | \
    grep -E "Cipher|Protocol" > "$REPORT_DIR/08_cipher_suites.txt"

if [ -s "$REPORT_DIR/08_cipher_suites.txt" ]; then
    echo "Cipher suites em uso:"
    cat "$REPORT_DIR/08_cipher_suites.txt"
    
    # Verificar se há ciphers fracos
    if grep -qiE "(rc4|des|md5|export|null)" "$REPORT_DIR/08_cipher_suites.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cipher suites fracos detectados${NC}"
    else
        echo -e "${GREEN}[✓] Nenhum cipher suite fraco detectado${NC}"
    fi
fi

################################################################################
# 9. Testar Diretórios Comuns
################################################################################
echo -e "\n${YELLOW}[9] Testando diretórios comuns...${NC}"
for dir in "admin" "api" "backup" "config" "uploads" ".git" ".env" "debug" \
           "_next" "__next" "static" "public"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$dir")
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "301" ] || [ "$STATUS" = "302" ] || [ "$STATUS" = "403" ]; then
        echo -e "${YELLOW}[!] /$dir: HTTP $STATUS - ENCONTRADO${NC}"
    else
        echo -e "${GREEN}[✓] /$dir: HTTP $STATUS${NC}"
    fi
done > "$REPORT_DIR/09_common_dirs.txt"
cat "$REPORT_DIR/09_common_dirs.txt"

################################################################################
# 10. Verificar robots.txt e sitemap.xml
################################################################################
echo -e "\n${YELLOW}[10] Verificando robots.txt e sitemap.xml...${NC}"

curl -s "$TARGET/robots.txt" -o "$REPORT_DIR/10_robots.txt"
if [ -s "$REPORT_DIR/10_robots.txt" ]; then
    echo "robots.txt encontrado:"
    cat "$REPORT_DIR/10_robots.txt"
else
    echo -e "${GREEN}[✓] robots.txt não encontrado${NC}"
fi

curl -s "$TARGET/sitemap.xml" -o "$REPORT_DIR/10_sitemap.xml"
if [ -s "$REPORT_DIR/10_sitemap.xml" ]; then
    echo "sitemap.xml encontrado:"
    head -20 "$REPORT_DIR/10_sitemap.xml"
else
    echo -e "${GREEN}[✓] sitemap.xml não encontrado${NC}"
fi

################################################################################
# 11. Verificar CORS
################################################################################
echo -e "\n${YELLOW}[11] Testando política CORS...${NC}"
curl -s -I "$TARGET" -H "Origin: https://malicious.com" > "$REPORT_DIR/11_cors_test.txt"
if grep -q "Access-Control-Allow-Origin" "$REPORT_DIR/11_cors_test.txt"; then
    echo "CORS headers encontrados:"
    grep -i "access-control" "$REPORT_DIR/11_cors_test.txt"
    
    if grep -q "Access-Control-Allow-Origin: \*" "$REPORT_DIR/11_cors_test.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: CORS permite qualquer origem (*)${NC}"
    elif grep -q "Access-Control-Allow-Origin: https://malicious.com" "$REPORT_DIR/11_cors_test.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: CORS reflete origem maliciosa${NC}"
    fi
else
    echo -e "${GREEN}[✓] CORS não configurado ou restrito${NC}"
fi

################################################################################
# 12. Verificar Server Info e Nginx
################################################################################
echo -e "\n${YELLOW}[12] Verificando informações do servidor...${NC}"
grep -iE "(server|x-powered-by)" "$REPORT_DIR/02_headers_main.txt" > "$REPORT_DIR/12_server_info.txt"
if [ -s "$REPORT_DIR/12_server_info.txt" ]; then
    echo "Server headers:"
    cat "$REPORT_DIR/12_server_info.txt"
    
    if grep -qi "nginx" "$REPORT_DIR/12_server_info.txt"; then
        echo -e "${GREEN}[✓] Servidor Nginx detectado${NC}"
    fi
else
    echo -e "${GREEN}[✓] Nenhuma informação de servidor exposta${NC}"
fi

################################################################################
# 13. Scan de Portas no IP
################################################################################
echo -e "\n${YELLOW}[13] Scan de portas no IP $TARGET_IP...${NC}"
echo "Testando portas: 21, 22, 80, 443, 3000, 8080, 8443"
for port in 21 22 80 443 3000 8080 8443; do
    timeout 3 bash -c "echo > /dev/tcp/$TARGET_IP/$port" 2>/dev/null && \
        echo -e "${YELLOW}[!] Porta $port: ABERTA${NC}" || \
        echo -e "${GREEN}[✓] Porta $port: Fechada/Filtrada${NC}"
done > "$REPORT_DIR/13_port_scan.txt"
cat "$REPORT_DIR/13_port_scan.txt"

################################################################################
# 14. Verificar Rate Limiting
################################################################################
echo -e "\n${YELLOW}[14] Testando rate limiting...${NC}"
echo "Enviando 15 requisições rápidas..."
for i in {1..15}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET")
    echo -n "$STATUS "
    if [ "$STATUS" = "429" ]; then
        echo -e "\n${GREEN}[✓] Rate limiting ativo (HTTP 429)${NC}"
        break
    fi
    sleep 0.2
done > "$REPORT_DIR/14_rate_limiting.txt"
echo ""
if ! grep -q "429" "$REPORT_DIR/14_rate_limiting.txt"; then
    echo -e "${YELLOW}[!] Rate limiting não detectado nas 15 requisições${NC}"
fi

################################################################################
# Resumo Final
################################################################################
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}RESUMO DO RETESTE${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Alvo: $TARGET / $TARGET_LP"
echo "IP: $TARGET_IP"
echo "Data: $(date)"
echo "Relatórios salvos em: $REPORT_DIR"
echo -e "\nVulnerabilidades a Verificar:"
echo "  - Acesso direto ao IP (bypass CDN/WAF)"
echo "  - Headers de segurança ausentes (HSTS, X-Frame-Options, CSP)"
echo "  - Exposição de tecnologia Next.js"
echo "  - APIs Next.js expostas"
echo "  - Protocolos TLS obsoletos (se presentes)"
echo "  - CORS permissivo"
echo -e "\nPontos Positivos (se aplicável):"
echo "  - Certificado TLS válido (Let's Encrypt)"
echo "  - TLS 1.2 e 1.3 ativos"
echo "  - Cipher suites fortes"
echo -e "\n${YELLOW}========================================${NC}"
