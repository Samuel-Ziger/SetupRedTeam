# Kali Linux - Scripts de Setup

## 📋 Visão Geral

Script de automação completa para configuração de Kali Linux como plataforma profissional de Penetration Testing.

### 🎯 Análise do Repositório Kali

**Estatísticas:**
- **Script principal:** 1 (setup-kali.sh)
- **Ferramentas incluídas:** 22 toolkits completos
- **Tamanho total:** ~310 MB
- **Categorias:** C2, Recon, Web Exploitation, OSINT, Malware, Privacy
- **Linguagens:** Bash, Python, C/C++, Go

**Destaques:**
- ✅ **pupy** - RAT profissional com execução in-memory
- ✅ **reconftw** - Automação completa de reconnaissance (50+ ferramentas integradas)
- ✅ **SecLists** - Wordlists mais completas da indústria (1GB+)
- ✅ **LeakLooker** - Encontra databases expostas (Elasticsearch, MongoDB, S3)
- ✅ **pwndb** - Busca credenciais vazadas via Tor
- ✅ **zphisher** - 30+ templates de phishing prontos

---

## 📁 Estrutura

```
Kali/
├── setup-kali.sh              # Script principal de setup
├── ExecutarSetup-Kali.md      # Guia de execução
├── README.md                  # Documentação (este arquivo)
└── Ferramentas/               # 22 toolkits completos (~305MB)
    ├── zphisher/              # Phishing framework
    ├── pupy/                  # Cross-platform RAT
    ├── reconftw/              # Automated reconnaissance
    ├── SecLists/              # Wordlists profissionais (1GB+)
    ├── pwndb/                 # Breach database search
    ├── xmr-stak/              # Cryptocurrency miner
    ├── LeakLooker/            # Open database finder
    ├── Ares/                  # Python RAT framework
    ├── Crypter/               # Ransomware builder
    ├── HTThief/               # HTTP/HTTPS traffic stealer
    ├── injector/              # DLL/Shellcode injector
    ├── buster/                # Advanced brute-forcer
    ├── webdiscover/           # Subdomain discovery
    ├── Scavenger/             # OSINT framework
    ├── Anon-Check/            # Anonymity checker
    ├── Proton-VPN-Helper/     # ProtonVPN automation
    ├── VPN-Chain/             # Multi-VPN chaining
    ├── Give-me-privacy-Google/             # Google privacy exploitation
    ├── Building-Malicious-Chrome-Extensions/ # Chrome extension attacks
    ├── CSRF-to-RCE-on-Backdrop-CMS/        # Backdrop CMS exploit
    ├── Exploit-XSS-Polyglot-on-Moodle-3.9.2/ # Moodle XSS
    └── Exploiting-WP-Database-Backup-WordPress-Plugin/ # WordPress exploit
```

---

## 🚀 Como Usar

### **1. Dar Permissão de Execução**

```bash
chmod +x setup-kali.sh
```

### **2. Executar como Root**

```bash
sudo ./setup-kali.sh
```

### **3. Aguardar Conclusão**

⏱️ Tempo estimado: **45-90 minutos** (dependendo da conexão)

### **4. Reiniciar o Sistema**

```bash
sudo reboot
```

---

## 🛠️ O Que Será Instalado

### **1. Meta-Pacotes Kali**
```bash
kali-linux-large    # Conjunto completo de ferramentas
```

> **Alternativa:** Para instalação completa (⚠️ ~15GB):
> ```bash
> # Edite o script e descomente:
> sudo apt install kali-linux-everything -y
> ```

### **2. Otimizações de Sistema**

- **CPU**: Performance máxima via `cpufrequtils`
- **Rede**: Parâmetros otimizados para scans (`net.ipv4.ip_forward`, `fs.file-max`)
- **Limites de arquivos**: Aumentados para suportar scans massivos

### **3. Ferramentas de Brute-Force**

| Ferramenta | Uso |
|------------|-----|
| Hydra | Brute-force multi-protocolo (SSH, FTP, HTTP, etc.) |
| Medusa | Brute-force paralelo |
| Ncrack | Network authentication cracker |

### **4. Enumeração e Reconhecimento**

| Ferramenta | Uso |
|------------|-----|
| Gobuster | Directory/DNS/vhost fuzzing |
| SecLists | Wordlists profissionais (~1GB) |
| BloodHound | Análise de Active Directory |
| bloodhound.py | Coletor remoto para BloodHound |
| Ffuf | Fast web fuzzer |
| Masscan | Port scanner massivo |

### **5. Ferramentas de Web Hacking**

| Ferramenta | Uso |
|------------|-----|
| SQLMap | SQL injection automático |
| WPScan | WordPress security scanner (via apt + gem) |

