@echo off
title BLOQUEIO DE JOGOS - ESCOLA
color 0A

echo ================================================
echo      BLOQUEIO SEGURO DE JOGOS APLICADO
echo ================================================
echo.

:: ---------------------------------------------------
:: 1. BLOQUEIO DE SITES DE JOGOS NO HOSTS
:: (NÃO AFETA SITES DE TECNOLOGIA)
:: ---------------------------------------------------
echo [1/3] Bloqueando sites de jogos...

set sites=store.steampowered.com steamcommunity.com epicgames.com riotgames.com battle.net roblox.com minecraft.net garena.com tlauncher.org

for %%s in (%sites%) do (
    findstr /i "%%s" "%SystemRoot%\System32\drivers\etc\hosts" >nul
    if errorlevel 1 (
        echo 127.0.0.1 %%s >> %SystemRoot%\System32\drivers\etc\hosts%
        echo   Bloqueado: %%s
    ) else (
        echo   Ja estava bloqueado: %%s
    )
)

:: ---------------------------------------------------
:: 2. BLOQUEIO DE LAUNCHERS NO FIREWALL
:: (Apenas jogos, NÃO bloqueia ferramentas de aula)
:: ---------------------------------------------------
echo [2/3] Bloqueando launchers no Firewall...

set launchers="C:\Program Files (x86)\Steam\steam.exe" ^
 "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" ^
 "C:\Riot Games\Riot Client\RiotClientServices.exe" ^
 "C:\Program Files (x86)\Battle.net\Battle.net.exe" ^
 "C:\Program Files (x86)\Garena\Garena\Garena.exe" ^
 "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"

for %%i in (%launchers%) do (
    if exist %%i (
        netsh advfirewall firewall add rule name="Bloqueio-Jogo-%%~nxi" dir=out action=block program="%%i" enable=yes >nul
        netsh advfirewall firewall add rule name="Bloqueio-Jogo-%%~nxi" dir=in  action=block program="%%i" enable=yes >nul
        echo   Launcher bloqueado: %%i
    ) else (
        echo   Launcher nao encontrado: %%i
    )
)

:: ---------------------------------------------------
:: 3. DESATIVAR TLAUNCHER & MC PIRATA SEM BLOQUEAR JAVA
:: ---------------------------------------------------
echo [3/3] Bloqueando TLauncher sem afetar Java...

set tlauncher_path="%APPDATA%\.minecraft\tlauncher.exe"

if exist %tlauncher_path% (
    icacls %tlauncher_path% /deny *S-1-1-0:(X) >nul
    echo   Executavel do TLauncher bloqueado.
) else (
    echo   TLauncher nao encontrado.
)

echo.
echo ================================================
echo  BLOQUEIO DE JOGOS CONCLUIDO!
echo  Ferramentas de programacao NAO foram afetadas.
echo ================================================
pause
exit
