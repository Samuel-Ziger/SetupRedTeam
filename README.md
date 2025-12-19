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
- **Scripts Windows:** 18 arquivos
  - 4 scripts principais (setup-attackbox.ps1, atack2.0-optimized.bat, atack2.0.bat, setup-notebook2.ps1)
  - 10 scripts auxiliares (verificação, debug, bloqueios, desbloqueios)
  - 2 scripts descontinuados (SetupAtack.bat, SetupAtack2.bat)
  - 2 documentações (README.md, NOTEBOOK2-GUIDE.md)
- **Scripts Kali:** 2 scripts de setup
  - `setup-kali.sh` - Setup completo automatizado
  - `setup-notebook1.sh` - Setup Notebook 1 (Stealth Box)
- **Scripts Pentest:** 
  - `pentest/pentest_completo.sh` - v4.0 (2145 linhas)
  - `pentest_automatizado.sh` - v3.0 (raiz)
  - `reteste/pentest_automation.py` - Script Python completo
  - `reteste/pentest_all_targets.py` - Múltiplos alvos
  - `reteste/pentest_all_targets.sh` - Versão Shell
  - `reteste/run_pentest.sh` - Executor de pentest
- **Scripts SQL Injection:** 1 script profissional + 3 bibliotecas auxiliares
  - `SQL/sql_injection_automatizado.sh` - Script principal
  - `SQL/lib/log.sh`, `SQL/lib/opsec.sh`, `SQL/lib/sqlmap.sh` - Bibliotecas
  - `SQL/modules/dump.sh` - Módulo de dump
- **Scripts Wi-Fi:** 4 scripts automatizados (`wifi/`)
  - `wifite_auto.sh` - Script automatizado estilo wifite
  - `capturar_handshake.sh` - Captura de handshake
  - `bruteforce_wifi.sh` - Brute force automático
  - `deauth_rapido.sh` - Ataque deauth rápido
- **Análise de Malware:** 3 scripts Python (`BotNet/scripts/`)
  - `analisar_config.py` - Análise de configurações
  - `gerar_iocs.py` - Geração de IOCs
  - `analisar_comportamento.py` - Análise de comportamento
- **Pentest Autônomo:** 12 scripts de exploração (`Kali/PentestAutonomo2.0/`)
  - 7 scripts exploit_*.sh (mysql, ssh, ftp, joomla, email, dns, all)
  - 5 scripts ataque_*.sh (geral, mysql, ssh, smtp, joomla)
- **Scripts Reteste:** 7 scripts organizados + 1 script mestre (`ScrpitPentestSH/retestesh/`)
  - `executar_todos_retestes.sh` - Script mestre que executa todos
  - `reteste_empresa1.sh` até `reteste_empresa5.sh` - Scripts individuais
  - `reteste_ngrok.sh` - Reteste específico ngrok
  - `reteste_with_opsec.sh` - Wrapper com OPSEC
  - 5 scripts legacy na raiz (`01_RETESTE_*.sh` até `05_RETESTE_*.sh`)
  - `TESTE_DDOS_CONTROLADO.sh` - Teste de DDoS controlado
- **Bibliotecas:** 5 bibliotecas reutilizáveis (`lib/`)
  - `opsec.sh` - Segurança operacional (10 funções)
  - `backup_tools.sh` - Sistema de backup automatizado
  - `generate_report.sh` - Gerador de relatórios (Markdown→PDF)
  - `install_wazuh.sh` - Instalador Wazuh SIEM
  - `resource_check.sh` - Verificação de recursos do sistema
- **Ferramentas Kali:** 29 toolkits completos (~312MB)
  - Social Engineering & Phishing (5): zphisher, EchoPhish, whatsappsess, whatsintruder, zportal
  - C2/RATs (2): pupy, Ares
  - Reconnaissance (4): reconftw, SecLists, webdiscover, Scavenger
  - Credentials (2): pwndb, LeakLooker
  - Web Exploitation (8): buster, injector, rce-scanner, HTThief, CSRF-to-RCE, XSS-Polyglot, WP-exploit, Chrome-extensions
  - Malware/Crypto (2): Crypter, xmr-stak
  - DDoS (1): DDos (Slowloris Pro)
  - Privacy/Anonymity (5): Auto_Tor_IP_changer, Anon-Check, Proton-VPN-Helper, VPN-Chain, Give-me-privacy-Google
