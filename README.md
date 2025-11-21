# Scripts-Bat

## 🎯 Propósito

Repositório de scripts de automação para configuração rápida de ambientes de **Penetration Testing** e **Red Team Operations**, suportando Windows e Kali Linux.

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
Scripts-Bat/
├── Kali/                    # Scripts para Kali Linux
│   ├── setup-kali.sh        # Setup completo automatizado
│   ├── ExecutarSetup-Kali.md
│   └── Ferramentas/
│       └── zphisher/        # Ferramenta de phishing educacional
│
└── Windows/                 # Scripts para Windows
    ├── atack2.0-optimized.bat  # Setup Notebook 2 (AD/Lateral Movement) ⭐ NOVO!
    ├── setup-attackbox.ps1  # Setup PowerShell (RECOMENDADO)
    ├── setup_attackbox.bat  # Launcher do setup
    ├── atack2.0.bat         # Setup completo com WSL2
    ├── bloqueioAPP.bat      # Bloqueio de aplicativos (ambientes controlados)
    ├── rollback.bat         # Reverter configurações ⭐ NOVO!
    ├── verificao.bat        # Verificação pós-instalação
    ├── setup-debug.bat      # Modo debug para troubleshooting
    ├── README.md            # Documentação Windows
    └── NOTEBOOK2-GUIDE.md   # Guia específico Notebook 2 (i5-3210M) ⭐ NOVO!
```

---

## 🚀 Início Rápido

### **Kali Linux**

```bash
# 1. Dar permissão de execução
chmod +x Kali/setup-kali.sh

# 2. Executar como root
sudo ./Kali/setup-kali.sh
```

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

### **Active Directory**
- BloodHound / SharpHound
- Rubeus (Kerberos)
- PowerView
- Impacket Suite

### **Post-Exploitation**
- Seatbelt
- WinPEAS
- SharpUp
- SharpMapExec

### **Networking**
- Nmap
- Masscan
- Ffuf
- Gobuster

### **Exploitation**
- Metasploit Framework
- SQLMap
- ExploitDB
- Veil-Evasion

### **Payloads**
- Donut
- ScareCrow
- Nimcrypt2

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

- [Windows/](./Windows/) - Detalhes sobre scripts Windows
- [Kali/](./Kali/) - Detalhes sobre scripts Kali
- [Kali/ExecutarSetup-Kali.md](./Kali/ExecutarSetup-Kali.md) - Guia de execução Kali

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

## 🔐 Segurança e Privacidade

- Nunca armazene credenciais nos scripts
- Use ambientes isolados (VMs/containers)
- Mantenha ferramentas atualizadas
- Audite regularmente seu ambiente de testes

---

**Última atualização:** Novembro 2025
