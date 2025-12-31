@echo off
title AttackBox Ultimate Setup (SAFE MODE)
chcp 65001 >nul

REM ============================
REM VERIFICA ADMIN
REM ============================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Este script precisa ser executado como Administrador.
    echo Reabrindo com privilegios elevados...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo =====================================================
echo        ATTACKBOX ULTIMATE - CONFIGURACAO COMPLETA
echo =====================================================
echo.

REM ============================
REM LIBERAR POWERSHELL
REM ============================
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"

REM ============================
REM INSTALAR CHOCOLATEY
REM ============================
echo [+] Instalando Chocolatey...
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex"

set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

REM ============================
REM FERRAMENTAS ESSENCIAIS
REM ============================
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

REM ============================
REM HABILITAR SSH
REM ============================
echo [+] Ativando SSH...
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
powershell -Command "Start-Service sshd"
powershell -Command "Set-Service sshd -StartupType Automatic"

REM ============================
REM ESTRUTURA DE PASTAS
REM ============================
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

REM ============================
REM WSL2 + KALI
REM ============================
echo [+] Ativando WSL2...

powershell -Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
powershell -Command "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"

echo [+] Instalando Kali WSL...
wsl --install -d kali-linux

REM ============================
REM PERFIL POWERSHELL
REM ============================
echo [+] Configurando PowerShell Profile...

set PROFILE=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
mkdir "%USERPROFILE%\Documents\WindowsPowerShell" 2>nul

(
echo Set-Alias ll ls
echo Set-Alias la "ls -Force"
echo Set-Alias grep Select-String
echo Import-Module PSReadLine
echo Set-PSReadLineOption -PredictionSource History
) >> "%PROFILE%"

echo.
echo =====================================================
echo      ATTACKBOX INSTALADA E PRONTA PARA O USO
echo =====================================================
echo Reinicie o sistema.
echo.
pause
exit /b 0
