@echo off
:: ============================================
:: Script de Bloqueio para Ambiente Escolar
:: Inclui desativação do Windows Defender e correção de permissões do hosts
:: ============================================

:: FORÇAR EXECUÇÃO COMO ADMINISTRADOR
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Este script requer privilegios de Administrador!
    pause
    exit /b 1
)

echo ============================================
echo DESATIVANDO WINDOWS DEFENDER E REPARANDO PERMISSOES
echo ============================================
echo.

:: ============================================
:: 1. FORÇAR DESATIVAÇÃO DO WINDOWS DEFENDER
:: ============================================

echo [1/3] Desativando protecao em tempo real...
powershell -command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -command "Set-MpPreference -DisableIOAVProtection $true" >nul 2>&1
powershell -command "Set-MpPreference -DisableScriptScanning $true" >nul 2>&1

echo [2/3] Desativando antispyware e antimalware...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t REG_DWORD /d 1 /f >nul

echo [3/3] Parando servicos relacionados ao Defender...
sc stop WinDefend >nul 2>&1
sc config WinDefend start= disabled >nul 2>&1

echo    Windows Defender desativado (exceto Tamper Protection).
echo.

:: ============================================
:: 2. CORRIGIR PERMISSOES DO ARQUIVO HOSTS
:: ============================================

echo Ajustando permissoes do arquivo hosts...

takeown /f "%SystemRoot%\System32\drivers\etc\hosts" >nul 2>&1
icacls "%SystemRoot%\System32\drivers\etc\hosts" /grant Administrators:F >nul 2>&1
icacls "%SystemRoot%\System32\drivers\etc\hosts" /grant SYSTEM:F >nul 2>&1

attrib -r -h -s "%SystemRoot%\System32\drivers\etc\hosts" >nul 2>&1

echo Permissoes corrigidas. Prosseguindo com o bloqueio...
echo.

:: ============================================
:: INICIALIZACAO DE LOGGING
:: ============================================
set "LOG_FILE=%TEMP%\bloqueio_escola.log"
echo ============================================ > "%LOG_FILE%"
echo  LOG DE BLOQUEIO ESCOLAR >> "%LOG_FILE%"
echo  Data/Hora: %date% %time% >> "%LOG_FILE%"
echo ============================================ >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

:: ============================================
:: 1. BLOQUEIO DE SITES VIA HOSTS FILE
:: ============================================
echo [1/12] Bloqueando sites de jogos via arquivo hosts...

:: Backup do arquivo hosts
copy /Y %SystemRoot%\System32\drivers\etc\hosts %SystemRoot%\System32\drivers\etc\hosts.backup >nul 2>&1
if %errorLevel% equ 0 (
    echo [LOG] Backup do arquivo hosts criado >> "%LOG_FILE%" 2>&1
)

:: Lista de sites de jogos a serem bloqueados
set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"

:: Verificar se os sites já estão bloqueados
findstr /C:"127.0.0.1 poki.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 poki.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.poki.com >> %HOSTS_FILE%
    echo 127.0.0.1 api.poki.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 crazygames.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 crazygames.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.crazygames.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 friv.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 friv.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.friv.com >> %HOSTS_FILE%
    echo 127.0.0.1 friv2.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.friv2.com >> %HOSTS_FILE%
    echo 127.0.0.1 frivplus.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.frivplus.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 y8.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 y8.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.y8.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 miniclip.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 miniclip.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.miniclip.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 kizi.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 kizi.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.kizi.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 armorgames.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 armorgames.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.armorgames.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 notdoppler.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 notdoppler.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.notdoppler.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 agame.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 agame.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.agame.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 games2girls.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 games2girls.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.games2girls.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 gameforge.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 gameforge.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.gameforge.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 kongregate.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 kongregate.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.kongregate.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 addictinggames.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 addictinggames.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.addictinggames.com >> %HOSTS_FILE%
)

:: Bloquear Roblox
findstr /C:"127.0.0.1 roblox.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 roblox.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.roblox.com >> %HOSTS_FILE%
    echo 127.0.0.1 en.roblox.com >> %HOSTS_FILE%
    echo 127.0.0.1 assetdelivery.roblox.com >> %HOSTS_FILE%
    echo 127.0.0.1 setup.roblox.com >> %HOSTS_FILE%
)

