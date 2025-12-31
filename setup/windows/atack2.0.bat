@echo off
title Windows Attack Box - Notebook 2 Setup (AD/Lateral Movement/Post-Ex)
chcp 65001 >nul

REM ============================================================
REM WINDOWS ATTACK BOX - NOTEBOOK 2
REM
REM Função: Máquina Windows para ataques/pós-exploração realistas
REM Foco: Active Directory, Lateral Movement, Insider Attacks
REM 
REM Ferramentas instaladas:
REM  - BloodHound + SharpHound (análise AD)
REM  - Evil-WinRM (lateral movement)
REM  - Rubeus, Seatbelt, WinPEAS (post-ex)
REM  - Donut, ScareCrow, Nimcrypt2 (payload evasion)
REM  - CrackMapExec via WSL2 + Kali
REM  - Impacket Suite
REM  - Office/HTA/MSI payload tools
REM ============================================================

REM ============================================================
REM VERIFICA SE O SCRIPT ESTÁ SENDO EXECUTADO COMO ADMINISTRADOR
REM ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Este script precisa ser executado como Administrador.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo =====================================================
echo   WINDOWS ATTACK BOX - NOTEBOOK 2 (i5-3210M/12GB)
echo   Configuracao para AD/Lateral Movement/Post-Ex
echo =====================================================
echo.
echo [i] Funcao: Ataques Windows Realistas
echo [i] Foco: Active Directory + Insider Attacks
echo.
pause

REM ============================================================
REM LIBERAR POWERSHELL PARA EXECUTAR SCRIPTS NO PROCESSO ATUAL
REM ============================================================
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"

REM ============================================================
REM INSTALAR CHOCOLATEY
REM - Instalador oficial via PowerShell
REM - PATH já é configurado automaticamente pelo próprio Choco
REM ============================================================
echo [+] Instalando Chocolatey...
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex"

REM (REMOVIDO) Linha desnecessária que poderia gerar conflito no PATH
REM set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

REM ============================================================
REM INSTALAR FERRAMENTAS ESSENCIAIS VIA CHOCO
REM ============================================================
echo [+] Instalando ferramentas...

choco install -y git
choco install -y python
choco install -y nmap
choco install -y wireshark
choco install -y sysinternals
choco install -y 7zip
choco install -y vscode
choco install -y jq
choco install -y openssh
choco install -y ruby

REM ============================================================
REM HABILITAR SERVIDOR SSH NATIVO DO WINDOWS
REM ============================================================
echo [+] Ativando SSH...
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
powershell -Command "Start-Service sshd"
powershell -Command "Set-Service sshd -StartupType Automatic"

REM ============================================================
REM CRIAR ESTRUTURA DE DIRETÓRIOS (PROFISSIONAL)
REM - Organização baseada em categorias de ataque
REM - Estrutura otimizada para engagements AD
REM ============================================================
echo [+] Criando estrutura profissional...

set ROOT=C:\Tools

mkdir %ROOT% 2>nul

REM === Active Directory ===
mkdir %ROOT%\AD 2>nul
mkdir %ROOT%\AD\Bloodhound 2>nul
mkdir %ROOT%\AD\SharpHound 2>nul
mkdir %ROOT%\AD\PowerView 2>nul
mkdir %ROOT%\AD\PowerUp 2>nul
mkdir %ROOT%\AD\PowerSharpPack 2>nul
mkdir %ROOT%\AD\ADRecon 2>nul

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

REM === Ferramentas Gerais ===
mkdir %ROOT%\Tools 2>nul
mkdir %ROOT%\Tools\Sysinternals 2>nul
mkdir %ROOT%\Tools\Mimikatz 2>nul
mkdir %ROOT%\Tools\Impacket 2>nul
mkdir %ROOT%\Tools\EvilWinRM 2>nul
mkdir %ROOT%\Tools\Responder 2>nul

REM === Outputs de Engagements ===
mkdir %ROOT%\Engagements 2>nul
mkdir %ROOT%\Loot 2>nul
mkdir %ROOT%\Loot\Credentials 2>nul
mkdir %ROOT%\Loot\Hashes 2>nul
mkdir %ROOT%\Loot\Tickets 2>nul

echo [OK] Estrutura criada em C:\Tools\
echo.

