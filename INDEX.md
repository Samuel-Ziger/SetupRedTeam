# 📑 Índice Completo - Scripts-Bat

Navegação rápida por todo o repositório.

---

## 📂 Estrutura Principal

```
Scripts-Bat/
├── 📄 README.md (Você está aqui)
├── 📄 INDEX.md (Este arquivo)
│
├── 🐧 Kali/                    (Scripts Linux)
├── 🪟 Windows/                 (Scripts Windows)
└── 🔐 ScrpitPentestSH/         (Scripts de Pentest)
```

---

## 🐧 Kali Linux

### **Documentação**
- [Kali/README.md](./Kali/README.md) - Documentação completa
- [Kali/ExecutarSetup-Kali.md](./Kali/ExecutarSetup-Kali.md) - Guia de execução
- [NOTEBOOK1-GUIDE.md](./NOTEBOOK1-GUIDE.md) - Guia completo Notebook 1 ⭐

### **Scripts**
- `setup-kali.sh` - Setup automatizado completo
- `setup-notebook1.sh` - Setup Notebook 1 (Stealth Box) ⭐

### **Ferramentas (29 toolkits)**

#### Social Engineering & Phishing (5)
- [zphisher/](./Kali/Ferramentas/zphisher/) - Framework de phishing (30+ templates)
- [EchoPhish/](./Kali/Ferramentas/EchoPhish/) - Instagram phishing + 2FA ⭐
- [whatsappsess/](./Kali/Ferramentas/whatsappsess/) - WhatsApp session hijacking ⭐
- [whatsintruder/](./Kali/Ferramentas/whatsintruder/) - WhatsApp media collector ⭐
- [zportal/](./Kali/Ferramentas/zportal/) - Captive portal 2FA M5 Cardputer ⭐

#### C2 / RATs (2)
- [pupy/](./Kali/Ferramentas/pupy/) - Cross-platform RAT
- [Ares/](./Kali/Ferramentas/Ares/) - Python RAT framework

#### Reconnaissance (4)
- [reconftw/](./Kali/Ferramentas/reconftw/) - Automated reconnaissance
- [SecLists/](./Kali/Ferramentas/SecLists/) - Wordlists profissionais (1GB+)
- [webdiscover/](./Kali/Ferramentas/webdiscover/) - Subdomain discovery
- [Scavenger/](./Kali/Ferramentas/Scavenger/) - OSINT framework

#### Credentials (2)
- [pwndb/](./Kali/Ferramentas/pwndb/) - Breach database search
- [LeakLooker/](./Kali/Ferramentas/LeakLooker/) - Open database finder

#### Web Exploitation (8)
- [buster/](./Kali/Ferramentas/buster/) - Advanced brute-forcer
- [injector/](./Kali/Ferramentas/injector/) - Multi-purpose injection
- [rce-scanner/](./Kali/Ferramentas/rce-scanner/) - RCE vulnerability scanner ⭐
- [HTThief/](./Kali/Ferramentas/HTThief/) - HTTP/HTTPS traffic stealer
- [CSRF-to-RCE-on-Backdrop-CMS/](./Kali/Ferramentas/CSRF-to-RCE-on-Backdrop-CMS/)
- [Exploit-XSS-Polyglot-on-Moodle-3.9.2/](./Kali/Ferramentas/Exploit-XSS-Polyglot-on-Moodle-3.9.2/)
- [Exploiting-WP-Database-Backup-WordPress-Plugin/](./Kali/Ferramentas/Exploiting-WP-Database-Backup-WordPress-Plugin/)
- [Building-Malicious-Chrome-Extensions/](./Kali/Ferramentas/Building-Malicious-Chrome-Extensions/)

#### Malware / Crypto (2)
- [Crypter/](./Kali/Ferramentas/Crypter/) - Ransomware builder
- [xmr-stak/](./Kali/Ferramentas/xmr-stak/) - Cryptocurrency miner

#### DDoS (1)
- [DDos/](./Kali/Ferramentas/DDos/) - Slowloris Pro

