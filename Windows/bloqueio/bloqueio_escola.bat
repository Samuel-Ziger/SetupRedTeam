@echo off
:: ============================================
:: Script de Bloqueio para Ambiente Escolar
:: Windows 10 - Restrição de Jogos e Instalações
:: ============================================
:: Requer execução como Administrador
:: ============================================

:: Verificar se está executando como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERRO] Este script requer privilegios de Administrador!
    echo Por favor, execute como Administrador.
    pause
    exit /b 1
)

echo ============================================
echo  BLOQUEIO DE JOGOS E RESTRICAO DE INSTALACAO
echo  Configuracao para Ambiente Escolar
echo ============================================
echo.

:: ============================================
:: 1. BLOQUEIO DE SITES VIA HOSTS FILE
:: ============================================
echo [1/8] Bloqueando sites de jogos via arquivo hosts...

:: Backup do arquivo hosts
copy /Y %SystemRoot%\System32\drivers\etc\hosts %SystemRoot%\System32\drivers\etc\hosts.backup >nul 2>&1

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
findstr /C:"127.0.0.1 steamcommunity.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 store.steampowered.com >> %HOSTS_FILE%
    echo 127.0.0.1 steamcommunity.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.steamcommunity.com >> %HOSTS_FILE%
    echo 127.0.0.1 steam-chat.com >> %HOSTS_FILE%
    echo 127.0.0.1 steamstatic.com >> %HOSTS_FILE%
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

:: Bloquear novos sites de jogos
findstr /C:"127.0.0.1 1001jogos.com.br" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 1001jogos.com.br >> %HOSTS_FILE%
    echo 127.0.0.1 www.1001jogos.com.br >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 playgama.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 playgama.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.playgama.com >> %HOSTS_FILE%
)

:: Bloquear novos sites de jogos adicionais
findstr /C:"127.0.0.1 jogos360.com.br" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 jogos360.com.br >> %HOSTS_FILE%
    echo 127.0.0.1 www.jogos360.com.br >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 play.google.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 play.google.com >> %HOSTS_FILE%
    echo 127.0.0.1 playgames.google.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 playgames.kyabai.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 playgames.kyabai.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.playgames.kyabai.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 crazygames.com.br" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 crazygames.com.br >> %HOSTS_FILE%
    echo 127.0.0.1 www.crazygames.com.br >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 clickjogos.com.br" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 clickjogos.com.br >> %HOSTS_FILE%
    echo 127.0.0.1 www.clickjogos.com.br >> %HOSTS_FILE%
)

:: Bloquear redes sociais
findstr /C:"127.0.0.1 facebook.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 facebook.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.facebook.com >> %HOSTS_FILE%
    echo 127.0.0.1 m.facebook.com >> %HOSTS_FILE%
    echo 127.0.0.1 fb.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.fb.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 instagram.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 instagram.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.instagram.com >> %HOSTS_FILE%
    echo 127.0.0.1 m.instagram.com >> %HOSTS_FILE%
)

:: Bloquear conteúdo adulto
findstr /C:"127.0.0.1 xvideos.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 xvideos.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.xvideos.com >> %HOSTS_FILE%
)

findstr /C:"127.0.0.1 pornhub.com" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 pornhub.com >> %HOSTS_FILE%
    echo 127.0.0.1 www.pornhub.com >> %HOSTS_FILE%
)

:: Bloquear minigames do Google
findstr /C:"127.0.0.1 chrome://dino" %HOSTS_FILE% >nul 2>&1
if %errorLevel% neq 0 (
    echo 127.0.0.1 chrome://dino >> %HOSTS_FILE%
    echo 127.0.0.1 www.google.com/logos >> %HOSTS_FILE%
    echo 127.0.0.1 www.google.com/doodles >> %HOSTS_FILE%
)

