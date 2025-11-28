#!/bin/bash

################################################################################
# Backup Tools - Scripts de Backup Automatizado
# Data: 2025-11-28
# Autor: Samuel Ziger
#
# Scripts para backup de ferramentas, VMs e dados críticos
################################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações (EDITE CONFORME SEU AMBIENTE)
BACKUP_ROOT="/mnt/backup"  # Onde guardar backups
TOOLS_DIR="$HOME/Documents/Scripts/Kali/Ferramentas"
RETENTION_DAYS=30  # Manter backups por 30 dias

################################################################################
# Criar diretório de backup
################################################################################
create_backup_dir() {
    local backup_name="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_ROOT/$backup_name/$timestamp"
    
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

################################################################################
# Backup das 29 Ferramentas Kali
################################################################################
backup_kali_tools() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         BACKUP DAS FERRAMENTAS KALI (29 TOOLKITS)        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "$TOOLS_DIR" ]; then
        echo -e "${RED}[BACKUP] ❌ Diretório de ferramentas não encontrado: $TOOLS_DIR${NC}"
        return 1
    fi
    
    local backup_dir=$(create_backup_dir "kali_tools")
    echo -e "${BLUE}[BACKUP] Destino: $backup_dir${NC}"
    echo ""
    
    # Calcular tamanho total
    local total_size=$(du -sh "$TOOLS_DIR" | awk '{print $1}')
    echo -e "${BLUE}[BACKUP] Tamanho total: $total_size${NC}"
    echo ""
    
    # Executar rsync com progresso
    echo -e "${GREEN}[BACKUP] Iniciando rsync...${NC}"
    rsync -av --progress \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        --exclude='.git' \
        "$TOOLS_DIR/" "$backup_dir/"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}[BACKUP] ✅ Backup concluído com sucesso!${NC}"
        echo -e "${GREEN}[BACKUP] Local: $backup_dir${NC}"
        
        # Criar arquivo de verificação
        echo "Backup criado em: $(date)" > "$backup_dir/backup_info.txt"
        echo "Origem: $TOOLS_DIR" >> "$backup_dir/backup_info.txt"
        echo "Tamanho: $total_size" >> "$backup_dir/backup_info.txt"
        
        return 0
    else
        echo -e "${RED}[BACKUP] ❌ Erro durante backup${NC}"
        return 1
    fi
}

################################################################################
# Backup de VMs do Proxmox
################################################################################
backup_proxmox_vms() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              BACKUP DE VMs PROXMOX                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Verificar se está no servidor Proxmox
    if ! command -v pvesh &> /dev/null; then
        echo -e "${YELLOW}[BACKUP] ⚠️ Este script deve ser executado no servidor Proxmox${NC}"
        echo -e "${YELLOW}[BACKUP] Gerando script para executar remotamente...${NC}"
        
        cat > backup_proxmox_remote.sh << 'EOF'
#!/bin/bash
# Execute este script NO SERVIDOR PROXMOX

BACKUP_DIR="/var/lib/vz/dump"
REMOTE_BACKUP="/mnt/backup/proxmox_vms"

# Listar VMs
echo "VMs disponíveis:"
qm list

# Fazer backup de todas as VMs
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
    echo "Fazendo backup da VM $vmid..."
    vzdump $vmid --compress gzip --mode snapshot --storage local
done

# Copiar para backup remoto
echo "Copiando para backup remoto..."
rsync -av --progress $BACKUP_DIR/ $REMOTE_BACKUP/

echo "Backup concluído!"
EOF
        
        chmod +x backup_proxmox_remote.sh
        echo -e "${GREEN}[BACKUP] ✅ Script criado: backup_proxmox_remote.sh${NC}"
        echo -e "${YELLOW}[BACKUP] Copie e execute no servidor Proxmox${NC}"
        return 0
    fi
    
    # Se estiver no Proxmox, executar backup
    local backup_dir=$(create_backup_dir "proxmox_vms")
    
    echo -e "${BLUE}[BACKUP] Listando VMs...${NC}"
    qm list
    echo ""
    
    read -p "Deseja fazer backup de todas as VMs? (s/n): " confirm
    if [ "$confirm" = "s" ]; then
        for vmid in $(qm list | awk 'NR>1 {print $1}'); do
            echo -e "${GREEN}[BACKUP] Fazendo backup da VM $vmid...${NC}"
            vzdump $vmid --compress gzip --mode snapshot --dumpdir "$backup_dir"
        done
        
        echo -e "${GREEN}[BACKUP] ✅ Backup de VMs concluído!${NC}"
    fi
}

################################################################################
# Backup de Wordlists (SecLists)
################################################################################
backup_wordlists() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           BACKUP DE WORDLISTS (SecLists)                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local seclists_dir="$HOME/Documents/Scripts/Kali/Ferramentas/SecLists"
    
    if [ ! -d "$seclists_dir" ]; then
        echo -e "${YELLOW}[BACKUP] ⚠️ SecLists não encontrado em: $seclists_dir${NC}"
        return 1
    fi
    
    local backup_dir=$(create_backup_dir "wordlists")
    
    echo -e "${BLUE}[BACKUP] Calculando tamanho...${NC}"
    du -sh "$seclists_dir"
    echo ""
    
    echo -e "${GREEN}[BACKUP] Iniciando backup (pode demorar ~10 minutos)...${NC}"
    rsync -av --progress "$seclists_dir/" "$backup_dir/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[BACKUP] ✅ Wordlists backup concluído!${NC}"
    fi
}

