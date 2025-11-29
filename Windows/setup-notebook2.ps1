# ============================================================
#  NOTEBOOK 2 - SETUP AUTOMÁTICO COMPLETO
#  Windows Attack Box - AD / Lateral Movement / Post-Exploitation
# ============================================================

param(
    [switch]$SkipWSL = $false,
    [switch]$SkipDefender = $false
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Cores para output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message, [int]$Step, [int]$Total)
    Write-ColorOutput "`n[$Step/$Total] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "[✓] $Message" "Green"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[✗] $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[i] $Message" "Yellow"
}

# ============================================================
#  VERIFICAÇÃO DE ADMINISTRADOR
# ============================================================
Write-ColorOutput "`n============================================================" "Cyan"
Write-ColorOutput "  NOTEBOOK 2 - SETUP AUTOMÁTICO COMPLETO" "Cyan"
Write-ColorOutput "  Windows Attack Box - AD / Lateral Movement" "Cyan"
Write-ColorOutput "============================================================" "Cyan"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script requer privilégios de Administrador!"
    Write-Info "Execute: Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup-notebook2.ps1"
    exit 1
}

Write-Success "Executando como Administrador"

# ============================================================
#  CONFIGURAÇÃO INICIAL
# ============================================================
Write-Step "Configurando ambiente PowerShell" 1 12

Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ToolsRoot = "C:\Tools"
$ToolsAD = "$ToolsRoot\AD"
$ToolsPostEx = "$ToolsRoot\PostEx"
$ToolsPayloads = "$ToolsRoot\Payloads"
$ToolsTools = "$ToolsRoot\Tools"
$ToolsLoot = "$ToolsRoot\Loot"
$ToolsEngagements = "$ToolsRoot\Engagements"

Write-Success "PowerShell configurado"

# ============================================================
#  INSTALAR CHOCOLATEY
# ============================================================
Write-Step "Instalando Chocolatey" 2 12

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Info "Chocolatey não encontrado. Instalando..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        refreshenv
        Write-Success "Chocolatey instalado"
    } catch {
        Write-Error "Falha ao instalar Chocolatey: $_"
        exit 1
    }
} else {
    Write-Success "Chocolatey já instalado"
}

# ============================================================
#  INSTALAR FERRAMENTAS BASE
# ============================================================
Write-Step "Instalando ferramentas base (Git, Python, Ruby, etc.)" 3 12

$BaseTools = @(
    "git",
    "python3",
    "ruby",
    "nmap",
    "wireshark",
    "sysinternals",
    "7zip",
    "vscode",
    "jq",
    "openssh",
    "golang"
)

foreach ($tool in $BaseTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Info "Instalando $tool..."
        choco install $tool -y --no-progress 2>&1 | Out-Null
    } else {
        Write-Info "$tool já instalado"
    }
}

# Atualizar PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Success "Ferramentas base instaladas"

# ============================================================
#  HABILITAR SSH SERVER
# ============================================================
Write-Step "Configurando SSH Server" 4 12

try {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue | Out-Null
    Start-Service sshd -ErrorAction SilentlyContinue
    Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue
    Write-Success "SSH Server configurado"
} catch {
    Write-Info "SSH Server pode já estar configurado"
}

# ============================================================
#  CRIAR ESTRUTURA DE PASTAS
# ============================================================
Write-Step "Criando estrutura de diretórios" 5 12

