# Laboratório de Ataque Bluetooth - Desconexão de Caixa de Som

Este laboratório demonstra como usar um notebook Kali Linux (bare metal) para realizar um ataque Bluetooth que desconecta um celular de uma caixa de som.

## ⚠️ AVISO LEGAL

Este material é apenas para fins educacionais e testes em ambientes controlados. Use apenas em dispositivos que você possui ou tem permissão explícita para testar. O uso não autorizado é ilegal.

## Pré-requisitos

### Hardware
- Notebook com Kali Linux instalado (bare metal)
- Adaptador Bluetooth compatível (recomendado: CSR8510, BCM20702, ou similar)
- Caixa de som Bluetooth
- Celular Android/iOS para teste

### Software
- Kali Linux (última versão)
- Python 3.x
- Bibliotecas Bluetooth necessárias

## Instalação

### 1. Instalar dependências do sistema

```bash
sudo apt update
sudo apt install -y python3-pip bluetooth bluez libbluetooth-dev
```

### 2. Instalar dependências Python

```bash
pip3 install pybluez bleak scapy
```

### 3. Verificar adaptador Bluetooth

```bash
hciconfig
# Se não aparecer, ative:
sudo hciconfig hci0 up
```

## Métodos de Ataque

### Método 1: Flooding de Conexões (L2CAP)
O script `bluetooth_flood.py` envia múltiplas requisições de conexão para sobrecarregar o dispositivo.

### Método 2: Desconexão Forçada (BlueBorne-style)
O script `bluetooth_disconnect.py` explora vulnerabilidades conhecidas para forçar desconexão.

### Método 3: Interferência de Frequência
O script `bluetooth_jammer.py` interfere nas frequências Bluetooth para causar desconexão.

## Uso

### Passo 1: Escanear dispositivos Bluetooth

```bash
python3 bluetooth_scan.py
```

### Passo 2: Identificar o MAC da caixa de som

Anote o endereço MAC (formato: XX:XX:XX:XX:XX:XX)

### Passo 3: Executar o ataque

```bash
# Método de flooding
python3 bluetooth_flood.py --target MAC_ADDRESS

# Método de desconexão forçada
python3 bluetooth_disconnect.py --target MAC_ADDRESS

# Método de interferência
sudo python3 bluetooth_jammer.py --target MAC_ADDRESS
```

## Troubleshooting

### Bluetooth não funciona
```bash
sudo systemctl start bluetooth
sudo systemctl enable bluetooth
```

### Permissões insuficientes
Alguns scripts requerem privilégios root:
```bash
sudo python3 script.py
```

### Adaptador não detectado
```bash
lsusb | grep -i bluetooth
sudo modprobe btusb
```

## Referências

- BlueZ Documentation
- Bluetooth SIG Specifications
- Kali Linux Wireless Attacks Guide

