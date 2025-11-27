@echo off
title DESBLOQUEIO COMPLETO - LIMPEZA TOTAL
color 0E

:: -------------------------
:: Verifica se é admin
:: -------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ================================================
    echo  ERRO: Execute como Administrador!
    echo ================================================
    echo Clique com o botao direito e escolha
    echo "Executar como administrador"
    pause
    exit /b 1
)

echo ================================================
echo     DESBLOQUEIO COMPLETO - LIMPEZA TOTAL
echo ================================================
echo.
echo Este script ira:
echo  - Remover TODAS as regras de firewall de bloqueio
echo  - Restaurar arquivo hosts ao padrao
echo  - Remover restricoes de execucao (SRP/Safer)
echo  - Desbloquear USB/Pendrive
echo  - Restaurar permissoes de download
echo.
pause

:: -------------------------
:: 1) RESTAURAR ARQUIVO HOSTS
:: -------------------------
echo.
echo [1/8] Restaurando arquivo hosts...
set hostsfile=%SystemRoot%\System32\drivers\etc\hosts

:: Assumir propriedade
takeown /f "%hostsfile%" >nul 2>&1
icacls "%hostsfile%" /grant Administrators:F >nul 2>&1

:: Escrever conteudo padrao
(
    echo # Copyright (c) 1993-2009 Microsoft Corp.
    echo # This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
    echo # localhost name resolution is handled within DNS itself.
    echo 127.0.0.1       localhost
    echo ::1             localhost
) > "%hostsfile%"

echo    [OK] Hosts restaurado

:: -------------------------
:: 2) LIMPAR CACHE DNS
:: -------------------------
echo [2/8] Limpando cache DNS...
ipconfig /flushdns >nul 2>&1
echo    [OK] Cache DNS limpo

:: -------------------------
:: 3) REMOVER REGRAS DE FIREWALL
:: -------------------------
echo [3/8] Removendo TODAS as regras de firewall de bloqueio...

:: Lista de executaveis que podem estar bloqueados
set "launchers=C:\Program Files (x86)\Steam\steam.exe"
set "launchers=%launchers% C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
set "launchers=%launchers% C:\Riot Games\Riot Client\RiotClientServices.exe"
set "launchers=%launchers% C:\Program Files (x86)\Battle.net\Battle.net.exe"
set "launchers=%launchers% C:\Program Files (x86)\Garena\Garena\Garena.exe"
set "launchers=%launchers% C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"

for %%i in (%launchers%) do (
    netsh advfirewall firewall delete rule name="Bloqueio %%i" >nul 2>&1
    netsh advfirewall firewall delete rule program="%%i" >nul 2>&1
)

:: Remover regras com padroes de nome
netsh advfirewall firewall delete rule name=all dir=out >nul 2>&1
netsh advfirewall firewall show rule name=all | findstr /i "bloqueio" >nul 2>&1
if %errorlevel% equ 0 (
    echo    Removendo regras com "Bloqueio" no nome...
    for /f "tokens=2 delims=:" %%a in ('netsh advfirewall firewall show rule name^=all ^| findstr /i /c:"Nome da Regra" /c:"Rule Name"') do (
        set rulename=%%a
        echo !rulename! | findstr /i "bloqueio" >nul
        if !errorlevel! equ 0 (
            netsh advfirewall firewall delete rule name="!rulename!" >nul 2>&1
        )
    )
)

echo    [OK] Regras de firewall removidas

:: -------------------------
:: 4) REMOVER SOFTWARE RESTRICTION POLICY (SRP)
:: -------------------------
echo [4/8] Removendo restricoes de execucao (SRP/Safer)...
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\SrpV2" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\Safer" /f >nul 2>&1
echo    [OK] SRP removido

:: -------------------------
:: 5) DESBLOQUEAR PENDRIVE/USB
:: -------------------------
echo [5/8] Desbloqueando dispositivos USB...
reg delete "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /f >nul 2>&1
reg delete "HKLM\System\CurrentControlSet\Control\StorageDevicePolicies" /f >nul 2>&1
reg delete "HKLM\System\CurrentControlSet\Services\USBSTOR" /v Start /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo    [OK] USB desbloqueado

:: -------------------------
:: 6) RESTAURAR DOWNLOADS
:: -------------------------
echo [6/8] Restaurando permissoes de download...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /f >nul 2>&1
echo    [OK] Downloads restaurados

:: -------------------------
:: 7) REMOVER APPLOCKER (se existir)
:: -------------------------
echo [7/8] Limpando AppLocker...
powershell -Command "Try { Set-AppLockerPolicy -XMLPolicy '<AppLockerPolicy Version=\"1\" />' -ErrorAction Stop } Catch { }" >nul 2>&1
echo    [OK] AppLocker limpo

:: -------------------------
:: 8) ATUALIZAR POLITICAS
:: -------------------------
echo [8/8] Aplicando mudancas nas politicas do sistema...
gpupdate /force >nul 2>&1
echo    [OK] Politicas atualizadas

:: -------------------------
:: FINALIZADO
:: -------------------------
echo.
echo ================================================
echo  DESBLOQUEIO COMPLETO FINALIZADO!
echo ================================================
echo.
echo Importante:
echo  1. REINICIE o computador agora
echo  2. Apos reiniciar, verifique se tudo funciona
echo  3. Se ainda houver bloqueios, execute este
echo     script novamente como administrador
echo.
echo ================================================
pause
exit /b 0
