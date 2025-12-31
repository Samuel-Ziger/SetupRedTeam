@echo off
title DESBLOQUEIO - REVERTER BLOQUEIO TOTAL
color 0E

:: ===================================================================
::  SCRIPT DE REVERSAO - DESFAZ BLOQUEIO APLICADO POR bloqueioAPP.bat
:: ===================================================================

echo ================================================
echo   PREVIEW: ACOES QUE SERAO EXECUTADAS
echo ================================================
echo.
echo Este script ira DESFAZER as seguintes configuracoes:
echo.
echo [1/7] Remover bloqueio de downloads
echo       - Restaurar politica de anexos
echo.
echo [2/7] Remover regras de Firewall para launchers
echo       - Steam
echo       - Epic Games
echo       - Riot Client
echo       - Battle.net
echo       - Garena
echo       - Minecraft Launcher
echo.
echo [3/7] Remover bloqueio de sites do arquivo hosts
echo       - store.steampowered.com
echo       - steamcommunity.com
echo       - epicgames.com
echo       - riotgames.com
echo       - battle.net
echo       - roblox.com
echo       - minecraft.net
echo       - garena.com
echo       - mediafire.com
echo       - mega.nz
echo       - tlauncher.org
echo       - uptodown.com
echo       - baixaki.com.br
echo.
echo [4/7] Remover Software Restriction Policy
echo       - Remover bloqueios de pastas (Downloads, Desktop, AppData)
echo.
echo [5/7] Remover bloqueio de instaladores
echo       - Desbloquear setup.exe, install.exe, launcher.exe, etc
echo.
echo [6/7] Desbloquear pendrive
echo       - Remover politica de bloqueio de dispositivos removiveis
echo.
echo [7/7] Aplicar politicas
echo       - Executar gpupdate /force
echo.
echo ================================================
echo   ATENCAO: Isso revertera TODAS as restricoes!
echo ================================================
echo.
echo Pressione qualquer tecla para CONFIRMAR e EXECUTAR...
echo Ou feche esta janela para CANCELAR.
pause >nul

cls
echo ================================================
echo   EXECUTANDO DESBLOQUEIO...
echo ================================================
echo.

:: ---------------------------------------------------
:: 1. DESBLOQUEAR DOWNLOADS
:: ---------------------------------------------------
echo [1/7] Desbloqueando downloads...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v ScanWithAntiVirus /f 2>nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /f 2>nul
echo   Downloads desbloqueados!

:: ---------------------------------------------------
:: 2. FIREWALL – DESBLOQUEAR LAUNCHERS
:: ---------------------------------------------------
echo [2/7] Removendo regras de bloqueio do Firewall...

set launchers="C:\Program Files (x86)\Steam\steam.exe" "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" "C:\Riot Games\Riot Client\RiotClientServices.exe" "C:\Program Files (x86)\Battle.net\Battle.net.exe" "C:\Program Files (x86)\Garena\Garena\Garena.exe" "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"

for %%i in (%launchers%) do (
    netsh advfirewall firewall delete rule name="Bloqueio %%i" 2>nul
    echo   Desbloqueado: %%i
)

:: ---------------------------------------------------
:: 3. DESBLOQUEAR SITES (REMOVER DO HOSTS)
:: ---------------------------------------------------
echo [3/7] Removendo bloqueios de sites do arquivo hosts...

set sites=store.steampowered.com steamcommunity.com epicgames.com riotgames.com battle.net roblox.com minecraft.net garena.com mediafire.com mega.nz tlauncher.org uptodown.com baixaki.com.br

:: Criar backup do hosts antes de modificar
copy %SystemRoot%\System32\drivers\etc\hosts %SystemRoot%\System32\drivers\etc\hosts.backup >nul 2>&1

:: Remover linhas dos sites bloqueados
for %%s in (%sites%) do (
    findstr /v /c:"127.0.0.1 %%s" %SystemRoot%\System32\drivers\etc\hosts > %SystemRoot%\System32\drivers\etc\hosts.tmp 2>nul
    move /y %SystemRoot%\System32\drivers\etc\hosts.tmp %SystemRoot%\System32\drivers\etc\hosts >nul 2>nul
    echo   Site desbloqueado: %%s
)

:: ---------------------------------------------------
:: 4. REMOVER SOFTWARE RESTRICTION POLICY
:: ---------------------------------------------------
echo [4/7] Removendo regras de Software Restriction Policy...

:: Remover DefaultLevel
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /f 2>nul

:: Remover todas as paths criadas (IDs 26200-26210)
for /l %%i in (26200,1,26210) do (
    reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\Paths\%%i" /f 2>nul
)

echo   Regras de restricao removidas!

:: ---------------------------------------------------
:: 5. DESBLOQUEAR INSTALADORES
:: ---------------------------------------------------
echo [5/7] Desbloqueando instaladores...
echo   (Ja removidos junto com Software Restriction Policy)

:: ---------------------------------------------------
:: 6. DESBLOQUEAR PEN-DRIVE
:: ---------------------------------------------------
echo [6/7] Desbloqueando pendrive...

reg delete "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /v Deny_All /f 2>nul
echo   Pendrive desbloqueado!

:: ---------------------------------------------------
:: 7. APLICAR POLÍTICAS
:: ---------------------------------------------------
echo [7/7] Aplicando politicas...
gpupdate /force >nul
echo   Politicas aplicadas!

echo.
echo ================================================
echo  DESBLOQUEIO CONCLUIDO COM SUCESSO!
echo ================================================
echo.
echo Todas as restricoes do bloqueioAPP.bat foram removidas.
echo Backup do arquivo hosts criado em:
echo %SystemRoot%\System32\drivers\etc\hosts.backup
echo.
echo Pressione qualquer tecla para finalizar...
pause >nul
exit
