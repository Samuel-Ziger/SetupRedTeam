# ================================
#  WINDOWS ATTACK BOX – SETUP PRO
#  Autor: ChatGPT para Samuel
# ================================

Write-Host "`n[+] Iniciando configuração da Attack Box..." -ForegroundColor Cyan

# ---------------------------
#   VERIFICAÇÃO DE ADMIN
# ---------------------------
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltinRole]::Administrator)) {

    Write-Host "[!] Execute este script como Administrador!" -ForegroundColor Red
    exit
}

# ---------------------------
#   CRIAÇÃO DAS PASTAS
# ---------------------------

$folders = @(
    "C:\Tools",
    "C:\Tools\AD",
    "C:\Tools\AD\Bloodhound",
    "C:\Tools\AD\SharpHound",
    "C:\Tools\PostEx",
    "C:\Tools\PostEx\Rubeus",
    "C:\Tools\PostEx\Seatbelt",
    "C:\Tools\PostEx\WinPEAS",
    "C:\Tools\PostEx\SharpUp",
    "C:\Tools\PostEx\SharpMapExec",
    "C:\Tools\Payloads",
    "C:\Tools\OfficeExploits",
    "C:\Tools\Enumerations"
)

foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
        Write-Host "[+] Criado: $folder" -ForegroundColor Green
    }
}

# ---------------------------
#     AJUSTE POWERSHELL
# ---------------------------
Write-Host "`n[+] Ajustando política de execução..." -ForegroundColor Cyan
Set-ExecutionPolicy Unrestricted -Force

# ---------------------------
#   INSTALAR WSL2 + KALI
# ---------------------------
Write-Host "`n[+] Instalando WSL2 + Kali Linux..." -ForegroundColor Cyan
wsl --install -d kali-linux

# ---------------------------
#   INSTALAR CHOCOLATEY
# ---------------------------
Write-Host "`n[+] Instalando Chocolatey..." -ForegroundColor Cyan

Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = 3072
iex ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))

# ---------------------------
#   INSTALAR FERRAMENTAS
# ---------------------------
Write-Host "`n[+] Instalando ferramentas..." -ForegroundColor Cyan

choco install git -y
choco install python -y
choco install ruby -y
choco install nmap -y
choco install sysinternals -y

# ---------------------------
#   INSTALAR EVIL-WINRM
# ---------------------------
Write-Host "`n[+] Instalando Evil-WinRM..." -ForegroundColor Cyan
gem install evil-winrm

# ---------------------------
#   BAIXAR FERRAMENTAS AD
# ---------------------------

Write-Host "`n[+] Baixando Bloodhound..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/BloodHoundAD/BloodHound/releases/latest/download/BloodHound-win-x64.zip" -OutFile "C:\Tools\AD\Bloodhound\Bloodhound.zip"

Write-Host "`n[+] Baixando SharpHound..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound.zip" -OutFile "C:\Tools\AD\SharpHound\SharpHound.zip"

# ---------------------------
#   BAIXAR FERRAMENTAS POST EXPLOIT
# ---------------------------

Write-Host "`n[+] Baixando Rubeus..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/GhostPack/Rubeus/releases/latest/download/Rubeus.zip" -OutFile "C:\Tools\PostEx\Rubeus\Rubeus.zip"

Write-Host "`n[+] Baixando Seatbelt..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/GhostPack/Seatbelt/releases/latest/download/Seatbelt.zip" -OutFile "C:\Tools\PostEx\Seatbelt\Seatbelt.zip"

Write-Host "`n[+] Baixando WinPEAS..." -ForegroundColor Cyan
Invoke-WebRequest -Uri "https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEAS.zip" -OutFile "C:\Tools\PostEx\WinPEAS\WinPEAS.zip"

# ---------------------------
#   DESATIVAR WINDOWS DEFENDER
# ---------------------------

Write-Host "`n[+] Ajustando Defender (exclusões)..." -ForegroundColor Cyan

Add-MpPreference -ExclusionPath "C:\Tools"
Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\AppData\Local\Temp"

Write-Host "[+] Exclusões adicionadas!" -ForegroundColor Green

Write-Host "`n[+] Desativando proteções do Defender..." -ForegroundColor Cyan

Set-MpPreference -DisableRealtimeMonitoring $true
Set-MpPreference -DisableIOAVProtection $true
Set-MpPreference -DisableBehaviorMonitoring $true
Set-MpPreference -DisableScriptScanning $true

# ---------------------------
#   FINAL
# ---------------------------

Write-Host "`n=========================================="
Write-Host "   Attack Box Windows configurada! 🔥"
Write-Host "   Tudo instalado e organizado em C:\Tools\"
Write-Host "==========================================`n"
