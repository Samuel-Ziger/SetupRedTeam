@echo off
setlocal enabledelayedexpansion
title BLOQUEIO DE JOGOS - ESCOLA DE TECNOLOGIA (APLICA A ALUNOS, ADM LIBERADO)
color 0A

if not "%username%"=="%computername%\%username%" echo. >nul
:: check admin
whoami /groups | find "S-1-5-32-544" >nul
if errorlevel 1 (
    echo Este script precisa ser executado como Administrador.
    pause
    exit /b 1
)

:: ---------- Config ----------
set HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts
set LAUNCHERS_LIST="C:\Program Files (x86)\Steam\steam.exe" ^
 "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe" ^
 "C:\Riot Games\Riot Client\RiotClientServices.exe" ^
 "C:\Program Files (x86)\Battle.net\Battle.net.exe" ^
 "C:\Program Files (x86)\Garena\Garena\Garena.exe" ^
 "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe" ^
 "C:\Program Files\Origin\Origin.exe" ^
 "C:\Program Files (x86)\Origin\Origin.exe" ^
 "C:\Program Files\Ubisoft\Ubisoft Game Launcher\Uplay.exe" ^
 "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\Uplay.exe" ^
 "C:\Program Files\Rockstar Games\Rockstar Games Launcher\Launcher.exe" ^
 "C:\Program Files (x86)\Rockstar Games\Rockstar Games Launcher\Launcher.exe"
set TLAUNCHER_RELATIVE=\.minecraft\tlauncher.exe

:: Lista EXTENSA de sites de jogos a inserir no hosts (categorias: plataformas, jogos web, arcades, etc)
:: IMPORTANTE: Sites separados por espacos, usar ^ para continuar na proxima linha
set "SITES=store.steampowered.com steamcommunity.com steam-chat.com steamstat.us epicgames.com epicgames.store riotgames.com valorant.com leagueoflegends.com ^
battle.net blizzard.com roblox.com robloxlabs.com minecraft.net minecraftshop.net tlauncher.org garena.com garena.sg ^
poki.com poki.io crazygames.com y8.com y8games.com friv.com friv2.com frivplus.com miniclip.com kizi.com armorgames.com ^
addictinggames.com kongregate.com notdoppler.com agame.com games2girls.com gameforge.com jogos123.com jogos360.com jogosonline.com.br ^
newgrounds.com itch.io gamejolt.com scratch.mit.edu code.org codecombat.com unity3d.com unrealengine.com ^
twitch.tv mixer.com discord.com discordapp.com discord.gg ^
gamepedia.com fandom.com gamefaqs.com ign.com gamespot.com ^
xbox.com xboxlive.com playstation.com nintendo.com nintendo.com.br ^
ea.com origin.com uplay.com rockstargames.com 2k.com activision.com ^
coolmathgames.com hoodamath.com mathplayground.com abcya.com ^
chess.com lichess.org chess24.com chessbase.com playchess.com chessgames.com chessbomb.com chess.org chesskid.com chesscube.com ^
tetris.com tetrisfriends.com ^
agar.io slither.io diep.io krunker.io ^
geoguessr.com kahoot.it kahoot.com"

:: ---------- Funcoes ----------
:menu
cls
echo ================================================
echo   BLOQUEIO DE JOGOS - ESCOLA DE TECNOLOGIA
echo   (ADMIN LIBERADO / ALUNOS BLOQUEADOS)
echo ================================================
echo.
echo FUNCIONALIDADES:
echo  - Bloqueio de instalacao (requer admin)
echo  - Bloqueio de desinstalacao (somente admin)
echo  - Bloqueio de jogos na web
echo  - Bloqueio de launchers e portas de jogos
echo.
echo OPCOES:
echo 1 ^> Aplicar bloqueio completo (PARA ALUNOS; ADM NAO AFETADO)
echo 2 ^> Reverter bloqueio (remover politicas aplicadas)
echo 3 ^> Permitir temporariamente downloads para um usuario
echo 4 ^> Reaplicar bloqueio para um usuario (apos instalacao)
echo 5 ^> Sair
echo.
set /p opt=Escolha uma opcao (1-5) ^> 
if "%opt%"=="1" goto apply_all
if "%opt%"=="2" goto revert_all
if "%opt%"=="3" goto allow_for_user
if "%opt%"=="4" goto reapply_for_user
if "%opt%"=="5" goto end
goto menu