$Folders = @(
    $ToolsRoot,
    "$ToolsAD\Bloodhound",
    "$ToolsAD\SharpHound",
    "$ToolsAD\PowerView",
    "$ToolsAD\PowerUp",
    "$ToolsAD\Certify",
    "$ToolsPostEx\Rubeus",
    "$ToolsPostEx\Seatbelt",
    "$ToolsPostEx\SharpUp",
    "$ToolsPostEx\WinPEAS",
    "$ToolsPostEx\SharpMapExec",
    "$ToolsPostEx\Certify",
    "$ToolsPostEx\SharpDPAPI",
    "$ToolsPayloads\Office",
    "$ToolsPayloads\HTA",
    "$ToolsPayloads\MSI",
    "$ToolsPayloads\LNK",
    "$ToolsPayloads\VBS",
    "$ToolsPayloads\Donut",
    "$ToolsPayloads\ScareCrow",
    "$ToolsPayloads\Nimcrypt2",
    "$ToolsTools\Impacket",
    "$ToolsTools\Responder",
    "$ToolsTools\Mimikatz",
    "$ToolsTools\Sysinternals",
    "$ToolsLoot\Credentials",
    "$ToolsLoot\Hashes",
    "$ToolsLoot\Tickets",
    "$ToolsEngagements"
)

