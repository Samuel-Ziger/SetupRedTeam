#!/bin/bash

################################################################################
# Script de Reteste - adivisao.com.br
# Data: 2025-11-28
# Autor: Samuel Ziger
# 
# Vulnerabilidades a validar:
# 1. Exposição de Tokens/Chaves no Front-end (ALTO)
# 2. Enumeração de Usuários via Endpoint de Busca (ALTO)
# 3. CORS Inconsistente/Permissivo (ALTO → Médio)
# 4. Cookie de Sessão sem HttpOnly (ALTO → Médio)
# 5. Endpoints Internos do Elasticsearch Expostos (Médio)
# 6. CSP Apenas em Report-Only e XSS Protections Desabilitadas (Médio)
# 7. Rate Limiting Parcial (Médio)
# 8. Exposição de Infra e Headers Sensíveis (Baixo → Médio)
################################################################################

TARGET="https://adivisao.com.br"
REPORT_DIR="./reteste_adivisao_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT_DIR"

echo "[+] Iniciando reteste de segurança para adivisao.com.br"
echo "[+] Relatório será salvo em: $REPORT_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# 1. Verificar Exposição de Tokens/Chaves no Front-end
################################################################################
echo -e "\n${YELLOW}[1] Testando exposição de tokens no front-end...${NC}"
curl -s "$TARGET" | grep -iE "(bearer|apikey|jwt|token|authorization)" > "$REPORT_DIR/01_tokens_expostos.txt"
if [ -s "$REPORT_DIR/01_tokens_expostos.txt" ]; then
    echo -e "${RED}[!] VULNERÁVEL: Tokens/chaves encontrados no front-end${NC}"
    cat "$REPORT_DIR/01_tokens_expostos.txt"
else
    echo -e "${GREEN}[✓] Nenhum token exposto encontrado${NC}"
fi

################################################################################
# 2. Testar Enumeração de Usuários via Elasticsearch
################################################################################
echo -e "\n${YELLOW}[2] Testando enumeração de usuários via Elasticsearch...${NC}"
curl -s -X POST "$TARGET/elasticsearch/msearch" \
    -H "Content-Type: application/json" \
    -d '{"query":{"match_all":{}}}' > "$REPORT_DIR/02_elasticsearch_enum.txt" 2>&1
if grep -q "email" "$REPORT_DIR/02_elasticsearch_enum.txt" || grep -q "user_signed_up" "$REPORT_DIR/02_elasticsearch_enum.txt"; then
    echo -e "${RED}[!] VULNERÁVEL: Endpoint Elasticsearch expõe dados de usuários${NC}"
    head -20 "$REPORT_DIR/02_elasticsearch_enum.txt"
else
    echo -e "${GREEN}[✓] Elasticsearch protegido ou não expõe dados sensíveis${NC}"
fi

################################################################################
# 3. Verificar CORS
################################################################################
echo -e "\n${YELLOW}[3] Testando política CORS...${NC}"
curl -s -I "$TARGET" -H "Origin: https://malicious.com" > "$REPORT_DIR/03_cors_test.txt"
if grep -q "Access-Control-Allow-Origin: \*" "$REPORT_DIR/03_cors_test.txt"; then
    echo -e "${RED}[!] VULNERÁVEL: CORS permite qualquer origem (*)${NC}"
elif grep -q "Access-Control-Allow-Origin: https://malicious.com" "$REPORT_DIR/03_cors_test.txt"; then
    echo -e "${RED}[!] VULNERÁVEL: CORS reflete origem maliciosa${NC}"
else
    echo -e "${GREEN}[✓] CORS configurado corretamente${NC}"
fi
cat "$REPORT_DIR/03_cors_test.txt" | grep -i "access-control"

################################################################################
# 4. Verificar Cookies sem HttpOnly/Secure
################################################################################
echo -e "\n${YELLOW}[4] Verificando flags de segurança nos cookies...${NC}"
curl -s -I "$TARGET" | grep -i "set-cookie" > "$REPORT_DIR/04_cookies.txt"
if [ -s "$REPORT_DIR/04_cookies.txt" ]; then
    if ! grep -qi "httponly" "$REPORT_DIR/04_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag HttpOnly${NC}"
    fi
    if ! grep -qi "secure" "$REPORT_DIR/04_cookies.txt"; then
        echo -e "${RED}[!] VULNERÁVEL: Cookie sem flag Secure${NC}"
    fi
    if ! grep -qi "samesite" "$REPORT_DIR/04_cookies.txt"; then
        echo -e "${YELLOW}[!] ATENÇÃO: Cookie sem flag SameSite${NC}"
    fi
    cat "$REPORT_DIR/04_cookies.txt"
else
    echo -e "${GREEN}[✓] Nenhum cookie definido nesta resposta${NC}"
fi

################################################################################
# 5. Verificar Endpoints Elasticsearch Expostos
################################################################################
echo -e "\n${YELLOW}[5] Testando endpoints internos do Elasticsearch...${NC}"
for endpoint in "bulk_watch" "msearch" "_search" "_all"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/elasticsearch/$endpoint")
    echo "  - /elasticsearch/$endpoint: HTTP $STATUS"
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
        echo -e "${RED}    [!] VULNERÁVEL: Endpoint acessível publicamente${NC}"
    fi