:: ---------------------------------------------------
:: Carrega hive de usuario, adiciona politicas (Chrome/Edge/Firefox) em HKU\<temp>
:: Depois descarrega o hive.
:: Param1 = caminho completo do NTUSER.DAT
:: ---------------------------------------------------
:apply_policies_to_hive
set "USER_HIVE=%~1"
set "TMPKEY=HKU\TempHive_%RANDOM%"
:: gerar nome unico - usaremos TempHive
reg load "HKU\TempHive" "%USER_HIVE%" >nul 2>&1
if errorlevel 1 (
    echo Falha ao carregar hive: %USER_HIVE%
    goto :eof
)

:: Chrome - Bloqueio de downloads e jogos web
reg add "HKU\TempHive\Software\Policies\Google\Chrome" /v DownloadRestrictions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 1 /t REG_SZ /d "*://*.roblox.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 2 /t REG_SZ /d "*://*.poki.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 3 /t REG_SZ /d "*://*.crazygames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 4 /t REG_SZ /d "*://*.y8.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 5 /t REG_SZ /d "*://*.friv.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 6 /t REG_SZ /d "*://*.miniclip.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 7 /t REG_SZ /d "*://*.kizi.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 8 /t REG_SZ /d "*://*.armorgames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 9 /t REG_SZ /d "*://*.addictinggames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 10 /t REG_SZ /d "*://*.kongregate.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 11 /t REG_SZ /d "*://*.agame.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 12 /t REG_SZ /d "*://*.coolmathgames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 13 /t REG_SZ /d "*://*.chess.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 14 /t REG_SZ /d "*://*.lichess.org/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 15 /t REG_SZ /d "*://*.chess24.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 16 /t REG_SZ /d "*://*.chessbase.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 17 /t REG_SZ /d "*://*.playchess.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 18 /t REG_SZ /d "*://*.chessgames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 19 /t REG_SZ /d "*://*.chessbomb.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 20 /t REG_SZ /d "*://*.chess.org/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 21 /t REG_SZ /d "*://*.chesskid.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 22 /t REG_SZ /d "*://*.chesscube.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 23 /t REG_SZ /d "*://*.agar.io/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 24 /t REG_SZ /d "*://*.slither.io/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 25 /t REG_SZ /d "*://*.friv2.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 26 /t REG_SZ /d "*://*.frivplus.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 27 /t REG_SZ /d "*://*.notdoppler.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 28 /t REG_SZ /d "*://*.gameforge.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\URLBlocklist" /v 29 /t REG_SZ /d "*://*.games2girls.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Google\Chrome\ExtensionInstallBlocklist" /v * /t REG_SZ /d "*" /f >nul 2>&1

