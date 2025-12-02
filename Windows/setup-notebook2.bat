@echo off
title Notebook 2 - Setup Automático Completo
chcp 65001 >nul

REM ============================================================
REM  LAUNCHER PARA SETUP-NOTEBOOK2.PS1
REM ============================================================

echo ============================================================
echo   NOTEBOOK 2 - SETUP AUTOMÁTICO COMPLETO
echo   Windows Attack Box - AD / Lateral Movement
echo ============================================================
echo.

REM Verificar se está executando como admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Execute como Administrador!
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Executar script PowerShell
powershell -ExecutionPolicy Bypass -File "%~dp0setup-notebook2.ps1"

pause


