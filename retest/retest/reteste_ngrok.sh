#!/bin/bash

################################################################################
# Script de Reteste - 0fc5d3bbe18c.ngrok-free.app
# Data: 2025-11-28
# Autor: Samuel Ziger
# 
# Vulnerabilidades a validar:
# 1. Ausência de X-Frame-Options (MÉDIA)
# 2. Ausência de X-Content-Type-Options (MÉDIA)
# 3. Ausência de headers de segurança gerais (MÉDIA)
# 4. Enumeração de diretórios (INFO)
# 5. APIs expostas (INFO)
################################################################################

TARGET="https://0fc5d3bbe18c.ngrok-free.app"
REPORT_DIR="./reteste_ngrok_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "[+] Iniciando reteste de segurança para ngrok URL"
echo "[+] Alvo: $TARGET"
echo "[+] Relatório será salvo em: $REPORT_DIR"
echo ""
echo "[!] ATENÇÃO: Esta é uma URL temporária do ngrok que pode expirar"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# 0. Verificar se o ngrok está ativo
################################################################################
echo -e "\n${YELLOW}[0] Verificando disponibilidade do ngrok...${NC}"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET" -m 10)
if [ "$STATUS" = "000" ] || [ "$STATUS" = "" ]; then
    echo -e "${RED}[!] ERRO: URL ngrok não responde - pode estar inativa${NC}"
    echo "Encerrando testes..."
    exit 1
elif [ "$STATUS" = "404" ]; then
    echo -e "${YELLOW}[!] URL retorna HTTP 404 - aplicação pode não estar rodando${NC}"
else
    echo -e "${GREEN}[✓] Ngrok responde - HTTP $STATUS${NC}"
fi

################################################################################
# 1. Verificar Headers de Segurança
################################################################################
echo -e "\n${YELLOW}[1] Verificando headers de segurança...${NC}"
curl -s -I "$TARGET" > "$REPORT_DIR/01_headers.txt"

# X-Frame-Options
if grep -qi "x-frame-options" "$REPORT_DIR/01_headers.txt"; then
    XFO=$(grep -i "x-frame-options" "$REPORT_DIR/01_headers.txt")
    echo -e "${GREEN}[✓] X-Frame-Options presente: $XFO${NC}"
else
    echo -e "${RED}[!] VULNERÁVEL: X-Frame-Options ausente (risco de clickjacking)${NC}"
fi

# X-Content-Type-Options
if grep -qi "x-content-type-options" "$REPORT_DIR/01_headers.txt"; then
    XCTO=$(grep -i "x-content-type-options" "$REPORT_DIR/01_headers.txt")
    echo -e "${GREEN}[✓] X-Content-Type-Options presente: $XCTO${NC}"
else
    echo -e "${RED}[!] VULNERÁVEL: X-Content-Type-Options ausente${NC}"
fi

# Strict-Transport-Security
if grep -qi "strict-transport-security" "$REPORT_DIR/01_headers.txt"; then
    HSTS=$(grep -i "strict-transport-security" "$REPORT_DIR/01_headers.txt")
    echo -e "${GREEN}[✓] HSTS presente: $HSTS${NC}"
else
    echo -e "${YELLOW}[!] HSTS ausente${NC}"
fi

# Content-Security-Policy
if grep -qi "content-security-policy:" "$REPORT_DIR/01_headers.txt"; then
    echo -e "${GREEN}[✓] CSP configurado${NC}"
    grep -i "content-security-policy" "$REPORT_DIR/01_headers.txt"
else
    echo -e "${YELLOW}[!] CSP ausente${NC}"
fi

# X-XSS-Protection
if grep -qi "x-xss-protection" "$REPORT_DIR/01_headers.txt"; then
    echo -e "${GREEN}[✓] X-XSS-Protection presente${NC}"
else
    echo -e "${YELLOW}[!] X-XSS-Protection ausente${NC}"
fi

# Referrer-Policy
if grep -qi "referrer-policy" "$REPORT_DIR/01_headers.txt"; then
    echo -e "${GREEN}[✓] Referrer-Policy presente${NC}"
else
    echo -e "${YELLOW}[!] Referrer-Policy ausente${NC}"
fi

################################################################################
# 2. Verificar robots.txt e sitemap.xml
################################################################################
echo -e "\n${YELLOW}[2] Verificando robots.txt e sitemap.xml...${NC}"

STATUS_ROBOTS=$(curl -s -o "$REPORT_DIR/02_robots.txt" -w "%{http_code}" "$TARGET/robots.txt")
if [ "$STATUS_ROBOTS" = "200" ]; then
    echo -e "${GREEN}[✓] robots.txt encontrado:${NC}"
    cat "$REPORT_DIR/02_robots.txt"
else
    echo -e "${YELLOW}[!] robots.txt não encontrado (HTTP $STATUS_ROBOTS)${NC}"
fi

