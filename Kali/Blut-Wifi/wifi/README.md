# WiFi DoS - Ferramenta de Teste de Segurança

⚠️ **AVISO LEGAL IMPORTANTE** ⚠️

Esta ferramenta é destinada **APENAS** para:
- Testes de segurança autorizados
- Ambientes de laboratório controlados
- Pesquisa e educação em segurança de redes
- Testes de penetração com autorização escrita

**O uso não autorizado desta ferramenta é ILEGAL** e pode resultar em:
- Penalidades criminais
- Processos civis
- Responsabilidade legal

## Requisitos

### Sistema Operacional
- Windows 10/11
- Linux (com suporte a monitor mode)
- macOS

### Dependências Python
```bash
pip install -r requirements.txt
```

### Permissões Necessárias
- **Windows**: Execute como Administrador
- **Linux**: Execute com `sudo` ou como root
- **macOS**: Pode precisar de permissões especiais

### Interface WiFi
- Interface WiFi compatível com modo monitor (recomendado)
- Ou interface WiFi normal (funcionalidade limitada)

## Instalação

1. Clone ou baixe este repositório
2. Instale as dependências:
```bash
pip install -r requirements.txt
```

## Uso

### 1. Escanear Redes WiFi Disponíveis

Primeiro, escaneie para encontrar o BSSID (MAC address) do AP alvo:

```bash
python wifi_dos.py --scan
```

ou especificando a interface:

```bash
python wifi_dos.py --scan -i "Wi-Fi"
```

### 2. Ataque de Desautenticação (Deauth)

Este é o ataque mais comum e efetivo. Força a desconexão de clientes do AP:

```bash
# Desconectar todos os clientes (broadcast)
python wifi_dos.py --deauth -b AA:BB:CC:DD:EE:FF

# Desconectar um cliente específico
python wifi_dos.py --deauth -b AA:BB:CC:DD:EE:FF -c 11:22:33:44:55:66

# Enviar número limitado de pacotes
python wifi_dos.py --deauth -b AA:BB:CC:DD:EE:FF --count 100
```

### 3. Flood de Beacons

Cria múltiplas redes WiFi falsas para sobrecarregar a lista de redes:

```bash
# Criar 500 redes falsas
python wifi_dos.py --beacon --count 500

# Com prefixo personalizado
python wifi_dos.py --beacon --count 200 --ssid-prefix "FAKE_"
```

### 4. Flood de Autenticação

Sobrecarrega o AP com requisições de autenticação:

```bash
python wifi_dos.py --auth -b AA:BB:CC:DD:EE:FF
```

### 5. Flood de Associação

Sobrecarrega o AP com requisições de associação:

```bash
python wifi_dos.py --assoc -b AA:BB:CC:DD:EE:FF
```

### 6. Múltiplos Ataques Simultâneos

Você pode combinar vários ataques:

```bash
python wifi_dos.py --deauth -b AA:BB:CC:DD:EE:FF --beacon --auth -b AA:BB:CC:DD:EE:FF
```

## Tipos de Ataque

### 1. Deauthentication Attack (Deauth)
- **Eficácia**: ⭐⭐⭐⭐⭐
- **Descrição**: Envia pacotes de desautenticação falsos, forçando clientes a desconectar
- **Impacto**: Desconexão imediata de clientes
- **Uso**: Mais comum e efetivo

### 2. Beacon Flood
- **Eficácia**: ⭐⭐⭐
- **Descrição**: Cria centenas de redes WiFi falsas
- **Impacto**: Sobrecarrega a lista de redes disponíveis
- **Uso**: Pode confundir usuários e sobrecarregar dispositivos

### 3. Authentication Flood
- **Eficácia**: ⭐⭐⭐⭐
- **Descrição**: Envia muitas requisições de autenticação falsas
- **Impacto**: Pode sobrecarregar o AP e causar lentidão/queda
- **Uso**: Efetivo contra APs mais antigos

### 4. Association Flood
- **Eficácia**: ⭐⭐⭐⭐
- **Descrição**: Envia muitas requisições de associação falsas
- **Impacto**: Similar ao auth flood, pode derrubar o AP
- **Uso**: Complementa outros ataques

## Troubleshooting

### Erro: "Interface WiFi não encontrada"
- No Windows: Use `netsh wlan show interfaces` para listar interfaces
- Especifique manualmente: `-i "Nome da Interface"`
- Verifique se a interface WiFi está ativa

### Erro: "Permission denied" ou "Access denied"
- Windows: Execute como Administrador
- Linux: Execute com `sudo`
- Verifique permissões da interface de rede

### Ataque não está funcionando
- Verifique se o BSSID está correto
- Certifique-se de estar próximo ao AP alvo
- Alguns APs modernos têm proteções contra deauth
- Tente usar modo monitor (requer drivers especiais)

### Performance baixa
- Use interface WiFi dedicada
- Modo monitor melhora significativamente a performance
- Reduza a taxa de pacotes se necessário

## Proteções e Mitigações

APs modernos podem ter proteções contra estes ataques:
- **802.11w (PMF)**: Protege contra deauth não autorizados
- **Rate limiting**: Limita requisições por segundo
- **Intrusion Detection**: Detecta padrões de ataque

## Responsabilidade

O desenvolvedor desta ferramenta **NÃO** se responsabiliza por:
- Uso não autorizado
- Danos causados pelo uso indevido
- Consequências legais do uso
- Qualquer violação de leis ou regulamentos

**Use por sua conta e risco. Use apenas em ambientes autorizados.**

## Licença

Esta ferramenta é fornecida "como está", sem garantias. Use apenas para fins legítimos e autorizados.

