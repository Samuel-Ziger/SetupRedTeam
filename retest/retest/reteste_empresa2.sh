#!/bin/bash

################################################################################
# Script de Reteste - divisaodeelite.com.br
# Data: 2025-11-28
# Autor: Samuel Ziger
# 
# Vulnerabilidades a validar:
# 1. Token bubble_plp_token exposto no window (ALTA)
# 2. Endpoint /version-test/api/1.1/init/data sem autenticação (ALTA)
# 3. Plugin enviando dados para servidor externo (CRÍTICA)
# 4. Cookies sem HttpOnly, Secure, SameSite (ALTA)
# 5. Scripts de terceiros sem SRI (ALTA)
# 6. Service Worker registrável (ALTA)
# 7. Ausência de CSP (ALTA)
# 8. CSP Permissivo - Form Hijacking (MÉDIA)
# 9. Proxies JS com risco de prototype pollution (MÉDIA)
################################################################################

TARGET="https://divisaodeelite.com.br"
REPORT_DIR="./reteste_divisaodeelite_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "[+] Iniciando reteste de segurança para divisaodeelite.com.br"
echo "[+] Relatório será salvo em: $REPORT_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# 1. Verificar Token bubble_plp_token Exposto
################################################################################
echo -e "\n${YELLOW}[1] Testando exposição de token bubble_plp_token...${NC}"
curl -s "$TARGET" | grep -o "bubble_plp_token.*" | head -5 > "$REPORT_DIR/01_bubble_token.txt"
if [ -s "$REPORT_DIR/01_bubble_token.txt" ]; then
    echo -e "${RED}[!] CRÍTICO: Token bubble_plp_token exposto no JavaScript${NC}"
    cat "$REPORT_DIR/01_bubble_token.txt"
else
    echo -e "${GREEN}[✓] Token bubble_plp_token não encontrado${NC}"
fi

################################################################################
# 2. Testar Endpoint version-test sem Autenticação
################################################################################
echo -e "\n${YELLOW}[2] Testando endpoint /version-test/api/1.1/init/data...${NC}"
curl -s "$TARGET/version-test/api/1.1/init/data?location=$TARGET" -o "$REPORT_DIR/02_version_test_endpoint.json"
if grep -q "app_id\|user\|data" "$REPORT_DIR/02_version_test_endpoint.json" 2>/dev/null; then
    echo -e "${RED}[!] CRÍTICO: Endpoint expõe dados sensíveis sem autenticação${NC}"
    head -20 "$REPORT_DIR/02_version_test_endpoint.json"
else
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/version-test/api/1.1/init/data")
    echo "Status HTTP: $STATUS"
    if [ "$STATUS" = "200" ]; then
        echo -e "${RED}[!] VULNERÁVEL: Endpoint retorna HTTP 200${NC}"
    else
        echo -e "${GREEN}[✓] Endpoint protegido ou não acessível${NC}"
    fi
fi

################################################################################
# 3. Verificar Plugin Malicioso (Data Exfiltration)
################################################################################
echo -e "\n${YELLOW}[3] Verificando plugin que envia dados para railway.app...${NC}"
curl -s "$TARGET" | grep -i "railway.app" > "$REPORT_DIR/03_railway_plugin.txt"
if [ -s "$REPORT_DIR/03_railway_plugin.txt" ]; then
    echo -e "${RED}[!] CRÍTICO: Plugin enviando dados para up.railway.app detectado${NC}"
    cat "$REPORT_DIR/03_railway_plugin.txt"
else
    echo -e "${GREEN}[✓] Nenhuma referência a railway.app encontrada${NC}"
fi

################################################################################
# 4. Verificar Cookies sem Proteção
################################################################################
echo -e "\n${YELLOW}[4] Verificando flags de segurança nos cookies...${NC}"
curl -s -I "$TARGET" | grep -i "set-cookie" > "$REPORT_DIR/04_cookies.txt"
if [ -s "$REPORT_DIR/04_cookies.txt" ]; then
    echo "Cookies encontrados:"
    cat "$REPORT_DIR/04_cookies.txt"
    
    if ! grep -qi "httponly" "$REPORT_DIR/04_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag HttpOnly${NC}"
    else
        echo -e "${GREEN}[✓] Flag HttpOnly presente${NC}"
    fi
    
    if ! grep -qi "secure" "$REPORT_DIR/04_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag Secure${NC}"
    else
        echo -e "${GREEN}[✓] Flag Secure presente${NC}"
    fi
    
    if ! grep -qi "samesite" "$REPORT_DIR/04_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag SameSite${NC}"
    else
        echo -e "${GREEN}[✓] Flag SameSite presente${NC}"
    fi
