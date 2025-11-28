#!/bin/bash

################################################################################
# Resource Check - Verificação de Recursos do Sistema
# Data: 2025-11-28
# Autor: Samuel Ziger
#
# Verifica CPU, RAM, Disco antes de executar operações pesadas
################################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

################################################################################
# Verificar CPU
################################################################################
check_cpu() {
    echo -e "${BLUE}[RESOURCE] Verificando CPU...${NC}"
    
    local cpu_cores=$(nproc)
    local cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    
    echo -e "${BLUE}  Modelo: $cpu_model${NC}"
    echo -e "${BLUE}  Cores: $cpu_cores${NC}"
    echo -e "${BLUE}  Uso atual: ${cpu_usage}%${NC}"
    
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        echo -e "${RED}  ❌ CPU sobrecarregada (>80%)${NC}"
        return 1
    elif (( $(echo "$cpu_usage > 50" | bc -l) )); then
        echo -e "${YELLOW}  ⚠️ CPU com carga média (>50%)${NC}"
        return 0
    else
        echo -e "${GREEN}  ✅ CPU disponível${NC}"
        return 0
    fi
}

################################################################################
# Verificar RAM
################################################################################
check_ram() {
    echo -e "${BLUE}[RESOURCE] Verificando RAM...${NC}"
    
    local total_ram=$(free -h | awk 'NR==2 {print $2}')
    local used_ram=$(free -h | awk 'NR==2 {print $3}')
    local available_ram=$(free -h | awk 'NR==2 {print $7}')
    local ram_percent=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
    
    echo -e "${BLUE}  Total: $total_ram${NC}"
    echo -e "${BLUE}  Usado: $used_ram ($ram_percent%)${NC}"
    echo -e "${BLUE}  Disponível: $available_ram${NC}"
    
    if [ $ram_percent -gt 90 ]; then
        echo -e "${RED}  ❌ RAM crítica (>90%)${NC}"
        return 1
    elif [ $ram_percent -gt 70 ]; then
        echo -e "${YELLOW}  ⚠️ RAM alta (>70%)${NC}"
        return 0
    else
        echo -e "${GREEN}  ✅ RAM disponível${NC}"
        return 0
    fi
}

################################################################################
# Verificar Disco
################################################################################
check_disk() {
    echo -e "${BLUE}[RESOURCE] Verificando espaço em disco...${NC}"
    
    local disk_total=$(df -h / | awk 'NR==2 {print $2}')
    local disk_used=$(df -h / | awk 'NR==2 {print $3}')
    local disk_available=$(df -h / | awk 'NR==2 {print $4}')
    local disk_percent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    
    echo -e "${BLUE}  Total: $disk_total${NC}"
    echo -e "${BLUE}  Usado: $disk_used ($disk_percent%)${NC}"
    echo -e "${BLUE}  Disponível: $disk_available${NC}"
    
    if [ $disk_percent -gt 90 ]; then
        echo -e "${RED}  ❌ Disco crítico (>90%)${NC}"
        return 1
    elif [ $disk_percent -gt 80 ]; then
        echo -e "${YELLOW}  ⚠️ Disco alto (>80%)${NC}"
        return 0
    else
        echo -e "${GREEN}  ✅ Espaço disponível${NC}"
        return 0
    fi
}

################################################################################
# Verificar Swap
################################################################################
check_swap() {
    echo -e "${BLUE}[RESOURCE] Verificando SWAP...${NC}"
    
    local swap_total=$(free -h | awk 'NR==3 {print $2}')
    local swap_used=$(free -h | awk 'NR==3 {print $3}')
    
    if [ "$swap_total" = "0B" ] || [ -z "$swap_total" ]; then
        echo -e "${YELLOW}  ⚠️ SWAP não configurado${NC}"
        return 0
    fi
    
    local swap_percent=$(free | awk 'NR==3 {if($2>0) printf "%.0f", $3/$2*100; else print 0}')
    
    echo -e "${BLUE}  Total: $swap_total${NC}"
    echo -e "${BLUE}  Usado: $swap_used ($swap_percent%)${NC}"
    
    if [ $swap_percent -gt 50 ]; then
        echo -e "${YELLOW}  ⚠️ Sistema usando SWAP (pode estar lento)${NC}"
        return 0
    else
        echo -e "${GREEN}  ✅ SWAP OK${NC}"
        return 0
    fi
}

