@echo off
REM Detecta se está rodando a partir de um pendrive (letra de unidade removível)
setlocal enabledelayedexpansion
set DRIVE=%~d0
wmic logicaldisk where "DeviceID='%DRIVE%'" get DriveType | find "2" > nul
if %errorlevel%==0 (
    echo Executando a partir de um pendrive (unidade removível).
    call "%~dp0payload.bat"
) else (
    echo Nao esta em um pendrive.
)