else
    echo -e "${GREEN}[✓] Nenhum cookie retornado nesta requisição${NC}"
fi

################################################################################
# 5. Verificar Scripts sem SRI (Subresource Integrity)
################################################################################
echo -e "\n${YELLOW}[5] Verificando scripts externos sem SRI...${NC}"
curl -s "$TARGET" | grep -E '<script.*src=' | grep -v 'integrity=' > "$REPORT_DIR/05_scripts_sem_sri.txt"
if [ -s "$REPORT_DIR/05_scripts_sem_sri.txt" ]; then
    echo -e "${RED}[!] VULNERÁVEL: Scripts externos sem SRI detectados:${NC}"
    cat "$REPORT_DIR/05_scripts_sem_sri.txt" | head -10
    echo "Total: $(wc -l < "$REPORT_DIR/05_scripts_sem_sri.txt") scripts sem SRI"
else
    echo -e "${GREEN}[✓] Todos os scripts externos possuem SRI${NC}"
fi

################################################################################
# 6. Verificar Service Worker
################################################################################
echo -e "\n${YELLOW}[6] Verificando registro de Service Worker...${NC}"
curl -s "$TARGET/service-worker.js" -o "$REPORT_DIR/06_service_worker.js" 2>&1
if [ -f "$REPORT_DIR/06_service_worker.js" ] && [ -s "$REPORT_DIR/06_service_worker.js" ]; then
    echo -e "${YELLOW}[!] Service Worker encontrado e acessível${NC}"
    echo "Primeiras 10 linhas:"
    head -10 "$REPORT_DIR/06_service_worker.js"
else
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/service-worker.js")
    echo "Status HTTP: $STATUS"
    if [ "$STATUS" = "404" ]; then
        echo -e "${GREEN}[✓] Service Worker não encontrado${NC}"
    fi
fi

# Verificar se há registro no HTML
curl -s "$TARGET" | grep -i "serviceWorker.register" > "$REPORT_DIR/06_sw_register.txt"
if [ -s "$REPORT_DIR/06_sw_register.txt" ]; then
    echo -e "${YELLOW}[!] Código de registro de Service Worker encontrado no HTML${NC}"
    cat "$REPORT_DIR/06_sw_register.txt"
fi

################################################################################
# 7. Verificar CSP (Content Security Policy)
################################################################################
echo -e "\n${YELLOW}[7] Verificando Content Security Policy...${NC}"
curl -s -I "$TARGET" > "$REPORT_DIR/07_headers_csp.txt"

if grep -qi "content-security-policy:" "$REPORT_DIR/07_headers_csp.txt"; then
    CSP=$(grep -i "content-security-policy:" "$REPORT_DIR/07_headers_csp.txt")
    echo "CSP encontrado: $CSP"
    
    # Verificar se é apenas report-only
    if grep -qi "content-security-policy-report-only" "$REPORT_DIR/07_headers_csp.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: CSP está apenas em modo report-only${NC}"
    fi
    
    # Verificar form-action
    if ! echo "$CSP" | grep -qi "form-action"; then
        echo -e "${RED}[!] VULNERÁVEL: CSP sem diretiva form-action (risco de form hijacking)${NC}"
    else
        echo -e "${GREEN}[✓] Diretiva form-action presente${NC}"
    fi
    
    # Verificar frame-ancestors
    if echo "$CSP" | grep -qi "frame-ancestors.*'none'"; then
        echo -e "${GREEN}[✓] Frame-ancestors configurado corretamente${NC}"
    elif ! echo "$CSP" | grep -qi "frame-ancestors"; then
        echo -e "${YELLOW}[!] ATENÇÃO: frame-ancestors não configurado${NC}"
    fi
else
    echo -e "${RED}[!] CRÍTICO: Nenhum CSP configurado${NC}"
fi

################################################################################
# 8. Verificar Headers de Segurança
################################################################################
echo -e "\n${YELLOW}[8] Verificando outros headers de segurança...${NC}"

# X-Frame-Options
if grep -qi "x-frame-options" "$REPORT_DIR/07_headers_csp.txt"; then
    echo -e "${GREEN}[✓] X-Frame-Options presente${NC}"