################################################################################
# Detectar hardware específico
################################################################################
detect_hardware() {
    echo -e "${BLUE}[RESOURCE] Detectando hardware...${NC}"
    
    local cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    local ram_total=$(free -h | awk 'NR==2 {print $2}')
    
    # Detectar PC1, PC2, NB1, NB2 baseado nas specs
    if echo "$cpu_model" | grep -iq "i5-12400F"; then
        echo -e "${GREEN}  🖥️ PC1 detectado (i5-12400F)${NC}"
        echo -e "${BLUE}  Recomendação: Proxmox + VMs${NC}"
    elif echo "$cpu_model" | grep -iq "i5-3330"; then
        echo -e "${GREEN}  🖥️ PC2 detectado (i5-3330)${NC}"
        echo -e "${YELLOW}  ⚠️ RAM: $ram_total (recomendado 16GB para scans pesados)${NC}"
    elif echo "$cpu_model" | grep -iq "Celeron N4020"; then
        echo -e "${GREEN}  💻 Notebook 1 detectado (Celeron N4020)${NC}"
        echo -e "${BLUE}  Função ideal: Stealth box / Pivot / Phishing${NC}"
        echo -e "${YELLOW}  ⚠️ Evitar: Scans pesados, Burp Suite, VMs${NC}"
    elif echo "$cpu_model" | grep -iq "i5-3210M"; then
        echo -e "${GREEN}  💻 Notebook 2 detectado (i5-3210M)${NC}"
        echo -e "${BLUE}  Função ideal: Windows Attack Box / AD / Bloodhound${NC}"
    else
        echo -e "${BLUE}  🖥️ Hardware: $cpu_model${NC}"
    fi
}

################################################################################
# Sugestões de otimização
################################################################################
suggest_optimizations() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              SUGESTÕES DE OTIMIZAÇÃO                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local ram_percent=$(free | awk 'NR==2 {printf "%.0f", $3/$2*100}')
    local disk_percent=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
    
    # Sugestões baseadas em RAM
    if [ $ram_percent -gt 70 ]; then
        echo -e "${YELLOW}💡 RAM alta:${NC}"
        echo "  - Fechar aplicações desnecessárias"
        echo "  - Limpar cache: sync; echo 3 > /proc/sys/vm/drop_caches"
        echo "  - Considerar upgrade de RAM"
        echo ""
    fi
    
    # Sugestões baseadas em disco
    if [ $disk_percent -gt 80 ]; then
        echo -e "${YELLOW}💡 Disco cheio:${NC}"
        echo "  - Limpar pacotes antigos: sudo apt autoremove --purge"
        echo "  - Limpar logs: sudo journalctl --vacuum-time=7d"
        echo "  - Verificar arquivos grandes: du -ah / | sort -rh | head -n 20"
        echo ""
    fi
    
    # Sugestões gerais
    echo -e "${BLUE}💡 Otimizações gerais:${NC}"
    echo "  - Desativar serviços desnecessários"
    echo "  - Configurar swap se não houver"
    echo "  - Usar SSD para ferramentas críticas"
    echo ""
}

################################################################################
# Check completo do sistema
################################################################################
full_system_check() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           VERIFICAÇÃO COMPLETA DO SISTEMA                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    detect_hardware
    echo ""
    
    local checks_passed=0
    local checks_total=4
    
    check_cpu && ((checks_passed++))
    echo ""
    
    check_ram && ((checks_passed++))
    echo ""
    
    check_disk && ((checks_passed++))
    echo ""
    
    check_swap && ((checks_passed++))
    echo ""
    
    # Resultado
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  RESULTADO: $checks_passed/$checks_total recursos OK${NC}"
    
    if [ $checks_passed -eq $checks_total ]; then
        echo -e "${GREEN}║  ✅ SISTEMA PRONTO PARA OPERAÇÕES${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    elif [ $checks_passed -ge 3 ]; then
        echo -e "${YELLOW}║  ⚠️ SISTEMA FUNCIONAL MAS COM ALERTAS${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        suggest_optimizations
    else
        echo -e "${RED}║  ❌ SISTEMA COM RECURSOS CRÍTICOS${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
        suggest_optimizations
    fi
    
    return 0
}

################################################################################
# Verificar se sistema aguenta operação específica
################################################################################
can_run_operation() {
    local operation="$1"
    
    case $operation in
        "masscan"|"nmap-aggressive"|"burp"|"metasploit")
            # Operações pesadas
            local ram_gb=$(free -g | awk 'NR==2 {print $7}')
            if [ $ram_gb -lt 2 ]; then
                echo -e "${RED}[RESOURCE] ❌ RAM insuficiente para $operation${NC}"
                echo -e "${YELLOW}[RESOURCE] Necessário: 2GB+ disponível${NC}"
                echo -e "${YELLOW}[RESOURCE] Disponível: ${ram_gb}GB${NC}"
                return 1
            fi
            ;;
        "vm"|"docker")
            # Virtualização
            local ram_gb=$(free -g | awk 'NR==2 {print $7}')
            if [ $ram_gb -lt 4 ]; then
                echo -e "${YELLOW}[RESOURCE] ⚠️ RAM baixa para VMs/Containers${NC}"
                echo -e "${YELLOW}[RESOURCE] Recomendado: 4GB+ disponível${NC}"
            fi
            ;;
        "light"|"stealth"|"pivot")
            # Operações leves
            echo -e "${GREEN}[RESOURCE] ✅ Recursos suficientes para $operation${NC}"
            return 0
            ;;
    esac
    
    echo -e "${GREEN}[RESOURCE] ✅ Sistema pode executar $operation${NC}"
    return 0
}

################################################################################
# Main
################################################################################
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    full_system_check
fi