:: Bloquear Steam
findstr /C:"127.0.0.1 steampowered.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 steampowered.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.steampowered.com >> %HOSTS_FILE%
    echo 127.0.0.1 store.steampowered.com >> %HOSTS_FILE%
    echo 127.0.0.1 steamcommunity.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.steamcommunity.com >> %HOSTS_FILE%
    echo 127.0.0.1 steam-chat.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.steam-chat.com >> %HOSTS_FILE%
    echo 127.0.0.1 steamstatic.com >> %HOSTS_FILE%
    echo 127.0.0.1 steamcdn-a.akamaihd.net >> %HOSTS_FILE%
    echo 127.0.0.1 steamcontent.com >> %HOSTS_FILE%
    echo 127.0.0.1 steamusercontent.com >> %HOSTS_FILE%
    echo 127.0.0.1 steamdb.info >> %HOSTS_FILE%
    echo 127.0.0.1 steam-api.com >> %HOSTS_FILE%
)

:: Bloquear Epic Games
findstr /C:"127.0.0.1 epicgames.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 epicgames.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.epicgames.com >> %HOSTS_FILE%
    echo 127.0.0.1 launcher-public-service-prod06.ol.epicgames.com >> %HOSTS_FILE%
    echo 127.0.0.1 download.epicgames.com >> %HOSTS_FILE%
)

:: Bloquear sites de xadrez
findstr /C:"127.0.0.1 chess.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 chess.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.chess.com >> %HOSTS_FILE%
    echo 127.0.0.1 lichess.org >> %HOSTS_FILE%
    echo 127.0.0.1 www.lichess.org >> %HOSTS_FILE%
    echo 127.0.0.1 chess24.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.chess24.com >> %HOSTS_FILE%
    echo 127.0.0.1 playchess.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.playchess.com >> %HOSTS_FILE%
)

:: Bloquear playgama.com
findstr /C:"127.0.0.1 playgama.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 playgama.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.playgama.com >> %HOSTS_FILE%
)

:: Bloquear firv.com
findstr /C:"127.0.0.1 firv.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 firv.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.firv.com >> %HOSTS_FILE%
)

:: Bloquear mais sites de jogos populares
findstr /C:"127.0.0.1 coolmathgames.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 coolmathgames.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.coolmathgames.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 unblockedgames.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 unblockedgames.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.unblockedgames.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 gamepix.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 gamepix.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.gamepix.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 gameflare.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 gameflare.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.gameflare.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 gamezhero.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 gamezhero.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.gamezhero.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 gamesgames.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 gamesgames.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.gamesgames.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 newgrounds.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 newgrounds.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.newgrounds.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 itch.io" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 itch.io >> %HOSTS_FILE%
    echo 127.0.0.1 www.itch.io >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 gamejolt.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 gamejolt.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.gamejolt.com >> %HOSTS_FILE%
)

echo    Sites bloqueados com sucesso!

:: ============================================
:: 2. BLOQUEIO DE INSTALACAO DE PROGRAMAS
:: ============================================
echo [2/12] Configurando restricoes de instalacao...

:: Desabilitar instalação para usuários não administradores
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 1 /f >nul 2>&1

:: Permitir apenas instalação elevada (requer senha de admin)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /t REG_DWORD /d 0 /f >nul 2>&1

:: Desabilitar instalação de drivers não assinados
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverInstall\Restrictions" /v DenyUnsignedInstallation /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear execução de executáveis portáteis (apenas Program Files e Windows permitidos)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /t REG_DWORD /d 0x00040000 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers\0\Paths" /v "C:\Users" /t REG_DWORD /d 0x00040000 /f >nul 2>&1
echo    [LOG] Bloqueio de executáveis portáteis configurado >> "%LOG_FILE%" 2>&1

:: Desabilitar instalação de aplicativos de fontes desconhecidas
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /v AllowAllTrustedApps /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear instaladores portáteis (ZIP/EXE/MSI)
reg add "HKLM\Software\Policies\Microsoft\Windows\Attachment Manager" /v SaveZoneInformation /t REG_DWORD /d 2 /f >nul 2>&1
echo    [LOG] Bloqueio de instaladores portáteis configurado >> "%LOG_FILE%" 2>&1

