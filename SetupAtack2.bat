@echo off
title AttackBox Ultimate Setup (FUNCIONAL)
chcp 65001 >nul

:: ============================================
:: VERIFICA PERMISSÃO DE ADMIN
:: ============================================
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

:: ============================================
:: 1 - LIBERAR POWERSHELL
:: ============================================
echo [+] Liberando PowerShell temporariamente...
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"

:: ============================================
:: 2 - INSTALAR CHOCOLATEY
:: ============================================
echo [+] Instalando Chocolatey...
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
"Set-ExecutionPolicy Bypass -Scope Process -Force; iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex"

:: força carregar novamente
set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

echo [+] Instalando ferramentas essenciais...

:: ============================================
:: 3 - FERRAMENTAS DE PENTEST
:: ============================================
choco install -y git
choco install -y python
choco install -y nmap
choco install -y wireshark
choco install -y sysinternals
choco install -y 7zip
choco install -y vscode
choco install -y jq
choco install -y openssh

:: ============================================
:: 4 - HABILITAR SERVIDOR SSH
:: ============================================
echo [+] Ativando OpenSSH Server...
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0" 
powershell -Command "Start-Service sshd"
powershell -Command "Set-Service sshd -StartupType Automatic"

:: ============================================
:: 5 - CRIAR ESTRUTURA DE PASTAS
:: ============================================
echo [+] Criando estrutura de pastas...

set ROOT=C:\AttackBox

mkdir %ROOT% >nul 2>&1

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

:: ============================================
:: 6 - INSTALAR WSL2 E KALI
:: ============================================
echo [+] Habilitando WSL2 + VirtualMachinePlatform...

powershell -Command "dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart"
powershell -Command "dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart"

echo [+] Instalando Kali WSL...
wsl --install -d kali-linux

:: ============================================
:: 7 - PERFIL POWERSHELL
:: ============================================
echo [+] Configurando aliases do PowerShell...

set PROFILE=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
mkdir "%USERPROFILE%\Documents\WindowsPowerShell" >nul 2>&1

(
echo Set-Alias ll ls
echo Set-Alias la "ls -Force"
echo Set-Alias grep Select-String
echo Import-Module PSReadLine
echo Set-PSReadLineOption -PredictionSource History
) >> "%PROFILE%"

:: ============================================
:: FINAL
:: ============================================
echo.
echo =====================================================
echo      ATTACKBOX INSTALADA E PRONTA PARA O USO
echo =====================================================
echo Reinicie o sistema para ativar todas as configuracoes.
echo.
pause
exit /b 0
