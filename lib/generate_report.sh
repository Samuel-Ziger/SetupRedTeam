#!/bin/bash

################################################################################
# Generate Report - Gerador de Relatórios Profissionais
# Data: 2025-11-28
# Autor: Samuel Ziger
#
# Converte output de retestes em relatório profissional (Markdown → PDF)
################################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
TEMPLATE_DIR="templates"
OUTPUT_DIR="relatorios"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

################################################################################
# Verificar dependências
################################################################################
check_dependencies() {
    echo -e "${BLUE}[REPORT] Verificando dependências...${NC}"
    
    local missing=()
    
    if ! command -v pandoc &> /dev/null; then
        missing+=("pandoc")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[REPORT] ❌ Dependências faltando: ${missing[*]}${NC}"
        echo ""
        echo -e "${YELLOW}[REPORT] Instale com:${NC}"
        echo "  sudo apt install pandoc texlive-latex-base texlive-fonts-recommended"
        echo ""
        echo -e "${YELLOW}[REPORT] Ou apenas:${NC}"
        echo "  sudo apt install pandoc"
        echo "  (PDF básico sem LaTeX)"
        return 1
    fi
    
    echo -e "${GREEN}[REPORT] ✅ Dependências OK${NC}"
    return 0
}

################################################################################
# Criar estrutura de diretórios
################################################################################
create_structure() {
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR/evidencias"
    echo -e "${GREEN}[REPORT] Diretórios criados${NC}"
}

################################################################################
# Gerar relatório a partir de template
################################################################################
generate_from_template() {
    local cliente="$1"
    local data="$2"
    local template="${TEMPLATE_DIR}/report_template.md"
    local output="${OUTPUT_DIR}/relatorio_${cliente}_${data}.md"
    
    if [ ! -f "$template" ]; then
        echo -e "${RED}[REPORT] ❌ Template não encontrado: $template${NC}"
        return 1
    fi
    
    # Copiar template
    cp "$template" "$output"
    
    # Substituir placeholders
    sed -i "s/\[NOME DO CLIENTE\]/$cliente/g" "$output"
    sed -i "s/\[DD\/MM\/YYYY\]/$(date +%d/%m/%Y)/g" "$output"
    sed -i "s/\[TIMESTAMP\]/$(date +%Y-%m-%d\ %H:%M:%S)/g" "$output"
    
    echo -e "${GREEN}[REPORT] ✅ Relatório Markdown gerado: $output${NC}"
    echo "$output"
}

################################################################################
# Converter Markdown para PDF
################################################################################
convert_to_pdf() {
    local markdown_file="$1"
    local pdf_file="${markdown_file%.md}.pdf"
    
    echo -e "${BLUE}[REPORT] Convertendo para PDF...${NC}"
    
    # Verificar pandoc
    if ! command -v pandoc &> /dev/null; then
        echo -e "${YELLOW}[REPORT] ⚠️ Pandoc não instalado, pulando PDF${NC}"
        return 1
    fi
    
    # Converter
    pandoc "$markdown_file" \
        -o "$pdf_file" \
        --from markdown \
        --to pdf \
        --pdf-engine=pdflatex \
        --toc \
        --toc-depth=3 \
        --number-sections \
        --metadata title="Relatório de Reteste" \
        --metadata author="Samuel Ziger" \
        --metadata date="$(date +%Y-%m-%d)" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[REPORT] ✅ PDF gerado: $pdf_file${NC}"
        return 0
    else
        # Tentar sem LaTeX (PDF básico)
        echo -e "${YELLOW}[REPORT] Tentando PDF sem LaTeX...${NC}"
        pandoc "$markdown_file" -o "$pdf_file" --pdf-engine=wkhtmltopdf 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[REPORT] ✅ PDF gerado (modo básico): $pdf_file${NC}"
            return 0
        fi
        
        echo -e "${YELLOW}[REPORT] ⚠️ Não foi possível gerar PDF${NC}"
        echo -e "${YELLOW}[REPORT] Use o arquivo Markdown: $markdown_file${NC}"
        return 1
    fi
}

