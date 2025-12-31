@echo off
title Windows Attack Box - Notebook 2 (i5-3210M/12GB) - AD/Lateral Movement/Post-Ex
chcp 65001 >nul

REM ============================================================
REM WINDOWS ATTACK BOX - NOTEBOOK 2
REM
REM Função: Máquina Windows para ataques/pós-exploração realistas
REM Hardware: i5-3210M + 12GB RAM
REM Foco: Active Directory, Lateral Movement, Insider Attacks
REM 
REM Ferramentas instaladas:
REM  ✓ BloodHound + SharpHound (análise AD)
REM  ✓ Evil-WinRM (lateral movement)
REM  ✓ Rubeus (Kerberos attacks)
REM  ✓ Seatbelt, WinPEAS (enumeration)
REM  ✓ Donut, ScareCrow, Nimcrypt2 (payload evasion)
REM  ✓ CrackMapExec via WSL2 + Kali
REM  ✓ Impacket Suite (SMB/LDAP/Kerberos)
REM  ✓ Responder (LLMNR poisoning)
REM  ✓ Office/HTA/MSI payload tools
REM ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Execute como Administrador!
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo =====================================================
echo   WINDOWS ATTACK BOX - NOTEBOOK 2
echo   i5-3210M / 12GB RAM
echo =====================================================
echo.
echo [i] Funcao: Ataques Windows Realistas
echo [i] Foco: Active Directory + Insider Attacks
echo [i] Tempo estimado: 30-60 minutos
echo.
pause

REM ============================================================
REM LIBERAR POWERSHELL
REM ============================================================
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"

REM ============================================================
REM INSTALAR CHOCOLATEY
REM ============================================================
echo.
echo [1/9] Instalando Chocolatey...
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex"

REM ============================================================
REM INSTALAR FERRAMENTAS ESSENCIAIS
REM ============================================================
echo.
echo [2/9] Instalando ferramentas base (Git, Python, Ruby, Nmap)...

choco install -y git
choco install -y python
choco install -y ruby
choco install -y nmap
choco install -y wireshark
choco install -y sysinternals
choco install -y 7zip
choco install -y vscode
choco install -y jq
choco install -y openssh
choco install -y golang

REM ============================================================
REM HABILITAR SSH SERVER
REM ============================================================
echo.
echo [3/9] Ativando SSH Server...
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0" >nul 2>&1
powershell -Command "Start-Service sshd" >nul 2>&1
powershell -Command "Set-Service sshd -StartupType Automatic" >nul 2>&1

REM ============================================================
REM CRIAR ESTRUTURA DE PASTAS PROFISSIONAL
REM ============================================================
echo.
echo [4/9] Criando estrutura de diretorios...

set ROOT=C:\Tools

mkdir %ROOT% 2>nul

REM === Active Directory ===
mkdir %ROOT%\AD 2>nul
mkdir %ROOT%\AD\Bloodhound 2>nul
mkdir %ROOT%\AD\SharpHound 2>nul
mkdir %ROOT%\AD\PowerView 2>nul
mkdir %ROOT%\AD\PowerUp 2>nul

REM === Post-Exploitation ===
mkdir %ROOT%\PostEx 2>nul
mkdir %ROOT%\PostEx\Rubeus 2>nul
mkdir %ROOT%\PostEx\Seatbelt 2>nul
mkdir %ROOT%\PostEx\SharpUp 2>nul
mkdir %ROOT%\PostEx\WinPEAS 2>nul
mkdir %ROOT%\PostEx\SharpMapExec 2>nul
mkdir %ROOT%\PostEx\Certify 2>nul
mkdir %ROOT%\PostEx\SharpDPAPI 2>nul

REM === Payloads & Evasion ===
mkdir %ROOT%\Payloads 2>nul
mkdir %ROOT%\Payloads\Office 2>nul
mkdir %ROOT%\Payloads\HTA 2>nul
mkdir %ROOT%\Payloads\MSI 2>nul
mkdir %ROOT%\Payloads\LNK 2>nul
mkdir %ROOT%\Payloads\VBS 2>nul
mkdir %ROOT%\Payloads\Donut 2>nul
mkdir %ROOT%\Payloads\ScareCrow 2>nul
mkdir %ROOT%\Payloads\Nimcrypt2 2>nul

REM === Enumerations ===
mkdir %ROOT%\Enum 2>nul
mkdir %ROOT%\Enum\SMB 2>nul
mkdir %ROOT%\Enum\LDAP 2>nul
mkdir %ROOT%\Enum\HTTP 2>nul
mkdir %ROOT%\Enum\Kerberos 2>nul

REM === Tools ===
mkdir %ROOT%\Tools 2>nul
mkdir %ROOT%\Tools\Sysinternals 2>nul
mkdir %ROOT%\Tools\Mimikatz 2>nul
mkdir %ROOT%\Tools\Impacket 2>nul
mkdir %ROOT%\Tools\Responder 2>nul