REM ============================================================
REM AVISO SOBRE GIT CLONE / EXPAND-ARCHIVE
REM - 'git clone' falha se pasta existir
REM - 'Expand-Archive' falha se zip estiver corrompido
REM - Execuções repetidas podem abortar o script
REM ============================================================

echo [+] Baixando ferramentas AD (BloodHound, SharpHound, PowerView)...

REM BLOODHOUND GUI (essencial para analise AD)
if not exist "%ROOT%\AD\Bloodhound\BloodHound.exe" (
    echo [DOWNLOAD] BloodHound GUI...
    powershell -Command "iwr https://github.com/BloodHoundAD/BloodHound/releases/latest/download/BloodHound-win32-x64.zip -OutFile %ROOT%\AD\Bloodhound\Bloodhound.zip"
    powershell -Command "Expand-Archive %ROOT%\AD\Bloodhound\Bloodhound.zip -DestinationPath %ROOT%\AD\Bloodhound -Force"
) else (
    echo [OK] BloodHound ja instalado.
)

REM SHARPHOUND (coletor de dados AD)
if not exist "%ROOT%\AD\SharpHound\SharpHound.exe" (
    echo [DOWNLOAD] SharpHound...
    powershell -Command "iwr https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound-v2.5.7.zip -OutFile %ROOT%\AD\SharpHound\SharpHound.zip"
    powershell -Command "Expand-Archive %ROOT%\AD\SharpHound\SharpHound.zip -DestinationPath %ROOT%\AD\SharpHound -Force"
) else (
    echo [OK] SharpHound ja instalado.
)

REM POWERVIEW (PowerShell AD enum)
if not exist "%ROOT%\AD\PowerView\PowerView.ps1" (
    echo [DOWNLOAD] PowerView...
    powershell -Command "iwr https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Recon/PowerView.ps1 -OutFile %ROOT%\AD\PowerView\PowerView.ps1"
) else (
    echo [OK] PowerView ja instalado.
)

REM POWERUP (privilege escalation)
if not exist "%ROOT%\AD\PowerUp\PowerUp.ps1" (
    echo [DOWNLOAD] PowerUp...
    powershell -Command "iwr https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1 -OutFile %ROOT%\AD\PowerUp\PowerUp.ps1"
) else (
    echo [OK] PowerUp ja instalado.
)

REM RUBEUS
if not exist "%ROOT%\PostEx\Rubeus\Rubeus.zip" (
    powershell -Command "iwr https://github.com/GhostPack/Rubeus/releases/latest/download/Rubeus.zip -OutFile %ROOT%\PostEx\Rubeus\Rubeus.zip"
    powershell -Command "Expand-Archive %ROOT%\PostEx\Rubeus\Rubeus.zip -DestinationPath %ROOT%\PostEx\Rubeus -Force"
) else (
    echo [INFO] Rubeus ja baixado, pulando...
)

REM SEATBELT
if not exist "%ROOT%\PostEx\Seatbelt\Seatbelt.zip" (
    powershell -Command "iwr https://github.com/GhostPack/Seatbelt/releases/latest/download/Seatbelt.zip -OutFile %ROOT%\PostEx\Seatbelt\Seatbelt.zip"
    powershell -Command "Expand-Archive %ROOT%\PostEx\Seatbelt\Seatbelt.zip -DestinationPath %ROOT%\PostEx\Seatbelt -Force"
) else (
    echo [INFO] Seatbelt ja baixado, pulando...
)

REM SHARPUP
if not exist "%ROOT%\PostEx\SharpUp\SharpUp.zip" (
    powershell -Command "iwr https://github.com/GhostPack/SharpUp/releases/latest/download/SharpUp.zip -OutFile %ROOT%\PostEx\SharpUp\SharpUp.zip"
    powershell -Command "Expand-Archive %ROOT%\PostEx\SharpUp\SharpUp.zip -DestinationPath %ROOT%\PostEx\SharpUp -Force"
) else (
    echo [INFO] SharpUp ja baixado, pulando...
)

REM SHARPMAPEXEC
if not exist "%ROOT%\PostEx\SharpMapExec\SharpMapExec.zip" (
    powershell -Command "iwr https://github.com/anthemtotheego/SharpMapExec/releases/latest/download/SharpMapExec.zip -OutFile %ROOT%\PostEx\SharpMapExec\SharpMapExec.zip"
    powershell -Command "Expand-Archive %ROOT%\PostEx\SharpMapExec\SharpMapExec.zip -DestinationPath %ROOT%\PostEx\SharpMapExec -Force"
) else (
    echo [INFO] SharpMapExec ja baixado, pulando...
)

