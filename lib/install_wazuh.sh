#!/bin/bash

################################################################################
# Install Wazuh - SIEM Open Source
# Data: 2025-11-28
# Autor: Samuel Ziger
#
# Instala Wazuh SIEM via Docker para logging centralizado
################################################################################

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            INSTALAÇÃO DO WAZUH SIEM (DOCKER)             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

################################################################################
# Verificar Docker
################################################################################
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[WAZUH] ❌ Docker não encontrado!${NC}"
    echo -e "${YELLOW}[WAZUH] Instale com: sudo apt install docker.io docker-compose${NC}"
    exit 1
fi

echo -e "${GREEN}[WAZUH] ✅ Docker encontrado${NC}"

################################################################################
# Verificar recursos
################################################################################
echo ""
echo -e "${BLUE}[WAZUH] Verificando recursos do sistema...${NC}"

# RAM
RAM_GB=$(free -g | awk 'NR==2 {print $7}')
if [ $RAM_GB -lt 4 ]; then
    echo -e "${RED}[WAZUH] ❌ RAM insuficiente!${NC}"
    echo -e "${YELLOW}[WAZUH] Necessário: 4GB+ disponível${NC}"
    echo -e "${YELLOW}[WAZUH] Disponível: ${RAM_GB}GB${NC}"
    read -p "Continuar mesmo assim? (s/n): " continue
    if [ "$continue" != "s" ]; then
        exit 1
    fi
fi

# Disco
DISK_GB=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
if [ $DISK_GB -lt 20 ]; then
    echo -e "${YELLOW}[WAZUH] ⚠️ Espaço em disco baixo: ${DISK_GB}GB${NC}"
    echo -e "${YELLOW}[WAZUH] Recomendado: 20GB+ livres${NC}"
fi

echo -e "${GREEN}[WAZUH] ✅ Recursos OK${NC}"

################################################################################
# Criar diretório
################################################################################
echo ""
echo -e "${BLUE}[WAZUH] Criando diretórios...${NC}"

WAZUH_DIR="$HOME/wazuh-docker"
mkdir -p "$WAZUH_DIR"
cd "$WAZUH_DIR"

################################################################################
# Baixar docker-compose
################################################################################
echo ""
echo -e "${BLUE}[WAZUH] Baixando docker-compose do Wazuh...${NC}"

if [ ! -f "docker-compose.yml" ]; then
    curl -so docker-compose.yml https://raw.githubusercontent.com/wazuh/wazuh-docker/master/single-node/docker-compose.yml
    echo -e "${GREEN}[WAZUH] ✅ docker-compose.yml baixado${NC}"
else
    echo -e "${YELLOW}[WAZUH] docker-compose.yml já existe, pulando...${NC}"
fi

################################################################################
# Gerar certificados
################################################################################
echo ""
echo -e "${BLUE}[WAZUH] Gerando certificados SSL...${NC}"

if [ ! -f "generate-indexer-certs.yml" ]; then
    curl -so generate-indexer-certs.yml https://raw.githubusercontent.com/wazuh/wazuh-docker/master/single-node/generate-indexer-certs.yml
fi

docker-compose -f generate-indexer-certs.yml run --rm generator

echo -e "${GREEN}[WAZUH] ✅ Certificados gerados${NC}"

################################################################################
# Iniciar Wazuh
################################################################################
echo ""
echo -e "${BLUE}[WAZUH] Iniciando containers (pode demorar 5-10 minutos)...${NC}"

docker-compose up -d

echo ""
echo -e "${GREEN}[WAZUH] ✅ Wazuh iniciado!${NC}"
echo ""

################################################################################
# Aguardar inicialização
################################################################################
echo -e "${BLUE}[WAZUH] Aguardando inicialização completa...${NC}"
sleep 30

################################################################################
# Informações de acesso
################################################################################
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              WAZUH INSTALADO COM SUCESSO                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📊 Acesso Web:${NC}"
echo "  URL: https://localhost"
echo "  Usuário: admin"
echo "  Senha: SecretPassword  (TROCAR APÓS LOGIN!)"
echo ""
echo -e "${GREEN}📡 Wazuh Manager:${NC}"
echo "  Host: localhost"
echo "  Porta: 1514"
echo ""
echo -e "${GREEN}🔧 Comandos úteis:${NC}"
echo "  Ver logs: docker-compose logs -f"
echo "  Parar: docker-compose stop"
echo "  Iniciar: docker-compose start"
echo "  Remover: docker-compose down"
echo ""
echo -e "${YELLOW}⚠️ PRÓXIMOS PASSOS:${NC}"
echo "  1. Acesse https://localhost"
echo "  2. Login com admin / SecretPassword"
echo "  3. TROCAR SENHA imediatamente"
echo "  4. Instalar agentes nas máquinas que quer monitorar"
echo ""
echo -e "${BLUE}📚 Documentação:${NC}"
echo "  https://documentation.wazuh.com/"
echo ""

################################################################################
# Script de instalação de agente
################################################################################
echo -e "${BLUE}[WAZUH] Gerando script de instalação de agente...${NC}"

cat > install_agent.sh << 'EOF'
#!/bin/bash
# Instalar Wazuh Agent em máquinas remotas

WAZUH_MANAGER="SEU_IP_AQUI"  # IP do servidor Wazuh

# Debian/Ubuntu
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.7.0-1_amd64.deb
sudo dpkg -i wazuh-agent_4.7.0-1_amd64.deb

# Configurar manager
sudo sed -i "s/<address>.*<\/address>/<address>$WAZUH_MANAGER<\/address>/" /var/ossec/etc/ossec.conf

# Iniciar
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

echo "Agent instalado! Verificar no dashboard: https://$WAZUH_MANAGER"
EOF

chmod +x install_agent.sh
echo -e "${GREEN}[WAZUH] ✅ Script de agente criado: install_agent.sh${NC}"
echo ""

echo -e "${GREEN}✅ Instalação concluída!${NC}"