### **6. Exploitation**

| Ferramenta | Uso |
|------------|-----|
| Metasploit Framework | Exploitation framework |
| ExploitDB | Database de exploits locais |
| Veil-Evasion | Payload obfuscation |

### **7. Ferramentas de Rede**

```bash
net-tools           # ifconfig, netstat, etc.
netcat-traditional  # Swiss-army knife de rede
```

### **8. Desenvolvimento**

| Ferramenta | Uso |
|------------|-----|
| Golang | Compilar ferramentas Go |
| Kerbrute | Kerberos enumeration/bruteforce |
| Docker | Containerização de ferramentas |

### **9. Infraestrutura**

```bash
OpenSSH Server      # Acesso remoto
Timeshift           # Snapshots do sistema (backup)
```

---

## 📂 Diretórios Criados

O script cria automaticamente uma estrutura organizada em `~/`:

```
~/recon/            # Dados de reconhecimento
~/exploit/          # Exploits e PoCs
~/bruteforce/       # Wordlists customizadas e resultados
~/enum/             # Outputs de enumeração
~/loot/             # Credenciais e dados sensíveis capturados
~/wordlists/        # SecLists (clonado do GitHub)
```

---

## ⚙️ Otimizações Aplicadas

### **CPU**
```bash
cpufreq-set -g performance
```
Força CPU em modo de alto desempenho (útil para cracking).

### **Rede**
```bash
net.ipv4.ip_forward = 1          # Ativa roteamento IP
net.core.somaxconn = 65535       # Aumenta queue de conexões
fs.file-max = 100000             # Permite mais arquivos abertos
```

### **SecLists**
Baixa automaticamente o repositório completo (~1GB):
```bash
~/wordlists/SecLists/
├── Discovery/
├── Fuzzing/
├── Passwords/
├── Usernames/
└── ...
```

---

## 🔧 Personalização do Script

### **Instalar Tudo (kali-linux-everything)**

Edite o arquivo `setup-kali.sh` e modifique a linha:

```bash
# Linha 15-16 (aproximadamente)
sudo apt install kali-linux-large -y

# Substitua por:
sudo apt install kali-linux-everything -y
```

⚠️ **Atenção:** Requer **15GB+ de espaço** e pode demorar **2-3 horas**.

### **Adicionar Ferramentas Customizadas**

Adicione antes da seção final:

```bash
echo "[12] Instalando <SUA_FERRAMENTA>..."
sudo apt install <nome_do_pacote> -y
```

---

## 📊 Verificação Pós-Instalação

### **1. Verificar Serviços**

```bash
# SSH
sudo systemctl status ssh

# Docker
sudo systemctl status docker
```

### **2. Testar Ferramentas**

```bash
# Nmap
nmap --version

# Metasploit
msfconsole -v

# Gobuster
gobuster version

# Kerbrute (Go)
~/go/bin/kerbrute --help
```

### **3. Verificar Diretórios**

```bash
ls -la ~/ | grep -E "recon|exploit|enum|loot"
ls ~/wordlists/SecLists/
```

---

## 🐛 Troubleshooting

### **Erro: "Permission denied"**

```bash
chmod +x setup-kali.sh
sudo ./setup-kali.sh
```

### **Erro: "Unable to locate package"**

```bash
sudo apt update
sudo apt full-upgrade -y
```

### **Git clone falha (SecLists)**

```bash
cd ~/wordlists
rm -rf SecLists
git clone https://github.com/danielmiessler/SecLists.git
```

### **Kerbrute não encontrado após instalação**

```bash
# Adicione ao PATH no ~/.bashrc ou ~/.zshrc
echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### **Docker não inicia**

```bash
sudo systemctl enable docker --now
sudo usermod -aG docker $USER
# Logout e login novamente
```

---

## 🔄 Atualizações e Manutenção

### **Atualizar Sistema e Ferramentas**

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y
```

### **Atualizar SecLists**

```bash
cd ~/wordlists/SecLists
git pull
```

### **Atualizar Metasploit**

```bash
sudo msfupdate
```

---

## 💡 Dicas de Uso

### **1. Criar Snapshot com Timeshift**

Antes de começar testes importantes:

```bash
sudo timeshift --create --comments "Pre-engagement snapshot"
```

### **2. Usar Docker para Ferramentas Isoladas**

```bash
# Exemplo: Rodar SQLMap em container
docker run -it --rm paoloo/sqlmap -u "http://target.com?id=1"
```

### **3. Organização de Engagements**

```bash
# Criar estrutura por cliente
mkdir -p ~/engagements/ClienteX/{recon,exploit,loot,reports}
cd ~/engagements/ClienteX
```