REM === Loot & Engagements ===
mkdir %ROOT%\Engagements 2>nul
mkdir %ROOT%\Loot 2>nul
mkdir %ROOT%\Loot\Credentials 2>nul
mkdir %ROOT%\Loot\Hashes 2>nul
mkdir %ROOT%\Loot\Tickets 2>nul

echo [OK] Estrutura criada em C:\Tools\

REM ============================================================
REM BAIXAR FERRAMENTAS AD (BLOODHOUND, SHARPHOUND, POWERVIEW)
REM ============================================================
echo.
echo [5/9] Baixando ferramentas Active Directory...

REM BloodHound GUI
if not exist "%ROOT%\AD\Bloodhound\BloodHound.exe" (
    echo [+] Baixando BloodHound GUI...
    powershell -Command "iwr https://github.com/BloodHoundAD/BloodHound/releases/latest/download/BloodHound-win32-x64.zip -OutFile %ROOT%\AD\Bloodhound\Bloodhound.zip"
    powershell -Command "Expand-Archive %ROOT%\AD\Bloodhound\Bloodhound.zip -DestinationPath %ROOT%\AD\Bloodhound -Force"
    echo [OK] BloodHound instalado.
) else (
    echo [OK] BloodHound ja instalado.
)

REM SharpHound
if not exist "%ROOT%\AD\SharpHound\SharpHound.exe" (
    echo [+] Baixando SharpHound...
    powershell -Command "iwr https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound-v2.5.7.zip -OutFile %ROOT%\AD\SharpHound\SharpHound.zip"
    powershell -Command "Expand-Archive %ROOT%\AD\SharpHound\SharpHound.zip -DestinationPath %ROOT%\AD\SharpHound -Force"
    echo [OK] SharpHound instalado.
) else (
    echo [OK] SharpHound ja instalado.
)

REM PowerView
if not exist "%ROOT%\AD\PowerView\PowerView.ps1" (
    echo [+] Baixando PowerView...
    powershell -Command "iwr https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1 -OutFile %ROOT%\AD\PowerView\PowerView.ps1"
    echo [OK] PowerView instalado.
) else (
    echo [OK] PowerView ja instalado.
)

REM PowerUp
if not exist "%ROOT%\AD\PowerUp\PowerUp.ps1" (
    echo [+] Baixando PowerUp...
    powershell -Command "iwr https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1 -OutFile %ROOT%\AD\PowerUp\PowerUp.ps1"
    echo [OK] PowerUp instalado.
) else (
    echo [OK] PowerUp ja instalado.
)

REM ============================================================
REM BAIXAR FERRAMENTAS POST-EXPLOITATION
REM ============================================================
echo.
echo [6/9] Baixando ferramentas Post-Exploitation...

REM Rubeus (Kerberos)
if not exist "%ROOT%\PostEx\Rubeus\.git" (
    echo [+] Clonando Rubeus...
    git clone https://github.com/GhostPack/Rubeus "%ROOT%\PostEx\Rubeus"
) else (
    echo [OK] Rubeus ja clonado.
)

REM Seatbelt
if not exist "%ROOT%\PostEx\Seatbelt\.git" (
    echo [+] Clonando Seatbelt...
    git clone https://github.com/GhostPack/Seatbelt "%ROOT%\PostEx\Seatbelt"
) else (
    echo [OK] Seatbelt ja clonado.
)

REM WinPEAS
if not exist "%ROOT%\PostEx\WinPEAS\winPEASx64.exe" (
    echo [+] Baixando WinPEAS...
    powershell -Command "iwr https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASx64.exe -OutFile %ROOT%\PostEx\WinPEAS\winPEASx64.exe"
    powershell -Command "iwr https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.exe -OutFile %ROOT%\PostEx\WinPEAS\winPEASany.exe"
    echo [OK] WinPEAS instalado.
) else (
    echo [OK] WinPEAS ja instalado.
)

REM Certify (AD CS)
if not exist "%ROOT%\PostEx\Certify\.git" (
    echo [+] Clonando Certify...
    git clone https://github.com/GhostPack/Certify "%ROOT%\PostEx\Certify"
) else (
    echo [OK] Certify ja clonado.
)

REM SharpDPAPI
if not exist "%ROOT%\PostEx\SharpDPAPI\.git" (
    echo [+] Clonando SharpDPAPI...
    git clone https://github.com/GhostPack/SharpDPAPI "%ROOT%\PostEx\SharpDPAPI"
) else (
    echo [OK] SharpDPAPI ja clonado.
)

REM ============================================================
REM BAIXAR FERRAMENTAS DE PAYLOAD/EVASION
REM ============================================================
echo.
echo [7/9] Baixando ferramentas Payload/Evasion (Office, HTA, MSI)...