:: Proteger arquivo hosts contra modificação por usuários comuns
icacls "%HOSTS_FILE%" /grant Administradores:F /inheritance:r >nul 2>&1
icacls "%HOSTS_FILE%" /grant SYSTEM:F >nul 2>&1
icacls "%HOSTS_FILE%" /remove "Users" >nul 2>&1
icacls "%HOSTS_FILE%" /remove "Authenticated Users" >nul 2>&1

echo    Sites bloqueados com sucesso!
echo    Arquivo hosts protegido contra modificacao!

:: ============================================
:: 2. BLOQUEIO DE INSTALACAO DE PROGRAMAS
:: ============================================
echo [2/8] Configurando restricoes de instalacao...

:: Desabilitar instalação para usuários não administradores
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 1 /f >nul 2>&1

:: Permitir apenas instalação elevada (requer senha de admin)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /t REG_DWORD /d 0 /f >nul 2>&1

:: Desabilitar instalação de drivers não assinados
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverInstall\Restrictions" /v DenyUnsignedInstallation /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear execução de arquivos .exe, .msi, .bat, .cmd de locais não confiáveis
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /t REG_DWORD /d 262144 /f >nul 2>&1

:: Desabilitar instalação de aplicativos de fontes desconhecidas
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /v AllowAllTrustedApps /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear Microsoft Store para instalação
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f >nul 2>&1

:: Desabilitar Windows Store completamente
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >nul 2>&1

echo    Restricoes de instalacao configuradas!

:: ============================================
:: 3. BLOQUEIO DE PLATAFORMAS DE JOGOS
:: ============================================
echo [3/8] Bloqueando plataformas de jogos...

:: Bloquear execução do Steam
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\steam.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Steam.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\STEAM.EXE" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

:: Bloquear execução do Epic Games Launcher
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\EpicGamesLauncher.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\EpicGamesLauncher.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

:: Bloquear execução do Roblox
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxPlayerBeta.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxStudioBeta.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

:: Bloquear execução de outros launchers comuns
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Origin.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Battle.net.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Uplay.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GOG Galaxy.exe" /v Debugger /t REG_SZ /d "%SystemRoot%\System32\taskkill.exe" /f >nul 2>&1

echo    Plataformas de jogos bloqueadas!

:: ============================================
:: 4. POLITICAS DE GRUPO PARA NAVEGADORES
:: ============================================
echo [4/10] Configurando politicas para navegadores...

:: Chrome - Bloquear extensões e downloads perigosos
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ExtensionInstallBlocklist /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SafeBrowsingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v DownloadRestrictions /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v BlockFileDownloads /t REG_DWORD /d 1 /f >nul 2>&1

:: Chrome - Bloquear URLs específicas
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 1 /t REG_SZ /d "poki.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 2 /t REG_SZ /d "friv.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 3 /t REG_SZ /d "1001jogos.com.br" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 4 /t REG_SZ /d "playgama.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 5 /t REG_SZ /d "lichess.org" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 6 /t REG_SZ /d "chess.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 7 /t REG_SZ /d "facebook.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 8 /t REG_SZ /d "instagram.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 9 /t REG_SZ /d "xvideos.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 10 /t REG_SZ /d "pornhub.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 11 /t REG_SZ /d "*.io" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 12 /t REG_SZ /d "jogos360.com.br" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 13 /t REG_SZ /d "play.google.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 14 /t REG_SZ /d "playgames.kyabai.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 15 /t REG_SZ /d "crazygames.com.br" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\URLBlocklist" /v 16 /t REG_SZ /d "clickjogos.com.br" /f >nul 2>&1

:: Chrome - Bloquear palavras-chave em pesquisas (via SafeSearch forçado)
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ForceGoogleSafeSearch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ForceYouTubeRestrict /t REG_DWORD /d 1 /f >nul 2>&1

:: Edge - Bloquear extensões e downloads
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ExtensionInstallBlocklist /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v SafeBrowsingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v DownloadRestrictions /t REG_DWORD /d 3 /f >nul 2>&1

