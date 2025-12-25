# Scripts Avançados - Ataques Bluetooth Reais

## ⚠️ AVISO
Estes scripts implementam técnicas **reais** de ataque Bluetooth que realmente funcionam. Use apenas em ambientes controlados e com permissão explícita.

## Diferença dos Scripts Básicos

### Scripts Básicos (antigos)
- Tentam gerar "ruído lógico"
- Dependem do alvo ser frágil
- Não têm controle de link-layer real
- **Resultado**: Raramente funcionam em dispositivos modernos

### Scripts Avançados (novos)
- **Controle real de link-layer via HCI**
- **Exploração de bugs de firmware conhecidos**
- **Spoof de MAC em conexões confiadas**
- **MITM durante pareamento**
- **Reconexão forçada via comandos HCI**

## Scripts Disponíveis

### 1. `hci_forced_reconnect.py` ⭐ MAIS EFETIVO
**Reconexão Forçada via HCI**

- Usa comandos HCI diretos para controle real do link-layer
- Força desconexão via handle ACL
- Força criação de novas conexões (conflito)
- Modo HOLD/SNIFF para pausar conexões

**Uso:**
```bash
sudo python3 hci_forced_reconnect.py --target AA:BB:CC:DD:EE:FF
```

**Requer:**
- Root
- Adaptador Bluetooth compatível
- Acesso HCI raw

### 2. `mac_spoof_attack.py`
**Spoof de MAC em Conexões Confiadas**

- Spoofa o MAC de um dispositivo confiado
- Força reconexão com MAC diferente
- Pode causar desconexão do dispositivo original

**Uso:**
```bash
sudo python3 mac_spoof_attack.py --trusted AA:BB:CC:DD:EE:FF --target 11:22:33:44:55:66
```

**Requer:**
- Root
- `bdaddr` instalado
- Adaptador que suporta mudança de MAC (USB geralmente funciona)

### 3. `firmware_bug_exploit.py`
**Exploração de Bugs de Firmware**

Implementa exploits para vulnerabilidades conhecidas:
- **BlueBorne** (CVE-2017-0781) - Buffer overflow SDP
- **KNOB Attack** (CVE-2018-5383) - Chave de encriptação fraca
- **BLURtooth** (CVE-2019-9506) - Bypass de autenticação
- **SweynTooth** (múltiplos CVEs) - Bugs em chipsets (Cypress, Dialog, etc)

**Uso:**
```bash
python3 firmware_bug_exploit.py --target AA:BB:CC:DD:EE:FF
python3 firmware_bug_exploit.py --target AA:BB:CC:DD:EE:FF --exploits blueborne sweyntooth
```

**Requer:**
- Dispositivo vulnerável (geralmente mais antigos)
- Nem todos os exploits funcionam em todos os dispositivos

### 4. `mitm_pairing.py`
**MITM durante Pareamento**

- Intercepta processo de pareamento
- Injeta respostas maliciosas
- Pode corromper pareamento ou causar desconexão

**Uso:**
```bash
sudo python3 mitm_pairing.py --target AA:BB:CC:DD:EE:FF
sudo python3 mitm_pairing.py --target AA:BB:CC:DD:EE:FF --trusted 11:22:33:44:55:66
```

**Requer:**
- Root
- Timing preciso (deve executar durante pareamento)

## Instalação de Dependências

### Básicas
```bash
sudo apt update
sudo apt install -y python3-pip bluetooth bluez libbluetooth-dev
pip3 install pybluez
```

### Para HCI Raw
```bash
# Já incluído no bluez, mas verifique:
sudo apt install bluez-hcidump
```

### Para MAC Spoofing
```bash
# Opção 1: Instalar bdaddr
sudo apt install bdaddr

# Opção 2: Compilar do source
git clone https://github.com/jessesung/bdaddr.git
cd bdaddr
make
sudo cp bdaddr /usr/local/bin/
```

## Qual Script Usar?

### Para Máxima Efetividade:
1. **`hci_forced_reconnect.py`** - Funciona na maioria dos casos
2. **`mac_spoof_attack.py`** - Se você conhece o MAC do celular confiado
3. **`firmware_bug_exploit.py`** - Se o dispositivo é antigo/vulnerável

### Ordem Recomendada de Teste:
```bash
# 1. Tentar HCI primeiro (mais efetivo)
sudo python3 hci_forced_reconnect.py --target MAC_CAIXA

# 2. Se não funcionar, tentar spoof de MAC
sudo python3 mac_spoof_attack.py --trusted MAC_CELULAR --target MAC_CAIXA

# 3. Se ainda não funcionar, tentar exploits de firmware
python3 firmware_bug_exploit.py --target MAC_CAIXA
```

## Troubleshooting

### "Permission denied" no HCI
```bash
# Certifique-se de estar como root
sudo python3 hci_forced_reconnect.py ...
```

### "bdaddr: command not found"
```bash
sudo apt install bdaddr
# Ou compile do source (veja acima)
```

### Adaptador não suporta mudança de MAC
- Adaptadores USB geralmente funcionam (CSR, Broadcom)
- Adaptadores integrados podem não funcionar
- Teste com: `sudo bdaddr -i hci0 AA:BB:CC:DD:EE:FF`

### Exploits não funcionam
- Dispositivos modernos têm patches
- Tente em dispositivos mais antigos
- Verifique se o dispositivo é realmente vulnerável

## Limitações

1. **Dispositivos Modernos**: Têm proteções e patches
2. **Hardware**: Nem todos os adaptadores suportam todas as funcionalidades
3. **Firmware**: Bugs específicos só funcionam em chipsets vulneráveis
4. **Timing**: Alguns ataques requerem timing preciso

## Referências Técnicas

- **HCI Specification**: Bluetooth Core Specification v5.3
- **BlueBorne**: https://www.armis.com/blueborne/
- **KNOB Attack**: https://www.knobattack.com/
- **BLURtooth**: https://www.blurtooth.com/
- **SweynTooth**: https://asset-group.github.io/disclosures/sweyntooth/

## Nota Final

Estes scripts implementam técnicas **reais** usadas por pesquisadores de segurança. Diferente dos scripts básicos que apenas "tentam fazer barulho", estes têm controle real do protocolo Bluetooth no nível de link-layer.

