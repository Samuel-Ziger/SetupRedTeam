# 🔐 Scripts Wi-Fi

Scripts automatizados para captura e quebra de handshake WPA/WPA2.

## 📦 Scripts Disponíveis

1. **`capturar_handshake.sh`** - Captura de handshake WPA/WPA2
2. **`bruteforce_wifi.sh`** - Brute force automático testando múltiplas wordlists
3. **`deauth_rapido.sh`** - Ataque deauth rápido (script auxiliar)

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
├── capturar_handshake.sh      # Script de captura de handshake
├── bruteforce_wifi.sh         # Script de brute force automático
├── deauth_rapido.sh           # Script auxiliar de deauth
├── README.md                  # Este arquivo
├── capturas/                  # Diretório de capturas (criado automaticamente)
│   └── captura_YYYYMMDD_HHMMSS-01.cap
└── resultados_bruteforce/     # Diretório de resultados do brute force
    ├── bruteforce_YYYYMMDD_HHMMSS.log
    └── senha_encontrada_YYYYMMDD_HHMMSS.txt
```

---

# 🔐 Captura de Handshake Wi-Fi

Script automatizado para captura de handshake WPA/WPA2.

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

---

# 🔓 Brute Force Wi-Fi Automático

Script automatizado para quebrar senhas WPA/WPA2 testando múltiplas wordlists da SecLists automaticamente.

## 🚀 Instalação

```bash
# Dar permissão de execução
chmod +x bruteforce_wifi.sh

# Executar como root
sudo ./bruteforce_wifi.sh [arquivo.cap]
```

## 📖 Como Usar

### Modo Rápido (com argumento)

```bash
# Executar com arquivo .cap diretamente
sudo ./bruteforce_wifi.sh capturas/captura_20250101_120000-01.cap
```

### Modo Interativo

```bash
# Executar sem argumentos para modo interativo
sudo ./bruteforce_wifi.sh
```

### Fluxo de Trabalho

1. **Preparar arquivo .cap**: Use `capturar_handshake.sh` para capturar o handshake
2. **Executar brute force**: Execute `bruteforce_wifi.sh` com o arquivo .cap
3. **Informar BSSID** (opcional): Acelera o processo se informado
4. **Aguardar**: O script testa wordlist por wordlist automaticamente
5. **Resultado**: Senha encontrada ou relatório de wordlists testadas

## 🔧 Funcionalidades

- ✅ Testa múltiplas wordlists automaticamente
- ✅ Ordem inteligente (wordlists menores/comuns primeiro)
- ✅ Suporte a SecLists local
- ✅ Log detalhado de todas as tentativas
- ✅ Relatório final com resultados
- ✅ Detecção automática de handshake
- ✅ Suporte a BSSID específico (acelera processo)
- ✅ Interface interativa e modo linha de comando

## 📋 Wordlists Testadas

O script testa wordlists na seguinte ordem de prioridade:

1. **WiFi-WPA específicas** (probable-v2-wpa-top62, top447, top4800)
2. **Senhas comuns** (best15, best110, best1050, 500-worst-passwords)
3. **Senhas mais usadas** (2025-199, 2024-197, 2023-200, etc.)
4. **Probable v2** (top-207, top-1575, top-12000)
5. **Pwdb** (top-1000, top-10000, top-100000)
6. **Xato-net** (10, 100, 1000, 10000, 100000, 1000000)
7. **RockYou** (05, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75)
8. **Outras wordlists** da SecLists

## 🎯 Exemplo de Uso Completo

```bash
# 1. Capturar handshake primeiro
sudo ./capturar_handshake.sh

# 2. Executar brute force no arquivo capturado
sudo ./bruteforce_wifi.sh capturas/captura_20250101_120000-01.cap

# 3. Informar BSSID quando solicitado (opcional)
# BSSID: 34:CE:00:7F:91:E0

# 4. Aguardar resultado
# O script testará wordlist por wordlist até encontrar a senha
```

## 📊 Saída do Script

### Quando a senha é encontrada:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 SENHA ENCONTRADA! 🎉
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Senha: senha123
Wordlist: probable-v2-wpa-top447.txt
Wordlists testadas: 3
```

### Quando a senha não é encontrada:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Senha não encontrada após testar 45 wordlists
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔍 Troubleshooting

### SecLists não encontrado

O script procura SecLists em:
- `Kali/Ferramentas/SecLists/Passwords` (relativo ao script)
- `/usr/share/seclists/Passwords`
- `/usr/share/wordlists/SecLists/Passwords`
- `~/SecLists/Passwords`

**Solução**: Instale com `sudo apt install seclists -y` ou clone o repositório.

### Handshake não detectado

- Verifique se o arquivo .cap contém um handshake válido
- Use `aircrack-ng arquivo.cap` para verificar manualmente
- O script continuará mesmo sem detecção, mas pode não funcionar

### Processo muito lento

- Informe o BSSID quando solicitado (acelera significativamente)
- Wordlists grandes podem levar horas/dias
- Considere usar hashcat com GPU para acelerar

### Senha não encontrada

- A senha pode não estar em nenhuma wordlist testada
- Tente wordlists maiores ou mais específicas
- Senhas fortes podem levar anos para quebrar
- Considere usar técnicas de engenharia social ou outros métodos

## 📝 Notas

- O script salva logs em `resultados_bruteforce/`
- Resultados são salvos em arquivos de texto separados
- O processo pode ser interrompido com `Ctrl+C`
- Wordlists muito grandes (>500MB) são ignoradas automaticamente
- O script testa wordlists em ordem de prioridade (menores primeiro)

## ⚡ Dicas

1. **BSSID**: Sempre informe o BSSID quando possível (acelera muito)
2. **Wordlists**: O script prioriza wordlists menores e mais comuns
3. **Paciência**: Quebrar senhas pode levar muito tempo
4. **GPU**: Para senhas complexas, considere usar hashcat com GPU
5. **Handshake**: Certifique-se de ter capturado um handshake válido

---

**Lembre-se**: Use apenas com autorização! 🔒