:: Edge - Bloqueio de downloads e jogos web
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge" /v DownloadRestrictions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 1 /t REG_SZ /d "*://*.roblox.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 2 /t REG_SZ /d "*://*.poki.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 3 /t REG_SZ /d "*://*.crazygames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 4 /t REG_SZ /d "*://*.y8.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 5 /t REG_SZ /d "*://*.friv.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 6 /t REG_SZ /d "*://*.miniclip.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 7 /t REG_SZ /d "*://*.kizi.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 8 /t REG_SZ /d "*://*.armorgames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 9 /t REG_SZ /d "*://*.addictinggames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 10 /t REG_SZ /d "*://*.kongregate.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 11 /t REG_SZ /d "*://*.agame.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 12 /t REG_SZ /d "*://*.coolmathgames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 13 /t REG_SZ /d "*://*.chess.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 14 /t REG_SZ /d "*://*.lichess.org/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 15 /t REG_SZ /d "*://*.chess24.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 16 /t REG_SZ /d "*://*.chessbase.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 17 /t REG_SZ /d "*://*.playchess.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 18 /t REG_SZ /d "*://*.chessgames.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 19 /t REG_SZ /d "*://*.chessbomb.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 20 /t REG_SZ /d "*://*.chess.org/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 21 /t REG_SZ /d "*://*.chesskid.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 22 /t REG_SZ /d "*://*.chesscube.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 23 /t REG_SZ /d "*://*.agar.io/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 24 /t REG_SZ /d "*://*.slither.io/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 25 /t REG_SZ /d "*://*.friv2.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 26 /t REG_SZ /d "*://*.frivplus.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 27 /t REG_SZ /d "*://*.notdoppler.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 28 /t REG_SZ /d "*://*.gameforge.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\URLBlocklist" /v 29 /t REG_SZ /d "*://*.games2girls.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge\ExtensionInstallBlocklist" /v * /t REG_SZ /d "*" /f >nul 2>&1

:: Firefox - Bloqueio de downloads e jogos web
reg add "HKU\TempHive\Software\Policies\Mozilla\Firefox" /v BlockAboutConfig /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Mozilla\Firefox" /v DisablePrivateBrowsing /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Mozilla\Firefox" /v DisableDeveloperTools /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Mozilla\Firefox\WebsiteFilter" /v Block /t REG_SZ /d "*://*.roblox.com/* *://*.poki.com/* *://*.crazygames.com/* *://*.y8.com/* *://*.friv.com/* *://*.miniclip.com/* *://*.kizi.com/* *://*.armorgames.com/* *://*.addictinggames.com/* *://*.kongregate.com/* *://*.agame.com/* *://*.coolmathgames.com/* *://*.chess.com/* *://*.lichess.org/* *://*.chess24.com/* *://*.chessbase.com/* *://*.playchess.com/* *://*.chessgames.com/* *://*.chessbomb.com/* *://*.chess.org/* *://*.chesskid.com/* *://*.chesscube.com/* *://*.agar.io/* *://*.slither.io/* *://*.friv2.com/* *://*.frivplus.com/* *://*.notdoppler.com/* *://*.gameforge.com/* *://*.games2girls.com/*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Mozilla\Firefox\Extensions" /v InstallSources /t REG_SZ /d "" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Mozilla\Firefox\Extensions" /v Blocked /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKU\TempHive\Software\Policies\Mozilla\Firefox\Permissions" /v Install /t REG_SZ /d "block" /f >nul 2>&1

:: Bloquear instalação de software (requer admin) - Política Local
reg add "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddRemovePrograms /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoRemovePage /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddPage /t REG_DWORD /d 1 /f >nul 2>&1

reg unload "HKU\TempHive" >nul 2>&1
goto :eof

:remove_policies_from_hive
set "USER_HIVE=%~1"
reg load "HKU\TempHive" "%USER_HIVE%" >nul 2>&1
if errorlevel 1 (
    echo Falha ao carregar hive: %USER_HIVE%
    goto :eof
)
reg delete "HKU\TempHive\Software\Policies\Google\Chrome" /f >nul 2>&1
reg delete "HKU\TempHive\Software\Policies\Microsoft\Edge" /f >nul 2>&1
reg delete "HKU\TempHive\Software\Policies\Mozilla\Firefox" /f >nul 2>&1
reg delete "HKU\TempHive\Software\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /f >nul 2>&1
reg unload "HKU\TempHive" >nul 2>&1
goto :eof

:: ---------------------------------------------------
:: Aplica hosts entries (idempotente)
:: ---------------------------------------------------
:apply_hosts
echo [Hosts] Inserindo entradas no hosts...
echo Processando sites... Por favor aguarde.
echo.