REM WINPEAS
if not exist "%ROOT%\PostEx\WinPEAS\winpeas.zip" (
    powershell -Command "iwr https://github.com/carlospolop/PEASS-ng/releases/latest/download/winPEASany.zip -OutFile %ROOT%\PostEx\WinPEAS\winpeas.zip"
    powershell -Command "Expand-Archive %ROOT%\PostEx\WinPEAS\winpeas.zip -DestinationPath %ROOT%\PostEx\WinPEAS -Force"
) else (
    echo [INFO] WinPEAS ja baixado, pulando...
)

REM DONUT
echo [+] Baixando ferramentas de Payload/Evasion (Office, HTA, MSI)...

REM DONUT (exe -> shellcode)
if not exist "%ROOT%\Payloads\Donut\donut.exe" (
    echo [DOWNLOAD] Donut...
    powershell -Command "iwr https://github.com/TheWover/donut/releases/latest/download/donut_v1.0_win64.zip -OutFile %ROOT%\Payloads\Donut\donut.zip"
    powershell -Command "Expand-Archive %ROOT%\Payloads\Donut\donut.zip -DestinationPath %ROOT%\Payloads\Donut -Force"
) else (
    echo [OK] Donut ja instalado.
)

REM SCARECROW (payload obfuscation + Office/HTA)
if not exist "%ROOT%\Payloads\ScareCrow\.git" (
    echo [DOWNLOAD] ScareCrow (AV evasion)...
    git clone https://github.com/optiv/ScareCrow "%ROOT%\Payloads\ScareCrow"
) else (
    echo [OK] ScareCrow ja clonado.
)

REM NIMCRYPT2 (.NET crypter)
if not exist "%ROOT%\Payloads\Nimcrypt2\.git" (
    echo [DOWNLOAD] Nimcrypt2...
    git clone https://github.com/icyguider/Nimcrypt2 "%ROOT%\Payloads\Nimcrypt2"
) else (
    echo [OK] Nimcrypt2 ja clonado.
)

echo.

REM IMPACKET (SMB/LDAP/Kerberos tools)
if not exist "%ROOT%\Tools\Impacket\.git" (
    echo [DOWNLOAD] Impacket Suite...
    git clone https://github.com/fortra/impacket "%ROOT%\Tools\Impacket"
    echo [INFO] Para instalar: cd %ROOT%\Tools\Impacket; pip install .
) else (
    echo [OK] Impacket ja clonado.
)

REM RESPONDER (LLMNR/NBT-NS poisoning)
if not exist "%ROOT%\Tools\Responder\.git" (
    echo [DOWNLOAD] Responder (LLMNR poisoning)...
    git clone https://github.com/lgandx/Responder "%ROOT%\Tools\Responder"
) else (
    echo [OK] Responder ja clonado.
)

echo.

REM EVIL-WINRM
gem install evil-winrm
echo [+] Evil-WinRM instalado!

REM ============================================================
REM ATIVAÇÃO DO WSL2
REM - O Windows exige reboot antes de instalar a distro
REM ============================================================
echo [+] Ativando WSL2...

powershell -Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all"
powershell -Command "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all"

echo.
echo [!] WSL habilitado. Reinicie o PC e execute o script novamente
echo     para instalar o Kali.
pause
exit /b

REM ============================================================
REM (APÓS O REBOOT, VOCÊ EXECUTA A PARTE ABAIXO MANUALMENTE)
REM ============================================================
echo [+] Instalando Kali WSL...
wsl --install -d kali-linux

REM ============================================================
REM CONFIGURAÇÃO DO PERFIL POWERSHELL (SEM DUPLICAÇÃO)
REM ============================================================
echo [+] Configurando PowerShell...

set PROFILE=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
mkdir "%USERPROFILE%\Documents\WindowsPowerShell" 2>nul

> "%PROFILE%" (
    echo Set-Alias ll ls
    echo Set-Alias la "ls -Force"
    echo Set-Alias grep Select-String
    echo Import-Module PSReadLine
    echo Set-PSReadLineOption -PredictionSource History
)

echo.
echo =====================================================
echo      ATTACKBOX NOTEBOOK 2 INSTALADA COM SUCESSO
echo =====================================================
echo Reinicie o sistema.
pause
exit /b 0