#### Privacy & Anonymity (5)
- [Auto_Tor_IP_changer/](./Kali/Ferramentas/Auto_Tor_IP_changer/) - Tor IP rotation ⭐
- [Anon-Check/](./Kali/Ferramentas/Anon-Check/) - Anonymity checker
- [Proton-VPN-Helper/](./Kali/Ferramentas/Proton-VPN-Helper/) - ProtonVPN automation
- [VPN-Chain/](./Kali/Ferramentas/VPN-Chain/) - Multi-VPN chaining
- [Give-me-privacy-Google/](./Kali/Ferramentas/Give-me-privacy-Google/) - Google privacy exploitation

---

## 🪟 Windows

### **Documentação**
- [Windows/README.md](./Windows/README.md) - Documentação completa
- [Windows/NOTEBOOK2-GUIDE.md](./Windows/NOTEBOOK2-GUIDE.md) - Guia Notebook 2 (i5-3210M)

### **Scripts Principais**
| Script | Função | Hardware |
|--------|--------|----------|
| `atack2.0-optimized.bat` | Setup Notebook 2 - AD/Lateral Movement ⭐ | i5-3210M/12GB |
| `setup-attackbox.ps1` | Setup PowerShell genérico (RECOMENDADO) | Qualquer |
| `setup_attackbox.bat` | Launcher PowerShell | Qualquer |
| `atack2.0.bat` | Setup completo com WSL2 | Qualquer |

### **Scripts Auxiliares**
| Script | Função |
|--------|--------|
| `rollback.bat` | Reverter configurações ⭐ |
| `verificao.bat` | Verificação pós-instalação |
| `setup-debug.bat` | Modo debug |

### **Scripts de Bloqueio** (Ambientes Controlados)
| Script | Função |
|--------|--------|
| `bloqueioAPP.bat` | Bloquear aplicativos específicos |
| `BloqueioGeral.bat` | Bloqueio geral de recursos |
| `Bloqueiojogos.bat` | Bloquear jogos |
| `DesbloqueioCompleto.bat` | Remover todos os bloqueios |
| `DesfazBloqueioAPP.bat` / `.ps1` | Remover bloqueio de apps |
| `desfazer_geral.bat` | Remover bloqueio geral |

### **Scripts Descontinuados**
- `SetupAtack.bat` (substituído por atack2.0.bat)
- `SetupAtack2.bat` (substituído por atack2.0.bat)

---

## 🔐 Scripts de Pentest

### **Documentação**
- [ScrpitPentestSH/README.md](./ScrpitPentestSH/README.md) - Overview dos scripts
- [ScrpitPentestSH/retestesh/README.md](./ScrpitPentestSH/retestesh/README.md) - Documentação completa
- [ScrpitPentestSH/retestesh/GUIA_RAPIDO.md](./ScrpitPentestSH/retestesh/GUIA_RAPIDO.md) - Início rápido
- [ScrpitPentestSH/retestesh/INDICE_VULNERABILIDADES.md](./ScrpitPentestSH/retestesh/INDICE_VULNERABILIDADES.md) - 54 vulnerabilidades

### **Scripts de Reteste (retestesh/) ✅ RECOMENDADO**
| Script | Alvo | Vulnerabilidades |
|--------|------|------------------|
| `executar_todos_retestes.sh` | **TODOS** | **54 vulns** ⭐ |
| `reteste_adivisao.sh` | adivisao.com.br | 10 vulns |
| `reteste_divisaodeelite.sh` | divisaodeelite.com.br | 11 vulns |
| `reteste_acheumveterano.sh` | acheumveterano.com.br | 8 vulns |
| `reteste_idivis.sh` | idivis.ao / 31.97.27.219 | 11 vulns |
| `reteste_planodechamadas.sh` | planodechamadas.com.br | 9 vulns |
| `reteste_ngrok.sh` | ngrok URL | 5 vulns |

### **Scripts Legacy (raiz)**
- `01_RETESTE_ADIVISAO.sh`
- `02_RETESTE_DIVISAODEELITE.sh`
- `03_RETESTE_ACHEUMVETERANO.sh`
- `04_RETESTE_IDIVIS.sh`
- `05_RETESTE_PLANODECHAMADAS.sh`

### **Outros**
- `TESTE_DDOS_CONTROLADO.sh` - Teste de stress controlado

---

## 🎯 Alvos Monitorados (Pentest)