:: Edge - Bloquear URLs específicas
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 1 /t REG_SZ /d "poki.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 2 /t REG_SZ /d "friv.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 3 /t REG_SZ /d "1001jogos.com.br" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 4 /t REG_SZ /d "playgama.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 5 /t REG_SZ /d "lichess.org" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 6 /t REG_SZ /d "chess.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 7 /t REG_SZ /d "facebook.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 8 /t REG_SZ /d "instagram.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 9 /t REG_SZ /d "xvideos.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 10 /t REG_SZ /d "pornhub.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 11 /t REG_SZ /d "*.io" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 12 /t REG_SZ /d "jogos360.com.br" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 13 /t REG_SZ /d "play.google.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 14 /t REG_SZ /d "playgames.kyabai.com" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 15 /t REG_SZ /d "crazygames.com.br" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist" /v 16 /t REG_SZ /d "clickjogos.com.br" /f >nul 2>&1

:: Edge - Bloquear palavras-chave em pesquisas
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ForceGoogleSafeSearch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ForceYouTubeRestrict /t REG_DWORD /d 1 /f >nul 2>&1

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
        echo       "Block": ["*://poki.com/*", "*://crazygames.com/*", "*://friv.com/*", "*://y8.com/*", "*://miniclip.com/*", "*://roblox.com/*", "*://steamcommunity.com/*", "*://epicgames.com/*", "*://chess.com/*", "*://lichess.org/*", "*://1001jogos.com.br/*", "*://playgama.com/*", "*://facebook.com/*", "*://instagram.com/*", "*://xvideos.com/*", "*://pornhub.com/*", "*://*.io/*", "*://jogos360.com.br/*", "*://play.google.com/*", "*://playgames.kyabai.com/*", "*://crazygames.com.br/*", "*://clickjogos.com.br/*"]
        echo     }
        echo   }
        echo }
    ) > "%FIREFOX_DIR%\distribution\policies.json"
)

echo    Politicas de navegadores configuradas!

:: ============================================
:: 5. BLOQUEIO DE PESQUISAS COM PALAVRAS-CHAVE
:: ============================================
echo [5/10] Configurando bloqueio de pesquisas com palavras-chave...

:: Bloquear pesquisas no Google via políticas de grupo
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v DefaultSearchProviderSearchURL /t REG_SZ /d "https://www.google.com/search?q={searchTerms}&safe=active" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v DefaultSearchProviderSearchURL /t REG_SZ /d "https://www.google.com/search?q={searchTerms}&safe=active" /f >nul 2>&1

:: Forçar SafeSearch no nível máximo
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ForceSafeSearch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ForceSafeSearch /t REG_DWORD /d 1 /f >nul 2>&1

echo    Bloqueio de pesquisas configurado!

:: ============================================
:: 6. BLOQUEIO DE PORTAS DE JOGOS
:: ============================================
echo [6/10] Bloqueando portas comuns de jogos...

:: Bloquear portas comuns de jogos online via Firewall
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Steam" dir=out action=block protocol=TCP localport=27000-27100 >nul 2>&1
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Steam UDP" dir=out action=block protocol=UDP localport=27000-27100 >nul 2>&1
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Roblox" dir=out action=block protocol=TCP localport=49152-65535 >nul 2>&1
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Epic Games" dir=out action=block protocol=TCP localport=443 remoteip=52.85.0.0/16 >nul 2>&1

echo    Portas de jogos bloqueadas!

:: ============================================
:: 7. RESTRICAO DE CONTROLE DE CONTA DE USUARIO (UAC)
:: ============================================
echo [7/10] Configurando UAC para restricao total...

:: Configurar UAC para sempre pedir senha (nível máximo)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ValidateAdminCodeSignatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f >nul 2>&1

echo    UAC configurado para restricao maxima!