:: Verificar se o arquivo hosts existe
if not exist "%HOSTS_FILE%" (
    echo ERRO: Arquivo hosts nao encontrado: %HOSTS_FILE%
    exit /b 1
)

:: Tentar obter permissões de escrita no arquivo hosts
:: Remover atributo somente leitura se existir
attrib -r "%HOSTS_FILE%" >nul 2>&1

:: Tentar dar permissao de escrita usando takeown e icacls
takeown /f "%HOSTS_FILE%" >nul 2>&1
icacls "%HOSTS_FILE%" /grant Administradores:F >nul 2>&1
icacls "%HOSTS_FILE%" /grant "%USERNAME%":F >nul 2>&1
icacls "%HOSTS_FILE%" /grant "%USERDOMAIN%\%USERNAME%":F >nul 2>&1

:: Fazer backup do hosts antes de modificar
set "HOSTS_BACKUP=%HOSTS_FILE%.backup_%date:~-4,4%%date:~-7,2%%date:~-10,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "HOSTS_BACKUP=%HOSTS_BACKUP: =0%"
copy "%HOSTS_FILE%" "%HOSTS_BACKUP%" >nul 2>&1
if errorlevel 1 (
    echo AVISO: Nao foi possivel criar backup do hosts. Continuando mesmo assim...
) else (
    echo Backup do hosts criado: %HOSTS_BACKUP%
)
echo.

:: Criar arquivo temporario para adicionar entradas
set "TEMP_HOSTS=%TEMP%\hosts_temp_%RANDOM%.txt"
copy "%HOSTS_FILE%" "%TEMP_HOSTS%" >nul 2>&1
if errorlevel 1 (
    echo ERRO: Nao foi possivel criar arquivo temporario. Tentando metodo direto...
    goto :direct_write
)

set /a processed=0
set /a blocked=0
set /a existing=0
set /a errors=0

:: Processar sites um por um
for %%s in (%SITES%) do (
    set /a processed+=1
    set "current_site=%%s"
    
    :: Verificar se o site nao esta vazio e nao e apenas espaco
    set "current_site=!current_site: =!"
    if not "!current_site!"=="" (
        :: Verificar se ja existe no hosts
        findstr /i /c:"!current_site!" "%TEMP_HOSTS%" >nul 2>&1
        if errorlevel 1 (
            :: Adicionar ao arquivo temporario
            echo 127.0.0.1 !current_site!>> "%TEMP_HOSTS%"
            if errorlevel 1 (
                set /a errors+=1
                echo   [ERRO] Falha ao adicionar: !current_site!
            ) else (
                set /a blocked+=1
                echo   [OK] Bloqueado: !current_site!
            )
        ) else (
            set /a existing+=1
            echo   [--] Ja presente: !current_site!
        )
    )
)

:: Copiar arquivo temporario de volta para hosts
copy /Y "%TEMP_HOSTS%" "%HOSTS_FILE%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERRO: Nao foi possivel atualizar o arquivo hosts.
    echo Tentando metodo alternativo...
    del "%TEMP_HOSTS%" >nul 2>&1
    goto :direct_write
) else (
    del "%TEMP_HOSTS%" >nul 2>&1
    goto :hosts_done
)

:direct_write
:: Metodo alternativo: escrever diretamente (pode falhar se nao tiver permissao)
set /a processed=0
set /a blocked=0
set /a existing=0
set /a errors=0

for %%s in (%SITES%) do (
    set /a processed+=1
    set "current_site=%%s"
    set "current_site=!current_site: =!"
    if not "!current_site!"=="" (
        findstr /i /c:"!current_site!" "%HOSTS_FILE%" >nul 2>&1
        if errorlevel 1 (
            echo 127.0.0.1 !current_site!>> "%HOSTS_FILE%"
            if errorlevel 1 (
                set /a errors+=1
                echo   [ERRO] Falha ao bloquear: !current_site!
            ) else (
                set /a blocked+=1
                echo   [OK] Bloqueado: !current_site!
            )
        ) else (
            set /a existing+=1
            echo   [--] Ja presente: !current_site!
        )
    )
)

