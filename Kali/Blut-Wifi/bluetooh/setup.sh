#!/bin/bash
# Script de instalação para Kali Linux

echo "=========================================="
echo "  Instalação - Laboratório Bluetooth"
echo "=========================================="
echo ""

# Verificar se está rodando como root para algumas operações
if [ "$EUID" -ne 0 ]; then 
    echo "[!] Algumas operações requerem privilégios root"
    echo "[!] Execute partes deste script com sudo quando necessário"
    echo ""
fi

# Atualizar sistema
echo "[*] Atualizando sistema..."
sudo apt update

# Instalar dependências do sistema
echo "[*] Instalando dependências do sistema..."
sudo apt install -y \
    python3 \
    python3-pip \
    bluetooth \
    bluez \
    libbluetooth-dev \
    hcitool \
    rfcomm \
    l2ping

# Instalar dependências Python
echo "[*] Instalando dependências Python..."
pip3 install -r requirements.txt

# Verificar adaptador Bluetooth
echo ""
echo "[*] Verificando adaptador Bluetooth..."
if hciconfig | grep -q "hci0"; then
    echo "[+] Adaptador Bluetooth encontrado"
    sudo hciconfig hci0 up
    echo "[+] Adaptador ativado"
else
    echo "[!] Adaptador Bluetooth não encontrado!"
    echo "[!] Verifique se o hardware está conectado"
fi

# Configurar permissões
echo ""
echo "[*] Configurando permissões..."
sudo usermod -aG bluetooth $USER 2>/dev/null || true

# Iniciar serviço Bluetooth
echo "[*] Iniciando serviço Bluetooth..."
sudo systemctl start bluetooth
sudo systemctl enable bluetooth

echo ""
echo "=========================================="
echo "  Instalação concluída!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Execute: python3 bluetooth_scan.py"
echo "2. Identifique o MAC da caixa de som"
echo "3. Execute o ataque desejado"
echo ""
echo "NOTA: Alguns scripts requerem sudo"
echo ""