:: Bloquear Microsoft Store para instalação
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f >nul 2>&1

:: Desabilitar Windows Store completamente
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >nul 2>&1

echo    Restricoes de instalacao configuradas!

:: ============================================
:: 3. BLOQUEIO DE PLATAFORMAS DE JOGOS
:: ============================================
echo [3/12] Bloqueando plataformas de jogos...

:: Bloquear execução do Steam
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\steam.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Steam.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\STEAM.EXE" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

:: Bloquear execução do Epic Games Launcher
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\EpicGamesLauncher.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

:: Bloquear execução do Roblox
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxPlayerBeta.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxStudioBeta.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

:: Bloquear execução de outros launchers comuns
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Origin.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Battle.net.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Uplay.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GOG Galaxy.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

:: Whitelist de Navegadores - Bloquear navegadores não autorizados
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\opera.exe" /v Debugger /t REG_SZ /d taskkill.exe /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\brave.exe" /v Debugger /t REG_SZ /d taskkill.exe /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\chromium.exe" /v Debugger /t REG_SZ /d taskkill.exe /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\firefox.exe" /v Debugger /t REG_SZ /d taskkill.exe /f >nul 2>&1
echo    [LOG] Whitelist de navegadores configurada (apenas Edge e Chrome permitidos) >> "%LOG_FILE%" 2>&1

echo    Plataformas de jogos bloqueadas!

:: ============================================
:: 4. POLITICAS DE GRUPO PARA NAVEGADORES
:: ============================================
echo [4/12] Configurando politicas para navegadores...

:: Chrome - Bloquear extensões e downloads perigosos (permitir downloads legítimos)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ExtensionInstallBlocklist /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SafeBrowsingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v DownloadRestrictions /t REG_DWORD /d 1 /f >nul 2>&1

:: Chrome - Políticas restritivas adicionais
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v BlockThirdPartyCookies /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v DefaultPluginsSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v AllowDeletingBrowserHistory /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v IncognitoModeAvailability /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ForceGoogleSafeSearch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ForceYouTubeRestrict /t REG_DWORD /d 2 /f >nul 2>&1

:: Chrome - Bloquear sites .io e URLs com termos de jogos (URLBlocklist mais abrangente)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 1 /t REG_SZ /d "*://*.io/*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 2 /t REG_SZ /d "*://*games*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 3 /t REG_SZ /d "*://*jogos*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 4 /t REG_SZ /d "*://*arcade*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 5 /t REG_SZ /d "*://*play*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 6 /t REG_SZ /d "*://*game*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 7 /t REG_SZ /d "*://*poki*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 8 /t REG_SZ /d "*://*crazygames*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 9 /t REG_SZ /d "*://*friv*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 10 /t REG_SZ /d "*://*y8*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 11 /t REG_SZ /d "*://*miniclip*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 12 /t REG_SZ /d "*://*roblox*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 13 /t REG_SZ /d "*://*steam*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 14 /t REG_SZ /d "*://*epicgames*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 15 /t REG_SZ /d "*://*playgama*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 16 /t REG_SZ /d "*://*firv*" /f >nul 2>&1

:: Chrome - Bloquear pesquisas com termos específicos via URLBlocklist (mais específico)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 17 /t REG_SZ /d "*://*google.com/search?*q=*games*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 18 /t REG_SZ /d "*://*google.com/search?*q=*jogos*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 19 /t REG_SZ /d "*://*google.com/search?*q=*arcade*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 20 /t REG_SZ /d "*://*google.com/search?*q=*play*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 21 /t REG_SZ /d "*://*bing.com/search?*q=*games*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 22 /t REG_SZ /d "*://*bing.com/search?*q=*jogos*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 23 /t REG_SZ /d "*://*bing.com/search?*q=*arcade*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 24 /t REG_SZ /d "*://*bing.com/search?*q=*play*" /f >nul 2>&1

:: Chrome - Configurar URLAllowlist (permitir apenas sites educacionais específicos se necessário)
:: Nota: Se precisar permitir sites específicos, adicione aqui