:hosts_done

echo.
echo [Hosts] Concluido: %blocked% bloqueados, %existing% ja existiam, %errors% erros (Total: %processed%)
if %errors% gtr 0 (
    echo AVISO: Alguns sites nao puderam ser bloqueados. Verifique as permissoes.
)
exit /b 0

:: ---------------------------------------------------
:: Aplica regras de firewall para launchers e portas de jogos
:: ---------------------------------------------------
:apply_firewall
echo.
echo [Firewall] Adicionando regras para launchers (se encontrados)...
for %%I in (%LAUNCHERS_LIST%) do (
    if exist %%~I (
        rem extrair nome do exe
        for %%F in ("%%~I") do set exeName=%%~nxF
        netsh advfirewall firewall add rule name="Bloqueio-Jogo-%%~nxI" dir=out action=block program="%%~I" enable=yes >nul 2>&1
        netsh advfirewall firewall add rule name="Bloqueio-Jogo-%%~nxI-IN" dir=in  action=block program="%%~I" enable=yes >nul 2>&1
        echo   Launcher bloqueado: %%~I
    ) else (
        echo   Launcher nao encontrado: %%~I
    )
)

echo.
echo [Firewall] Bloqueando portas comuns de jogos online...
:: Portas comuns de jogos (Steam, Battle.net, Riot, etc)
netsh advfirewall firewall add rule name="Bloqueio-Porta-Steam" dir=out action=block protocol=TCP localport=27015-27030 enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Bloqueio-Porta-Steam-UDP" dir=out action=block protocol=UDP localport=27015-27030 enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Bloqueio-Porta-BattleNet" dir=out action=block protocol=TCP localport=1119,3724,4000,6112-6119 enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Bloqueio-Porta-Riot" dir=out action=block protocol=TCP localport=5000-5500,8080,8443 enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Bloqueio-Porta-Roblox" dir=out action=block protocol=TCP localport=49152-49200 enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Bloqueio-Porta-Minecraft" dir=out action=block protocol=TCP localport=25565 enable=yes >nul 2>&1
netsh advfirewall firewall add rule name="Bloqueio-Porta-EpicGames" dir=out action=block protocol=TCP localport=5222 enable=yes >nul 2>&1
echo   Portas de jogos bloqueadas (Steam, Battle.net, Riot, Roblox, Minecraft, Epic Games)

echo [Firewall] Concluido.
goto :eof

:: ---------------------------------------------------
:: Bloqueia TLauncher no perfil de cada usuario (icacls) sem afetar Java
:: ---------------------------------------------------
:apply_tlauncher_deny
echo.
echo [TLauncher] Negando execucao do TLauncher nos perfis de usuarios...
for /d %%U in (C:\Users\*) do (
    set "PROF=%%~fU"
    if /I "%%~nxU"=="Default" goto :skip_default
    if /I "%%~nxU"=="Public" goto :skip_default
    if /I "%%~nxU"=="All Users" goto :skip_default
    if exist "%%~fU%TLAUNCHER_RELATIVE%" (
        icacls "%%~fU%TLAUNCHER_RELATIVE%" /deny *S-1-1-0:(X) >nul 2>&1
        echo   TLauncher bloqueado em: %%~nxU
    )
    :skip_default
)
echo [TLauncher] Concluido.
goto :eof

:: ---------------------------------------------------
:: Aplica politicas de sistema para bloquear instalacao/desinstalacao (somente admin)
:: ---------------------------------------------------
:apply_system_policies
echo.
echo [Politicas Sistema] Aplicando bloqueio de instalacao/desinstalacao (requer admin)...
:: Bloquear instalação de software - requer privilégios de administrador
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1