- **Documentação:** 20+ arquivos Markdown profissionais
  - Guias principais: README.md, INDEX.md, CHANGELOG.md, QUICK_START.md, GUIA_COMPLETO_PENTEST.md
  - Análises: ANALISE_CODIGO.md, ANALISE_PROJETO_COMPLETA.md, IMPLEMENTACAO_COMPLETA.md
  - Documentação por módulo: Windows/README.md, Kali/README.md, pentest/README.md, etc.
- **Templates:** 1 template de relatório profissional (`templates/report_template.md`)
- **Rubber Ducky:** 3 arquivos (`Rubber ducky/`)
  - `autorun.inf` - Autoexecução
  - `detect_pendrive.bat` - Detecção de pendrive
  - `payload.bat` - Payload principal
- **Linguagens:** Batch (.bat), PowerShell (.ps1), Bash (.sh), Python (.py), Ruby, Go, C/C++
- **Última atualização:** Dezembro 2025

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
│   ├── PentestAutonomo2.0/  # Scripts de Exploração Autônoma ⭐ NOVO!
│   │   ├── exploit_all.sh  # Executa todos os scripts de exploração
│   │   ├── exploit_mysql.sh # Exploração MySQL
│   │   ├── exploit_ssh.sh  # Exploração SSH
│   │   ├── exploit_ftp.sh  # Exploração FTP
│   │   ├── exploit_joomla.sh # Exploração Joomla CMS
│   │   ├── exploit_email.sh # Exploração de serviços de email
│   │   ├── exploit_dns.sh  # Exploração DNS
│   │   ├── ataque_geral.sh  # Ataque geral
│   │   ├── ataque_mysql.sh # Ataque MySQL
│   │   ├── ataque_ssh.sh   # Ataque SSH
│   │   ├── ataque_smtp.sh  # Ataque SMTP
│   │   ├── ataque_joomla.sh # Ataque Joomla
│   │   └── README.md        # Documentação completa
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
├── Windows/                 # Scripts para Windows (18 arquivos)
│   ├── setup-notebook2.ps1  # Setup Notebook 2 COMPLETO PowerShell (MAIS RECOMENDADO) ⭐
│   ├── setup-notebook2.bat  # Launcher para setup-notebook2.ps1
│   ├── atack2.0-optimized.bat  # Setup Notebook 2 Batch (AD/Lateral Movement) ⭐
│   ├── setup-attackbox.ps1  # Setup PowerShell genérico (RECOMENDADO)
│   ├── setup_attackbox.bat  # Launcher do setup PowerShell
│   ├── atack2.0.bat         # Setup completo com WSL2
│   ├── rollback.bat         # Reverter configurações ⭐
│   ├── verificao.bat        # Verificação pós-instalação
│   ├── setup-debug.bat      # Modo debug para troubleshooting
│   ├── bloqueioAPP.bat      # Bloqueio de aplicativos (ambientes controlados)
│   ├── BloqueioGeral.bat    # Bloqueio geral de recursos
│   ├── Bloqueiojogos.bat    # Bloqueio específico de jogos
│   ├── bloqueio_escola.bat  # Bloqueio específico para ambientes escolares
│   ├── DesbloqueioCompleto.bat # Desfaz todos os bloqueios aplicados
│   ├── DesfazBloqueioAPP.bat # Desfaz bloqueios de aplicativos
│   ├── DesfazBloqueioAPP.ps1 # PowerShell version
│   ├── desfazer_geral.bat   # Desfaz bloqueio geral
│   ├── desfazer_bloqueio_escola.bat # Desfaz bloqueio escolar
│   ├── bloqueio/            # Scripts de bloqueio organizados
│   │   ├── bloqueio_escola.bat
│   │   ├── desfazer_bloqueio_escola.bat
│   │   ├── restringir_instalacao.bat
│   │   └── desfazer_restringir_instalacao.bat
│   ├── SetupAtack.bat       # ⚠️ DESCONTINUADO (use atack2.0.bat)
│   ├── SetupAtack2.bat      # ⚠️ DESCONTINUADO (use atack2.0.bat)
│   ├── README.md            # Documentação completa Windows
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
├── BotNet/                   # Análise de Malware ⭐ NOVO!
│   ├── darkddoser/          # Malware DarkDDoSer (educacional)
│   │   └── DarkDDoSer/      # Executável e configurações
│   ├── scripts/             # Scripts de análise Python
│   │   ├── analisar_config.py # Análise de configurações INI
│   │   ├── gerar_iocs.py    # Geração de IOCs (YARA, Sigma)
│   │   └── analisar_comportamento.py # Análise de comportamento
│   ├── ANALISE_TECNICA.md   # Análise técnica detalhada
│   ├── README_ANALISE.md    # Documentação de análise
│   ├── README.md            # Visão geral
│   └── requirements.txt     # Dependências Python
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
│   ├── README.md            # Overview dos scripts de pentest
│   ├── 01_RETESTE_ADIVISAO.sh # Script legacy (raiz)
│   ├── 01_RETESTE_EMPRESA1.sh # Script legacy (raiz)
│   ├── 02_RETESTE_EMPRESA2.sh # Script legacy (raiz)
│   ├── 03_RETESTE_.sh       # Script legacy (raiz)
│   ├── 03_RETESTE_EMPRESA3.sh # Script legacy (raiz)
│   ├── 04_RETESTE_EMPRESA4.sh # Script legacy (raiz)
│   ├── 04_RETESTE_IDIVIS.sh # Script legacy (raiz)
│   ├── 05_RETESTE_EMPRESA5.sh # Script legacy (raiz)
│   └── retestesh/           # Scripts de reteste organizados ⭐ RECOMENDADO
│       ├── executar_todos_retestes.sh # Script mestre - executa todos ⭐
│       ├── reteste_empresa1.sh # Reteste adivisao.com.br (10 vulns)
│       ├── reteste_empresa2.sh # Reteste divisaodeelite.com.br (11 vulns)
│       ├── reteste_empresa3.sh # Reteste acheumveterano.com.br (8 vulns)
│       ├── reteste_empresa4.sh # Reteste idivis.ao (11 vulns)
│       ├── reteste_empresa5.sh # Reteste planodechamadas.com.br (9 vulns)
│       ├── reteste_ngrok.sh # Reteste ngrok URL (5 vulns)
│       ├── reteste_with_opsec.sh # Wrapper com OPSEC
│       ├── README.md        # Documentação completa (405 linhas)
│       ├── GUIA_RAPIDO.md   # Guia rápido de uso
│       └── INDICE_VULNERABILIDADES.md # Índice de 54 vulnerabilidades
│
├── Rubber ducky/            # Scripts Rubber Ducky ⭐
│   ├── autorun.inf          # Autoexecução
│   ├── detect_pendrive.bat  # Detecção de pendrive
│   └── payload.bat          # Payload principal
│
├── pentest_automatizado.sh  # Pentest automatizado v3.0 (raiz) ⭐
├── INDEX.md                 # Índice completo de navegação
├── CHANGELOG.md             # Histórico de atualizações
├── GUIA_COMPLETO_PENTEST.md # Guia completo (~1100 linhas)
├── QUICK_START.md           # Início rápido
├── NOVAS_FUNCIONALIDADES.md # Changelog detalhado
├── NOTEBOOK2_COMPLETO.md    # Guia completo Notebook 2 (raiz)
├── ANALISE_CODIGO.md        # Análise de código
├── ANALISE_PROJETO_COMPLETA.md # Análise completa do projeto
├── IMPLEMENTACAO_COMPLETA.md # Implementação completa
├── git_push_update.bat      # Script de atualização Git
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

