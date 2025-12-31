@echo off
title ROLLBACK - AttackBox Windows
color 0C

echo =====================================================
echo   ROLLBACK - REVERTER CONFIGURACOES ATTACKBOX
echo =====================================================
echo.
echo AVISO: Este script ira reverter as alteracoes feitas
echo pelos scripts de setup da AttackBox.
echo.
echo O que sera revertido:
echo  - Reativar Windows Defender
echo  - Restaurar ExecutionPolicy
echo  - Remover exclusoes do Defender
echo  - Reativar servicos do Windows
echo  - (OPCIONAL) Remover ferramentas instaladas
echo.
pause

REM ============================================
REM VERIFICACAO DE ADMIN
REM ============================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Este script precisa ser executado como Administrador.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo =====================================================
echo   INICIANDO ROLLBACK...
echo =====================================================
echo.

REM ============================================
REM 1. REATIVAR WINDOWS DEFENDER
REM ============================================
echo [1/8] Reativando Windows Defender...

powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false"
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false"
powershell -Command "Set-MpPreference -DisableIOAVProtection $false"

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1

powershell -Command "Start-Service WinDefend" >nul 2>&1

echo [OK] Defender reativado.
echo.

REM ============================================
REM 2. REMOVER EXCLUSOES DO DEFENDER
REM ============================================
echo [2/8] Removendo exclusoes do Defender...

powershell -Command "Remove-MpPreference -ExclusionPath 'C:\Tools' -ErrorAction SilentlyContinue"
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\AttackBox' -ErrorAction SilentlyContinue"
powershell -Command "Remove-MpPreference -ExclusionPath 'C:\Users\%USERNAME%\AppData\Local\Temp' -ErrorAction SilentlyContinue"

echo [OK] Exclusoes removidas.
echo.

REM ============================================
REM 3. RESTAURAR EXECUTIONPOLICY
REM ============================================
echo [3/8] Restaurando ExecutionPolicy...

powershell -Command "Set-ExecutionPolicy Restricted -Scope LocalMachine -Force"

echo [OK] ExecutionPolicy restaurado para Restricted.
echo.

REM ============================================
REM 4. REATIVAR SMARTSCREEN
REM ============================================
echo [4/8] Reativando SmartScreen...

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v ConfigureAppInstallControlEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\SmartScreen" /v EnableSmartScreen /f >nul 2>&1

echo [OK] SmartScreen reativado.
echo.

REM ============================================
REM 5. REATIVAR SERVICOS DO WINDOWS
REM ============================================
echo [5/8] Reativando servicos do Windows...

sc config "DiagTrack" start=auto >nul
sc start "DiagTrack" >nul 2>&1

sc config "WSearch" start=auto >nul
sc start "WSearch" >nul 2>&1

echo [OK] Servicos reativados.
echo.

REM ============================================
REM 6. RESTAURAR MODO DE ENERGIA
REM ============================================
echo [6/8] Restaurando plano de energia...

powercfg -setactive SCHEME_BALANCED

echo [OK] Modo de energia restaurado para Balanceado.
echo.

REM ============================================
REM 7. REATIVAR HIBERNACAO
REM ============================================
echo [7/8] Reativando hibernacao...

powercfg -h on

echo [OK] Hibernacao reativada.
echo.

REM ============================================
REM 8. REMOVER FERRAMENTAS (OPCIONAL)
REM ============================================
echo [8/8] Remover ferramentas instaladas?
echo.
echo Isso ira:
echo  - Desinstalar Chocolatey e todas as ferramentas
echo  - Remover C:\Tools
echo  - Remover C:\AttackBox
echo  - Manter WSL2 e Kali (nao sera removido)
echo.
choice /C SN /M "Deseja remover as ferramentas?"

if %errorlevel%==1 (
    echo.
    echo Removendo ferramentas...
    
    REM Desinstalar tudo via Chocolatey
    if exist "%ALLUSERSPROFILE%\chocolatey\bin\choco.exe" (
        echo [+] Desinstalando pacotes Chocolatey...
        choco uninstall all -y
        
        echo [+] Removendo Chocolatey...
        rmdir /s /q "%ALLUSERSPROFILE%\chocolatey" 2>nul
    )
    
    REM Remover diretórios
    if exist "C:\Tools" (
        echo [+] Removendo C:\Tools...
        rmdir /s /q "C:\Tools" 2>nul
    )
    
    if exist "C:\AttackBox" (
        echo [+] Removendo C:\AttackBox...
        rmdir /s /q "C:\AttackBox" 2>nul
    )
    
    echo [OK] Ferramentas removidas.
) else (
    echo [INFO] Ferramentas mantidas.
)

echo.
echo =====================================================
echo   ROLLBACK CONCLUIDO COM SUCESSO!
echo =====================================================
echo.
echo Recomendacoes:
echo  1. Reinicie o sistema
echo  2. Execute o Windows Defender para scan completo
echo  3. Verifique as configuracoes de seguranca
echo.
pause
exit /b 0
