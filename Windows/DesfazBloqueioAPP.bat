@echo off
title DESBLOQUEIO TOTAL - REVERSAO
color 0C

echo ================================================
echo      REVERTENDO TODAS AS ALTERAÇÕES
echo ================================================
echo.

:: ---------------------------------------------------
:: 1. DESFAZER BLOQUEIO DE DOWNLOADS
:: ---------------------------------------------------
echo [1/7] Restaurando configuracoes de downloads...

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v ScanWithAntiVirus /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /f >nul

:: ---------------------------------------------------
:: 2. REMOVER REGRAS DO FIREWALL
:: ---------------------------------------------------
echo [2/7] Removendo regras de Firewall...

set launchers="C:\Program Files (x86)\Steam\steam.exe" "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" "C:\Riot Games\Riot Client\RiotClientServices.exe" "C:\Program Files (x86)\Battle.net\Battle.net.exe" "C:\Program Files (x86)\Garena\Garena\Garena.exe" "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"

for %%i in (%launchers%) do (
    netsh advfirewall firewall delete rule name="Bloqueio %%i" >nul 2>&1
    netsh advfirewall firewall delete rule program=%%i >nul 2>&1
    echo   Desbloqueado: %%i
)

:: ---------------------------------------------------
:: 3. DESFAZER BLOQUEIO DE SITES NO HOSTS
:: ---------------------------------------------------
echo [3/7] Restaurando arquivo hosts...

set hostsfile=%SystemRoot%\System32\drivers\etc\hosts
set tmp=%SystemRoot%\System32\drivers\etc\hosts_clean

(
    for /f "tokens=* usebackq" %%a in ("%hostsfile%") do (
        echo %%a | findstr /i "steampowered steamcommunity epicgames riotgames battle.net roblox minecraft net garena mediafire mega.nz tlauncher uptodown baixaki" >nul
        if errorlevel 1 echo %%a
    )
) > "%tmp%"

copy /y "%tmp%" "%hostsfile%" >nul
del "%tmp%" >nul

:: ---------------------------------------------------
:: 4. REMOVER SOFTWARE RESTRICTION POLICY (SRP)
:: ---------------------------------------------------
echo [4/7] Removendo restricoes de execucao...

reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /f >nul

:: ---------------------------------------------------
:: 5. DESBLOQUEAR INSTALADORES
:: (já incluso ao remover o Safer CodeIdentifiers)
:: ---------------------------------------------------
echo [5/7] Instaladores liberados.

:: ---------------------------------------------------
:: 6. DESBLOQUEAR PEN-DRIVE
:: ---------------------------------------------------
echo [6/7] Restaurando acesso ao USB...

reg delete "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /v Deny_All /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /f >nul 2>&1
reg delete "HKLM\System\CurrentControlSet\Control\StorageDevicePolicies" /v WriteProtect /f >nul 2>&1

:: ---------------------------------------------------
:: 7. APLICAR POLÍTICAS
:: ---------------------------------------------------
echo [7/7] Atualizando politicas...
gpupdate /force >nul

echo.
echo ================================================
echo  DESBLOQUEIO TOTAL CONCLUIDO!
echo  Reinicie o computador.
echo ================================================
pause
exit
