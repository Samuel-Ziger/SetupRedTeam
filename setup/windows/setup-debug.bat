@echo off
setlocal enabledelayedexpansion
title SETUP ATTACKBOX - DEBUG MODE (NAO FECHA)
cls

:: Mantém a janela aberta mesmo se ocorrer erro fatal
echo ================================================
echo      ATTACKBOX WINDOWS - MODO DEBUG
echo      A JANELA NAO VAI FECHAR
echo ================================================
echo.

echo [DEBUG] Script iniciou. Se travar aqui, problema no CMD.
pause

:: Testa Admin
echo [DEBUG] Testando privilegio Admin...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRO: Script NAO esta como Admin.
    echo Clique com o botao direito e escolha: Executar como administrador
    echo.
    pause
    exit /b
)
echo [OK] Executando como Administrador.
pause

echo [DEBUG] Iniciando instalacao do setup original...
pause

:: Roda seu setup REAL e captura todos os erros sem fechar
powershell -ExecutionPolicy Bypass -File "%~dp0setup-attackbox.ps1"
echo.
echo [DEBUG] O script PowerShell terminou de rodar.
echo.

pause
exit /b
