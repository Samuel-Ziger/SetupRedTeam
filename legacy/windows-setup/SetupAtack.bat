@echo off
title AttackBox Ultimate Setup
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
:: 1 - DESATIVAR RESTRICOES DO POWERSHELL
:: ============================================
echo [+] Liberando PowerShell temporariamente...
powershell -Command "Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force"
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"

:: ============================================
:: 2 - DESATIVAR SMARTSCREEN
:: ============================================
echo [+] Desativando SmartScreen...
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControlEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul

:: ============================================
:: 3 - DESATIVAR WINDOWS DEFENDER COMPLETO
:: ============================================
echo [+] Desativando Windows Defender...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true"
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true"
powershell -Command "Set-MpPreference -DisableIOAVProtection $true"
powershell -Command "Set-MpPreference -DisablePrivacyMode $true"
powershell -Command "Set-MpPreference -SignatureDisableUpdateOnStartupWithoutEngine $true"
powershell -Command "net stop WinDefend"

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul

:: ============================================
:: 4 - INSTALAR CHOCOLATEY
:: ============================================
echo [+] Instalando Chocolatey...
powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command ^
"Set-ExecutionPolicy Bypass -Scope Process -Force; iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex"

:: Atualiza o PATH após instalar o Choco
refreshenv >nul 2>&1

:: ============================================
:: 5 - INSTALAR FERRAMENTAS DE PENTEST
:: ============================================
echo.
echo [+] Instalando ferramentas essenciais...

choco install -y nmap
choco install -y wireshark
choco install -y metasploit
choco install -y gobuster
choco install -y curl
choco install -y python
choco install -y git
choco install -y fzf
choco install -y 7zip
choco install -y vscode
choco install -y neovim
choco install -y rust
choco install -y openssh

:: Ferramentas extras
choco install -y whois
choco install -y wget
choco install -y jq

:: ============================================
:: 6 - CONFIGURAR SSH FULL
:: ============================================
echo [+] Ativando servidor SSH...
powershell -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0" >nul 2>&1
powershell -Command "Start-Service sshd" 
powershell -Command "Set-Service -Name sshd -StartupType Automatic"

:: ============================================
:: 7 - ADICIONAR ALIASES E FERRAMENTAS NO POWERSHELL
:: ============================================
echo [+] Configurando ambiente PowerShell...

(
echo Set-Alias ll ls
echo Set-Alias la "ls -Force"
echo Set-Alias grep Select-String
echo Set-Alias wget curl
echo Set-Alias cat Get-Content
echo Import-Module PSReadLine
echo Set-PSReadLineOption -PredictionSource History
) >> "%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

:: ============================================
:: 8 - OTIMIZAR PERFORMANCE DO WINDOWS
:: ============================================
echo [+] Ajustando desempenho para Máximo...

:: Performance absoluta
powershell -Command "powercfg -setactive SCHEME_MIN"

:: Desliga hibernação
powercfg -h off

:: Desliga energia híbrida
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul

:: Remove limites de execução
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul

:: ============================================
:: 9 - REDUZIR SERVIÇOS DO WINDOWS (DEIXA MAIS LEVE)
:: ============================================
echo [+] Desativando serviços desnecessários...

sc stop "DiagTrack" >nul
sc config "DiagTrack" start=disabled

sc stop "WSearch" >nul
sc config "WSearch" start=disabled

sc stop "RetailDemo" >nul
sc config "RetailDemo" start=disabled

:: ============================================
:: 10 - LIMPEZA FINAL
:: ============================================
echo [+] Limpando arquivos temporários...
del /s /q "%TEMP%\*" >nul 2>&1

echo [+] Atualizando PATH e sessões...
refreshenv >nul 2>&1

echo.
echo =====================================================
echo      ATTACKBOX INSTALADA E PRONTA PARA O USO
echo =====================================================
echo Reinicie o sistema para ativar todas as configuracoes.
echo.
pause
exit /b 0
