@echo off
:: ============================================
:: Script de Desbloqueio - Reverter Alteracoes
:: Windows 10 - Remover Restricoes de Jogos
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
echo  DESBLOQUEIO E REMOCAO DE RESTRICOES
echo  Revertendo Configuracoes de Ambiente Escolar
echo ============================================
echo.

:: ============================================
:: 1. RESTAURAR ARQUIVO HOSTS
:: ============================================
echo [1/8] Restaurando arquivo hosts...

set "HOSTS_FILE=%SystemRoot%\System32\drivers\etc\hosts"
set "HOSTS_BACKUP=%SystemRoot%\System32\drivers\etc\hosts.backup"

:: Verificar se existe backup
if exist "%HOSTS_BACKUP%" (
    copy /Y "%HOSTS_BACKUP%" "%HOSTS_FILE%" >nul 2>&1
    echo    Arquivo hosts restaurado do backup!
) else (
    :: Se não houver backup, remover manualmente as entradas de jogos
    echo    Backup nao encontrado. Removendo entradas manualmente...
    
    :: Criar arquivo temporário sem as linhas bloqueadas
    findstr /V /C:"poki.com" /C:"crazygames.com" /C:"friv.com" /C:"friv2.com" /C:"frivplus.com" /C:"y8.com" /C:"miniclip.com" /C:"kizi.com" /C:"armorgames.com" /C:"notdoppler.com" /C:"agame.com" /C:"games2girls.com" /C:"gameforge.com" /C:"kongregate.com" /C:"addictinggames.com" /C:"roblox.com" /C:"steamcommunity.com" /C:"steampowered.com" /C:"steam-chat.com" /C:"steamstatic.com" /C:"epicgames.com" /C:"chess.com" /C:"lichess.org" /C:"chess24.com" /C:"playchess.com" "%HOSTS_FILE%" > "%HOSTS_FILE%.tmp" 2>nul
    move /Y "%HOSTS_FILE%.tmp" "%HOSTS_FILE%" >nul 2>&1
    echo    Entradas de jogos removidas do arquivo hosts!
)

:: ============================================
:: 2. REMOVER RESTRICOES DE INSTALACAO
:: ============================================
echo [2/8] Removendo restricoes de instalacao...

:: Remover restrições do Windows Installer
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /f >nul 2>&1

:: Remover restrições de drivers
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverInstall\Restrictions" /v DenyUnsignedInstallation /f >nul 2>&1

:: Remover restrições de execução de arquivos
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /f >nul 2>&1

:: Remover restrições de Appx
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /v AllowAllTrustedApps /f >nul 2>&1

:: Reabilitar Microsoft Store
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /f >nul 2>&1

:: Reabilitar Windows Consumer Features
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /f >nul 2>&1

echo    Restricoes de instalacao removidas!

:: ============================================
:: 3. DESBLOQUEAR PLATAFORMAS DE JOGOS
:: ============================================
echo [3/8] Desbloqueando plataformas de jogos...

:: Remover bloqueios de execução do Steam
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\steam.exe" /v Debugger /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Steam.exe" /v Debugger /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\STEAM.EXE" /v Debugger /f >nul 2>&1

:: Remover bloqueios do Epic Games Launcher
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\EpicGamesLauncher.exe" /v Debugger /f >nul 2>&1

:: Remover bloqueios do Roblox
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxPlayerBeta.exe" /v Debugger /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\RobloxStudioBeta.exe" /v Debugger /f >nul 2>&1

:: Remover bloqueios de outros launchers
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Origin.exe" /v Debugger /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Battle.net.exe" /v Debugger /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Uplay.exe" /v Debugger /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\GOG Galaxy.exe" /v Debugger /f >nul 2>&1

echo    Plataformas de jogos desbloqueadas!

:: ============================================
:: 4. REMOVER POLITICAS DE NAVEGADORES
:: ============================================
echo [4/8] Removendo politicas de navegadores...