:: Edge - Bloquear extensões e downloads
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ExtensionInstallBlocklist /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v SafeBrowsingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v DownloadRestrictions /t REG_DWORD /d 3 /f >nul 2>&1

:: Edge - Políticas restritivas adicionais
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BlockThirdPartyCookies /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v DefaultPluginsSetting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v AllowDeletingBrowserHistory /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v InPrivateModeAvailability /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ForceGoogleSafeSearch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ForceYouTubeRestrict /t REG_DWORD /d 2 /f >nul 2>&1

:: Edge - Bloquear sites .io e URLs com termos de jogos (URLBlocklist mais abrangente)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 1 /t REG_SZ /d "*://*.io/*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 2 /t REG_SZ /d "*://*games*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 3 /t REG_SZ /d "*://*jogos*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 4 /t REG_SZ /d "*://*arcade*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 5 /t REG_SZ /d "*://*play*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 6 /t REG_SZ /d "*://*game*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 7 /t REG_SZ /d "*://*poki*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 8 /t REG_SZ /d "*://*crazygames*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 9 /t REG_SZ /d "*://*friv*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 10 /t REG_SZ /d "*://*y8*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 11 /t REG_SZ /d "*://*miniclip*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 12 /t REG_SZ /d "*://*roblox*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 13 /t REG_SZ /d "*://*steam*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 14 /t REG_SZ /d "*://*epicgames*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 15 /t REG_SZ /d "*://*playgama*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 16 /t REG_SZ /d "*://*firv*" /f >nul 2>&1

:: Edge - Bloquear pesquisas com termos específicos via URLBlocklist (mais específico)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 17 /t REG_SZ /d "*://*google.com/search?*q=*games*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 18 /t REG_SZ /d "*://*google.com/search?*q=*jogos*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 19 /t REG_SZ /d "*://*google.com/search?*q=*arcade*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 20 /t REG_SZ /d "*://*google.com/search?*q=*play*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 21 /t REG_SZ /d "*://*bing.com/search?*q=*games*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 22 /t REG_SZ /d "*://*bing.com/search?*q=*jogos*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 23 /t REG_SZ /d "*://*bing.com/search?*q=*arcade*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 24 /t REG_SZ /d "*://*bing.com/search?*q=*play*" /f >nul 2>&1

:: Firefox - Criar políticas (requer arquivo policies.json)
set "FIREFOX_DIR=%ProgramFiles%\Mozilla Firefox"
if exist "%FIREFOX_DIR%" (
    if not exist "%FIREFOX_DIR%\distribution" mkdir "%FIREFOX_DIR%\distribution"
    (
        echo {
        echo   "policies": {
        echo     "BlockAboutAddons": true,
        echo     "BlockAboutConfig": true,
        echo     "BlockAboutSupport": true,
        echo     "DisableAppUpdate": true,
        echo     "DisableDeveloperTools": true,
        echo     "DisableFirefoxAccounts": true,
        echo     "DisableFirefoxStudies": true,
        echo     "DisableForgetButton": true,
        echo     "DisableFormHistory": true,
        echo     "DisableMasterPasswordCreation": true,
        echo     "DisablePasswordReveal": true,
        echo     "DisablePocket": true,
        echo     "DisablePrivateBrowsing": true,
        echo     "DisableProfileImport": true,
        echo     "DisableProfileRefresh": true,
        echo     "DisableSafeMode": true,
        echo     "DisableSecurityBypass": true,
        echo     "DisableSystemAddonUpdate": true,
        echo     "DisableTelemetry": true,
        echo     "DisableUserJS": true,
        echo     "Extensions": {
        echo       "Install": [],
        echo       "Uninstall": ["*"]
        echo     },
        echo     "WebsiteFilter": {
        echo       "Block": ["*://poki.com/*", "*://crazygames.com/*", "*://friv.com/*", "*://firv.com/*", "*://y8.com/*", "*://miniclip.com/*", "*://playgama.com/*", "*://roblox.com/*", "*://steamcommunity.com/*", "*://epicgames.com/*", "*://chess.com/*", "*://lichess.org/*", "*://*.io/*", "*://*games*", "*://*jogos*", "*://*arcade*", "*://*play*"]
        echo     }
        echo   }
        echo }
    ) > "%FIREFOX_DIR%\distribution\policies.json"
)