done > "$REPORT_DIR/05_elasticsearch_endpoints.txt"
cat "$REPORT_DIR/05_elasticsearch_endpoints.txt"

################################################################################
# 6. Verificar CSP e Headers de Segurança
################################################################################
echo -e "\n${YELLOW}[6] Verificando Content Security Policy e headers de segurança...${NC}"
curl -s -I "$TARGET" > "$REPORT_DIR/06_security_headers.txt"

# Verificar CSP
if grep -qi "content-security-policy-report-only" "$REPORT_DIR/06_security_headers.txt"; then
    echo -e "${RED}[!] VULNERÁVEL: CSP está apenas em modo report-only${NC}"
elif grep -qi "content-security-policy:" "$REPORT_DIR/06_security_headers.txt"; then
    echo -e "${GREEN}[✓] CSP ativo em modo enforce${NC}"
else
    echo -e "${RED}[!] VULNERÁVEL: CSP não configurado${NC}"
fi

# Verificar X-XSS-Protection
if grep -qi "x-xss-protection: 0" "$REPORT_DIR/06_security_headers.txt"; then
    echo -e "${YELLOW}[!] ATENÇÃO: X-XSS-Protection desabilitado${NC}"
fi

# Verificar outros headers importantes
for header in "strict-transport-security" "x-frame-options" "x-content-type-options"; do
    if grep -qi "$header" "$REPORT_DIR/06_security_headers.txt"; then
        echo -e "${GREEN}[✓] Header $header presente${NC}"
    else
        echo -e "${YELLOW}[!] Header $header ausente${NC}"
    fi
done

################################################################################
# 7. Testar Rate Limiting
################################################################################
echo -e "\n${YELLOW}[7] Testando rate limiting...${NC}"
echo "Enviando 20 requisições rápidas para /api/auth/refresh..."
for i in {1..20}; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/api/auth/refresh" -X POST)
    echo -n "$STATUS "
    if [ "$STATUS" = "429" ]; then
        echo -e "\n${GREEN}[✓] Rate limiting ativo (HTTP 429 recebido)${NC}"
        break
    fi
    sleep 0.1
done > "$REPORT_DIR/07_rate_limiting.txt"
if ! grep -q "429" "$REPORT_DIR/07_rate_limiting.txt"; then
    echo -e "\n${RED}[!] VULNERÁVEL: Sem rate limiting detectado após 20 requisições${NC}"
fi

################################################################################
# 8. Verificar Headers que Expõem Infraestrutura
################################################################################
echo -e "\n${YELLOW}[8] Verificando headers que expõem informações de infraestrutura...${NC}"
curl -s -I "$TARGET" | grep -iE "(x-powered-by|server|x-bubble|sb-project-ref)" > "$REPORT_DIR/08_infra_headers.txt"
if [ -s "$REPORT_DIR/08_infra_headers.txt" ]; then
    echo -e "${YELLOW}[!] ATENÇÃO: Headers revelam informações de infraestrutura:${NC}"
    cat "$REPORT_DIR/08_infra_headers.txt"
else
    echo -e "${GREEN}[✓] Headers sensíveis não encontrados${NC}"
fi

################################################################################
# 9. Teste de Endpoints de Upload
################################################################################
echo -e "\n${YELLOW}[9] Verificando endpoint /fileupload...${NC}"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET/fileupload")
echo "  - /fileupload: HTTP $STATUS" | tee "$REPORT_DIR/09_fileupload.txt"
if [ "$STATUS" = "200" ] || [ "$STATUS" = "201" ]; then
    echo -e "${RED}[!] CRÍTICO: Endpoint de upload acessível${NC}"
fi

################################################################################
# 10. Scan de Portas Administrativas
################################################################################
echo -e "\n${YELLOW}[10] Verificando portas administrativas expostas...${NC}"
echo "Testando portas: 2052, 2053, 2082, 2083, 2086, 2087, 2095, 2096, 8080, 8443, 8880"
for port in 2052 2053 2082 2083 2086 2087 2095 2096 8080 8443 8880; do
    timeout 3 bash -c "echo > /dev/tcp/adivisao.com.br/$port" 2>/dev/null && \
        echo -e "${RED}[!] Porta $port ABERTA${NC}" || \
        echo -e "${GREEN}[✓] Porta $port fechada/filtrada${NC}"
done > "$REPORT_DIR/10_admin_ports.txt"
cat "$REPORT_DIR/10_admin_ports.txt"

################################################################################
# Resumo Final
################################################################################
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}RESUMO DO RETESTE${NC}"
echo -e "${YELLOW}========================================${NC}"
echo "Alvo: $TARGET"
echo "Data: $(date)"
echo "Relatórios salvos em: $REPORT_DIR"
echo -e "\nVerifique os arquivos gerados para detalhes completos."
echo -e "${YELLOW}========================================${NC}"