:: Remover políticas do Chrome
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /v ExtensionInstallBlocklist /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /v SafeBrowsingEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /v DownloadRestrictions /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /v BlockFileDownloads /f >nul 2>&1

:: Remover políticas do Edge
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v ExtensionInstallBlocklist /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v SafeBrowsingEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v DownloadRestrictions /f >nul 2>&1

:: Remover políticas do Firefox
set "FIREFOX_DIR=%ProgramFiles%\Mozilla Firefox"
if exist "%FIREFOX_DIR%\distribution\policies.json" (
    del /F /Q "%FIREFOX_DIR%\distribution\policies.json" >nul 2>&1
    echo    Arquivo policies.json do Firefox removido!
)

echo    Politicas de navegadores removidas!

:: ============================================
:: 5. REMOVER REGRAS DE FIREWALL
:: ============================================
echo [5/8] Removendo regras de firewall...

:: Remover regras de bloqueio de jogos
netsh advfirewall firewall delete rule name="Bloquear Jogos Online - Steam" >nul 2>&1
netsh advfirewall firewall delete rule name="Bloquear Jogos Online - Steam UDP" >nul 2>&1
netsh advfirewall firewall delete rule name="Bloquear Jogos Online - Roblox" >nul 2>&1
netsh advfirewall firewall delete rule name="Bloquear Jogos Online - Epic Games" >nul 2>&1

echo    Regras de firewall removidas!

:: ============================================
:: 6. RESTAURAR CONFIGURACOES DE UAC
:: ============================================
echo [6/8] Restaurando configuracoes de UAC...

:: Restaurar UAC para configurações padrão (nível médio)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ValidateAdminCodeSignatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f >nul 2>&1

echo    UAC restaurado para configuracoes padrao!

:: ============================================
:: 7. REMOVER BLOQUEIOS DE EXECUCAO
:: ============================================
echo [7/8] Removendo bloqueios de execucao...

:: Remover lista de bloqueios de execução
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v DisallowRun /f >nul 2>&1

:: Remover entradas individuais de bloqueio
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /f >nul 2>&1

echo    Bloqueios de execucao removidos!

:: ============================================
:: 8. REABILITAR SERVICOS DE JOGOS
:: ============================================
echo [8/8] Reabilitando servicos de jogos...

:: Reabilitar serviços do Xbox
sc config "XblAuthManager" start= demand >nul 2>&1
sc config "XblGameSave" start= demand >nul 2>&1
sc config "XboxGipSvc" start= demand >nul 2>&1
sc config "xbgm" start= demand >nul 2>&1

:: Reabilitar Windows Game Mode
reg add "HKLM\SOFTWARE\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1

echo    Servicos de jogos reabilitados!

:: ============================================
:: LIMPEZA DE CHAVES VAZIAS
:: ============================================
echo.
echo [Limpeza] Removendo chaves de registro vazias...

:: Tentar remover chaves vazias (pode falhar se ainda tiver valores)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverInstall\Restrictions" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Google\Chrome" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /f >nul 2>&1

echo    Limpeza concluida!

:: ============================================
:: FINALIZACAO
:: ============================================
echo.
echo ============================================
echo  DESBLOQUEIO CONCLUIDO COM SUCESSO!
echo ============================================
echo.
echo Alteracoes revertidas:
echo  - Arquivo hosts restaurado
echo  - Restricoes de instalacao removidas
echo  - Microsoft Store reabilitado
echo  - Plataformas de jogos desbloqueadas
echo  - Sites de jogos desbloqueados
echo  - Politicas de navegadores removidas
echo  - Regras de firewall removidas
echo  - UAC restaurado para padrao
echo  - Servicos de jogos reabilitados
echo.
echo IMPORTANTE: 
echo  - Todas as restricoes foram removidas
echo  - Usuarios podem instalar programas normalmente
echo  - Sites de jogos estao acessiveis novamente
echo  - Plataformas de jogos podem ser executadas
echo  - Reinicie o computador para aplicar todas as mudancas
echo.
echo ============================================
pause