**O que será instalado (Notebook 1 - Stealth Box):**
- Servidores HTTP (Python, Lighttpd, PHP)
- Reverse shell listeners (Netcat, Socat, Ncat, Pwncat)
- SSH e RDP servers
- Ferramentas de tunneling (Chisel, Serveo, SSHuttle)
- Geradores de payload (MSFVenom, PayloadsAllTheThings)
- C2 frameworks leves (Sliver, PoshC2)
- Ferramentas de stealth (scans lentos, coleta passiva)
- Phishing (Gophish)
- Scripts auxiliares e aliases

📖 **Guia completo:** [NOTEBOOK1-GUIDE.md](./NOTEBOOK1-GUIDE.md) (verificar se existe)

**O que será instalado (Setup Completo - PC2/Kali Principal):**
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

**Recomendado - PowerShell:**
```powershell
# Executar como Administrador
.\Windows\setup-notebook2.ps1
# ou via launcher
.\Windows\setup-notebook2.bat
```

**Alternativa - Batch:**
```cmd
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

📖 **Guias completos:**
- [NOTEBOOK2_COMPLETO.md](./NOTEBOOK2_COMPLETO.md) - Guia completo na raiz (detalhado)
- [Windows/NOTEBOOK2-GUIDE.md](./Windows/NOTEBOOK2-GUIDE.md) - Guia rápido local

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

#### **Opção 3: Setup Notebook 2 PowerShell Completo** ⭐ **MAIS RECOMENDADO**

```powershell
# Executar como Administrador
.\Windows\setup-notebook2.ps1
# ou via launcher
.\Windows\setup-notebook2.bat
```

**O que será instalado:**
- Todas as ferramentas do Notebook 2 otimizado
- Instalação mais robusta e com melhor tratamento de erros
- Verificação de duplicatas (não baixa ferramentas já existentes)
- Mensagens informativas em português

📖 **Guia completo:** [NOTEBOOK2_COMPLETO.md](./NOTEBOOK2_COMPLETO.md) (raiz) ou [Windows/NOTEBOOK2-GUIDE.md](./Windows/NOTEBOOK2-GUIDE.md)

#### **Opção 4: Debug Mode**

Se o setup travar ou apresentar erros:

```cmd
.\Windows\setup-debug.bat
```

#### **Opção 5: Verificação Pós-Instalação**

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

- **[NOTEBOOK1-GUIDE.md](./NOTEBOOK1-GUIDE.md)** - Guia completo Notebook 1 (Stealth Box) ⚠️ Verificar se existe
  - Configuração de servidores e listeners
  - Tunneling e pivoting
  - Payload generation
  - C2 frameworks leves
  - Workflows práticos

- **[NOTEBOOK2_COMPLETO.md](./NOTEBOOK2_COMPLETO.md)** - Guia completo Notebook 2 (raiz)
  - Explicação detalhada de cada ferramenta
  - Workflows práticos para AD
  - Comandos de lateral movement
  - Exemplos de uso das ferramentas

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

#### **Análise de Malware:**
- **[BotNet/README_ANALISE.md](./BotNet/README_ANALISE.md)** - Kit de Análise DarkDDoSer
  - Scripts Python de análise
  - Geração de IOCs (YARA, Sigma)
  - Análise de configurações e comportamento
  - Guia completo de uso

- **[BotNet/ANALISE_TECNICA.md](./BotNet/ANALISE_TECNICA.md)** - Análise Técnica Detalhada
  - Análise profunda do malware
  - Comportamento e técnicas
  - Recomendações de mitigação

#### **Pentest Autônomo:**
- **[Kali/PentestAutonomo2.0/README.md](./Kali/PentestAutonomo2.0/README.md)** - Scripts de Exploração Autônoma
  - 12 scripts de exploração autônoma
  - Múltiplas áreas de ataque (MySQL, SSH, FTP, Joomla, Email, DNS)
  - Execução autônoma completa
  - Logging e relatórios consolidados

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

### **BotNet/** - Análise de Malware ⭐

Kit de análise educacional para o malware **DarkDDoSer** - DDoS botnet.

**⚠️ AVISO:** Este projeto é destinado **EXCLUSIVAMENTE** para pesquisa em segurança cibernética, educação em análise de malware e desenvolvimento de defesas. O uso não autorizado de malware é ILEGAL.

**Recursos:**
- ✅ **Análise de configurações** - Extrai e analisa arquivos INI do malware
- ✅ **Geração de IOCs** - Gera regras YARA, Sigma e lista de IOCs
- ✅ **Análise de comportamento** - Analisa comportamento esperado do malware
- ✅ **Documentação técnica** - Análise técnica detalhada do malware

**Scripts Python disponíveis:**
- ✅ **analisar_config.py** - Analisa arquivos de configuração (login.ini, settings.ini)
- ✅ **gerar_iocs.py** - Gera IOCs em múltiplos formatos (YARA, Sigma, JSON)
- ✅ **analisar_comportamento.py** - Analisa comportamento de rede, sistema de arquivos e processos

**Uso:**
```bash
cd BotNet
# Instalar dependências
pip install -r requirements.txt