STATUS_SITEMAP=$(curl -s -o "$REPORT_DIR/02_sitemap.xml" -w "%{http_code}" "$TARGET/sitemap.xml")
if [ "$STATUS_SITEMAP" = "200" ]; then
    echo -e "${GREEN}[✓] sitemap.xml encontrado:${NC}"
    head -20 "$REPORT_DIR/02_sitemap.xml"
else
    echo -e "${YELLOW}[!] sitemap.xml não encontrado (HTTP $STATUS_SITEMAP)${NC}"
fi

################################################################################
# 3. Testar Diretórios Administrativos
################################################################################
echo -e "\n${YELLOW}[3] Testando diretórios administrativos...${NC}"
for dir in "admin" "admin/" "admin." "admin/." "admin%2e/" "administrator" "panel" "dashboard"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$dir" -m 5)
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "301" ] || [ "$STATUS" = "302" ] || [ "$STATUS" = "308" ]; then
        echo -e "${RED}[!] /$dir: HTTP $STATUS - ACESSÍVEL${NC}"
    else
        echo -e "${GREEN}[✓] /$dir: HTTP $STATUS${NC}"
    fi
done > "$REPORT_DIR/03_admin_dirs.txt"
cat "$REPORT_DIR/03_admin_dirs.txt"

################################################################################
# 4. Testar Endpoints de API
################################################################################
echo -e "\n${YELLOW}[4] Testando endpoints de API...${NC}"
for api in "api" "api/" "api/v1" "api/v2" "api/users" "api/admin" "_api" "rest"; do
    STATUS=$(curl -s -o "$REPORT_DIR/04_api_$api.txt" -w "%{http_code}" "$TARGET/$api" -m 5)
    echo "  - /$api: HTTP $STATUS"
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
        echo -e "${YELLOW}    [!] API respondeu - verificar conteúdo${NC}"
        head -10 "$REPORT_DIR/04_api_$api.txt"
    fi
done > "$REPORT_DIR/04_api_endpoints.txt"
cat "$REPORT_DIR/04_api_endpoints.txt"

################################################################################
# 5. Verificar Server Information
################################################################################
echo -e "\n${YELLOW}[5] Verificando informações do servidor...${NC}"
grep -iE "(server|x-powered-by|x-aspnet-version)" "$REPORT_DIR/01_headers.txt" > "$REPORT_DIR/05_server_info.txt"
if [ -s "$REPORT_DIR/05_server_info.txt" ]; then
    echo "Headers de servidor encontrados:"
    cat "$REPORT_DIR/05_server_info.txt"
else
    echo -e "${GREEN}[✓] Nenhum header de servidor exposto${NC}"
fi

################################################################################
# 6. Testar Métodos HTTP
################################################################################
echo -e "\n${YELLOW}[6] Testando métodos HTTP permitidos...${NC}"
curl -s -I -X OPTIONS "$TARGET" > "$REPORT_DIR/06_http_methods.txt"
if grep -qi "allow:" "$REPORT_DIR/06_http_methods.txt"; then
    echo "Métodos permitidos:"
    grep -i "allow:" "$REPORT_DIR/06_http_methods.txt"
    
    if grep -qi "allow:.*\(PUT\|DELETE\|TRACE\)" "$REPORT_DIR/06_http_methods.txt"; then
        echo -e "${YELLOW}[!] ATENÇÃO: Métodos HTTP sensíveis permitidos (PUT/DELETE/TRACE)${NC}"
    fi
else
    echo -e "${GREEN}[✓] Header Allow não retornado${NC}"
fi

################################################################################
# 7. Verificar CORS
################################################################################
echo -e "\n${YELLOW}[7] Testando política CORS...${NC}"
curl -s -I "$TARGET" -H "Origin: https://malicious.com" > "$REPORT_DIR/07_cors_test.txt"
if grep -q "Access-Control-Allow-Origin" "$REPORT_DIR/07_cors_test.txt"; then
    echo "CORS headers encontrados:"
    grep -i "access-control" "$REPORT_DIR/07_cors_test.txt"
    
    if grep -q "Access-Control-Allow-Origin: \*" "$REPORT_DIR/07_cors_test.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: CORS permite qualquer origem (*)${NC}"
    elif grep -q "Access-Control-Allow-Origin: https://malicious.com" "$REPORT_DIR/07_cors_test.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: CORS reflete origem maliciosa${NC}"
    else
        echo -e "${GREEN}[✓] CORS configurado de forma restrita${NC}"
    fi
else
    echo -e "${GREEN}[✓] CORS não configurado ou não responde a origem externa${NC}"
fi

