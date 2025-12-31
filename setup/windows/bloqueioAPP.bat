@echo off
title BLOQUEIO TOTAL - ESCOLA
color 0A

echo ================================================
echo   APLICANDO BLOQUEIO TOTAL PARA ESCOLA
echo ================================================
echo.

:: ---------------------------------------------------
:: 1. BLOQUEAR DOWNLOADS
:: ---------------------------------------------------
echo [1/7] Bloqueando downloads...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v ScanWithAntiVirus /t REG_DWORD /d 3 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 2 /f >nul

:: ---------------------------------------------------
:: 2. FIREWALL – BLOQUEAR LAUNCHERS
:: ---------------------------------------------------
echo [2/7] Bloqueando launchers no Firewall...

set launchers="C:\Program Files (x86)\Steam\steam.exe" "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" "C:\Riot Games\Riot Client\RiotClientServices.exe" "C:\Program Files (x86)\Battle.net\Battle.net.exe" "C:\Program Files (x86)\Garena\Garena\Garena.exe" "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"

for %%i in (%launchers%) do (
    if exist %%i (
        netsh advfirewall firewall add rule name="Bloqueio %%i" dir=out action=block program="%%i" enable=yes
        echo   Bloqueado: %%i
    )
)

:: ---------------------------------------------------
:: 3. BLOQUEAR SITES DE DOWNLOAD
:: ---------------------------------------------------
echo [3/7] Bloqueando sites de jogos...

set sites=store.steampowered.com steamcommunity.com epicgames.com riotgames.com battle.net roblox.com minecraft.net garena.com mediafire.com mega.nz tlauncher.org uptodown.com baixaki.com.br

for %%s in (%sites%) do (
    echo 127.0.0.1 %%s >> %SystemRoot%\System32\drivers\etc\hosts
)

:: ---------------------------------------------------
:: 4. SOFTWARE RESTRICTION POLICY – BLOQUEAR EXECUÇÃO
:: ---------------------------------------------------
echo [4/7] Criando regras de bloqueio de execução...

reg add "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /t REG_DWORD /d 0 /f >nul

setlocal enabledelayedexpansion
set id=26200

for %%p in ("C:\Users\*\Downloads" "C:\Users\*\Desktop" "C:\Users\*\AppData\Local" "C:\Users\*\AppData\Roaming") do (
    reg add "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\Paths\!id!" /v ItemData /t REG_SZ /d %%p /f >nul
    reg add "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\Paths\!id!" /v SaferFlags /t REG_DWORD /d 0 /f >nul
    echo   Bloqueado: %%p
    set /a id+=1
)

:: ---------------------------------------------------
:: 5. BLOQUEAR INSTALADORES (.exe e .msi)
:: ---------------------------------------------------
echo [5/7] Bloqueando instaladores...

for %%x in ("setup.exe" "install.exe" "launcher.exe" "update.exe" "game.exe") do (
    reg add "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\Paths\!id!" /v ItemData /t REG_SZ /d %%x /f >nul
    reg add "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\Paths\!id!" /v SaferFlags /t REG_DWORD /d 0 /f >nul
    echo   Instalador bloqueado: %%x
    set /a id+=1
)

:: ---------------------------------------------------
:: 6. BLOQUEAR PEN-DRIVE
:: ---------------------------------------------------
echo [6/7] Bloqueando pendrive...

reg add "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /v Deny_All /t REG_DWORD /d 1 /f >nul

:: ---------------------------------------------------
:: 7. APLICAR POLÍTICAS
:: ---------------------------------------------------
echo [7/7] Aplicando politicas...
gpupdate /force >nul

echo.
echo ================================================
echo  BLOQUEIO TOTAL APLICADO COM SUCESSO!
echo ================================================
pause
exit
