@echo off
title AttackBox Safe Setup - Notebook 2
color 0a

:: -------------------------
:: Verifica elevação (Admin)
:: -------------------------
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Este script deve ser executado como Administrador.
    echo [!] Clique com o botao direito -> Executar como administrador.
    pause
    exit /b 1
)

echo ====================================================
echo   AttackBox - Preparacao Segura (WSL2 + Tooling)
echo ====================================================
echo.

:: -------------------------
:: 1) Criar estrutura de pastas
:: -------------------------
echo [1/6] Criando pastas em C:\AttackBox...
mkdir "C:\AttackBox" 2>nul
mkdir "C:\AttackBox\Tools" 2>nul
mkdir "C:\AttackBox\Payloads" 2>nul
mkdir "C:\AttackBox\PostEx" 2>nul
mkdir "C:\AttackBox\WSL" 2>nul
mkdir "C:\AttackBox\Downloads" 2>nul
echo OK.
echo.

:: -------------------------
:: 2) Habilitar WSL e VirtualMachinePlatform
:: -------------------------
echo [2/6] Habilitando WSL2 e VirtualMachinePlatform (pode pedir reinicio)...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1
if %errorlevel% equ 0 (
    echo Recursos WSL habilitados (será necessario reiniciar apos instalacao do Kali).
) else (
    echo [!] Erro ao habilitar recursos WSL (verifique privileges). Continuando...
)
echo.

:: -------------------------
:: 3) Instalar Chocolatey (se nao existir)
:: -------------------------
echo [3/6] Instalando Chocolatey (se necessario)...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) } else {Write-Output 'choco ja instalado'}"
echo OK.
echo.

:: -------------------------
:: 4) Instalar pacotes basicos via choco
:: -------------------------
echo [4/6] Instalando pacotes basicos: git, python, dotnet-runtime, sysinternals, 7zip...
choco feature enable -n allowGlobalConfirmation >nul 2>&1
choco install -y git python dotnet-runtime --no-progress
choco install -y sysinternals 7zip --no-progress
echo OK.
echo.

:: -------------------------
:: 5) Instalar WSL2 (Kali) via wsl.exe (opcao 1 - sem GUI)
:: -------------------------
echo [5/6] Instalando Kali (WSL2) - aguarde. Pode pedir credenciais ao abrir pela primeira vez.
wsl --install -d kali-linux >nul 2>&1
if %errorlevel% equ 0 (
    echo Kali solicitado para instalacao via WSL2.
    echo Obs: Abra o aplicativo 'Kali' no menu iniciar apos reboot para completar a criacao do usuario.
) else (
    echo [!] Falha automatica ao invocar wsl --install. Tente instalar manualmente via: wsl --install -d kali-linux
)
echo.

:: -------------------------
:: 6) Defender: adicionar exclusao apenas para C:\AttackBox (NAO desativa Defender)
:: -------------------------
echo [6/6] Protegendo rotina: adicionando exclusao no Windows Defender para C:\AttackBox...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Try { Add-MpPreference -ExclusionPath 'C:\AttackBox' ; Write-Output 'Exclusao adicionada.' } Catch { Write-Output 'Falha ao adicionar exclusao no Defender: ' + $_.Exception.Message }"
echo OK.
echo.

:: -------------------------
:: Final: instrucoes e checklist
:: -------------------------
echo ====================================================
echo Finalizado. Confira os proximos passos (LEIA):
echo 1) Reinicie o sistema para finalizar a habilitacao do WSL/VirtualMachinePlatform.
echo 2) Abra o 'Kali' pelo menu iniciar e complete a criacao de usuario no primeiro boot.
echo 3) Dentro do WSL (Kali) rode: sudo apt update && sudo apt upgrade -y
echo 4) Instale ferramentas dentro do WSL APENAS em rede isolada / laboratorio.
echo 5) Crie uma snapshot/imagem do sistema (backup) antes de testar payloads reais.
echo 6) Configure VLAN isolada / switch separado para o lab. NUNCA conecte essa maquina a redes de producao sem autorizacao.
echo ====================================================

pause
exit /b 0
