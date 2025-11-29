# 🔐 Captura de Handshake Wi-Fi

Script automatizado para captura e quebra de handshake WPA/WPA2.

## ⚠️ AVISO LEGAL

**Este script é apenas para fins educacionais e testes autorizados!**

- Use apenas em redes próprias ou com autorização formal por escrito
- Atacar redes sem autorização é ilegal em praticamente todos os países
- O autor não se responsabiliza pelo uso indevido deste script

## 📋 Requisitos

- Sistema operacional: Linux (Kali Linux recomendado)
- Permissões: Root (sudo)
- Hardware: Placa Wi-Fi compatível com modo monitor
- Dependências: `aircrack-ng` (instalado automaticamente se necessário)

## 🚀 Instalação

```bash
# Dar permissão de execução
chmod +x capturar_handshake.sh

# Executar como root
sudo ./capturar_handshake.sh
```

## 📖 Como Usar

### 1. Executar o Script

```bash
sudo ./capturar_handshake.sh
```

### 2. Fluxo de Trabalho

#### Passo 1: Escanear Redes
- Escolha opção `[1]` no menu
- O script mostrará todas as redes Wi-Fi disponíveis
- Anote:
  - **BSSID** do AP (ex: `34:CE:00:7F:91:E0`)
  - **Canal (CH)**
  - **Nome da rede (ESSID)**
- Pressione `Ctrl+C` quando encontrar a rede alvo

#### Passo 2: Capturar Handshake
- Escolha opção `[2]` no menu
- Informe:
  - BSSID do AP
  - Canal
  - Nome da rede (opcional)
  - MAC do cliente específico (opcional, deixe em branco para todos)
- O script iniciará a captura

#### Passo 3: Forçar Reconexão (Deauth)
- **Opção A**: Em outro terminal, execute:
  ```bash
  sudo aireplay-ng --deauth 10 -a [BSSID] -c [MAC_CLIENTE] [INTERFACE_MON]
  ```
  
- **Opção B**: Use a opção `[3]` do menu para executar deauth automático

#### Passo 4: Verificar Handshake
- Escolha opção `[4]` no menu
- O script verificará se o handshake foi capturado com sucesso

#### Passo 5: Quebrar Senha
- Escolha opção `[5]` no menu
- Selecione a wordlist (padrão: `/usr/share/wordlists/rockyou.txt`)
- Aguarde o processo de quebra (pode levar muito tempo)

## 🔧 Funcionalidades

- ✅ Detecção automática de interface Wi-Fi
- ✅ Ativação automática de modo monitor
- ✅ Escaneamento de redes Wi-Fi
- ✅ Captura de handshake específico
- ✅ Ataque deauth automático
- ✅ Verificação de handshake capturado
- ✅ Quebra de senha com wordlist
- ✅ Restauração automática da interface

## 📁 Estrutura de Arquivos

```
wifi/
├── capturar_handshake.sh    # Script principal
├── README.md                # Este arquivo
└── capturas/               # Diretório de capturas (criado automaticamente)
    └── captura_YYYYMMDD_HHMMSS-01.cap
```

## 🎯 Exemplo de Uso Completo

```bash
# 1. Executar script
sudo ./capturar_handshake.sh

# 2. Escanear redes (opção 1)
# Anotar: BSSID, Canal, ESSID

# 3. Capturar handshake (opção 2)
# Informar: BSSID=34:CE:00:7F:91:E0, Canal=6

# 4. Em outro terminal, executar deauth:
sudo aireplay-ng --deauth 10 -a 34:CE:00:7F:91:E0 wlan0mon

# 5. Verificar handshake (opção 4)

# 6. Quebrar senha (opção 5)
# Usar wordlist: /usr/share/wordlists/rockyou.txt
```

## 🔍 Troubleshooting

### Interface não entra em modo monitor
- Verifique se a placa Wi-Fi suporta modo monitor
- Tente desabilitar NetworkManager: `sudo systemctl stop NetworkManager`
- Verifique se há processos bloqueando: `sudo airmon-ng check kill`

### Handshake não é capturado
- ✅ Certifique-se de executar o ataque deauth
- ✅ Verifique se está no canal correto
- ✅ Verifique se o BSSID está correto
- ✅ Tente aumentar o número de pacotes deauth
- ⚠️ WPA3 não pode ser capturado com este método

### Senha não é quebrada
- A senha pode não estar na wordlist
- Tente wordlists maiores ou específicas
- Senhas fortes podem levar dias/anos para quebrar
- Considere usar GPU para acelerar (hashcat)

## 📚 Recursos Adicionais

- [Aircrack-ng Documentation](https://www.aircrack-ng.org/)
- [Kali Linux Wireless Attacks](https://www.kali.org/tools/aircrack-ng/)

## 🛡️ Boas Práticas de Segurança

### Para Testar (Redes Próprias):
- Use senhas fracas para treinar: `12345678`, `senha123`, `wifi1234`
- Compare com senhas fortes para ver a diferença prática

### Para Proteger Sua Rede:
- Use senhas fortes e complexas (mínimo 12 caracteres)
- Ative WPA3 se sua roteador suportar
- Desative WPS
- Use MAC filtering (não é muito seguro, mas ajuda)
- Monitore dispositivos conectados regularmente

## 📝 Notas

- O script restaura automaticamente a interface ao sair
- Arquivos de captura são salvos em `capturas/`
- O processo pode ser interrompido com `Ctrl+C` a qualquer momento
- Para treinar, use senhas fracas em redes de laboratório

## ⚡ Dicas

1. **Treinamento**: Configure uma rede de teste com senha fraca para praticar
2. **Wordlists**: Use wordlists específicas para sua região/idioma
3. **GPU**: Para senhas mais complexas, considere usar hashcat com GPU
4. **Paciência**: Quebrar senhas pode levar muito tempo dependendo da complexidade

---

**Lembre-se**: Use apenas com autorização! 🔒

