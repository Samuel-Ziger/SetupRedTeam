# TelNet Analyzer & Bruteforcer

Ferramenta completa para análise e exploração de serviços Telnet, especialmente otimizada para roteadores ZTE.

## 📋 Características

- **Coleta de Informações**: Banner grabbing e identificação de versão
- **Bruteforce Inteligente**: Ataque de força bruta com detecção de falsos positivos
- **Tratamento de Erros**: Mecanismos robustos de tratamento de erros e retry
- **Multi-threading**: Suporte a múltiplas threads para acelerar o bruteforce
- **Detecção de Falsos Positivos**: Verifica respostas do servidor para evitar falsos positivos

## 🚀 Instalação

```bash
# Clone ou baixe os arquivos
# Não há dependências externas necessárias (usa apenas bibliotecas padrão do Python)
```

## 📖 Uso

### Script Principal (Recomendado)

```bash
# Apenas coletar informações
python telnet_main.py --info 192.168.1.1

# Testar senhas padrão primeiro (recomendado - mais rápido)
python telnet_main.py --defaults 192.168.1.1

# Apenas bruteforce
python telnet_main.py --bruteforce 192.168.1.1 xato_net_passwords.txt

# Análise completa (informações + bruteforce)
python telnet_main.py --all 192.168.1.1 xato_net_passwords.txt

# Com opções customizadas
python telnet_main.py --bruteforce 192.168.1.1 xato_net_passwords.txt \
    --username root \
    --port 23 \
    --threads 10 \
    --delay 0.3
```

### Scripts Individuais

#### Coleta de Informações

```bash
python telnet_info.py 192.168.1.1 [porta]
```

#### Bruteforce

```bash
python telnet_bruteforce.py <IP> <wordlist> [opções]

# Opções disponíveis:
#   --username USER    Nome de usuário (padrão: root)
#   --port PORT        Porta (padrão: 23)
#   --threads N        Número de threads (padrão: 5)
#   --delay SECONDS    Delay entre tentativas (padrão: 0.5)
```

#### Testar Senhas Padrão

```bash
python telnet_default_passwords.py <IP> [opções]

# Testa senhas padrão comuns de roteadores ZTE antes do bruteforce completo
# Opções disponíveis:
#   --username USER    Nome de usuário (padrão: root)
#   --port PORT        Porta (padrão: 23)
#   --delay SECONDS    Delay entre tentativas (padrão: 0.3)
```

## 🔍 Detalhes Técnicos

### Detecção de Falsos Positivos

O script verifica múltiplos indicadores para evitar falsos positivos:

- **Padrões de Erro**: Detecta mensagens como "incorrect", "wrong", "invalid", "failed", "denied"
- **Padrões de Sucesso**: Procura por prompts de shell (#, $, >) e mensagens de boas-vindas
- **Confirmação Ativa**: Envia um comando de teste após login aparentemente bem-sucedido para confirmar

### Tratamento de Erros

- Retry automático em caso de falhas de conexão
- Timeout configurável
- Tratamento de exceções de rede
- Detecção de timeouts e reconexão

### Otimizações

- Multi-threading para paralelizar tentativas
- Delay configurável entre tentativas para evitar bloqueios
- Leitura eficiente de wordlists grandes
- Buffer limitado para evitar overflow

## ⚠️ Avisos Legais e Éticos

**IMPORTANTE**: Esta ferramenta é fornecida apenas para fins educacionais e testes de segurança autorizados. 

- **NUNCA** use esta ferramenta em sistemas sem autorização explícita
- Testes de penetração não autorizados são **ILEGAIS** e podem resultar em consequências legais graves
- Use apenas em ambientes controlados, laboratórios ou sistemas próprios
- O desenvolvedor não se responsabiliza pelo uso indevido desta ferramenta

## 📝 Exemplo de Saída

```
[*] Modo: Análise Completa
[*] Alvo: 192.168.1.1:23

============================================================
ETAPA 1: COLETA DE INFORMAÇÕES
============================================================
[*] Conectando em 192.168.1.1:23...
[+] Banner coletado:
------------------------------------------------------------
          ************************************************************
                          Welcome to the world of CLI !
          ************************************************************
Username:root
Password:
------------------------------------------------------------
[+] Versão identificada: 1.00-pre7 - 1.14.0
[+] Características: Requer autenticação, Dispositivo ZTE, Roteador

============================================================
ETAPA 2: BRUTEFORCE
============================================================
[*] Iniciando bruteforce em 192.168.1.1:23
[*] Usuário: root
[*] Wordlist: xato_net_passwords.txt
[*] Threads: 5
[*] Delay entre tentativas: 0.5s
------------------------------------------------------------
[*] Total de senhas na wordlist: 5189454
------------------------------------------------------------
[*] Tentativas: 100 | Testando: 123456...
[*] Tentativas: 200 | Testando: password...

[+] SENHA ENCONTRADA: admin123
[+] Tentativas realizadas: 234
```

## 🛠️ Estrutura dos Arquivos

- `telnet_main.py` - Script principal que orquestra todas as funcionalidades
- `telnet_info.py` - Módulo de coleta de informações e banner grabbing
- `telnet_bruteforce.py` - Módulo de bruteforce com detecção de falsos positivos
- `telnet_default_passwords.py` - Testa senhas padrão comuns de roteadores ZTE
- `requirements.txt` - Dependências (nenhuma externa necessária)
- `README.md` - Este arquivo

## 🔧 Requisitos

- Python 3.6 ou superior
- Acesso de rede ao alvo
- Wordlist de senhas (ex: xato_net_passwords.txt)

## 📚 Notas sobre ZTE Telnetd

Com base na análise do arquivo `telnet23.txt`, o alvo é um roteador ZTE com:
- Versão do telnetd: 1.00-pre7 - 1.14.0
- Banner: "Welcome to the world of CLI !"
- Autenticação: Usuário "root" com prompt direto de senha
- Dispositivo: Roteador ZTE (MAC: C0:FD:84:81:F8:8C)
- Modelo: ZXHN H108N V2.5 (identificado via HTTP)

### Vulnerabilidades Conhecidas

Roteadores ZTE são conhecidos por:
- **Senhas Padrão**: Muitos modelos vêm com senhas padrão fracas ou conhecidas
- **Backdoors**: Alguns modelos têm backdoors conhecidos
- **Firmware Desatualizado**: Versões antigas podem ter vulnerabilidades não corrigidas
- **Telnet Habilitado por Padrão**: Muitos roteadores ZTE têm Telnet habilitado por padrão

**Recomendação**: Sempre teste senhas padrão primeiro antes de fazer bruteforce completo, pois é muito mais rápido e eficiente.

## 🤝 Contribuições

Melhorias e sugestões são bem-vindas! Por favor, use esta ferramenta de forma ética e responsável.

## 📄 Licença

Este projeto é fornecido "como está" para fins educacionais. Use por sua conta e risco.

