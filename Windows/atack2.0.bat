@echo off
title AttackBox Ultimate Setup (NOTEBOOK 2)
chcp 65001 >nul

REM ============================================================
REM VERIFICA SE O SCRIPT ESTÁ SENDO EXECUTADO COMO ADMINISTRADOR
REM - 'net session' só funciona com privilégios elevados
REM - Se não estiver como admin, o script se reinicia com RunAs
REM ============================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Este script precisa ser executado como Administrador.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo =====================================================
echo        ATTACKBOX NOTEBOOK 2 - INSTALLER FINAL
echo =====================================================
echo.

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
REM CRIAR ESTRUTURA DE DIRETÓRIOS BÁSICA
REM - O "2>nul" evita erro caso a pasta já exista
REM ============================================================
echo [+] Criando estrutura...

set ROOT=C:\AttackBox

mkdir %ROOT% 2>nul

mkdir %ROOT%\Bloodhound
mkdir %ROOT%\SharpHound

mkdir %ROOT%\AD-Tools
mkdir %ROOT%\AD-Tools\Powerview
mkdir %ROOT%\AD-Tools\PowerUp
mkdir %ROOT%\AD-Tools\PowerSharpPack
mkdir %ROOT%\AD-Tools\AD-Recon

mkdir %ROOT%\PostEx
mkdir %ROOT%\PostEx\Rubeus
mkdir %ROOT%\PostEx\Seatbelt
mkdir %ROOT%\PostEx\SharpUp
mkdir %ROOT%\PostEx\WinPEAS
mkdir %ROOT%\PostEx\SharpMapExec
mkdir %ROOT%\PostEx\PrinterNightmare

mkdir %ROOT%\Payloads
mkdir %ROOT%\Payloads\Office
mkdir %ROOT%\Payloads\HTA
mkdir %ROOT%\Payloads\MSI
mkdir %ROOT%\Payloads\EXE

mkdir %ROOT%\Enum
mkdir %ROOT%\Enum\smb
mkdir %ROOT%\Enum\http
mkdir %ROOT%\Enum\ldap

mkdir %ROOT%\Tools
mkdir %ROOT%\Tools\sysinternals
mkdir %ROOT%\Tools\mimikatz
mkdir %ROOT%\Tools\impacket
mkdir %ROOT%\Tools\evilwinrm

REM ============================================================
REM AVISO SOBRE GIT CLONE / EXPAND-ARCHIVE
REM - 'git clone' falha se pasta existir
REM - 'Expand-Archive' falha se zip estiver corrompido
REM - Execuções repetidas podem abortar o script
REM ============================================================

echo [+] Baixando ferramentas AD / Post-Ex / Payloads...

REM BLOODHOUND GUI
if not exist "%ROOT%\Bloodhound\Bloodhound.zip" (
    powershell -Command "iwr https://github.com/BloodHoundAD/BloodHound/releases/latest/download/BloodHound-win32-x64.zip -OutFile %ROOT%\Bloodhound\Bloodhound.zip"
    powershell -Command "Expand-Archive %ROOT%\Bloodhound\Bloodhound.zip -DestinationPath %ROOT%\Bloodhound -Force"
) else (
    echo [INFO] Bloodhound ja baixado, pulando...
)

REM SHARPHOUND
if not exist "%ROOT%\SharpHound\SharpHound.zip" (
    powershell -Command "iwr https://github.com/BloodHoundAD/SharpHound/releases/latest/download/SharpHound.zip -OutFile %ROOT%\SharpHound\SharpHound.zip"
    powershell -Command "Expand-Archive %ROOT%\SharpHound\SharpHound.zip -DestinationPath %ROOT%\SharpHound -Force"
) else (
    echo [INFO] SharpHound ja baixado, pulando...
)

REM POWERVIEW
if not exist "%ROOT%\AD-Tools\Powerview\.git" (
    git clone https://github.com/PowerShellEmpire/PowerTools "%ROOT%\AD-Tools\Powerview"
) else (
    echo [INFO] PowerView ja clonado, pulando...
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
if not exist "%ROOT%\Payloads\donut.zip" (
    powershell -Command "iwr https://github.com/TheWover/donut/releases/latest/download/donut.zip -OutFile %ROOT%\Payloads\donut.zip"
    powershell -Command "Expand-Archive %ROOT%\Payloads\donut.zip -DestinationPath %ROOT%\Payloads -Force"
) else (
    echo [INFO] Donut ja baixado, pulando...
)

REM SCARECROW
if not exist "%ROOT%\Payloads\ScareCrow\.git" (
    git clone https://github.com/optiv/ScareCrow "%ROOT%\Payloads\ScareCrow"
) else (
    echo [INFO] ScareCrow ja clonado, pulando...
)

REM NIMCRYPT2
if not exist "%ROOT%\Payloads\Nimcrypt2\.git" (
    git clone https://github.com/icyguider/Nimcrypt2 "%ROOT%\Payloads\Nimcrypt2"
) else (
    echo [INFO] Nimcrypt2 ja clonado, pulando...
)

REM IMPACKET
if not exist "%ROOT%\Tools\impacket\.git" (
    git clone https://github.com/fortra/impacket "%ROOT%\Tools\impacket"
) else (
    echo [INFO] Impacket ja clonado, pulando...
)

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
