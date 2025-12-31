#!/bin/bash

################################################################################
# Script Mestre - Executar Todos os Retestes
# Data: 2025-11-28
# Autor: Samuel Ziger
#
# Este script executa todos os scripts de reteste sequencialmente
# e gera um relatório consolidado
################################################################################

MASTER_REPORT="relatorio_reteste_completo_$(date +%Y%m%d_%H%M%S).txt"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        EXECUÇÃO DE RETESTES - TODOS OS ALVOS              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Data de início: $(date)"
echo "Diretório: $SCRIPT_DIR"
echo "Relatório consolidado: $MASTER_REPORT"
echo ""

# Iniciar relatório
{
    echo "======================================================================"
    echo "RELATÓRIO CONSOLIDADO DE RETESTES"
    echo "======================================================================"
    echo "Data: $(date)"
    echo "Executado por: $(whoami)"
    echo "======================================================================"
    echo ""
} > "$MASTER_REPORT"

# Array com os scripts
SCRIPTS=(
    "reteste_adivisao.sh:adivisao.com.br"
    "reteste_divisaodeelite.sh:divisaodeelite.com.br"
    "reteste_acheumveterano.sh:acheumveterano.com.br / app.acheumveterano.com.br"
    "reteste_idivis.sh:idivis.ao / 31.97.27.219"
    "reteste_planodechamadas.sh:planodechamadas.com.br / lp.planodechamadas.com.br"
    "reteste_ngrok.sh:0fc5d3bbe18c.ngrok-free.app (URL temporária)"
)

TOTAL_SCRIPTS=${#SCRIPTS[@]}
CURRENT=0
SUCCESS=0
FAILED=0

# Executar cada script
for script_info in "${SCRIPTS[@]}"; do
    CURRENT=$((CURRENT + 1))
    SCRIPT_NAME="${script_info%%:*}"
    TARGET_NAME="${script_info##*:}"
    
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}[$CURRENT/$TOTAL_SCRIPTS] Executando: $SCRIPT_NAME${NC}"
    echo -e "${BLUE}Alvo: $TARGET_NAME${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Verificar se o script existe
    if [ ! -f "$SCRIPT_DIR/$SCRIPT_NAME" ]; then
        echo -e "${RED}[ERRO] Script não encontrado: $SCRIPT_NAME${NC}"
        FAILED=$((FAILED + 1))
        
        {
            echo "----------------------------------------------------------------------"
            echo "[$CURRENT/$TOTAL_SCRIPTS] $TARGET_NAME"
            echo "----------------------------------------------------------------------"
            echo "STATUS: FALHA - Script não encontrado"
            echo ""
        } >> "$MASTER_REPORT"
        
        continue
    fi
    
    # Tornar executável
    chmod +x "$SCRIPT_DIR/$SCRIPT_NAME"
    
    # Executar script
    START_TIME=$(date +%s)
    
    if bash "$SCRIPT_DIR/$SCRIPT_NAME" 2>&1 | tee -a "$MASTER_REPORT.temp"; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        SUCCESS=$((SUCCESS + 1))
        
        echo ""
        echo -e "${GREEN}[✓] Reteste concluído com sucesso${NC}"
        echo -e "${GREEN}Tempo de execução: ${DURATION}s${NC}"
        
        {
            echo ""
            echo "STATUS: SUCESSO"
            echo "Tempo de execução: ${DURATION}s"
            echo ""
        } >> "$MASTER_REPORT"
        
    else
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        FAILED=$((FAILED + 1))
        
        echo ""
        echo -e "${RED}[✗] Reteste falhou ou encontrou erros${NC}"
        echo -e "${YELLOW}Tempo de execução: ${DURATION}s${NC}"
        
        {
            echo ""
            echo "STATUS: FALHA/ERRO"
            echo "Tempo de execução: ${DURATION}s"
            echo ""
        } >> "$MASTER_REPORT"
    fi
    
    # Adicionar separador ao relatório
    {
        echo "======================================================================"
        echo ""
    } >> "$MASTER_REPORT"
    
    # Aguardar entre scripts para não sobrecarregar
    if [ $CURRENT -lt $TOTAL_SCRIPTS ]; then
        echo ""
        echo -e "${YELLOW}Aguardando 5 segundos antes do próximo teste...${NC}"
        sleep 5
    fi
done

# Remover arquivo temporário se existir
[ -f "$MASTER_REPORT.temp" ] && rm "$MASTER_REPORT.temp"

# Resumo final
END_MASTER=$(date)

{
    echo ""
    echo "======================================================================"
    echo "RESUMO FINAL"
    echo "======================================================================"
    echo "Data de término: $END_MASTER"
    echo ""
    echo "Total de scripts: $TOTAL_SCRIPTS"
    echo "Sucessos: $SUCCESS"
    echo "Falhas: $FAILED"
    echo ""
    echo "======================================================================"
} >> "$MASTER_REPORT"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  RESUMO DA EXECUÇÃO                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Data de término: $END_MASTER"
echo ""
echo -e "Total de scripts executados: ${BLUE}$TOTAL_SCRIPTS${NC}"
echo -e "Sucessos: ${GREEN}$SUCCESS${NC}"
echo -e "Falhas: ${RED}$FAILED${NC}"
echo ""
echo -e "${YELLOW}Relatório consolidado salvo em:${NC}"
echo -e "${GREEN}$MASTER_REPORT${NC}"
echo ""

# Listar diretórios de relatórios criados
echo -e "${YELLOW}Diretórios de relatórios individuais criados:${NC}"
ls -d reteste_*_20* 2>/dev/null | tail -10

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Execução completa!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Retornar código de saída apropriado
if [ $FAILED -gt 0 ]; then
    exit 1
else
    exit 0
fi