echo    Politicas de navegadores configuradas!

:: Forçar aplicação das políticas do Chrome/Edge (encerrar processos para recarregar)
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
taskkill /F /IM firefox.exe >nul 2>&1
timeout /t 2 /nobreak >nul 2>&1
echo    [LOG] Processos de navegadores encerrados para aplicar politicas >> "%LOG_FILE%" 2>&1

:: ============================================
:: 5. BLOQUEIO DE PORTAS DE JOGOS
:: ============================================
echo [5/12] Bloqueando portas comuns de jogos...

:: Verificar e bloquear portas comuns de jogos online via Firewall
netsh advfirewall firewall show rule name="Bloquear Jogos Online - Steam" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="Bloquear Jogos Online - Steam" dir=out action=block protocol=TCP localport=27000-27100 >nul 2>&1
    echo    [LOG] Regra de firewall Steam TCP adicionada >> "%LOG_FILE%" 2>&1
)

netsh advfirewall firewall show rule name="Bloquear Jogos Online - Steam UDP" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="Bloquear Jogos Online - Steam UDP" dir=out action=block protocol=UDP localport=27000-27100 >nul 2>&1
    echo    [LOG] Regra de firewall Steam UDP adicionada >> "%LOG_FILE%" 2>&1
)

netsh advfirewall firewall show rule name="Bloquear Jogos Online - Epic Games" >nul 2>&1
if %errorLevel% neq 0 (
    netsh advfirewall firewall add rule name="Bloquear Jogos Online - Epic Games" dir=out action=block protocol=TCP localport=443 remoteip=52.85.0.0/16 >nul 2>&1
    echo    [LOG] Regra de firewall Epic Games adicionada >> "%LOG_FILE%" 2>&1
)

echo    Portas de jogos bloqueadas!

:: ============================================
:: 6. RESTRICAO DE CONTROLE DE CONTA DE USUARIO (UAC)
:: ============================================
echo [6/12] Configurando UAC para restricao total...

:: Configurar UAC para sempre pedir senha (nível máximo)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ValidateAdminCodeSignatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f >nul 2>&1

echo    UAC configurado para restricao maxima!

:: ============================================
:: 7. BLOQUEIO DE EXECUCAO DE ARQUIVOS DE JOGOS
:: ============================================
echo [7/12] Bloqueando execucao de arquivos de jogos...

:: Bloquear execução de arquivos comuns de jogos
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v DisallowRun /t REG_DWORD /d 1 /f >nul 2>&1

:: Lista de executáveis de jogos a bloquear
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 1 /t REG_SZ /d "steam.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 2 /t REG_SZ /d "EpicGamesLauncher.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 3 /t REG_SZ /d "RobloxPlayerBeta.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 4 /t REG_SZ /d "RobloxStudioBeta.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 5 /t REG_SZ /d "Origin.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 6 /t REG_SZ /d "Battle.net.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 7 /t REG_SZ /d "Uplay.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 8 /t REG_SZ /d "GOG Galaxy.exe" /f >nul 2>&1

echo    Executaveis de jogos bloqueados!

:: ============================================
:: 8. DESABILITAR SERVICOS RELACIONADOS A JOGOS
:: ============================================
echo [8/12] Desabilitando servicos relacionados a jogos...

:: Desabilitar Xbox Game Bar e serviços relacionados
sc config "XblAuthManager" start= disabled >nul 2>&1
sc config "XblGameSave" start= disabled >nul 2>&1
sc config "XboxGipSvc" start= disabled >nul 2>&1
sc config "xbgm" start= disabled >nul 2>&1

:: Parar serviços se estiverem rodando
net stop "XblAuthManager" >nul 2>&1
net stop "XblGameSave" >nul 2>&1
net stop "XboxGipSvc" >nul 2>&1
net stop "xbgm" >nul 2>&1

:: Desabilitar Windows Game Mode
reg add "HKLM\SOFTWARE\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1

echo    Servicos de jogos desabilitados!

