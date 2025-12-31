@echo off
title Verificacao Completa - AttackBox Windows
cls

echo ================================================
echo     VERIFICACAO COMPLETA DO ATTACKBOX WINDOWS
echo ================================================
echo.

:: ====== FUNCAO CHECK ======
:check
set VALUE=%1
set EXPECT=%2
set MSG=%3

if "%VALUE%"=="%EXPECT%" (
    echo [OK] %MSG%
) else (
    echo [FALHOU] %MSG%  (valor: %VALUE%)
)
goto :eof

:: ====== 1. CHECAR DEFENDER ======
echo [1/9] Verificando Windows Defender...
powershell -command ^
 "Get-MpComputerStatus | Format-List RealTimeProtectionEnabled,BehaviorMonitoring,IOAVProtectionEnabled" ^
 > defender.tmp 2>nul

findstr /i "False" defender.tmp >nul
if %errorlevel%==0 (
    echo [OK] Defender aparentemente desativado.
) else (
    echo [FALHOU] Defender ainda possui protecoes ativas.
)

del defender.tmp
echo.

:: ====== 2. CHECAR SSH ======
echo [2/9] Verificando servico SSH...
for /f "tokens=3" %%a in ('sc query sshd ^| findstr STATE') do set SSHSTATE=%%a
call :check "%SSHSTATE%" "RUNNING" "SSHD ativo"
echo.

:: ====== 3. CHECAR PORTA 22 ======
echo [3/9] Verificando porta 22...
netstat -ano | findstr :22 >nul
if %errorlevel%==0 (
    echo [OK] Porta 22 aberta e escutando.
) else (
    echo [FALHOU] Porta 22 nao esta escutando.
)
echo.

:: ====== 4. CHECAR CHOCOLATEY ======
echo [4/9] Verificando Chocolatey...
choco -v >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Chocolatey instalado.
) else (
    echo [FALHOU] Chocolatey nao encontrado.
)
echo.

:: ====== 5. CHECAR FERRAMENTAS ======
echo [5/9] Verificando ferramentas instaladas...

call :tool nmap
call :tool wireshark
call :tool python
call :tool git
call :tool code
call :tool curl
call :tool rustc

echo.
goto continue_check

:tool
%1 --version >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Ferramenta %1 encontrada.
) else (
    echo [FALHOU] Ferramenta %1 nao encontrada.
)
goto :eof

:continue_check

:: ====== 6. CHECAR PERFIL DO POWERSHELL ======
echo [6/9] Verificando perfil do PowerShell...

powershell -command ^
 "if (Test-Path $PROFILE) { exit 0 } else { exit 1 }"

if %errorlevel%==0 (
    echo [OK] Perfil do PowerShell existe.
) else (
    echo [FALHOU] Perfil do PowerShell nao encontrado.
)
echo.

:: ====== 7. CHECAR WSL ======
echo [7/9] Verificando WSL2...
wsl -l -v > wsl.tmp 2>nul

findstr /i "kali" wsl.tmp >nul
if %errorlevel%==0 (
    echo [OK] Kali WSL encontrado.
) else (
    echo [FALHOU] Kali WSL nao detectado.
)

findstr /i "2" wsl.tmp >nul
if %errorlevel%==0 (
    echo [OK] WSL2 esta ativo.
) else (
    echo [FALHOU] WSL esta em modo 1 (errado).
)

del wsl.tmp
echo.

:: ====== 8. MODO DE ENERGIA ======
echo [8/9] Verificando plano de energia...
powercfg /getactivescheme | findstr /i "High" >nul
if %errorlevel%==0 (
    echo [OK] Modo de alto desempenho ativo.
) else (
    echo [FALHOU] Modo de energia nao esta no maximo.
)
echo.

:: ====== 9. SERVICOS DESATIVADOS ======
echo [9/9] Verificando servicos desativados...

for %%s in (diagtrack wsearch SysMain) do (
    sc query %%s | findstr /i "STOPPED" >nul
    if !errorlevel!==0 (
        echo [OK] %%s desativado.
    ) else (
        echo [FALHOU] %%s esta ativo.        
    )
)

echo.
echo ================================================
echo        VERIFICACAO FINALIZADA!
echo ================================================
pause
exit