foreach ($folder in $Folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

Write-Success "Estrutura de pastas criada em $ToolsRoot"

# ============================================================
#  BAIXAR FERRAMENTAS AD
# ============================================================
Write-Step "Baixando ferramentas Active Directory" 6 12

# BloodHound
if (-not (Test-Path "$ToolsAD\Bloodhound\BloodHound.exe")) {
    Write-Info "Baixando BloodHound..."
    try {
        $url = "https://github.com/BloodHoundAD/BloodHound/releases/latest/download/BloodHound-win32-x64.zip"
        $zip = "$ToolsAD\Bloodhound\Bloodhound.zip"
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath "$ToolsAD\Bloodhound" -Force
        Remove-Item $zip -Force
        Write-Success "BloodHound instalado"
    } catch {
        Write-Error "Falha ao baixar BloodHound: $_"
    }
} else {
    Write-Success "BloodHound já instalado"
}

# SharpHound
if (-not (Test-Path "$ToolsAD\SharpHound\SharpHound.exe")) {
    Write-Info "Baixando SharpHound..."
    try {
        $url = "https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound-v2.5.7.zip"
        $zip = "$ToolsAD\SharpHound\SharpHound.zip"
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath "$ToolsAD\SharpHound" -Force
        Remove-Item $zip -Force
        Write-Success "SharpHound instalado"
    } catch {
        Write-Error "Falha ao baixar SharpHound: $_"
    }
} else {
    Write-Success "SharpHound já instalado"
}

# PowerView
if (-not (Test-Path "$ToolsAD\PowerView\PowerView.ps1")) {
    Write-Info "Baixando PowerView..."
    try {
        $url = "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1"
        Invoke-WebRequest -Uri $url -OutFile "$ToolsAD\PowerView\PowerView.ps1" -UseBasicParsing
        Write-Success "PowerView instalado"
    } catch {
        Write-Error "Falha ao baixar PowerView: $_"
    }
} else {
    Write-Success "PowerView já instalado"
}

# PowerUp
if (-not (Test-Path "$ToolsAD\PowerUp\PowerUp.ps1")) {
    Write-Info "Baixando PowerUp..."
    try {
        $url = "https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1"
        Invoke-WebRequest -Uri $url -OutFile "$ToolsAD\PowerUp\PowerUp.ps1" -UseBasicParsing
        Write-Success "PowerUp instalado"
    } catch {
        Write-Error "Falha ao baixar PowerUp: $_"
    }
} else {
    Write-Success "PowerUp já instalado"
}

# ============================================================
#  BAIXAR FERRAMENTAS POST-EXPLOITATION
# ============================================================
Write-Step "Baixando ferramentas Post-Exploitation" 7 12

# Rubeus
if (-not (Test-Path "$ToolsPostEx\Rubeus\.git")) {
    Write-Info "Clonando Rubeus..."
    try {
        & git clone https://github.com/GhostPack/Rubeus.git "$ToolsPostEx\Rubeus" 2>&1 | Out-Null
        Write-Success "Rubeus clonado"
    } catch {
        Write-Error "Falha ao clonar Rubeus: $_"
    }
} else {
    Write-Success "Rubeus já clonado"
}

# Seatbelt
if (-not (Test-Path "$ToolsPostEx\Seatbelt\.git")) {
    Write-Info "Clonando Seatbelt..."
    try {
        & git clone https://github.com/GhostPack/Seatbelt.git "$ToolsPostEx\Seatbelt" 2>&1 | Out-Null
        Write-Success "Seatbelt clonado"
    } catch {
        Write-Error "Falha ao clonar Seatbelt: $_"
    }
} else {
    Write-Success "Seatbelt já clonado"
}

# WinPEAS
if (-not (Test-Path "$ToolsPostEx\WinPEAS\winPEASx64.exe")) {
    Write-Info "Baixando WinPEAS..."
    try {
        $url64 = "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe"
        $urlAny = "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.exe"
        Invoke-WebRequest -Uri $url64 -OutFile "$ToolsPostEx\WinPEAS\winPEASx64.exe" -UseBasicParsing
        Invoke-WebRequest -Uri $urlAny -OutFile "$ToolsPostEx\WinPEAS\winPEASany.exe" -UseBasicParsing
        Write-Success "WinPEAS instalado"
    } catch {
        Write-Error "Falha ao baixar WinPEAS: $_"
    }
} else {
    Write-Success "WinPEAS já instalado"
}

# Certify
if (-not (Test-Path "$ToolsPostEx\Certify\.git")) {
    Write-Info "Clonando Certify..."
    try {
        & git clone https://github.com/GhostPack/Certify.git "$ToolsPostEx\Certify" 2>&1 | Out-Null
        Write-Success "Certify clonado"
    } catch {
        Write-Error "Falha ao clonar Certify: $_"
    }
} else {
    Write-Success "Certify já clonado"
}

# SharpDPAPI
if (-not (Test-Path "$ToolsPostEx\SharpDPAPI\.git")) {
    Write-Info "Clonando SharpDPAPI..."
    try {
        & git clone https://github.com/GhostPack/SharpDPAPI.git "$ToolsPostEx\SharpDPAPI" 2>&1 | Out-Null
        Write-Success "SharpDPAPI clonado"
    } catch {
        Write-Error "Falha ao clonar SharpDPAPI: $_"
    }
} else {
    Write-Success "SharpDPAPI já clonado"
}

# SharpUp
if (-not (Test-Path "$ToolsPostEx\SharpUp\.git")) {
    Write-Info "Clonando SharpUp..."
    try {
        & git clone https://github.com/GhostPack/SharpUp.git "$ToolsPostEx\SharpUp" 2>&1 | Out-Null
        Write-Success "SharpUp clonado"
    } catch {
        Write-Error "Falha ao clonar SharpUp: $_"
    }
} else {
    Write-Success "SharpUp já clonado"
}

# SharpMapExec
if (-not (Test-Path "$ToolsPostEx\SharpMapExec\.git")) {
    Write-Info "Clonando SharpMapExec..."
    try {
        & git clone https://github.com/cube0x0/SharpMapExec.git "$ToolsPostEx\SharpMapExec" 2>&1 | Out-Null
        Write-Success "SharpMapExec clonado"
    } catch {
        Write-Error "Falha ao clonar SharpMapExec: $_"
    }
} else {
    Write-Success "SharpMapExec já clonado"
}

# ============================================================
#  BAIXAR FERRAMENTAS DE PAYLOAD/EVASION
# ============================================================
Write-Step "Baixando ferramentas Payload/Evasion" 8 12

# Donut
if (-not (Test-Path "$ToolsPayloads\Donut\.git")) {
    Write-Info "Clonando Donut..."
    try {
        & git clone https://github.com/TheWover/donut.git "$ToolsPayloads\Donut" 2>&1 | Out-Null
        Write-Success "Donut clonado"
    } catch {
        Write-Error "Falha ao clonar Donut: $_"
    }
} else {
    Write-Success "Donut já clonado"
}

# ScareCrow
if (-not (Test-Path "$ToolsPayloads\ScareCrow\.git")) {
    Write-Info "Clonando ScareCrow..."
    try {
        & git clone https://github.com/optiv/ScareCrow.git "$ToolsPayloads\ScareCrow" 2>&1 | Out-Null
        Write-Success "ScareCrow clonado"
    } catch {
        Write-Error "Falha ao clonar ScareCrow: $_"
    }
} else {
    Write-Success "ScareCrow já clonado"
}

# Nimcrypt2
if (-not (Test-Path "$ToolsPayloads\Nimcrypt2\.git")) {
    Write-Info "Clonando Nimcrypt2..."
    try {
        & git clone https://github.com/icyguider/Nimcrypt2.git "$ToolsPayloads\Nimcrypt2" 2>&1 | Out-Null
        Write-Success "Nimcrypt2 clonado"
    } catch {
        Write-Error "Falha ao clonar Nimcrypt2: $_"
    }
} else {
    Write-Success "Nimcrypt2 já clonado"
}

# ============================================================
#  INSTALAR IMPACKET E RESPONDER
# ============================================================
Write-Step "Baixando Impacket e Responder" 9 12

# Impacket
if (-not (Test-Path "$ToolsTools\Impacket\.git")) {
    Write-Info "Clonando Impacket..."
    try {
        & git clone https://github.com/fortra/impacket.git "$ToolsTools\Impacket" 2>&1 | Out-Null
        Write-Info "Instalando Impacket via pip..."
        & pip install "$ToolsTools\Impacket" 2>&1 | Out-Null
        Write-Success "Impacket instalado"
    } catch {
        Write-Error "Falha ao instalar Impacket: $_"
    }
} else {
    Write-Success "Impacket já clonado"
    Write-Info "Atualizando Impacket..."
    & pip install "$ToolsTools\Impacket" --upgrade 2>&1 | Out-Null
}

# Responder
if (-not (Test-Path "$ToolsTools\Responder\.git")) {
    Write-Info "Clonando Responder..."
    try {
        & git clone https://github.com/lgandx/Responder.git "$ToolsTools\Responder" 2>&1 | Out-Null
        Write-Success "Responder clonado"
    } catch {
        Write-Error "Falha ao clonar Responder: $_"
    }
} else {
    Write-Success "Responder já clonado"
}

# Evil-WinRM
Write-Info "Instalando Evil-WinRM..."
try {
    & gem install evil-winrm 2>&1 | Out-Null
    Write-Success "Evil-WinRM instalado"
} catch {
    Write-Error "Falha ao instalar Evil-WinRM. Certifique-se que Ruby está instalado."
}

# ============================================================
#  CONFIGURAR WSL2 + KALI
# ============================================================
if (-not $SkipWSL) {
    Write-Step "Configurando WSL2 + Kali Linux" 10 12
    
    try {
        # Habilitar recursos necessários
        Write-Info "Habilitando recursos do Windows..."
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
        
        Write-Info "WSL2 habilitado. Após reiniciar, execute:"
        Write-ColorOutput "  wsl --install -d kali-linux" "Yellow"
        Write-Info "Dentro do Kali, instale:"
        Write-ColorOutput "  sudo apt update && sudo apt upgrade -y" "Yellow"
        Write-ColorOutput "  sudo apt install -y bloodhound python3-impacket crackmapexec smbmap enum4linux-ng kerbrute responder" "Yellow"
    } catch {
        Write-Error "Falha ao configurar WSL2: $_"
    }
} else {
    Write-Info "Pulando instalação do WSL2 (--SkipWSL)"
}

# ============================================================
#  CONFIGURAR PERFIL POWERSHELL
# ============================================================
Write-Step "Configurando perfil PowerShell" 11 12

$ProfilePath = $PROFILE.CurrentUserAllHosts
$ProfileDir = Split-Path $ProfilePath -Parent

if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

$ProfileContent = @"
# ============================================================
#  NOTEBOOK 2 - ATTACK BOX PROFILE
# ============================================================

# Aliases úteis
Set-Alias ll Get-ChildItem
Set-Alias la Get-ChildItem
Set-Alias grep Select-String
Set-Alias wget Invoke-WebRequest
Set-Alias cat Get-Content

# Funções de navegação rápida
function goto-tools { Set-Location C:\Tools }
function goto-ad { Set-Location C:\Tools\AD }
function goto-postex { Set-Location C:\Tools\PostEx }
function goto-payloads { Set-Location C:\Tools\Payloads }
function goto-loot { Set-Location C:\Tools\Loot }
function goto-engagements { Set-Location C:\Tools\Engagements }

# Importar módulos úteis
Import-Module PSReadLine -ErrorAction SilentlyContinue
Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue

# Banner
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  NOTEBOOK 2 - WINDOWS ATTACK BOX" -ForegroundColor Cyan
Write-Host "  AD / Lateral Movement / Post-Exploitation" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
"@

Set-Content -Path $ProfilePath -Value $ProfileContent -Force
Write-Success "Perfil PowerShell configurado"

# ============================================================
#  CONFIGURAR WINDOWS DEFENDER
# ============================================================
if (-not $SkipDefender) {
    Write-Step "Configurando Windows Defender" 12 12
    
    try {
        # Adicionar exclusões
        Add-MpPreference -ExclusionPath $ToolsRoot -ErrorAction SilentlyContinue
        Add-MpPreference -ExclusionPath "$env:USERPROFILE\AppData\Local\Temp" -ErrorAction SilentlyContinue
        
        # Desativar proteções (APENAS PARA AMBIENTE DE TESTE!)
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
        
        Write-Success "Windows Defender configurado (exclusões em $ToolsRoot)"
        Write-Info "⚠️  ATENÇÃO: Proteções foram desativadas! Use apenas em ambiente isolado!"
    } catch {
        Write-Error "Falha ao configurar Windows Defender: $_"
    }
} else {
    Write-Info "Pulando configuração do Windows Defender (--SkipDefender)"
}

# ============================================================
#  FINALIZAÇÃO
# ============================================================
Write-ColorOutput "`n============================================================" "Green"
Write-ColorOutput "  INSTALAÇÃO CONCLUÍDA COM SUCESSO!" "Green"
Write-ColorOutput "============================================================" "Green"
Write-Host ""
Write-ColorOutput "📁 Estrutura criada em: $ToolsRoot" "Cyan"
Write-Host ""
Write-ColorOutput "📦 Ferramentas instaladas:" "Yellow"
Write-Host "  [AD] BloodHound, SharpHound, PowerView, PowerUp, Certify"
Write-Host "  [PostEx] Rubeus, Seatbelt, WinPEAS, SharpUp, SharpMapExec, SharpDPAPI"
Write-Host "  [Payloads] Donut, ScareCrow, Nimcrypt2"
Write-Host "  [Tools] Impacket, Responder, Evil-WinRM"
Write-Host ""
Write-ColorOutput "🚀 Próximos passos:" "Yellow"
Write-Host "  1. REINICIE o sistema (necessário para WSL2)"
Write-Host "  2. Execute: wsl --install -d kali-linux"
Write-Host "  3. No Kali: sudo apt install bloodhound python3-impacket crackmapexec"
Write-Host "  4. Compile ferramentas .NET conforme necessário (Visual Studio)"
Write-Host "  5. Teste BloodHound: C:\Tools\AD\Bloodhound\BloodHound.exe"
Write-Host ""
Write-ColorOutput "📖 Consulte o guia completo: NOTEBOOK2_COMPLETO.md" "Cyan"
Write-Host ""
Write-ColorOutput "⚠️  IMPORTANTE:" "Red"
Write-Host "  - Use apenas em ambiente isolado/VM"
Write-Host "  - Windows Defender foi desativado"
Write-Host "  - Use rollback.bat para reverter configurações"
Write-Host ""

