#!/bin/bash

echo "========================================"
echo "   Kali Linux - Setup Completo Automático"
echo "========================================"

# 1. Atualizar o sistema
echo "[1] Atualizando o sistema..."
sudo apt update && sudo apt full-upgrade -y

# 2. Instalar Kali Full
echo "[2] Instalando meta-pacotes do Kali..."
sudo apt install kali-linux-large -y
# OU para tudo mesmo:
# sudo apt install kali-linux-everything -y

# 3. Ativar performance da CPU
echo "[3] Otimizando CPU..."
sudo apt install cpufrequtils -y
sudo cpufreq-set -g performance

# 4. Instalar ferramentas Red Team
echo "[4] Instalando ferramentas de brute-force..."
sudo apt install hydra medusa ncrack -y

echo "[4] Instalando ferramentas de enumeração..."
sudo apt install gobuster seclists bloodhound bloodhound.py -y

echo "[4] Instalando SQLmap..."
sudo apt install sqlmap -y

echo "[4] Instalando ExploitDB, Metasploit e Veil..."
sudo apt install exploitdb metasploit-framework veil-evasion -y

echo "[4] Instalando utilidades de rede..."
sudo apt install net-tools netcat-traditional -y

echo "[4] Instalando WPScan..."
sudo apt install wpscan -y

# 5. Criar diretórios de ataque
echo "[5] Criando diretórios padrão..."
mkdir -p ~/recon ~/exploit ~/bruteforce ~/enum ~/loot ~/wordlists

# 6. Baixar wordlists pesados
echo "[6] Baixando SecLists..."
cd ~/wordlists
sudo git clone https://github.com/danielmiessler/SecLists.git

# 7. Otimizar rede
echo "[7] Otimizando rede para scans..."
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.core.somaxconn = 65535' | sudo tee -a /etc/sysctl.conf
echo 'fs.file-max = 100000' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 8. Instalar ferramentas específicas
echo "[8] Instalando Masscan..."
sudo apt install masscan -y

echo "[8] Instalando Ffuf..."
sudo apt install ffuf -y

echo "[8] Instalando Golang e Kerbrute..."
sudo apt install golang -y
go install github.com/ropnop/kerbrute@latest

# 9. WordPress hacking – WPScan Gem
echo "[9] Instalando WPScan via Gem..."
sudo gem install wpscan

# 10. Docker
echo "[10] Instalando Docker..."
sudo apt install docker.io docker-compose -y
sudo systemctl enable docker --now

# 11. Timeshift
echo "[11] Instalando Timeshift..."
sudo apt install timeshift -y

# 12. OpenSSH Server
echo "[12] Instalando SSH Server..."
sudo apt install openssh-server -y
sudo systemctl enable ssh --now

################################################################################
# NOVAS ADIÇÕES - C2 FRAMEWORKS MODERNOS (2025-11-28)
################################################################################

echo "[13] Instalando C2 Frameworks modernos..."
echo "  Sliver, Havoc, Mythic..."

# Sliver C2 (Go-based, moderno, substituiu Cobalt Strike para muitos)
echo "[13.1] Instalando Sliver C2..."
if ! command -v sliver-server &> /dev/null; then
    curl https://sliver.sh/install | sudo bash
    echo "  ✓ Sliver instalado"
else
    echo "  ✓ Sliver já instalado, pulando..."
fi

# Havoc C2 (C2 moderno open-source)
echo "[13.2] Instalando Havoc C2..."
if [ ! -d ~/Tools/Havoc ]; then
    mkdir -p ~/Tools
    cd ~/Tools
    git clone https://github.com/HavocFramework/Havoc.git
    cd Havoc
    # Instalação requer compilação manual - ver README
    echo "  ✓ Havoc clonado (compilar manualmente: cd ~/Tools/Havoc && make)"
else
    echo "  ✓ Havoc já existe, pulando..."
fi

# Instalar dependências para Mythic (via Docker)
echo "[13.3] Preparando Mythic C2..."
echo "  Mythic requer Docker (já instalado anteriormente)"
echo "  Para instalar Mythic: git clone https://github.com/its-a-feature/Mythic && cd Mythic && ./install_docker_ubuntu.sh"

################################################################################
# CLOUD SECURITY TOOLS (2025-11-28)
################################################################################

echo "[14] Instalando Cloud Security Tools..."

# Pacu (AWS exploitation framework)
echo "[14.1] Instalando Pacu (AWS)..."
if [ ! -d ~/Tools/pacu ]; then
    mkdir -p ~/Tools
    cd ~/Tools
    git clone https://github.com/RhinoSecurityLabs/pacu.git
    cd pacu
    pip3 install -r requirements.txt
    echo "  ✓ Pacu instalado"
else
    echo "  ✓ Pacu já instalado, pulando..."
fi

# ScoutSuite (Multi-cloud auditing)
echo "[14.2] Instalando ScoutSuite (Multi-cloud)..."
if ! command -v scout &> /dev/null; then
    pip3 install scoutsuite
    echo "  ✓ ScoutSuite instalado"
else
    echo "  ✓ ScoutSuite já instalado, pulando..."
fi

# Prowler (AWS/Azure/GCP security)
echo "[14.3] Instalando Prowler (AWS/Azure/GCP)..."
if ! command -v prowler &> /dev/null; then
    pip3 install prowler-cloud
    echo "  ✓ Prowler instalado"
else
    echo "  ✓ Prowler já instalado, pulando..."
fi

# CloudFox (AWS situational awareness)
echo "[14.4] Instalando CloudFox (AWS)..."
if [ ! -f /usr/local/bin/cloudfox ]; then
    wget https://github.com/BishopFox/cloudfox/releases/latest/download/cloudfox-linux-amd64 -O /tmp/cloudfox
    sudo mv /tmp/cloudfox /usr/local/bin/cloudfox
    sudo chmod +x /usr/local/bin/cloudfox
    echo "  ✓ CloudFox instalado"
else
    echo "  ✓ CloudFox já instalado, pulando..."
fi

echo "========================================"
echo "   SETUP FINALIZADO!"
echo " Reinicie a máquina para aplicar tudo."
echo "========================================"
echo ""
echo "🆕 Novidades instaladas (2025-11-28):"
echo "  ✓ Sliver C2 (comando: sliver-server)"
echo "  ✓ Havoc C2 (~/Tools/Havoc - compilar manualmente)"
echo "  ✓ Pacu (AWS) - cd ~/Tools/pacu && python pacu.py"
echo "  ✓ ScoutSuite (Multi-cloud) - comando: scout"
echo "  ✓ Prowler (AWS/Azure/GCP) - comando: prowler"
echo "  ✓ CloudFox (AWS) - comando: cloudfox"
echo ""
echo "📚 Documentação:"
echo "  Sliver: https://github.com/BishopFox/sliver/wiki"
echo "  Havoc: https://havocframework.com/docs"
echo "  Mythic: https://docs.mythic-c2.net"
echo "  Pacu: https://github.com/RhinoSecurityLabs/pacu"
echo "========================================"