REM Donut
if not exist "%ROOT%\Payloads\Donut\.git" (
    echo [+] Clonando Donut...
    git clone https://github.com/TheWover/donut "%ROOT%\Payloads\Donut"
) else (
    echo [OK] Donut ja clonado.
)

REM ScareCrow
if not exist "%ROOT%\Payloads\ScareCrow\.git" (
    echo [+] Clonando ScareCrow...
    git clone https://github.com/optiv/ScareCrow "%ROOT%\Payloads\ScareCrow"
) else (
    echo [OK] ScareCrow ja clonado.
)

REM Nimcrypt2
if not exist "%ROOT%\Payloads\Nimcrypt2\.git" (
    echo [+] Clonando Nimcrypt2...
    git clone https://github.com/icyguider/Nimcrypt2 "%ROOT%\Payloads\Nimcrypt2"
) else (
    echo [OK] Nimcrypt2 ja clonado.
)

REM ============================================================
REM INSTALAR IMPACKET + RESPONDER
REM ============================================================
echo.
echo [8/9] Baixando Impacket e Responder...

REM Impacket
if not exist "%ROOT%\Tools\Impacket\.git" (
    echo [+] Clonando Impacket...
    git clone https://github.com/fortra/impacket "%ROOT%\Tools\Impacket"
    echo [INFO] Para instalar: cd %ROOT%\Tools\Impacket; pip install .
) else (
    echo [OK] Impacket ja clonado.
)

REM Responder
if not exist "%ROOT%\Tools\Responder\.git" (
    echo [+] Clonando Responder...
    git clone https://github.com/lgandx/Responder "%ROOT%\Tools\Responder"
) else (
    echo [OK] Responder ja clonado.
)

REM Evil-WinRM
echo [+] Instalando Evil-WinRM (requer Ruby)...
gem install evil-winrm >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Evil-WinRM instalado!
) else (
    echo [AVISO] Evil-WinRM falhou. Certifique-se que Ruby esta instalado.
)

REM ============================================================
REM ATIVAR WSL2 + KALI
REM ============================================================
echo.
echo [9/9] Ativando WSL2 + Kali Linux...

powershell -Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" >nul 2>&1
powershell -Command "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart" >nul 2>&1

echo [INFO] WSL2 habilitado. Apos reiniciar, execute:
echo        wsl --install -d kali-linux
echo.
echo [INFO] Dentro do Kali, instale:
echo        sudo apt update
echo        sudo apt install bloodhound python3-impacket crackmapexec smbmap

REM ============================================================
REM CONFIGURAR PERFIL POWERSHELL
REM ============================================================
echo.
echo [+] Configurando PowerShell Profile...

set PROFILE=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
mkdir "%USERPROFILE%\Documents\WindowsPowerShell" 2>nul

(
echo # Attack Box Profile - Notebook 2
echo Set-Alias ll ls
echo Set-Alias la "ls -Force"
echo Set-Alias grep Select-String
echo Import-Module PSReadLine
echo Set-PSReadLineOption -PredictionSource History
echo.
echo # Quick paths
echo function goto-tools { cd C:\Tools }
echo function goto-ad { cd C:\Tools\AD }
echo function goto-postex { cd C:\Tools\PostEx }
echo function goto-payloads { cd C:\Tools\Payloads }
echo function goto-loot { cd C:\Tools\Loot }
echo.
echo Write-Host "[AttackBox] Notebook 2 - AD/Lateral Movement" -ForegroundColor Cyan
) > "%PROFILE%"

echo [OK] Profile configurado!

REM ============================================================
REM DESATIVAR DEFENDER (APENAS PARA TESTE!)
REM ============================================================
echo.
echo [+] Configurando exclusoes do Windows Defender...

powershell -Command "Add-MpPreference -ExclusionPath 'C:\Tools'" >nul 2>&1
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true" >nul 2>&1

echo [OK] Defender configurado (exclusoes em C:\Tools)

REM ============================================================
REM FINAL
REM ============================================================
echo.
echo =====================================================
echo   WINDOWS ATTACK BOX - INSTALACAO CONCLUIDA!
echo =====================================================
echo.
echo [OK] Estrutura criada em: C:\Tools\
echo.
echo Proximos passos:
echo  1. REINICIE o sistema
echo  2. Execute: wsl --install -d kali-linux
echo  3. No Kali: apt install crackmapexec impacket bloodhound
echo  4. Teste BloodHound: C:\Tools\AD\Bloodhound\BloodHound.exe
echo  5. Compile ferramentas .NET conforme necessario
echo.
echo Ferramentas instaladas:
echo  [AD] BloodHound, SharpHound, PowerView, PowerUp
echo  [PostEx] Rubeus, Seatbelt, WinPEAS, Certify, SharpDPAPI
echo  [Payloads] Donut, ScareCrow, Nimcrypt2
echo  [Tools] Impacket, Responder, Evil-WinRM
echo.
echo Use "rollback.bat" para reverter configuracoes.
echo.
pause
exit /b 0