1. **adivisao.com.br** - 10 vulnerabilidades
   - Tokens expostos, Elasticsearch, CORS, endpoint /fileupload
   
2. **divisaodeelite.com.br** - 11 vulnerabilidades
   - Plugin malicioso railway.app, Bubble token, ausência CSP
   
3. **acheumveterano.com.br** - 8 vulnerabilidades
   - OpenSSH 10.0p2 (CVEs), wp-app.log exposto, WordPress
   
4. **idivis.ao (31.97.27.219)** - 11 vulnerabilidades
   - Porta 3000 Next.js dev, arquivos sensíveis, backups
   
5. **planodechamadas.com.br** - 9 vulnerabilidades
   - Exposição IP real, Next.js sem segurança, headers
   
6. **0fc5d3bbe18c.ngrok-free.app** - 5 vulnerabilidades
   - Headers de segurança ausentes

**Total:** 54 vulnerabilidades rastreadas

---

## 🚀 Quick Start

### **Setup Kali Linux**
```bash
cd Kali
chmod +x setup-kali.sh
sudo ./setup-kali.sh
```

### **Setup Notebook 1 (Stealth Box)** ⭐
```bash
cd Kali
chmod +x setup-notebook1.sh
sudo ./setup-notebook1.sh
```

### **Setup Windows Attack Box**
```powershell
# Como Administrador
.\Windows\setup_attackbox.bat
```

### **Setup Notebook 2 (i5-3210M)**
```cmd
# Como Administrador
.\Windows\atack2.0-optimized.bat
```

### **Executar Todos os Retestes**
```bash
cd ScrpitPentestSH/retestesh
chmod +x executar_todos_retestes.sh
./executar_todos_retestes.sh
```

### **Reteste Individual**
```bash
cd ScrpitPentestSH/retestesh
./reteste_adivisao.sh
```

---

## 📊 Estatísticas Gerais

- **Total de arquivos:** 6,900+
- **Tamanho total:** ~312 MB
- **Scripts Windows:** 18 arquivos
- **Scripts Kali:** 1 setup principal
- **Scripts Pentest:** 13 scripts
- **Ferramentas Kali:** 29 toolkits
- **Vulnerabilidades rastreadas:** 54
- **Alvos monitorados:** 6

---

## 🔍 Busca Rápida

### **Procurando por Ferramentas?**
- Active Directory → [Windows/README.md](./Windows/README.md) (BloodHound, Rubeus, PowerView)
- Phishing → [Kali/Ferramentas/](./Kali/Ferramentas/) (zphisher, EchoPhish)
- Reconnaissance → [Kali/Ferramentas/](./Kali/Ferramentas/) (reconftw, SecLists)
- Lateral Movement → [Windows/README.md](./Windows/README.md) (Evil-WinRM, Impacket)
- Post-Exploitation → [Windows/README.md](./Windows/README.md) (Seatbelt, WinPEAS)

### **Procurando por Documentação?**
- Setup Windows → [Windows/README.md](./Windows/README.md)
- Setup Kali → [Kali/README.md](./Kali/README.md)
- Retestes → [ScrpitPentestSH/retestesh/README.md](./ScrpitPentestSH/retestesh/README.md)
- Guia Notebook 2 → [Windows/NOTEBOOK2-GUIDE.md](./Windows/NOTEBOOK2-GUIDE.md)
- Vulnerabilidades → [ScrpitPentestSH/retestesh/INDICE_VULNERABILIDADES.md](./ScrpitPentestSH/retestesh/INDICE_VULNERABILIDADES.md)

---

## ⚠️ Aviso Legal

**USO RESPONSÁVEL:**
- ✅ Use apenas em ambientes autorizados
- ✅ Obtenha permissão por escrito
- ✅ Respeite leis locais e internacionais
- ❌ Nunca use para atividades ilegais

**O autor não se responsabiliza por uso indevido.**

---

## 👤 Autor

**Samuel Ziger**
- GitHub: [@Samuel-Ziger](https://github.com/Samuel-Ziger)
- Repositório: [Scripts-Bat](https://github.com/Samuel-Ziger/Scripts-Bat)

---

**Última atualização:** 28/11/2025  
**Versão:** 1.0