################################################################################
# Converter HTML
################################################################################
convert_to_html() {
    local markdown_file="$1"
    local html_file="${markdown_file%.md}.html"
    
    echo -e "${BLUE}[REPORT] Convertendo para HTML...${NC}"
    
    pandoc "$markdown_file" \
        -o "$html_file" \
        --from markdown \
        --to html5 \
        --standalone \
        --toc \
        --toc-depth=3 \
        --css=style.css \
        --self-contained \
        --metadata title="Relatório de Reteste"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[REPORT] ✅ HTML gerado: $html_file${NC}"
        return 0
    else
        echo -e "${YELLOW}[REPORT] ⚠️ Erro ao gerar HTML${NC}"
        return 1
    fi
}

################################################################################
# Processar output de reteste
################################################################################
process_reteste_output() {
    local reteste_file="$1"
    local cliente="$2"
    
    if [ ! -f "$reteste_file" ]; then
        echo -e "${RED}[REPORT] ❌ Arquivo de reteste não encontrado: $reteste_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[REPORT] Processando output de reteste...${NC}"
    
    local data=$(date +%Y%m%d)
    local output="${OUTPUT_DIR}/relatorio_${cliente}_${data}.md"
    
    # Criar relatório base
    cat > "$output" << EOF
# Relatório de Reteste - $cliente

**Data:** $(date +%d/%m/%Y)  
**Gerado automaticamente de:** $reteste_file

---

## Resultados do Reteste

\`\`\`
EOF
    
    # Adicionar conteúdo do reteste
    cat "$reteste_file" >> "$output"
    
    cat >> "$output" << EOF
\`\`\`

---

## Análise

[Adicionar análise manual aqui]

---

**Gerado em:** $(date +%Y-%m-%d\ %H:%M:%S)
EOF
    
    echo -e "${GREEN}[REPORT] ✅ Relatório processado: $output${NC}"
    echo "$output"
}

################################################################################
# Menu interativo
################################################################################
show_menu() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         GERADOR DE RELATÓRIOS PROFISSIONAIS              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "1) Criar novo relatório do zero (template)"
    echo "2) Processar output de reteste existente"
    echo "3) Converter Markdown → PDF"
    echo "4) Converter Markdown → HTML"
    echo "5) Ver relatórios existentes"
    echo "6) Sair"
    echo ""
}

################################################################################
# Main
################################################################################
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    cd "$SCRIPT_DIR"
    
    # Verificar dependências
    check_dependencies
    
    # Criar estrutura
    create_structure
    
    while true; do
        show_menu
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                echo ""
                read -p "Nome do cliente: " cliente
                cliente=$(echo "$cliente" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
                data=$(date +%Y%m%d)
                
                markdown_file=$(generate_from_template "$cliente" "$data")
                
                if [ $? -eq 0 ]; then
                    echo ""
                    read -p "Deseja converter para PDF agora? (s/n): " convert
                    if [ "$convert" = "s" ]; then
                        convert_to_pdf "$markdown_file"
                    fi
                    
                    echo ""
                    echo -e "${BLUE}[REPORT] Edite o arquivo:${NC}"
                    echo "  $markdown_file"
                fi
                ;;
            2)
                echo ""
                read -p "Caminho do arquivo de reteste: " reteste_file
                read -p "Nome do cliente: " cliente
                cliente=$(echo "$cliente" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
                
                markdown_file=$(process_reteste_output "$reteste_file" "$cliente")
                
                if [ $? -eq 0 ]; then
                    echo ""
                    read -p "Deseja converter para PDF? (s/n): " convert
                    if [ "$convert" = "s" ]; then
                        convert_to_pdf "$markdown_file"
                    fi
                fi
                ;;
            3)
                echo ""
                read -p "Caminho do arquivo Markdown: " md_file
                convert_to_pdf "$md_file"
                ;;
            4)
                echo ""
                read -p "Caminho do arquivo Markdown: " md_file
                convert_to_html "$md_file"
                ;;
            5)
                echo ""
                echo -e "${BLUE}[REPORT] Relatórios existentes:${NC}"
                ls -lh "$OUTPUT_DIR"/*.{md,pdf,html} 2>/dev/null || echo "Nenhum relatório encontrado"
                ;;
            6)
                echo -e "${BLUE}[REPORT] Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[REPORT] Opção inválida${NC}"
                ;;
        esac
        
        echo ""
        read -p "Pressione ENTER para continuar..."
    done
fi