---

## ⚠️ Avisos Importantes

1. **Use apenas em ambientes autorizados** - Nunca em sistemas sem permissão
2. **Mantenha o sistema atualizado** - `sudo apt update && sudo apt upgrade`
3. **Crie snapshots regularmente** - Use Timeshift
4. **SecLists ocupa ~1GB** - Certifique-se de ter espaço
5. **Execução pode demorar 45-90 minutos** - Dependendo da conexão

---

## 📚 Recursos Adicionais

- [Kali Linux Documentation](https://www.kali.org/docs/)
- [SecLists GitHub](https://github.com/danielmiessler/SecLists)
- [Metasploit Unleashed](https://www.metasploit.com/unleashed)
- [HackTricks](https://book.hacktricks.xyz/)
- [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)

---

## 🔐 Ferramentas Incluídas no Diretório Ferramentas/

### **🎣 Social Engineering & Phishing**

#### **zphisher**
- **Descrição:** Framework de phishing automatizado com 30+ templates prontos
- **Templates:** Instagram, Facebook, Netflix, PayPal, Google, Microsoft, Steam, etc.
- **Recursos:** Servidor web integrado, captura de credenciais, compatível com Ngrok/LocalXpose
- **⚠️ USO EDUCACIONAL APENAS!** Nunca use contra alvos reais sem autorização

```bash
cd Ferramentas/zphisher
bash zphisher.sh
```

---

### **🎯 Command & Control (C2) / RATs**

#### **pupy**
- **Descrição:** RAT multiplataforma escrito em Python (Windows/Linux/macOS/Android)
- **Recursos:**
  - Execução 100% em memória (não toca o disco)
  - Reflective DLL injection (Windows)
  - Migração entre processos
  - Import remoto de módulos Python
  - Múltiplos transportes (HTTP, DNS, WebSocket, SSL)
- **Uso:** Post-exploitation, C2 operations
- **Linguagens:** Python, C

```bash
cd Ferramentas/pupy
# Instalação via pipx (ver README)
```

#### **Ares**
- **Descrição:** Python-based Remote Access Trojan framework
- **Recursos:** Reverse shell, keylogger, screenshot, file transfer
- **Uso:** Red team operations, educacional
- **Linguagem:** Python

---

### **🔍 Reconnaissance & OSINT**

#### **reconftw**
- **Descrição:** Framework de reconhecimento totalmente automatizado
- **Módulos:**
  - Subdomain enumeration (passive + bruteforce + permutations)
  - Vulnerability scanning (XSS, SQLi, SSRF, CRLF, Open Redirects)
  - Port scanning (Nmap integration)
  - Screenshot automation
  - Directory fuzzing
  - Nuclei integration
- **Uso:** Bug bounty, penetration testing
- **Tecnologias:** Bash, integra 50+ ferramentas

```bash
cd Ferramentas/reconftw
./reconftw.sh -d target.com -a
```

#### **SecLists**
- **Descrição:** Coleção massiva de wordlists profissionais (~1GB)
- **Categorias:**
  - **Passwords:** Rockyou, leaked databases, common passwords
  - **Usernames:** 10 million+ usernames
  - **Discovery:** DNS, directories, web-content
  - **Fuzzing:** Payloads XSS, SQLi, LFI, Command injection
  - **Pattern matching:** Regex, file extensions
- **Uso:** Brute-force, fuzzing, content discovery
- **Tamanho:** ~1.2 GB

```bash
# Já clonado em ~/wordlists/SecLists/
ls Ferramentas/SecLists/
```

#### **webdiscover**
- **Descrição:** Web reconnaissance e subdomain discovery
- **Recursos:** Passive DNS, certificate transparency, web scraping
- **Uso:** Subdomain enumeration

#### **Scavenger**
- **Descrição:** OSINT framework multi-purpose
- **Recursos:** Email harvesting, social media profiling, metadata extraction
- **Uso:** Information gathering

---

### **🔓 Credential & Breach Search**

#### **pwndb**
- **Descrição:** Busca credenciais vazadas via Tor (database de breaches)
- **Requisitos:** Tor service rodando (porta 9050/9150)
- **Uso:** Verificar se emails/domínios foram comprometidos
- **Linguagem:** Python

```bash
cd Ferramentas/pwndb
# Inicie o Tor primeiro
sudo systemctl start tor
python3 pwndb.py --target email@example.com
```

#### **LeakLooker**
- **Descrição:** Encontra databases/serviços abertos na internet (powered by BinaryEdge API)
- **Suporta:**
  - Elasticsearch, MongoDB, CouchDB
  - Amazon S3 buckets abertos
  - Gitlab, Jenkins, Sonarqube expostos
  - Rsync, Kibana, Cassandra, RethinkDB
  - Directory listing
- **Requisitos:** BinaryEdge API key
- **Uso:** Bug bounty, security research

```bash
cd Ferramentas/LeakLooker
# Configure API key no código
python3 leaklooker.py
```

---

### **🌐 Web Exploitation**

#### **buster**
- **Descrição:** Advanced web brute-force tool
- **Recursos:** Directory fuzzing, login brute-force, custom wordlists
- **Uso:** Web pentesting

#### **injector**
- **Descrição:** Multi-purpose injection tool
- **Tipos:** SQL injection, XSS, LFI, command injection
- **Uso:** Web application testing

#### **HTThief**
- **Descrição:** HTTP/HTTPS traffic interceptor e credential stealer
- **Recursos:** Man-in-the-middle, SSL stripping, credential capture
- **Uso:** Network attacks, pentesting

#### **CSRF-to-RCE-on-Backdrop-CMS**
- **Descrição:** Exploit chain para Backdrop CMS
- **Vulnerabilidade:** CSRF leading to RCE
- **Uso:** CMS exploitation research

#### **Exploit-XSS-Polyglot-on-Moodle-3.9.2**
- **Descrição:** XSS polyglot payload para Moodle 3.9.2
- **Tipo:** Stored XSS
- **Uso:** Educational platform testing

#### **Exploiting-WP-Database-Backup-WordPress-Plugin**
- **Descrição:** Exploit para WordPress Database Backup plugin
- **Vulnerabilidade:** Arbitrary file download/RCE
- **Uso:** WordPress security auditing

#### **Building-Malicious-Chrome-Extensions**
- **Descrição:** Toolkit para criar extensões maliciosas do Chrome
- **Recursos:** Data exfiltration, keylogging, session hijacking
- **Uso:** Browser security research

---

### **💀 Malware & Cryptography**

#### **Crypter**
- **Descrição:** Ransomware builder e crypter (educacional)
- **⚠️ USO EDUCACIONAL APENAS!**
- **Recursos:** File encryption, custom ransom notes
- **Linguagem:** Python/C++

#### **xmr-stak**
- **Descrição:** Cryptocurrency miner (Monero/RandomX)
- **Recursos:** CPU/GPU mining, pool support
- **Uso:** Cryptocurrency mining (legal use only)
- **Algoritmos:** RandomX, CryptoNight

```bash
cd Ferramentas/xmr-stak
# Compilação necessária (ver README)
```

---

### **🔒 Privacy & Anonymity**

#### **Anon-Check**
- **Descrição:** Verifica nível de anonimato da conexão
- **Testa:** DNS leaks, WebRTC leaks, IP exposure, browser fingerprinting
- **Uso:** Validar VPN/Tor/Proxy

#### **Proton-VPN-Helper**
- **Descrição:** Scripts de automação para ProtonVPN
- **Recursos:** Auto-connect, server switching, kill-switch
- **Uso:** VPN automation

#### **VPN-Chain**
- **Descrição:** Conecta múltiplas VPNs em cadeia
- **Recursos:** Multi-hop connections, increased anonymity
- **Uso:** Advanced privacy

#### **Give-me-privacy-Google**
- **Descrição:** Explora vazamentos de privacidade do Google
- **Recursos:** Data extraction, tracking analysis
- **Uso:** Privacy research

---

## 📊 Resumo das Ferramentas por Categoria

| Categoria | Quantidade | Ferramentas Principais |
|-----------|------------|------------------------|
| **Social Engineering** | 1 | zphisher |
| **C2/RATs** | 2 | pupy, Ares |
| **Reconnaissance** | 4 | reconftw, SecLists, webdiscover, Scavenger |
| **Credentials** | 2 | pwndb, LeakLooker |
| **Web Exploitation** | 7 | buster, injector, HTThief, CSRF-to-RCE, Moodle XSS, WP exploit, Chrome extensions |
| **Malware/Crypto** | 2 | Crypter, xmr-stak |
| **Privacy** | 4 | Anon-Check, Proton-VPN-Helper, VPN-Chain, Give-me-privacy-Google |
| **TOTAL** | **22 toolkits** | **~310 MB** |

---

## 🔐 Ferramentas de Phishing (zphisher)

**⚠️ USO EDUCACIONAL APENAS!**

O diretório `Ferramentas/zphisher/` contém um framework de phishing.

**NUNCA use contra alvos reais sem autorização expressa.**

Para executar:
```bash
cd Ferramentas/zphisher
bash zphisher.sh
```

---

**Última atualização:** Novembro 2025