################################################################################
# 8. Verificar Cookies
################################################################################
echo -e "\n${YELLOW}[8] Verificando cookies...${NC}"
curl -s -I "$TARGET" | grep -i "set-cookie" > "$REPORT_DIR/08_cookies.txt"
if [ -s "$REPORT_DIR/08_cookies.txt" ]; then
    echo "Cookies encontrados:"
    cat "$REPORT_DIR/08_cookies.txt"
    
    if ! grep -qi "httponly" "$REPORT_DIR/08_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag HttpOnly${NC}"
    else
        echo -e "${GREEN}[✓] HttpOnly presente${NC}"
    fi
    
    if ! grep -qi "secure" "$REPORT_DIR/08_cookies.txt"; then
        echo -e "${YELLOW}[!] Cookie sem flag Secure${NC}"
    else
        echo -e "${GREEN}[✓] Secure presente${NC}"
    fi
    
    if ! grep -qi "samesite" "$REPORT_DIR/08_cookies.txt"; then
        echo -e "${YELLOW}[!] Cookie sem flag SameSite${NC}"
    else
        echo -e "${GREEN}[✓] SameSite presente${NC}"
    fi
else
    echo -e "${GREEN}[✓] Nenhum cookie retornado nesta requisição${NC}"
fi

################################################################################
# 9. Testar Arquivos Sensíveis
################################################################################
echo -e "\n${YELLOW}[9] Testando arquivos sensíveis...${NC}"
for file in ".env" ".git/config" "config.php" "phpinfo.php" "web.config" \
            "composer.json" "package.json" ".htaccess" "server.js"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/$file" -m 5)
    if [ "$STATUS" = "200" ]; then
        echo -e "${RED}[!] /$file: HTTP $STATUS - ACESSÍVEL${NC}"
    else
        echo -e "${GREEN}[✓] /$file: HTTP $STATUS${NC}"
    fi
done > "$REPORT_DIR/09_sensitive_files.txt"
cat "$REPORT_DIR/09_sensitive_files.txt"

################################################################################
# 10. Verificar Redirecionamento HTTPS
################################################################################
echo -e "\n${YELLOW}[10] Verificando redirecionamento HTTPS...${NC}"
HTTP_TARGET="http://0fc5d3bbe18c.ngrok-free.app"
curl -s -I "$HTTP_TARGET" -m 5 > "$REPORT_DIR/10_http_redirect.txt" 2>&1
if grep -qi "301\|302\|307\|308" "$REPORT_DIR/10_http_redirect.txt" && grep -qi "https" "$REPORT_DIR/10_http_redirect.txt"; then
    echo -e "${GREEN}[✓] HTTP redireciona para HTTPS${NC}"
else
    echo -e "${YELLOW}[!] HTTP não redireciona automaticamente para HTTPS${NC}"
fi

################################################################################
# 11. Análise do HTML
################################################################################
echo -e "\n${YELLOW}[11] Análise básica do HTML...${NC}"
curl -s "$TARGET" > "$REPORT_DIR/11_html_content.html"

# Procurar comentários sensíveis
grep -oE "<!--.*-->" "$REPORT_DIR/11_html_content.html" | head -5 > "$REPORT_DIR/11_comments.txt"
if [ -s "$REPORT_DIR/11_comments.txt" ]; then
    echo "Comentários HTML encontrados:"
    cat "$REPORT_DIR/11_comments.txt"
fi

# Procurar informações sensíveis
if grep -qiE "(password|secret|key|token|api)" "$REPORT_DIR/11_html_content.html"; then
    echo -e "${YELLOW}[!] ATENÇÃO: Palavras sensíveis encontradas no HTML${NC}"
    grep -iE "(password|secret|key|token|api)" "$REPORT_DIR/11_html_content.html" | head -3
fi

################################################################################
# 12. Verificar ngrok-skip-browser-warning
################################################################################
echo -e "\n${YELLOW}[12] Testando bypass do warning do ngrok...${NC}"
curl -s -I "$TARGET" -H "ngrok-skip-browser-warning: true" > "$REPORT_DIR/12_ngrok_bypass.txt"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET" -H "ngrok-skip-browser-warning: true")
echo "Status com bypass header: HTTP $STATUS"
if [ "$STATUS" = "200" ]; then
    echo -e "${GREEN}[✓] Bypass do warning funciona (comportamento esperado do ngrok)${NC}"
fi

################################################################################
# Resumo Final
################################################################################
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}RESUMO DO RETESTE${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Alvo: $TARGET"
echo "Data: $(date)"
echo "Relatórios salvos em: $REPORT_DIR"
echo -e "\nVulnerabilidades Encontradas:"
echo "  - Verificar headers de segurança ausentes"
echo "  - Verificar diretórios administrativos"
echo "  - Verificar APIs expostas"
echo "  - Verificar cookies sem proteção"
echo -e "\nObservações:"
echo "  - Esta é uma URL temporária do ngrok"
echo "  - Aplicação pode estar em desenvolvimento/teste"
echo "  - Ngrok fornece HTTPS por padrão mas não headers de segurança"
echo -e "\n${YELLOW}========================================${NC}"