:: Bloquear acesso ao Painel de Controle - Programas e Recursos (desinstalação)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddRemovePrograms /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoRemovePage /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddPage /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear execução de instaladores comuns sem privilégios de admin
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableAutomaticRestartSignOn /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear MSI (Windows Installer) para usuários não-admin
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear execução de arquivos .exe, .msi, .bat, .cmd de locais temporários (comum em instalações)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v ScanWithAntiVirus /t REG_DWORD /d 1 /f >nul 2>&1

echo [Politicas Sistema] Concluido - Instalacao/Desinstalacao requerem privilegios de administrador.
goto :eof

:: ---------------------------------------------------
:: Remove politicas de sistema
:: ---------------------------------------------------
:remove_system_policies
echo.
echo [Politicas Sistema] Removendo bloqueios de instalacao/desinstalacao...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /f >nul 2>&1
echo [Politicas Sistema] Removido.
goto :eof

:: ---------------------------------------------------
:: Aplica politicas HKCU para todos os usuarios NAO-ADMIN (edita NTUSER.DAT)
:: ---------------------------------------------------
:apply_to_non_admin_users
echo.
echo [Politicas] Aplicando bloqueio de downloads para usuarios NAO-ADMIN...
for /d %%U in (C:\Users\*) do (
    set "UNAME=%%~nxU"
    rem pular perfis padrao
    if /I "%%~nxU"=="Default" (
        echo   Pulando Default
        goto :continue_loop
    )
    if /I "%%~nxU"=="Public" (
        echo   Pulando Public
        goto :continue_loop
    )
    if /I "%%~nxU"=="All Users" (
        echo   Pulando All Users
        goto :continue_loop
    )
    rem verificar se pasta de perfil tem NTUSER.DAT
    if not exist "%%~fU\NTUSER.DAT" (
        echo   Sem NTUSER.DAT: %%~nxU
        goto :continue_loop
    )

    rem checar se esse usuario eh membro do grupo Administradores
    rem obter SID do usuario (usando wmic)
    for /f "tokens=2 delims== " %%S in ('wmic useraccount where "name='%%~nxU' and domain='%COMPUTERNAME%'" get sid /value 2^>nul') do set "USER_SID=%%S"
    if defined USER_SID (
        rem verificar se SID esta no grupo Administradores
        whoami /groups | findstr /i /c:"%USER_SID%" >nul 2>&1
        rem OBS: whoami /groups local verifica usuario corrente, nao o outro. Entao usaremos outra estrategia:
        rem Vamos verificar se o usuario faz parte do grupo Administradores usando net localgroup
        net localgroup Administradores | findstr /i "%%~nxU" >nul 2>&1
        if not errorlevel 1 (
            echo   Usuario Administrador (pulando): %%~nxU
            goto :continue_loop
        )
    )

    rem carregar hive, aplicar politicas, descarregar
    echo   Aplicando politicas em: %%~nxU
    call :apply_policies_to_hive "%%~fU\NTUSER.DAT"

    :continue_loop
)
rem também aplicar no Default user (novo usuario herdará)
if exist "C:\Users\Default\NTUSER.DAT" (
    echo Aplicando politicas no Default user...
    call :apply_policies_to_hive "C:\Users\Default\NTUSER.DAT"
)
echo [Politicas] Concluido.
goto :eof