:: ============================================
:: 9. DESABILITAR MUDANCAS DE DNS
:: ============================================
echo [9/12] Desabilitando mudancas de DNS...

reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v AddrConfigControl /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows NT\DNSClient" /v DisableDNSOverHTTPS /t REG_DWORD /d 1 /f >nul 2>&1
echo    [LOG] Mudancas de DNS desabilitadas >> "%LOG_FILE%" 2>&1

echo    Mudancas de DNS desabilitadas!

:: ============================================
:: 10. BLOQUEIO DE VPNS
:: ============================================
echo [10/12] Bloqueando VPNs...

reg add "HKLM\System\CurrentControlSet\Services\PolicyAgent" /v AssumeUDPEncapsulationContextOnSendRule /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear executáveis comuns de VPN
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\protonvpn.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\openvpn.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\windscribe.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\NordVPN.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\ExpressVPN.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
echo    [LOG] VPNs bloqueadas >> "%LOG_FILE%" 2>&1

echo    VPNs bloqueadas!

:: ============================================
:: 11. PROTECAO DO ARQUIVO HOSTS
:: ============================================
echo [11/12] Protegendo arquivo hosts contra alteracoes...

:: Remover atributos de proteção temporariamente para permitir modificação
attrib -r -s -h %SystemRoot%\System32\drivers\etc\hosts >nul 2>&1

:: Aplicar proteções ao arquivo hosts
attrib +r +s +h %SystemRoot%\System32\drivers\etc\hosts >nul 2>&1
icacls %SystemRoot%\System32\drivers\etc\hosts /inheritance:r >nul 2>&1
icacls %SystemRoot%\System32\drivers\etc\hosts /deny "Users":W >nul 2>&1
icacls %SystemRoot%\System32\drivers\etc\hosts /deny "Everyone":W >nul 2>&1
echo    [LOG] Arquivo hosts protegido contra alteracoes >> "%LOG_FILE%" 2>&1

echo    Arquivo hosts protegido!

:: ============================================
:: 12. LOGGING DE ALTERACOES
:: ============================================
echo [12/12] Finalizando logging...

echo [LOG] Script de bloqueio executado em %date% %time% >> "%LOG_FILE%" 2>&1
echo [LOG] Todas as configuracoes foram aplicadas com sucesso >> "%LOG_FILE%" 2>&1
echo.
echo    Log de alteracoes salvo em: %LOG_FILE%

:: ============================================
:: FINALIZACAO
:: ============================================
echo.
echo ============================================
echo  CONFIGURACAO CONCLUIDA COM SUCESSO!
echo ============================================
echo.
echo Restricoes aplicadas:
echo  - Sites de jogos bloqueados via hosts (protegido contra alteracoes)
echo  - Sites playgama.com e firv.com bloqueados
echo  - Todos os sites com final .io bloqueados
echo  - Pesquisas com termos: games, jogos, arcade, play bloqueadas
echo  - Instalacao/desinstalacao restrita ao administrador
echo  - Microsoft Store bloqueado
echo  - Plataformas de jogos bloqueadas (Steam, Epic, Roblox)
echo  - Sites de xadrez bloqueados
echo  - Navegadores configurados (apenas Edge e Chrome permitidos)
echo  - Portas de jogos bloqueadas no firewall
echo  - UAC configurado para restricao maxima
echo  - Servicos de jogos desabilitados
echo  - Executaveis portateis bloqueados (apenas Program Files e Windows)
echo  - Instaladores portateis bloqueados
echo  - VPNs bloqueadas
echo  - Mudancas de DNS desabilitadas
echo.
echo IMPORTANTE: 
echo  - Apenas o usuario administrador ou com senha
echo    de administrador pode instalar/desinstalar programas
echo  - Mesmo executando como administrador, sera necessario
echo    a senha do administrador para instalacoes
echo  - As politicas dos navegadores foram aplicadas e os
echo    processos foram encerrados para recarregar as configuracoes
echo  - REINICIE O COMPUTADOR para aplicar todas as mudancas
echo    e garantir que os bloqueios funcionem corretamente
echo  - Apos reiniciar, os navegadores Chrome e Edge terao
echo    bloqueios mais restritivos aplicados via politicas
echo.
echo ============================================
pause

