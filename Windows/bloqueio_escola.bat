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

echo    Sites bloqueados com sucesso!

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
echo [4/8] Configurando politicas para navegadores...

:: Chrome - Bloquear extensões e downloads perigosos
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v ExtensionInstallBlocklist /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v SafeBrowsingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v DownloadRestrictions /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v BlockFileDownloads /t REG_DWORD /d 1 /f >nul 2>&1

:: Edge - Bloquear extensões e downloads
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ExtensionInstallBlocklist /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v SafeBrowsingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v DownloadRestrictions /t REG_DWORD /d 3 /f >nul 2>&1

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
        echo       "Block": ["*://poki.com/*", "*://crazygames.com/*", "*://friv.com/*", "*://y8.com/*", "*://miniclip.com/*", "*://roblox.com/*", "*://steamcommunity.com/*", "*://epicgames.com/*", "*://chess.com/*", "*://lichess.org/*"]
        echo     }
        echo   }
        echo }
    ) > "%FIREFOX_DIR%\distribution\policies.json"
)

echo    Politicas de navegadores configuradas!

:: ============================================
:: 5. BLOQUEIO DE PORTAS DE JOGOS
:: ============================================
echo [5/8] Bloqueando portas comuns de jogos...

:: Bloquear portas comuns de jogos online via Firewall
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Steam" dir=out action=block protocol=TCP localport=27000-27100 >nul 2>&1
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Steam UDP" dir=out action=block protocol=UDP localport=27000-27100 >nul 2>&1
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Roblox" dir=out action=block protocol=TCP localport=49152-65535 >nul 2>&1
netsh advfirewall firewall add rule name="Bloquear Jogos Online - Epic Games" dir=out action=block protocol=TCP localport=443 remoteip=52.85.0.0/16 >nul 2>&1

echo    Portas de jogos bloqueadas!

:: ============================================
:: 6. RESTRICAO DE CONTROLE DE CONTA DE USUARIO (UAC)
:: ============================================
echo [6/8] Configurando UAC para restricao total...

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
echo [7/8] Bloqueando execucao de arquivos de jogos...

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
echo [8/8] Desabilitando servicos relacionados a jogos...

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
:: FINALIZACAO
:: ============================================
echo.
echo ============================================
echo  CONFIGURACAO CONCLUIDA COM SUCESSO!
echo ============================================
echo.
echo Restricoes aplicadas:
echo  - Sites de jogos bloqueados via hosts
echo  - Instalacao/desinstalacao restrita ao administrador
echo  - Microsoft Store bloqueado
echo  - Plataformas de jogos bloqueadas (Steam, Epic, Roblox)
echo  - Sites de xadrez bloqueados
echo  - Navegadores configurados (Chrome, Edge, Firefox)
echo  - Portas de jogos bloqueadas no firewall
echo  - UAC configurado para restricao maxima
echo  - Servicos de jogos desabilitados
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