################################################################################
# Backup de Scripts Customizados
################################################################################
backup_custom_scripts() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           BACKUP DE SCRIPTS CUSTOMIZADOS                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local scripts_dir="$HOME/Documents/Scripts"
    local backup_dir=$(create_backup_dir "custom_scripts")
    
    echo -e "${GREEN}[BACKUP] Fazendo backup de $scripts_dir${NC}"
    
    rsync -av --progress \
        --exclude='Kali/Ferramentas' \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        "$scripts_dir/" "$backup_dir/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[BACKUP] ✅ Scripts customizados backup concluído!${NC}"
        
        # Fazer commit automático no Git
        cd "$scripts_dir"
        if [ -d ".git" ]; then
            echo ""
            echo -e "${BLUE}[BACKUP] Fazendo commit no Git...${NC}"
            git add .
            git commit -m "Auto-backup $(date +%Y-%m-%d_%H:%M:%S)"
            echo -e "${YELLOW}[BACKUP] Para enviar ao GitHub: git push${NC}"
        fi
    fi
}

################################################################################
# Limpar backups antigos
################################################################################
cleanup_old_backups() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         LIMPEZA DE BACKUPS ANTIGOS (>$RETENTION_DAYS dias)        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_ROOT" ]; then
        echo -e "${YELLOW}[BACKUP] Nenhum backup encontrado${NC}"
        return 0
    fi
    
    echo -e "${BLUE}[BACKUP] Procurando backups com mais de $RETENTION_DAYS dias...${NC}"
    
    find "$BACKUP_ROOT" -type d -mtime +$RETENTION_DAYS -print | while read old_backup; do
        local size=$(du -sh "$old_backup" | awk '{print $1}')
        echo -e "${YELLOW}[BACKUP] Deletando: $old_backup ($size)${NC}"
        rm -rf "$old_backup"
    done
    
    echo -e "${GREEN}[BACKUP] ✅ Limpeza concluída${NC}"
}

################################################################################
# Verificar integridade dos backups
################################################################################
verify_backups() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           VERIFICAÇÃO DE INTEGRIDADE                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -d "$BACKUP_ROOT" ]; then
        echo -e "${RED}[BACKUP] ❌ Nenhum backup encontrado${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[BACKUP] Listando backups disponíveis:${NC}"
    echo ""
    
    find "$BACKUP_ROOT" -name "backup_info.txt" | while read info_file; do
        echo -e "${GREEN}▶ $(dirname $info_file)${NC}"
        cat "$info_file" | sed 's/^/  /'
        echo ""
    done
    
    # Estatísticas
    local total_backups=$(find "$BACKUP_ROOT" -type d -maxdepth 2 | wc -l)
    local total_size=$(du -sh "$BACKUP_ROOT" 2>/dev/null | awk '{print $1}')
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Total de backups: $total_backups${NC}"
    echo -e "${BLUE}║  Espaço utilizado: $total_size${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

################################################################################
# Menu principal
################################################################################
show_menu() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              SISTEMA DE BACKUP AUTOMATIZADO              ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "1) Backup de Ferramentas Kali (29 toolkits)"
    echo "2) Backup de VMs Proxmox"
    echo "3) Backup de Wordlists (SecLists)"
    echo "4) Backup de Scripts Customizados"
    echo "5) Backup COMPLETO (1+2+3+4)"
    echo "6) Verificar integridade dos backups"
    echo "7) Limpar backups antigos (>$RETENTION_DAYS dias)"
    echo "8) Sair"
    echo ""
}

################################################################################
# Main
################################################################################
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Verificar diretório de backup
    if [ ! -d "$BACKUP_ROOT" ]; then
        echo -e "${YELLOW}[BACKUP] Diretório de backup não existe: $BACKUP_ROOT${NC}"
        echo -e "${YELLOW}[BACKUP] Criando diretório...${NC}"
        mkdir -p "$BACKUP_ROOT"
    fi
    
    while true; do
        show_menu
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                backup_kali_tools
                ;;
            2)
                backup_proxmox_vms
                ;;
            3)
                backup_wordlists
                ;;
            4)
                backup_custom_scripts
                ;;
            5)
                echo -e "${GREEN}[BACKUP] Iniciando backup completo...${NC}"
                echo ""
                backup_kali_tools
                echo ""
                backup_wordlists
                echo ""
                backup_custom_scripts
                echo ""
                echo -e "${GREEN}[BACKUP] ✅ Backup completo finalizado!${NC}"
                ;;
            6)
                verify_backups
                ;;
            7)
                cleanup_old_backups
                ;;
            8)
                echo -e "${BLUE}[BACKUP] Saindo...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[BACKUP] Opção inválida${NC}"
                ;;
        esac
        
        echo ""
        read -p "Pressione ENTER para continuar..."
    done
fi