# Analisar configurações
python scripts/analisar_config.py

# Gerar IOCs
python scripts/gerar_iocs.py

# Analisar comportamento
python scripts/analisar_comportamento.py
```

**Saídas geradas:**
- `analise_config.json` - Relatório de configurações
- `iocs/darkddoser.yara` - Regra YARA para detecção
- `iocs/darkddoser.yml` - Regra Sigma para SIEM
- `iocs/iocs.json` - Lista completa de IOCs
- `analise_comportamento.json` - Relatório de comportamentos

**Documentação:**
- `README_ANALISE.md` - Guia completo de análise
- `ANALISE_TECNICA.md` - Análise técnica detalhada do malware

---

### **Kali/PentestAutonomo2.0/** - Scripts de Exploração Autônoma ⭐

Scripts autônomos e agressivos de exploração de segurança para testes de penetração autorizados.

**⚠️ AVISO LEGAL:** Estes scripts são para uso **APENAS** em ambientes autorizados e para fins de teste de penetração legal. O uso não autorizado é ilegal e pode resultar em consequências criminais.

**Recursos:**
- ✅ **Execução autônoma completa** - Verificam e instalam ferramentas automaticamente
- ✅ **Múltiplas áreas de ataque** - MySQL, SSH, FTP, Joomla, Email, DNS, Web
- ✅ **Agressividade configurável** - Múltiplas threads para brute force
- ✅ **Pós-exploração automática** - Tentativas automáticas de pós-exploração
- ✅ **Logging detalhado** - Logs completos de todas as fases
- ✅ **Relatórios consolidados** - Relatório final com todos os resultados

**Scripts disponíveis:**
- ✅ **exploit_all.sh** - Executa todos os scripts de exploração sequencialmente
- ✅ **exploit_mysql.sh** - Exploração MySQL (brute force, CVE-2012-2122, extração de dados)
- ✅ **exploit_ssh.sh** - Exploração SSH (brute force, enumeração, backdoors)
- ✅ **exploit_ftp.sh** - Exploração FTP (brute force, login anônimo, enumeração)
- ✅ **exploit_joomla.sh** - Exploração Joomla CMS (brute force admin, SQLi, LFI/RFI)
- ✅ **exploit_email.sh** - Exploração de serviços de email (POP3, IMAP, SMTP)
- ✅ **exploit_dns.sh** - Exploração DNS (enumeração, zone transfer, recursão)
- ✅ **ataque_geral.sh** - Ataque geral multi-serviço
- ✅ **ataque_mysql.sh** - Ataque específico MySQL
- ✅ **ataque_ssh.sh** - Ataque específico SSH
- ✅ **ataque_smtp.sh** - Ataque específico SMTP
- ✅ **ataque_joomla.sh** - Ataque específico Joomla

**Uso:**
```bash
cd Kali/PentestAutonomo2.0

