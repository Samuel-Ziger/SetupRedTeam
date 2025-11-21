# Kali Linux - Scripts de Setup

## 📋 Visão Geral

Script de automação completa para configuração de Kali Linux como plataforma profissional de Penetration Testing.

---

## 📁 Estrutura

```
Kali/
├── setup-kali.sh              # Script principal de setup
├── ExecutarSetup-Kali.md      # Guia de execução
└── Ferramentas/
    └── zphisher/              # Ferramenta de phishing (educacional)
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
