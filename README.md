# SetupRedTam

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Scripts](https://img.shields.io/badge/scripts-31-green)
![Ferramentas](https://img.shields.io/badge/ferramentas-29-orange)
<!-- Badge removido para evitar exposição de dados sensíveis -->
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Kali%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-Educational-yellow)

📑 **[Ver Índice Completo](./INDEX.md)** - Navegação rápida por todo o repositório  
📝 **[Ver Changelog](./CHANGELOG.md)** - Histórico de atualizações

## 🎯 Propósito

Repositório de scripts de automação para configuração rápida de ambientes de **Penetration Testing** e **Red Team Operations**, suportando Windows e Kali Linux.

### 📊 Estatísticas do Repositório

- **Total de arquivos:** 6,900+
- **Tamanho total:** ~312 MB
- **Scripts Windows:** 18 arquivos (Attack Box, bloqueios, verificação)
- **Scripts Kali:** 1 setup principal
- **Scripts Pentest:** 
  - `pentest/pentest_completo.sh` - v4.0 (2145 linhas)
  - `pentest_automatizado.sh` - v3.0 (raiz)
  - `reteste/pentest_automation.py` - Script Python completo
  - `reteste/pentest_all_targets.py` - Múltiplos alvos
- **Scripts SQL Injection:** 1 script profissional (`SQL/sql_injection_automatizado.sh`)
- **Scripts Wi-Fi:** 4 scripts automatizados (`wifi/`)
- **Scripts Reteste:** 7 scripts organizados (`ScrpitPentestSH/retestesh/`) + 5 legacy
- **Bibliotecas:** 5 bibliotecas reutilizáveis (`lib/`)
- **Ferramentas Kali:** 29 toolkits completos (~312MB)
- **Documentação:** 15+ arquivos Markdown profissionais
- **Templates:** 1 template de relatório profissional
<!-- Informação removida para evitar exposição de dados sensíveis -->
- **Linguagens:** Batch, PowerShell, Bash, Python, Ruby, Go
- **Última atualização:** Novembro 2025

## ⚠️ AVISO LEGAL

**Este repositório é destinado EXCLUSIVAMENTE para:**
- Profissionais de segurança cibernética
- Testes de penetração autorizados
- Ambientes de laboratório e educação
- Pesquisa em segurança

**USO RESPONSÁVEL:**
- ❌ NÃO use estas ferramentas em sistemas sem autorização expressa
- ❌ NÃO utilize para atividades ilegais
- ✅ Respeite as leis locais e internacionais de cibersegurança
- ✅ Obtenha permissão por escrito antes de testar qualquer sistema

**O autor não se responsabiliza por uso indevido destes scripts.**

---

## 📁 Estrutura do Repositório

```
Scripts/
├── Kali/                    # Scripts para Kali Linux
│   ├── setup-kali.sh        # Setup completo automatizado
│   ├── setup-notebook1.sh   # Setup Notebook 1 (Stealth Box) ⭐
│   ├── ExecutarSetup-Kali.md
│   ├── README.md            # Documentação Kali
│   └── Ferramentas/         # 29 ferramentas especializadas (~312MB)
│       ├── zphisher/        # Phishing framework (30+ templates)
│       ├── EchoPhish/       # Instagram phishing com 2FA ⭐
│       ├── pupy/            # Cross-platform RAT/C2
│       ├── reconftw/        # Automated reconnaissance
│       ├── SecLists/        # Wordlists profissionais (1GB+)
│       ├── pwndb/           # Breach database search
│       ├── xmr-stak/        # Cryptocurrency miner
│       ├── LeakLooker/      # Open database finder
│       ├── Ares/            # Python RAT framework
│       ├── Crypter/         # Ransomware builder
│       ├── DDos/            # Slowloris Pro DDoS tool
│       ├── HTThief/         # HTTP/HTTPS traffic stealer
│       ├── injector/        # DLL/Shellcode injector
│       ├── buster/          # Brute-force tool
│       ├── Auto_Tor_IP_changer/ # Automatic Tor IP rotation ⭐
│       ├── rce-scanner/     # RCE vulnerability scanner ⭐
│       ├── whatsappsess/    # WhatsApp session hijacking ⭐
│       ├── whatsintruder/   # WhatsApp media collector ⭐
│       ├── zportal/         # 2FA captive portal for M5 Cardputer ⭐
│       ├── webdiscover/     # Web subdomain discovery
│       ├── Scavenger/       # OSINT framework
│       ├── Anon-Check/      # Anonymity checker
│       ├── Proton-VPN-Helper/ # ProtonVPN automation
│       ├── VPN-Chain/       # Multi-VPN chaining
│       ├── Give-me-privacy-Google/ # Google privacy exploitation
│       ├── Building-Malicious-Chrome-Extensions/ # Chrome extension attacks
│       ├── CSRF-to-RCE-on-Backdrop-CMS/ # Backdrop CMS exploit
│       ├── Exploit-XSS-Polyglot-on-Moodle-3.9.2/ # Moodle XSS
│       └── Exploiting-WP-Database-Backup-WordPress-Plugin/ # WordPress exploit
│
├── Windows/                 # Scripts para Windows
│   ├── atack2.0-optimized.bat  # Setup Notebook 2 (AD/Lateral Movement) ⭐
│   ├── setup-attackbox.ps1  # Setup PowerShell (RECOMENDADO)
│   ├── setup_attackbox.bat  # Launcher do setup
│   ├── atack2.0.bat         # Setup completo com WSL2
│   ├── bloqueioAPP.bat      # Bloqueio de aplicativos (ambientes controlados)
│   ├── rollback.bat         # Reverter configurações ⭐
│   ├── verificao.bat        # Verificação pós-instalação
│   ├── setup-debug.bat      # Modo debug para troubleshooting
│   ├── DesbloqueioCompleto.bat # Desfaz bloqueios aplicados
│   ├── BloqueioGeral.bat    # Bloqueio geral de recursos
│   ├── Bloqueiojogos.bat    # Bloqueio específico de jogos
│   ├── DesfazBloqueioAPP.bat # Desfaz bloqueios de aplicativos
│   ├── DesfazBloqueioAPP.ps1 # PowerShell version
│   ├── desfazer_geral.bat   # Desfaz bloqueio geral
│   ├── README.md            # Documentação Windows
│   └── NOTEBOOK2-GUIDE.md   # Guia específico Notebook 2 (i5-3210M) ⭐
│
├── pentest/                 # Scripts de Pentest Profissional ⭐ NOVO!
│   ├── pentest_completo.sh  # Pentest completo v4.0 (2145 linhas)
│   ├── executar_pentest.sh  # Launcher do pentest
│   ├── README.md            # Documentação completa
│   ├── CHECKLIST_PENTEST.md # Checklist profissional
│   └── GUIA_RAPIDO.md       # Guia rápido de uso
│
├── reteste/                 # Scripts de Pentest Automatizado ⭐ NOVO!
│   ├── pentest_automation.py # Script Python completo
│   ├── pentest_all_targets.py # Pentest em múltiplos alvos
│   ├── pentest_all_targets.sh # Versão Shell
│   ├── run_pentest.sh       # Executor de pentest
│   ├── targets_list.txt     # Lista de alvos
│   ├── README_PENTEST.md    # Documentação do script principal
│   ├── README_TODOS_ALVOS.md # Guia para múltiplos alvos
│   ├── INICIO_RAPIDO.md     # Início rápido
│   ├── EXEMPLO_USO.md       # Exemplos de uso
│   └── RESUMO_IMPLEMENTACAO.md # Resumo técnico
│
├── SQL/                     # SQL Injection Automatizado ⭐ NOVO!
│   ├── sql_injection_automatizado.sh # Script profissional
│   ├── README_SQL_INJECTION_AUTOMATIZADO.md # Documentação
│   ├── lib/                  # Bibliotecas auxiliares
│   │   ├── log.sh           # Sistema de logs
│   │   ├── opsec.sh         # Funções OPSEC
│   │   └── sqlmap.sh        # Wrapper SQLMap
│   ├── modules/              # Módulos extras
│   │   └── dump.sh          # Módulo de dump
│   └── result/               # Resultados
│       ├── logs/             # Logs detalhados
│       ├── relatorio/        # Relatórios finais
│       └── dumps/            # Dumps de bancos
│
├── wifi/                     # Scripts Wi-Fi ⭐ NOVO!
│   ├── wifite_auto.sh       # Script automatizado estilo wifite
│   ├── capturar_handshake.sh # Captura de handshake WPA/WPA2
│   ├── bruteforce_wifi.sh   # Brute force automático
│   ├── deauth_rapido.sh     # Ataque deauth rápido
│   ├── README.md            # Documentação completa
│   └── passwords/            # Wordlists de senhas
│
├── lib/                      # Bibliotecas Reutilizáveis ⭐ NOVO!
│   ├── opsec.sh             # Biblioteca OPSEC (10 funções)
│   ├── backup_tools.sh      # Sistema de backup automatizado
│   ├── generate_report.sh   # Gerador de relatórios (Markdown→PDF)
│   ├── install_wazuh.sh     # Instalador Wazuh SIEM
│   └── resource_check.sh    # Verificação de recursos do sistema
│
├── docs/                     # Documentação Profissional ⭐ NOVO!
│   ├── OPSEC_CHECKLIST.md   # Checklist de segurança operacional
│   ├── BACKUP_STRATEGY.md   # Estratégia 3-2-1 de backup
│   └── UPGRADE_GUIDE.md     # Guia de upgrade de hardware
│
├── templates/                # Templates de Relatórios ⭐ NOVO!
│   └── report_template.md   # Template profissional Markdown
│
├── ScrpitPentestSH/          # Scripts de reteste automatizado
│   ├── TESTE_DDOS_CONTROLADO.sh # Teste controlado de DDoS
│   ├── 01_RETESTE_*.sh      # Scripts legacy (raiz)
│   └── retestesh/           # Scripts de reteste organizados
│       ├── executar_todos_retestes.sh # Executa todos os retestes
│       ├── reteste_empresa*.sh # Scripts individuais
│       ├── reteste_ngrok.sh # Reteste específico
│       ├── reteste_with_opsec.sh # Wrapper com OPSEC
│       ├── README.md        # Documentação completa
│       ├── GUIA_RAPIDO.md   # Guia rápido de uso
│       └── INDICE_VULNERABILIDADES.md # Índice de 54 vulnerabilidades
│
├── pentest_automatizado.sh  # Pentest automatizado v3.0 (raiz) ⭐
├── GUIA_COMPLETO_PENTEST.md # Guia completo (~1100 linhas)
├── QUICK_START.md           # Início rápido
├── NOVAS_FUNCIONALIDADES.md # Changelog detalhado
└── README.md                # Este arquivo
```

---

## 🚀 Início Rápido

### **Kali Linux**

#### **Setup Completo (PC2 ou Kali Principal)**

```bash
# 1. Dar permissão de execução
chmod +x Kali/setup-kali.sh

# 2. Executar como root
sudo ./Kali/setup-kali.sh
```

#### **Notebook 1 - Stealth Box** ⭐

```bash
# 1. Dar permissão de execução
chmod +x Kali/setup-notebook1.sh

# 2. Executar como root
sudo ./Kali/setup-notebook1.sh
```

**O que será instalado:**
- Servidores HTTP (Python, Lighttpd, PHP)
- Reverse shell listeners (Netcat, Socat, Ncat, Pwncat)
- SSH e RDP servers
Ferramentas de tunneling (Chisel, Serveo, SSHuttle)
- Geradores de payload (MSFVenom, PayloadsAllTheThings)
- C2 frameworks leves (Sliver, PoshC2)
- Ferramentas de stealth (scans lentos, coleta passiva)
- Phishing (Gophish)
- Scripts auxiliares e aliases

📖 **Guia completo:** [NOTEBOOK1-GUIDE.md](./NOTEBOOK1-GUIDE.md)

**O que será instalado:**
- Meta-pacotes Kali (kali-linux-large)
- Ferramentas de brute-force (Hydra, Medusa, Ncrack)
- Enumeração (Gobuster, BloodHound, SecLists)
- Exploits (Metasploit, ExploitDB, SQLMap)
- Docker + Timeshift + SSH Server
- Otimizações de rede e performance

---

### **Windows**

#### **Opção 1: Notebook 2 - Attack Box Especializada (i5-3210M/12GB)** ⭐

**Focado em Active Directory, Lateral Movement e Post-Exploitation**

```powershell
# Executar como Administrador
.\Windows\atack2.0-optimized.bat
```

**O que será instalado:**
- BloodHound + SharpHound (análise AD)
- Evil-WinRM (lateral movement)
- Rubeus, Certify (Kerberos attacks)
- Seatbelt, WinPEAS (enumeration)
- Donut, ScareCrow, Nimcrypt2 (payload evasion)
- Impacket + Responder
- WSL2 + Kali com CrackMapExec

📖 **Guia completo**: [Windows/NOTEBOOK2-GUIDE.md](./Windows/NOTEBOOK2-GUIDE.md)

---

#### **Opção 2: Setup Completo Genérico**

```powershell
# Executar como Administrador
.\Windows\setup_attackbox.bat
```

**O que será instalado:**
- Chocolatey (gerenciador de pacotes)
- WSL2 + Kali Linux
- Ferramentas essenciais (Nmap, Wireshark, Git, Python, Ruby)
- BloodHound + SharpHound
- Ferramentas AD (Rubeus, Seatbelt, WinPEAS, SharpUp)
- Evil-WinRM
- Impacket
- SSH Server
- Estrutura de diretórios em `C:\Tools\`

#### **Opção 2: Debug Mode**

Se o setup travar ou apresentar erros:

```cmd
.\Windows\setup-debug.bat
```

#### **Opção 3: Verificação Pós-Instalação**

```cmd
.\Windows\verificao.bat
```

Verifica:
- Status do Windows Defender
- Serviço SSH
- Chocolatey
- Ferramentas instaladas
- WSL2 + Kali
- Perfil PowerShell
- Modo de energia

---

## 🛠️ Ferramentas Incluídas

### **🎯 Active Directory (Windows)**
- **BloodHound** - Análise gráfica de relações AD
- **SharpHound** - Coletor de dados AD (C#)
- **Rubeus** - Kerberos exploitation toolkit
- **PowerView** - PowerShell para enum AD
- **Impacket Suite** - Protocolos de rede Windows
- **Certify** - AD Certificate Services exploitation

### **🔓 Post-Exploitation (Windows)**
- **Seatbelt** - Enumeration de segurança Windows
- **WinPEAS** - Privilege escalation automation
- **SharpUp** - Privilege escalation checker
- **SharpMapExec** - Lateral movement framework
- **SharpDPAPI** - DPAPI credential extractor
- **Mimikatz** - Credential dumping (manual)

### **🌐 Networking & Scanning**
- **Nmap** - Network scanner
- **Masscan** - Port scanner massivo
- **Ffuf** - Fast web fuzzer
- **Gobuster** - Directory/DNS/vhost brute-forcer
- **Wireshark** - Packet analyzer

### **💥 Exploitation Frameworks**
- **Metasploit Framework** - Exploitation framework
- **SQLMap** - SQL injection automation
- **ExploitDB** - Exploit database local
- **Veil-Evasion** - Payload obfuscation

### **🎭 Payloads & Evasion (Windows)**
- **Donut** - Shellcode generator (.NET to shellcode)
- **ScareCrow** - Payload obfuscation with EDR evasion
- **Nimcrypt2** - .NET executable encryptor

### **🐧 Ferramentas Kali Linux (29 Toolkits)**

#### **Reconnaissance & OSINT**
- **reconftw** - Automated reconnaissance workflow (subdomain enum, vulnerability scan, screenshots)
- **SecLists** - Wordlists profissionais (1GB+) - Passwords, usernames, DNS, fuzzing
- **webdiscover** - Web subdomain discovery
- **Scavenger** - OSINT framework

#### **Credential & Breach Search**
- **pwndb** - Search leaked credentials via Tor (requer Tor service)
- **LeakLooker** - Find open databases (Elasticsearch, MongoDB, S3 buckets, Jenkins, etc.)

#### **Command & Control (C2)**
- **pupy** - Cross-platform RAT (Windows/Linux/macOS) - In-memory execution, reflective DLL
- **Ares** - Python-based RAT framework

#### **Social Engineering & Phishing**
- **zphisher** - Phishing framework (30+ templates: Instagram, Facebook, Netflix, etc.)
- **EchoPhish** ⭐ **NOVO!** - Instagram phishing avançado com captura de 2FA, cookies e sessões ativas
- **whatsappsess** ⭐ **NOVO!** - WhatsApp session hijacking via phishing com Selenium
- **whatsintruder** ⭐ **NOVO!** - WhatsApp media collector via APK malicioso (Android 6.0+)
- **zportal** ⭐ **NOVO!** - Captive portal 2FA para M5 Cardputer (integração com EchoPhish)
- **Give-me-privacy-Google** - Google privacy exploitation

#### **Web Exploitation**
- **buster** - Advanced web brute-forcer
- **injector** - SQL/XSS/LFI injection automation
- **rce-scanner** ⭐ **NOVO!** - Scanner automatizado de RCE (PHPUnit, ThinkPHP, Laravel, FCKeditor, elFinder)
- **HTThief** - HTTP/HTTPS traffic stealer
- **CSRF-to-RCE-on-Backdrop-CMS** - Backdrop CMS exploit chain
- **Exploit-XSS-Polyglot-on-Moodle-3.9.2** - Moodle XSS polyglot
- **Exploiting-WP-Database-Backup-WordPress-Plugin** - WordPress DB Backup exploit
- **Building-Malicious-Chrome-Extensions** - Chrome extension attack toolkit

#### **Malware & Ransomware**
- **Crypter** - Ransomware builder (educacional)
- **xmr-stak** - Cryptocurrency miner (Monero/RagerX)

#### **DDoS & Network Attacks**
- **DDos (Slowloris Pro)** - Advanced Slowloris DDoS attack (HTTP/HTTPS, proxy support)

#### **Privacy & Anonymity**
- **Auto_Tor_IP_changer** ⭐ **NOVO!** - Rotação automática de IP via Tor com configuração de intervalo
- **Anon-Check** - Anonymity checker
- **Proton-VPN-Helper** - ProtonVPN automation
- **VPN-Chain** - Multi-VPN chaining

---

## 📋 Pré-requisitos

### **Windows**
- Windows 10/11 (versão 1903+)
- Permissões de Administrador
- Conexão com internet
- 20GB+ de espaço livre

### **Kali Linux**
- Kali Linux 2020.1+
- Acesso root
- Conexão com internet
- 30GB+ de espaço livre

---

## 🔧 Configurações Aplicadas (Windows)

### **Segurança**
- ⚠️ Desativa Windows Defender (apenas para ambientes de teste)
- Adiciona exclusões em `C:\Tools`
- Desativa SmartScreen

### **Performance**
- Modo de energia: Alto desempenho
- Desativa hibernação
- Remove serviços desnecessários (DiagTrack, WSearch)

### **Desenvolvimento**
- ExecutionPolicy: Unrestricted
- Perfil PowerShell customizado com aliases
- SSH Server habilitado

---

## 🔄 Rollback / Restauração

**IMPORTANTE:** Os scripts fazem alterações profundas no sistema. Para reverter:

### **Windows**
```powershell
# Reativar Defender
Set-MpPreference -DisableRealtimeMonitoring $false

# Restaurar ExecutionPolicy
Set-ExecutionPolicy Restricted -Scope LocalMachine

# Remover ferramentas
choco uninstall all -y
Remove-Item C:\Tools -Recurse -Force
```

### **Kali Linux**
Use Timeshift (instalado automaticamente) para criar snapshots antes do setup.

---

## 🐛 Troubleshooting

### **Erro: "Script não pode ser carregado"**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### **Chocolatey não encontrado após instalação**
```cmd
refreshenv
# ou reinicie o terminal
```

### **WSL2 falha ao instalar**
1. Certifique-se que virtualização está habilitada na BIOS
2. Execute: `wsl --update`
3. Reinicie o sistema

### **Git clone falha (pasta já existe)**
Os scripts ainda não verificam existência. Delete a pasta manualmente:
```powershell
Remove-Item C:\Tools\<pasta> -Recurse -Force
```

---

## 📚 Documentação Adicional

### **Por Categoria:**

#### **Setup e Configuração:**
- **[Windows/README.md](./Windows/README.md)** - Documentação completa dos scripts Windows
  - Setup Attack Box
  - Scripts de bloqueio/desbloqueio
  - Troubleshooting Windows
  
- **[Windows/NOTEBOOK2-GUIDE.md](./Windows/NOTEBOOK2-GUIDE.md)** - Guia especializado Notebook 2
  - Workflows práticos para AD
  - Comandos de lateral movement
  - Exemplos de uso das ferramentas

- **[NOTEBOOK1-GUIDE.md](./NOTEBOOK1-GUIDE.md)** - Guia completo Notebook 1 (Stealth Box)
  - Configuração de servidores e listeners
  - Tunneling e pivoting
  - Payload generation
  - C2 frameworks leves
  - Workflows práticos

- **[Kali/README.md](./Kali/README.md)** - Documentação completa Kali Linux
  - Setup automatizado
  - Descrição das 29 ferramentas
  - Otimizações aplicadas
  
- **[Kali/ExecutarSetup-Kali.md](./Kali/ExecutarSetup-Kali.md)** - Guia rápido de execução

#### **Pentest e Exploração:**
- **[pentest/README.md](./pentest/README.md)** - Pentest Profissional Completo v4.0
  - 5 fases automatizadas
  - Integração OPSEC
  - Classificação de vulnerabilidades
  - Relatórios profissionais

- **[pentest/CHECKLIST_PENTEST.md](./pentest/CHECKLIST_PENTEST.md)** - Checklist profissional completo
  - Pré-pentest
  - Fases de reconhecimento
  - Exploração e pós-exploração

- **[pentest/GUIA_RAPIDO.md](./pentest/GUIA_RAPIDO.md)** - Guia rápido de uso

- **[reteste/README_PENTEST.md](./reteste/README_PENTEST.md)** - Pentest Automatizado em Múltiplos Alvos
  - Script Python completo
  - 4 fases automatizadas
  - Exemplos de uso

- **[reteste/README_TODOS_ALVOS.md](./reteste/README_TODOS_ALVOS.md)** - Guia para múltiplos alvos
  - Processamento em lote
  - Configuração de alvos
  - Relatórios consolidados

- **[SQL/README_SQL_INJECTION_AUTOMATIZADO.md](./SQL/README_SQL_INJECTION_AUTOMATIZADO.md)** - SQL Injection Automatizado
  - Auditoria e compliance
  - Detecção de WAF
  - Integração Metasploit

#### **Reteste e Validação:**
- **[ScrpitPentestSH/README.md](./ScrpitPentestSH/README.md)** - Scripts de Reteste
  - Visão geral dos scripts
  - Estrutura de diretórios
  - Fluxo de trabalho

- **[ScrpitPentestSH/retestesh/README.md](./ScrpitPentestSH/retestesh/README.md)** - Retestes Organizados
  - Documentação detalhada de cada script
  - Descrição de vulnerabilidades
  - Exemplos de uso

- **[ScrpitPentestSH/retestesh/GUIA_RAPIDO.md](./ScrpitPentestSH/retestesh/GUIA_RAPIDO.md)** - Guia rápido
  - Comandos essenciais
  - Tabela de referência
  - Troubleshooting

- **[ScrpitPentestSH/retestesh/INDICE_VULNERABILIDADES.md](./ScrpitPentestSH/retestesh/INDICE_VULNERABILIDADES.md)** - Índice de Vulnerabilidades
  - Lista consolidada de 54 vulnerabilidades
  - Organizado por alvo
  - Níveis de criticidade

#### **Wi-Fi:**
- **[wifi/README.md](./wifi/README.md)** - Scripts Wi-Fi Automatizados
  - Captura de handshake
  - Brute force automático
  - Scripts auxiliares

#### **Bibliotecas e Utilitários:**
- **[docs/OPSEC_CHECKLIST.md](./docs/OPSEC_CHECKLIST.md)** - Checklist OPSEC
  - 15 verificações essenciais
  - Pré-engagement
  - Segurança operacional

- **[docs/BACKUP_STRATEGY.md](./docs/BACKUP_STRATEGY.md)** - Estratégia de Backup
  - Regra 3-2-1
  - Automação completa
  - Prioridades e métodos

- **[docs/UPGRADE_GUIDE.md](./docs/UPGRADE_GUIDE.md)** - Guia de Upgrade
  - Prioridades de hardware
  - Custos e ROI
  - Recomendações

#### **Guias Gerais:**
- **[GUIA_COMPLETO_PENTEST.md](./GUIA_COMPLETO_PENTEST.md)** - Guia Completo de Pentest (~1100 linhas)
  - Metodologia completa
  - Ferramentas e técnicas
  - Workflows práticos

- **[QUICK_START.md](./QUICK_START.md)** - Início Rápido
  - Começar em 5 minutos
  - Comandos essenciais
  - Primeiros passos

- **[NOVAS_FUNCIONALIDADES.md](./NOVAS_FUNCIONALIDADES.md)** - Changelog Detalhado
  - Todas as novas funcionalidades
  - Histórico de atualizações
  - Melhorias implementadas

---

## 🤝 Contribuindo

Melhorias são bem-vindas! Para contribuir:

1. Fork o repositório
2. Crie uma branch: `git checkout -b feature/melhoria`
3. Commit suas mudanças: `git commit -am 'Adiciona nova feature'`
4. Push: `git push origin feature/melhoria`
5. Abra um Pull Request

---

## 📄 Licença

Este projeto é fornecido "como está", sem garantias. Use por sua conta e risco.

---

## 👤 Autor

**Samuel Ziger**
- GitHub: [@Samuel-Ziger](https://github.com/Samuel-Ziger)

---

## 🌐 Recursos Externos Úteis

### **Documentação de Ferramentas**
- [BloodHound Documentation](https://bloodhound.readthedocs.io/) - Análise de Active Directory
- [Impacket GitHub](https://github.com/fortra/impacket) - Suite de protocolos Windows
- [Evil-WinRM Wiki](https://github.com/Hackplayers/evil-winrm/wiki) - WinRM shell
- [Metasploit Unleashed](https://www.metasploit.com/unleashed) - Curso gratuito de Metasploit

### **Wordlists e Payloads**
- [SecLists](https://github.com/danielmiessler/SecLists) - Wordlists profissionais
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) - Repositório de payloads
- [FuzzDB](https://github.com/fuzzdb-project/fuzzdb) - Patterns para fuzzing

### **Privilege Escalation**
- [PEASS-ng](https://github.com/carlospolop/PEASS-ng) - WinPEAS/LinPEAS
- [GTFOBins](https://gtfobins.github.io/) - Unix binaries para bypass
- [LOLBAS](https://lolbas-project.github.io/) - Living Off The Land Binaries

### **Active Directory**
- [HackTricks - AD](https://book.hacktricks.xyz/windows-hardening/active-directory-methodology) - Metodologia AD
- [WADComs](https://wadcoms.github.io/) - Comandos AD interativos
- [AD Security](https://adsecurity.org/) - Blog especializado

### **Cheat Sheets**
- [HackTricks](https://book.hacktricks.xyz/) - Enciclopédia de hacking
- [Red Team Notes](https://www.ired.team/) - Red team techniques
- [NetSec Focus](https://netsec.ws/?p=337) - OSCP cheatsheet

---

## 🔐 Segurança e Privacidade

- Nunca armazene credenciais nos scripts
- Use ambientes isolados (VMs/containers)
- Mantenha ferramentas atualizadas
- Audite regularmente seu ambiente de testes

---

## 🔍 Scripts de Pentest e Reteste

### **pentest/** - Pentest Profissional Completo v4.0 ⭐

Script profissional de penetration testing que executa todas as etapas de um pentest completo de forma automatizada.

**Recursos:**
- ✅ **5 fases automatizadas:** Reconhecimento → Scanning → Enumeração → Exploração → Relatório
- ✅ **Integração OPSEC:** Verificação pré-engagement automática
- ✅ **Rotação Tor:** Suporte a rotação automática de IP via Tor
- ✅ **+20 ferramentas integradas:** Nmap, Nikto, SQLMap, Hydra, Gobuster, WPScan, etc.
- ✅ **Classificação de vulnerabilidades:** Crítica, Alta, Média, Baixa, Info
- ✅ **Relatório completo:** Markdown com estatísticas e evidências

**Uso:**
```bash
cd pentest
sudo ./pentest_completo.sh -t target.com
sudo ./pentest_completo.sh -t target.com --tor --intensity max
```

**Documentação:**
- `README.md` - Documentação completa (449 linhas)
- `CHECKLIST_PENTEST.md` - Checklist profissional
- `GUIA_RAPIDO.md` - Guia rápido de uso

---

### **reteste/** - Pentest Automatizado em Múltiplos Alvos ⭐

Scripts Python e Shell para executar pentest automatizado em múltiplos alvos sequencialmente.

**Recursos:**
- ✅ **Pentest em múltiplos alvos:** Processa lista de alvos automaticamente
- ✅ **4 fases:** OSINT → Infraestrutura → Detecção → Exploração (opcional)
- ✅ **Ferramentas integradas:** WHOIS, DNS, Sublist3r, Amass, TheHarvester, Nmap, Nikto, Gobuster, FFuF, SSLyze
- ✅ **Relatórios por fase:** Relatórios separados para cada fase
- ✅ **Modo não-invasivo:** Opção de pular fase de exploração

**Uso:**
```bash
cd reteste
python3 pentest_all_targets.py
# ou
./pentest_all_targets.sh
```

**Documentação:**
- `README_PENTEST.md` - Documentação do script principal
- `README_TODOS_ALVOS.md` - Guia para múltiplos alvos
- `INICIO_RAPIDO.md` - Início rápido
- `EXEMPLO_USO.md` - Exemplos práticos

---

### **SQL/** - SQL Injection Automatizado Profissional ⭐

Script profissional para testes automatizados de SQL Injection com auditoria, OPSEC e logs corporativos.

**Recursos:**
- ✅ **Auditoria completa:** Exige arquivo digital de autorização
- ✅ **Múltiplos alvos:** Suporte a arquivo de escopo com múltiplas URLs
- ✅ **Detecção de WAF:** Detecção e bypass automático
- ✅ **Integração Metasploit:** Pós-exploração opcional
- ✅ **Logs corporativos:** JSONL, CSV, logs detalhados
- ✅ **Dumps automáticos:** Exportação de bancos e credenciais

**Uso:**
```bash
cd SQL
sudo ./sql_injection_automatizado.sh
```

**Documentação:**
- `README_SQL_INJECTION_AUTOMATIZADO.md` - Guia completo

---

### **wifi/** - Scripts Wi-Fi Automatizados ⭐

Scripts automatizados para captura e quebra de handshake WPA/WPA2.

**Scripts disponíveis:**
- ✅ **wifite_auto.sh** - Script completamente automatizado estilo wifite
- ✅ **capturar_handshake.sh** - Captura de handshake WPA/WPA2
- ✅ **bruteforce_wifi.sh** - Brute force automático testando múltiplas wordlists
- ✅ **deauth_rapido.sh** - Ataque deauth rápido

**Uso:**
```bash
cd wifi
sudo ./wifite_auto.sh
# ou
sudo ./capturar_handshake.sh
```

**Documentação:**
- `README.md` - Documentação completa com exemplos

---

### **lib/** - Bibliotecas Reutilizáveis ⭐

Bibliotecas de funções para uso em scripts de pentest e automação.

**Bibliotecas disponíveis:**
- ✅ **opsec.sh** - 10 funções de segurança operacional (VPN check, DNS leak, rate limiting, etc.)
- ✅ **backup_tools.sh** - Sistema de backup automatizado (estratégia 3-2-1)
- ✅ **generate_report.sh** - Gerador de relatórios profissionais (Markdown→PDF)
- ✅ **install_wazuh.sh** - Instalador Wazuh SIEM via Docker
- ✅ **resource_check.sh** - Verificação de recursos do sistema (CPU, RAM, Disco)

**Uso:**
```bash
# Importar biblioteca OPSEC
source lib/opsec.sh
check_vpn
check_dns_leak

# Verificar recursos
source lib/resource_check.sh
check_cpu
check_ram
```

**Documentação:**
- `docs/OPSEC_CHECKLIST.md` - Checklist completo de OPSEC
- `docs/BACKUP_STRATEGY.md` - Estratégia de backup detalhada

---

### **docs/** - Documentação Profissional ⭐

Documentação completa para operações profissionais de pentest.

**Documentos disponíveis:**
- ✅ **OPSEC_CHECKLIST.md** - Checklist pré-engagement (15 verificações essenciais)
- ✅ **BACKUP_STRATEGY.md** - Estratégia 3-2-1 de backup com automação
- ✅ **UPGRADE_GUIDE.md** - Guia de upgrade de hardware

---

### **templates/** - Templates de Relatórios ⭐

Templates profissionais para geração de relatórios.

**Templates disponíveis:**
- ✅ **report_template.md** - Template Markdown profissional para relatórios de pentest

**Uso:**
```bash
# Gerar relatório PDF
source lib/generate_report.sh
generate_report templates/report_template.md relatorio_final.pdf
```

---

### **ScrpitPentestSH/** - Scripts de Reteste Automatizado

Diretório contendo scripts especializados para testes de penetração e retestes de vulnerabilidades.

#### **Scripts de Reteste Automatizado**

Localizado em `ScrpitPentestSH/retestesh/`, contém scripts bash para validação de correções de vulnerabilidades de forma genérica e segura.

**Uso rápido:**
```bash
cd ScrpitPentestSH/retestesh
chmod +x executar_todos_retestes.sh
./executar_todos_retestes.sh
```

**Recursos:**
- ✅ Relatórios automáticos com timestamp
- ✅ Códigos de cores para status
- ✅ Verificação de HTTP status codes
- ✅ Testes de headers de segurança
- ✅ Scan de portas e serviços
- ✅ Validação TLS/SSL
- ✅ Índice de 54 vulnerabilidades

**Documentação:**
- `README.md` - Documentação detalhada de cada script
- `GUIA_RAPIDO.md` - Início rápido e troubleshooting
- `INDICE_VULNERABILIDADES.md` - Lista consolidada de 54 vulnerabilidades

#### **Scripts de Reteste (Raiz)**

Scripts na raiz de `ScrpitPentestSH/` (versão legacy):
- `01_RETESTE_ADIVISAO.sh`
- `02_RETESTE_DIVISAODEELITE.sh`
- `03_RETESTE_ACHEUMVETERANO.sh`
- `04_RETESTE_IDIVIS.sh`
- `05_RETESTE_PLANODECHAMADAS.sh`

**Nota:** Use os scripts em `retestesh/` que estão mais atualizados.

#### **Teste de DDoS Controlado**

- `TESTE_DDOS_CONTROLADO.sh` - Script para testes controlados de stress em servidores autorizados

⚠️ **IMPORTANTE:** Todos os scripts de pentest devem ser usados apenas em ambientes autorizados!

---

## 🆕 **NOVIDADES - Atualização 28/11/2025** ⭐

### **🚀 PENTEST PROFISSIONAL COMPLETO v4.0** - Enterprise Level 🔥
✅ **Pentest completo automatizado** - 2145 linhas de código profissional  
✅ **5 fases automatizadas:** Reconhecimento → Scanning → Enumeração → Exploração → Relatório  
✅ **Rotação automática de IP via Tor** - Suporte completo a anonimato  
✅ **Integração OPSEC completa** - Checklist pré-engagement automático  
✅ **+20 ferramentas integradas:** Nmap, Nikto, SQLMap, Hydra, Gobuster, WPScan, etc.  
✅ **Classificação de vulnerabilidades:** Crítica, Alta, Média, Baixa, Info  
✅ **Relatório completo Markdown:** Sumário executivo + evidências detalhadas  
📖 **Script:** `pentest/pentest_completo.sh`  
📖 **Documentação:** `pentest/README.md` (449 linhas)  
📖 **Checklist:** `pentest/CHECKLIST_PENTEST.md`  

**Uso:**
```bash
cd pentest
sudo ./pentest_completo.sh -t target.com
sudo ./pentest_completo.sh -t target.com --tor --intensity max
```

---

### **🚀 PENTEST AUTOMATIZADO v3.0** - Múltiplos Alvos 🔥
✅ **Pentest em múltiplos alvos** - Processa lista de alvos automaticamente  
✅ **4 fases:** OSINT → Infraestrutura → Detecção → Exploração (opcional)  
✅ **Ferramentas integradas:** WHOIS, DNS, Sublist3r, Amass, TheHarvester, Nmap, Nikto, Gobuster, FFuF, SSLyze  
✅ **Relatórios por fase:** Relatórios separados para cada fase  
✅ **Modo não-invasivo:** Opção de pular fase de exploração  
📖 **Scripts:** `reteste/pentest_automation.py`, `reteste/pentest_all_targets.py`  
📖 **Documentação:** `reteste/README_PENTEST.md`  

**Uso:**
```bash
cd reteste
python3 pentest_all_targets.py
```

---

### **💉 SQL INJECTION AUTOMATIZADO** - Profissional ⭐
✅ **Auditoria completa** - Exige arquivo digital de autorização  
✅ **Múltiplos alvos** - Suporte a arquivo de escopo  
✅ **Detecção de WAF** - Detecção e bypass automático  
✅ **Integração Metasploit** - Pós-exploração opcional  
✅ **Logs corporativos** - JSONL, CSV, logs detalhados  
✅ **Dumps automáticos** - Exportação de bancos e credenciais  
📖 **Script:** `SQL/sql_injection_automatizado.sh`  
📖 **Documentação:** `SQL/README_SQL_INJECTION_AUTOMATIZADO.md`  

---

### **📡 SCRIPTS WI-FI AUTOMATIZADOS** ⭐
✅ **wifite_auto.sh** - Script completamente automatizado estilo wifite  
✅ **capturar_handshake.sh** - Captura de handshake WPA/WPA2  
✅ **bruteforce_wifi.sh** - Brute force automático com múltiplas wordlists  
✅ **deauth_rapido.sh** - Ataque deauth rápido  
📖 **Documentação:** `wifi/README.md` (507 linhas)  

---

### **🔒 Biblioteca OPSEC** - Segurança Operacional
✅ **10 funções de segurança** para pentests (VPN check, DNS leak, rate limiting, etc.)  
✅ **Checklist pré-engagement** - 15 verificações essenciais  
📖 **Guia completo:** `docs/OPSEC_CHECKLIST.md`  
📖 **Script:** `lib/opsec.sh`  

---

### **💾 Sistema de Backup Automatizado**
✅ **Estratégia 3-2-1** - 3 cópias, 2 mídias, 1 offsite  
✅ **Backup de ferramentas, VMs, scripts e wordlists**  
✅ **Limpeza automática** de backups antigos (>30 dias)  
✅ **Verificação de integridade**  
📖 **Estratégia completa:** `docs/BACKUP_STRATEGY.md`  
📖 **Script:** `lib/backup_tools.sh`  

---

### **🖥️ Verificação de Recursos**
✅ **Detecção automática** de PC1, PC2, NB1, NB2  
✅ **Verifica CPU/RAM/Disco/SWAP** antes de operações pesadas  
✅ **Sugestões de otimização** personalizadas  
📖 **Script:** `lib/resource_check.sh`  

---

### **📄 Gerador de Relatórios Profissionais**
✅ **Markdown → PDF automático** (via Pandoc)  
✅ **Templates profissionais** incluídos  
✅ **Conversão HTML** também disponível  
📖 **Template:** `templates/report_template.md`  
📖 **Script:** `lib/generate_report.sh`  

---

### **📊 Wazuh SIEM**
✅ **Logging centralizado** via Docker  
✅ **Dashboard web profissional**  
✅ **Threat detection + Compliance**  
📖 **Script:** `lib/install_wazuh.sh`  

---

### **📚 Documentação Profissional**
✅ **Guia Completo de Penetration Testing** - ~1100 linhas, passo a passo completo  
✅ **Guia de Upgrade de Hardware** - Prioridades, custos, ROI  
✅ **Estratégia 3-2-1 de Backup** - Automação completa  
✅ **Checklist OPSEC** - 15 verificações essenciais  
📁 **Tudo em:** `docs/` + raiz do projeto  

---

**👉 Pentest Completo v4.0:** `pentest/pentest_completo.sh`  
**👉 Pentest Automatizado v3.0:** `pentest_automatizado.sh`  
**👉 Pentest Múltiplos Alvos:** `reteste/pentest_all_targets.py`  
**👉 SQL Injection:** `SQL/sql_injection_automatizado.sh`  
**👉 Wi-Fi:** `wifi/wifite_auto.sh`  
**👉 Guia Completo:** `GUIA_COMPLETO_PENTEST.md`  
**👉 Detalhes completos:** `NOVAS_FUNCIONALIDADES.md`  
**👉 Começar em 5 min:** `QUICK_START.md`  

---

**Última atualização:** 28 de Novembro de 2025