# Executar todos os ataques
sudo ./exploit_all.sh exemplo.com.br 192.168.1.100

# Executar ataque específico
sudo ./exploit_mysql.sh exemplo.com.br 192.168.1.100
sudo ./exploit_ssh.sh exemplo.com.br 192.168.1.100
sudo ./exploit_dns.sh exemplo.com.br
```

**Ferramentas utilizadas:**
- Nmap, Hydra, SQLMap, Nikto, Gobuster, Dirb, Metasploit, DNSenum, DNSrecon, Joomscan

**Estrutura de saída:**
- `logs/` - Logs detalhados de cada fase
- `results/` - Credenciais, vulnerabilidades, arquivos extraídos
- `results/consolidated_report.txt` - Relatório consolidado final

**Documentação:**
- `README.md` - Documentação completa (223 linhas)

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

#### **Scripts de Reteste Automatizado** ⭐ **RECOMENDADO**

Localizado em `ScrpitPentestSH/retestesh/`, contém scripts bash para validação de correções de vulnerabilidades de forma genérica e segura.

**Scripts disponíveis (7 scripts + 1 mestre):**
- ✅ **executar_todos_retestes.sh** - Script mestre que executa todos os retestes sequencialmente ⭐
- ✅ **reteste_empresa1.sh** - adivisao.com.br (10 vulnerabilidades)
- ✅ **reteste_empresa2.sh** - divisaodeelite.com.br (11 vulnerabilidades)
- ✅ **reteste_empresa3.sh** - acheumveterano.com.br (8 vulnerabilidades)
- ✅ **reteste_empresa4.sh** - idivis.ao / 31.97.27.219 (11 vulnerabilidades)
- ✅ **reteste_empresa5.sh** - planodechamadas.com.br (9 vulnerabilidades)
- ✅ **reteste_ngrok.sh** - ngrok URL (5 vulnerabilidades)
- ✅ **reteste_with_opsec.sh** - Wrapper com OPSEC

**Total:** 54 vulnerabilidades rastreadas em 6 alvos

**Uso rápido:**
```bash
cd ScrpitPentestSH/retestesh
chmod +x executar_todos_retestes.sh
./executar_todos_retestes.sh
```

**Recursos:**
- ✅ Relatórios automáticos com timestamp
- ✅ Códigos de cores para status (🔴 Crítico, 🟡 Médio, 🟢 OK)
- ✅ Verificação de HTTP status codes
- ✅ Testes de headers de segurança
- ✅ Scan de portas e serviços
- ✅ Validação TLS/SSL
- ✅ Índice completo de 54 vulnerabilidades

**Documentação:**
- `README.md` - Documentação detalhada de cada script (405 linhas)
- `GUIA_RAPIDO.md` - Início rápido e troubleshooting
- `INDICE_VULNERABILIDADES.md` - Lista consolidada de 54 vulnerabilidades

#### **Scripts de Reteste (Raiz)** - Legacy

Scripts na raiz de `ScrpitPentestSH/` (versão legacy - não recomendado):
- `01_RETESTE_ADIVISAO.sh` / `01_RETESTE_EMPRESA1.sh`
- `02_RETESTE_EMPRESA2.sh`
- `03_RETESTE_.sh` / `03_RETESTE_EMPRESA3.sh`
- `04_RETESTE_EMPRESA4.sh` / `04_RETESTE_IDIVIS.sh`
- `05_RETESTE_EMPRESA5.sh`

**Nota:** Use sempre os scripts em `retestesh/` que estão mais atualizados e organizados.

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

### **🛡️ ANÁLISE DE MALWARE - DarkDDoSer** ⭐
✅ **Kit de análise educacional** - Análise completa do malware DarkDDoSer  
✅ **3 scripts Python** - Análise de configurações, geração de IOCs, análise de comportamento  
✅ **Geração de IOCs** - YARA, Sigma e JSON  
✅ **Análise técnica detalhada** - Documentação completa do malware  
📖 **Scripts:** `BotNet/scripts/`  
📖 **Documentação:** `BotNet/README_ANALISE.md`, `BotNet/ANALISE_TECNICA.md`  

⚠️ **USO EDUCACIONAL APENAS!** Destinado exclusivamente para pesquisa e desenvolvimento de defesas.

---

### **⚡ PENTEST AUTÔNOMO 2.0** - Exploração Autônoma ⭐
✅ **12 scripts de exploração autônoma** - Execução completamente autônoma  
✅ **Múltiplas áreas de ataque** - MySQL, SSH, FTP, Joomla, Email, DNS, Web  
✅ **Execução agressiva** - Múltiplas threads, brute force intensivo  
✅ **Pós-exploração automática** - Tentativas automáticas de pós-exploração  
✅ **Logging detalhado** - Logs completos de todas as fases  
✅ **Relatórios consolidados** - Relatório final com todos os resultados  
📖 **Scripts:** `Kali/PentestAutonomo2.0/`  
📖 **Documentação:** `Kali/PentestAutonomo2.0/README.md` (223 linhas)  

⚠️ **USO APENAS EM AMBIENTES AUTORIZADOS!** O uso não autorizado é ilegal.

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

---

## 🦆 Rubber Ducky Scripts

Scripts para uso com dispositivos USB Rubber Ducky ou similares.

**⚠️ AVISO LEGAL:** Use apenas em sistemas próprios ou com autorização explícita!

**Arquivos disponíveis:**
- ✅ **autorun.inf** - Configuração de autoexecução
- ✅ **detect_pendrive.bat** - Script de detecção de pendrive
- ✅ **payload.bat** - Payload principal

**Uso:**
1. Copie os arquivos para o dispositivo USB
2. Configure o `autorun.inf` conforme necessário
3. Execute apenas em ambientes autorizados

**⚠️ IMPORTANTE:** Estes scripts são para fins educacionais e testes autorizados apenas!

---

**Última atualização:** 18 de Dezembro de 2025