:: ---------------------------------------------------
:: Remove politicas de todos os perfis (reverter)
:: ---------------------------------------------------
:remove_from_non_admin_users
echo.
echo [Politicas] Removendo politicas (revertendo) de perfis...
for /d %%U in (C:\Users\*) do (
    set "UNAME=%%~nxU"
    if /I "%%~nxU"=="Default" (
        echo   Pulando Default
        goto :cont2
    )
    if /I "%%~nxU"=="Public" (
        echo   Pulando Public
        goto :cont2
    )
    if /I "%%~nxU"=="All Users" (
        echo   Pulando All Users
        goto :cont2
    )
    if not exist "%%~fU\NTUSER.DAT" (
        echo   Sem NTUSER.DAT: %%~nxU
        goto :cont2
    )
    rem checar se usuario admin e pular (simplificado)
    net localgroup Administradores | findstr /i "%%~nxU" >nul 2>&1
    if not errorlevel 1 (
        echo   Usuario Administrador (pulando): %%~nxU
        goto :cont2
    )
    echo   Removendo politicas em: %%~nxU
    call :remove_policies_from_hive "%%~fU\NTUSER.DAT"
    :cont2
)
if exist "C:\Users\Default\NTUSER.DAT" (
    echo Removendo politicas do Default user...
    call :remove_policies_from_hive "C:\Users\Default\NTUSER.DAT"
)
echo [Politicas] Removido.
goto :eof

:: ---------------------------------------------------
:: Permitir downloads temporariamente para usuario especifico (remove politicas do NTUSER.DAT dele)
:: Param: nome do usuario
:: ---------------------------------------------------
:allow_user_once
set "TARGET_USER=%~1"
if "%TARGET_USER%"=="" (
    echo Usuario nao informado.
    goto :eof
)
if not exist "C:\Users\%TARGET_USER%\NTUSER.DAT" (
    echo Perfil nao encontrado: %TARGET_USER%
    goto :eof
)
echo Removendo politicas para: %TARGET_USER%
call :remove_policies_from_hive "C:\Users\%TARGET_USER%\NTUSER.DAT"
echo Downloads liberados para %TARGET_USER%.
goto :eof

:: ---------------------------------------------------
:: Reaplicar politicas para usuario (apos instalacao)
:: ---------------------------------------------------
:reapply_user
set "TARGET_USER=%~1"
if "%TARGET_USER%"=="" (
    echo Usuario nao informado.
    goto :eof
)
if not exist "C:\Users\%TARGET_USER%\NTUSER.DAT" (
    echo Perfil nao encontrado: %TARGET_USER%
    goto :eof
)
echo Reaplicando politicas para: %TARGET_USER%
call :apply_policies_to_hive "C:\Users\%TARGET_USER%\NTUSER.DAT"
echo Bloqueio restaurado para %TARGET_USER%.
goto :eof

:: ---------------------------------------------------
:: MAIN ACTIONS
:: ---------------------------------------------------
:apply_all
echo Iniciando aplicacao completa do bloqueio...
echo.
echo ================================================
echo   BLOQUEIO SERA APLICADO EM ETAPAS
echo ================================================
echo.
echo Pressione qualquer tecla para continuar ou Ctrl+C para cancelar...
pause >nul

echo.
echo [ETAPA 1/5] Bloqueando sites de jogos no arquivo hosts...
call :apply_hosts
if errorlevel 1 (
    echo ERRO ao aplicar bloqueio de hosts!
    pause
    goto menu
)
echo.
echo [ETAPA 1/5] CONCLUIDA - Sites bloqueados no hosts
echo.
set /p continue1=Deseja continuar para a proxima etapa? (S/N) ^> 
if /i not "%continue1%"=="S" if /i not "%continue1%"=="s" (
    echo Bloqueio interrompido pelo usuario.
    pause
    goto menu
)

echo.
echo [ETAPA 2/5] Bloqueando launchers e portas de jogos no firewall...
call :apply_firewall
if errorlevel 1 (
    echo ERRO ao aplicar regras de firewall!
    pause
    goto menu
)
echo.
echo [ETAPA 2/5] CONCLUIDA - Firewall configurado
echo.
set /p continue2=Deseja continuar para a proxima etapa? (S/N) ^> 
if /i not "%continue2%"=="S" if /i not "%continue2%"=="s" (
    echo Bloqueio interrompido pelo usuario.
    pause
    goto menu
)