else
    echo -e "${RED}[!] VULNERÁVEL: X-Frame-Options ausente (risco de clickjacking)${NC}"
fi

# X-Content-Type-Options
if grep -qi "x-content-type-options" "$REPORT_DIR/07_headers_csp.txt"; then
    echo -e "${GREEN}[✓] X-Content-Type-Options presente${NC}"
else
    echo -e "${YELLOW}[!] X-Content-Type-Options ausente${NC}"
fi

# Strict-Transport-Security
if grep -qi "strict-transport-security" "$REPORT_DIR/07_headers_csp.txt"; then
    echo -e "${GREEN}[✓] HSTS configurado${NC}"
else
    echo -e "${YELLOW}[!] HSTS não configurado${NC}"
fi

################################################################################
# 9. Testar Fingerprinting Bubble.io
################################################################################
echo -e "\n${YELLOW}[9] Verificando fingerprinting da plataforma Bubble.io...${NC}"
curl -s -I "$TARGET" | grep -iE "(x-bubble|x-powered-by.*express)" > "$REPORT_DIR/09_bubble_fingerprint.txt"
if [ -s "$REPORT_DIR/09_bubble_fingerprint.txt" ]; then
    echo -e "${YELLOW}[!] ATENÇÃO: Headers revelam uso do Bubble.io:${NC}"
    cat "$REPORT_DIR/09_bubble_fingerprint.txt"
else
    echo -e "${GREEN}[✓] Headers sensíveis não encontrados${NC}"
fi

################################################################################
# 10. Verificar Endpoints Comuns do Bubble
################################################################################
echo -e "\n${YELLOW}[10] Testando endpoints comuns da plataforma Bubble...${NC}"
for endpoint in "version-test" "api/1.1/wf" "api/1.1/obj" "api/1.1/meta" "api/1.1/upload"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$endpoint")
    echo "  - /$endpoint: HTTP $STATUS"
    if [ "$STATUS" = "200" ]; then
        echo -e "    ${RED}[!] Endpoint acessível${NC}"
    fi
done > "$REPORT_DIR/10_bubble_endpoints.txt"
cat "$REPORT_DIR/10_bubble_endpoints.txt"

################################################################################
# 11. Verificar robots.txt e version-test
################################################################################
echo -e "\n${YELLOW}[11] Verificando robots.txt...${NC}"
curl -s "$TARGET/robots.txt" -o "$REPORT_DIR/11_robots.txt"
if [ -s "$REPORT_DIR/11_robots.txt" ]; then
    echo "Conteúdo do robots.txt:"
    cat "$REPORT_DIR/11_robots.txt"
    if grep -qi "version-test" "$REPORT_DIR/11_robots.txt"; then
        echo -e "${YELLOW}[!] ATENÇÃO: robots.txt revela ambiente version-test${NC}"
    fi
else
    echo -e "${GREEN}[✓] robots.txt não encontrado ou vazio${NC}"
fi

################################################################################
# 12. Scan de Portas (Cloudflare Alternative Ports)
################################################################################
echo -e "\n${YELLOW}[12] Verificando portas alternativas do Cloudflare...${NC}"
echo "Testando portas: 2052, 2053, 2082, 2083, 2086, 2087, 2095, 2096, 8080, 8443, 8880"
for port in 2052 2053 2082 2083 2086 2087 2095 2096 8080 8443 8880; do
    timeout 3 bash -c "echo > /dev/tcp/divisaodeelite.com.br/$port" 2>/dev/null && \
        echo -e "${YELLOW}[!] Porta $port ABERTA (Cloudflare)${NC}" || \
        echo -e "${GREEN}[✓] Porta $port fechada/filtrada${NC}"
done > "$REPORT_DIR/12_cloudflare_ports.txt"
cat "$REPORT_DIR/12_cloudflare_ports.txt"

################################################################################
# Resumo Final
################################################################################
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}RESUMO DO RETESTE${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Alvo: $TARGET"
echo "Data: $(date)"
echo "Relatórios salvos em: $REPORT_DIR"
echo -e "\nVulnerabilidades Críticas a Verificar:"
echo "  - Token bubble_plp_token exposto"
echo "  - Plugin enviando dados para railway.app"
echo "  - Endpoint version-test sem autenticação"
echo "  - Cookies sem proteção adequada"
echo "  - Scripts sem SRI"
echo "  - Ausência de CSP ou CSP inadequado"
echo -e "\n${YELLOW}========================================${NC}"
