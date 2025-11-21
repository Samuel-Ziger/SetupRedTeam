@echo off
setlocal

:: Caminho do script PowerShell
set SCRIPT=%~dp0setup-attackbox.ps1

:: Verifica se o script existe
if not exist "%SCRIPT%" (
    echo ERRO: O arquivo setup-attackbox.ps1 nao foi encontrado no mesmo diretorio.
    pause
    exit /b 1
)

:: Detecta se tem permissoes de Admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissoes de administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo ===============================================
echo Iniciando Script de Instalacao da AttackBox...
echo ===============================================

:: Altera temporariamente a ExecutionPolicy
powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force"

:: Executa o script PowerShell
powershell -ExecutionPolicy Bypass -File "%SCRIPT%"

echo ===============================================
echo Script Finalizado!
echo ===============================================
pause

endlocal
exit /b 0