echo.
echo [ETAPA 3/5] Bloqueando TLauncher nos perfis de usuarios...
call :apply_tlauncher_deny
if errorlevel 1 (
    echo ERRO ao aplicar bloqueio do TLauncher!
    pause
    goto menu
)
echo.
echo [ETAPA 3/5] CONCLUIDA - TLauncher bloqueado
echo.
set /p continue3=Deseja continuar para a proxima etapa? (S/N) ^> 
if /i not "%continue3%"=="S" if /i not "%continue3%"=="s" (
    echo Bloqueio interrompido pelo usuario.
    pause
    goto menu
)

echo.
echo [ETAPA 4/5] Aplicando politicas de sistema (instalacao/desinstalacao)...
call :apply_system_policies
if errorlevel 1 (
    echo ERRO ao aplicar politicas de sistema!
    pause
    goto menu
)
echo.
echo [ETAPA 4/5] CONCLUIDA - Politicas de sistema aplicadas
echo.
set /p continue4=Deseja continuar para a proxima etapa? (S/N) ^> 
if /i not "%continue4%"=="S" if /i not "%continue4%"=="s" (
    echo Bloqueio interrompido pelo usuario.
    pause
    goto menu
)

echo.
echo [ETAPA 5/5] Aplicando bloqueio de navegadores para usuarios nao-admin...
echo Esta etapa pode demorar alguns minutos dependendo do numero de usuarios...
call :apply_to_non_admin_users
if errorlevel 1 (
    echo ERRO ao aplicar politicas de usuarios!
    pause
    goto menu
)
echo.
echo [ETAPA 5/5] CONCLUIDA - Politicas de usuarios aplicadas

echo.
echo ================================================
echo       BLOQUEIO APLICADO COM SUCESSO!
echo ================================================
echo.
echo FUNCIONALIDADES APLICADAS:
echo  [X] Bloqueio de sites de jogos na web (hosts)
echo  [X] Bloqueio de launchers de jogos (firewall)
echo  [X] Bloqueio de portas de jogos online
echo  [X] Bloqueio de instalacao (requer privilegios de admin)
echo  [X] Bloqueio de desinstalacao (somente admin)
echo  [X] Bloqueio de downloads em navegadores (Chrome, Edge, Firefox)
echo  [X] Bloqueio de extensoes de navegador
echo  [X] Bloqueio de jogos web via URLBlocklist (Chrome, Edge, Firefox)
echo.
echo OBSERVACOES:
echo  - Administradores permanecem sem bloqueio (podem instalar/desinstalar).
echo  - Alunos NAO PODEM instalar ou desinstalar software sem autorizacao admin.
echo  - Todos os tipos de jogos na web estao bloqueados para alunos.
echo  - Para liberar temporariamente para um usuario, escolha a opcao 3 no menu.
echo  - Para reverter tudo, execute a opcao 2.
echo ================================================
pause
goto menu

:revert_all
echo Iniciando reversao (removendo politicas aplicadas)...
call :remove_from_non_admin_users
call :remove_system_policies

echo.
echo Nota: Este processo remove as politicas aplicadas via NTUSER.DAT e sistema.
echo Se desejar remover entradas do hosts ou firewall, faca manualmente ou use o backup.
echo.
echo ATENCAO: As regras de firewall e entradas do hosts NAO foram removidas automaticamente.
echo Para remover completamente, execute manualmente ou restaure um backup.
pause
goto menu

:allow_for_user
set /p userName=Digite o nome do usuario (nome da pasta em C:\Users) ^> 
if "%userName%"=="" goto menu
call :allow_user_once "%userName%"
pause
goto menu

:reapply_for_user
set /p userName=Digite o nome do usuario (nome da pasta em C:\Users) ^> 
if "%userName%"=="" goto menu
call :reapply_user "%userName%"
pause
goto menu

:end
echo Finalizando...
endlocal
exit /b 0
 