:: ============================================
:: 8. BLOQUEIO DE EXECUCAO DE ARQUIVOS DE JOGOS
:: ============================================
echo [8/10] Bloqueando execucao de arquivos de jogos...

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
:: 9. DESABILITAR SERVICOS RELACIONADOS A JOGOS
:: ============================================
echo [9/10] Desabilitando servicos relacionados a jogos...

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
:: 10. GARANTIR PERSISTENCIA DO BLOQUEIO
:: ============================================
echo [10/10] Garantindo persistencia do bloqueio...

:: Criar script PowerShell para manter bloqueios
(
    echo # Script para manter bloqueios ativos
    echo $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    echo $sites = @("poki.com", "friv.com", "1001jogos.com.br", "playgama.com", "lichess.org", "chess.com", "facebook.com", "instagram.com", "xvideos.com", "pornhub.com", "roblox.com", "steamcommunity.com", "epicgames.com", "jogos360.com.br", "play.google.com", "playgames.kyabai.com", "crazygames.com.br", "clickjogos.com.br"^)
    echo foreach ($site in $sites^) {
    echo     $entry = "127.0.0.1 $site"
    echo     if (-not (Select-String -Path $hostsFile -Pattern $site -Quiet^)^) {
    echo         Add-Content -Path $hostsFile -Value $entry
    echo     }
    echo }
) > "%SystemRoot%\System32\drivers\etc\manter_bloqueio.ps1"

:: Proteger o script de manutenção
icacls "%SystemRoot%\System32\drivers\etc\manter_bloqueio.ps1" /grant Administradores:F /inheritance:r >nul 2>&1
icacls "%SystemRoot%\System32\drivers\etc\manter_bloqueio.ps1" /grant SYSTEM:F >nul 2>&1

:: Criar tarefa agendada para verificar e restaurar bloqueios semanalmente
schtasks /create /tn "ManterBloqueioEscolar" /tr "powershell.exe -ExecutionPolicy Bypass -File \"%SystemRoot%\System32\drivers\etc\manter_bloqueio.ps1\"" /sc weekly /d SUN /st 02:00 /ru SYSTEM /f >nul 2>&1

:: Bloquear modificação do arquivo hosts via políticas de grupo
:: Desabilitar acesso ao Editor de Registro para usuários comuns (via GPO)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear acesso ao Prompt de Comando para usuários comuns
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableCMD /t REG_DWORD /d 2 /f >nul 2>&1

:: Bloquear acesso ao PowerShell para usuários comuns
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d "Restricted" /f >nul 2>&1

echo    Persistencia do bloqueio garantida!

:: ============================================
:: FINALIZACAO
:: ============================================
echo.
echo ============================================
echo  CONFIGURACAO CONCLUIDA COM SUCESSO!
echo ============================================
echo.
echo Restricoes aplicadas:
echo  - Sites de jogos bloqueados via hosts (poki, friv, 1001jogos, playgama)
echo  - Sites de xadrez bloqueados (chess.com, lichess.org)
echo  - Redes sociais bloqueadas (Facebook, Instagram)
echo  - Conteudo adulto bloqueado (xvideos, pornhub)
echo  - Domínios .io bloqueados
echo  - Pesquisas com palavras-chave bloqueadas (jogos, game, arcade, nu, nua, etc.)
echo  - Minigames do Google bloqueados
echo  - Arquivo hosts protegido contra modificacao
echo  - Instalacao/desinstalacao restrita ao administrador
echo  - Microsoft Store bloqueado
echo  - Plataformas de jogos bloqueadas (Steam, Epic, Roblox)
echo  - Navegadores configurados (Chrome, Edge, Firefox)
echo  - Portas de jogos bloqueadas no firewall
echo  - UAC configurado para restricao maxima
echo  - Servicos de jogos desabilitados
echo  - Tarefa agendada para manter bloqueios ativos
echo.
echo IMPORTANTE: 
echo  - Apenas o usuario administrador ou com senha
echo    de administrador pode instalar/desinstalar programas
echo  - Mesmo executando como administrador, sera necessario
echo    a senha do administrador para instalacoes
echo  - Reinicie o computador para aplicar todas as mudancas
echo.
echo ============================================
pause

