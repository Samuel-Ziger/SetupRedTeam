@echo off
title AttackBox Notebook 2 - Setup Automático
chcp 65001 >nul

:: -----------------------------------------------------
:: Elevar para Administrador
:: -----------------------------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Reabrindo com privilegios de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

cls
echo ================================================
echo     AttackBox Notebook 2 - Instalacao Completa
echo ================================================
echo.

:: -----------------------------------------------------
:: Liberar PowerShell
:: -----------------------------------------------------
echo [+] Liberando PowerShell...
powershell -Command "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"

:: -----------------------------------------------------
:: Desativar SmartScreen
:: -----------------------------------------------------
echo [+] Desativando SmartScreen...
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul

:: -----------------------------------------------------
:: Desativar Windows Defender inteiro
:: -----------------------------------------------------
echo [+] Desativando Windows Defender...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true"
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true"
powershell -Command "Set-MpPreference -DisableIOAVProtection $true"
powershell -Command "Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true"
powershell -Command "Set-MpPreference -MAPSReporting 0"
powershell -Command "Set-MpPreference -DisableScriptScanning $true"

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul

net stop WinDefend >nul 2>&1

:: -----------------------------------------------------
:: Criar estrutura AttackBox
:: -----------------------------------------------------
echo [+] Criando estrutura AttackBox...
mkdir "C:\AttackBox" >nul 2>&1
mkdir "C:\AttackBox\Tools" >nul 2>&1
mkdir "C:\AttackBox\Payloads" >nul 2>&1
mkdir "C:\AttackBox\Scripts" >nul 2>&1
mkdir "C:\AttackBox\Wordlists" >nul 2>&1

:: -----------------------------------------------------
:: Instalar Chocolatey
:: -----------------------------------------------------
echo [+] Instalando Chocolatey...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex"

:: Forçar atualização do PATH
call "%ProgramData%\chocolatey\bin\refreshenv.cmd" >nul 2>&1

:: -----------------------------------------------------
:: Instalar ferramentas essenciais
:: -----------------------------------------------------
echo [+] Instalando ferramentas de pentest...

choco install -y nmap
choco install -y wireshark
choco install -y python
choco install -y git
choco install -y curl
choco install -y neovim
choco install -y vscode
choco install -y 7zip
choco install -y jq
choco install -y wget
choco install -y fzf
choco install -y openssh

:: Ferramentas extras
choco install -y rust
choco install -y sysinternals

:: -----------------------------------------------------
:: Ativar SSH Server no Windows
:: -----------------------------------------------------
echo [+] Ativando servidor SSH...
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"
powershell -Command "Set-Service sshd -StartupType Automatic"
powershell -Command "Start-Service sshd"

:: -----------------------------------------------------
:: Configurar PowerShell com aliases úteis
:: -----------------------------------------------------
echo [+] Configurando PowerShell...

(
echo Set-Alias ll ls
echo Set-Alias la "ls -Force"
echo Set-Alias grep Select-String
echo Set-Alias cat Get-Content
echo Import-Module PSReadLine
echo Set-PSReadLineOption -PredictionSource History
) >> "%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

:: -----------------------------------------------------
:: Otimizar desempenho
:: -----------------------------------------------------
echo [+] Otimizando desempenho...

powercfg -setactive SCHEME_MIN
powercfg -h off

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul

:: -----------------------------------------------------
:: Desativar serviços inúteis
:: -----------------------------------------------------
echo [+] Desativando servicos desnecessarios...

sc stop "DiagTrack" >nul
sc config "DiagTrack" start=disabled

sc stop "WSearch" >nul
sc config "WSearch" start=disabled

:: -----------------------------------------------------
:: Limpeza final
:: -----------------------------------------------------
echo [+] Limpando arquivos temporarios...
del /s /q "%TEMP%\*" >nul 2>&1

echo.
echo ================================================
echo     AttackBox instalada e pronta para uso!
echo ================================================
echo Reinicie o notebook para aplicar tudo.
echo.
pause
exit /b 0
