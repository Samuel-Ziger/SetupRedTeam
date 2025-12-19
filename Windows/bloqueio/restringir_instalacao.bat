@echo off
:: ============================================
:: Script de Restrição de Instalação
:: Windows 10/11 - Bloquear Instalação/Desinstalação
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
echo  RESTRICAO DE INSTALACAO E DESINSTALACAO
echo  Configuracao para Ambiente Escolar
echo ============================================
echo.

:: ============================================
:: 1. BLOQUEAR INSTALACAO PARA USUARIOS COMUNS
:: ============================================
echo [1/8] Bloqueando instalacao para usuarios comuns...

:: Desabilitar instalação MSI para usuários não administradores
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 1 /f >nul 2>&1

:: Garantir que apenas administradores podem instalar
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear instalação de drivers não assinados
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverInstall\Restrictions" /v DenyUnsignedInstallation /t REG_DWORD /d 1 /f >nul 2>&1

:: Desabilitar instalação de aplicativos de fontes desconhecidas
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /v AllowAllTrustedApps /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear Microsoft Store para instalação
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f >nul 2>&1

echo    Instalacao bloqueada para usuarios comuns!

:: ============================================
:: 2. BLOQUEAR EXECUCAO DE INSTALADORES
:: ============================================
echo [2/8] Bloqueando execucao de instaladores...

:: Bloquear execução de .exe, .msi, .bat, .cmd, .ps1 para usuários comuns
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /t REG_DWORD /d 262144 /f >nul 2>&1

:: Bloquear execução de arquivos .exe de locais não confiáveis
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v DisallowRun /t REG_DWORD /d 1 /f >nul 2>&1

:: Criar lista de bloqueio para instaladores comuns
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 1 /t REG_SZ /d "setup.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 2 /t REG_SZ /d "install.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 3 /t REG_SZ /d "installer.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 4 /t REG_SZ /d "uninstall.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /v 5 /t REG_SZ /d "uninst.exe" /f >nul 2>&1

:: Bloquear execução de scripts PowerShell para usuários comuns
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d "Restricted" /f >nul 2>&1

echo    Execucao de instaladores bloqueada!

:: ============================================
:: 3. BLOQUEAR ACESSO AO PAINEL DE CONTROLE > PROGRAMAS
:: ============================================
echo [3/8] Bloqueando acesso ao Painel de Controle > Programas...

:: Ocultar "Programas e Recursos" do Painel de Controle
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddRemovePrograms /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear acesso ao applet de desinstalação
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoRemovePage /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddPage /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoWindowsSetupPage /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear acesso via appwiz.cpl
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v DisallowCpl /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowCpl" /v 1 /t REG_SZ /d "appwiz.cpl" /f >nul 2>&1

echo    Acesso ao Painel de Controle > Programas bloqueado!

:: ============================================
:: 4. BLOQUEAR ACESSO AO CONFIGURACOES > APLICATIVOS
:: ============================================
echo [4/8] Bloqueando acesso ao Configuracoes > Aplicativos...

:: Bloquear acesso às Configurações do Windows
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSettingsApp /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear acesso específico à página de Aplicativos
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /v BlockNonAdminUserInstall /t REG_DWORD /d 1 /f >nul 2>&1

:: Desabilitar instalação de aplicativos da Microsoft Store para usuários comuns
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /t REG_DWORD /d 1 /f >nul 2>&1

echo    Acesso ao Configuracoes > Aplicativos bloqueado!

:: ============================================
:: 5. CONFIGURAR UAC PARA BLOQUEAR ELEVACAO
:: ============================================
echo [5/8] Configurando UAC para bloquear elevacao...

:: Configurar UAC para sempre pedir senha (nível máximo)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear usuários padrão de executar arquivos com privilégios elevados
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1

echo    UAC configurado para bloquear elevacao!

:: ============================================
:: 6. BLOQUEAR EXECUCAO DE ARQUIVOS .BAT, .CMD, .PS1
:: ============================================
echo [6/8] Bloqueando execucao de scripts...

:: Bloquear execução de arquivos .bat e .cmd
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoRun /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear execução de scripts PowerShell
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d "Restricted" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d "AllSigned" /f >nul 2>&1

:: Bloquear execução de scripts via política de grupo
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v ScriptExecution /t REG_DWORD /d 1 /f >nul 2>&1

echo    Execucao de scripts bloqueada!

:: ============================================
:: 7. BLOQUEAR ACESSO A PASTAS DE INSTALACAO
:: ============================================
echo [7/8] Bloqueando acesso a pastas de instalacao...

:: Bloquear acesso à pasta Program Files para usuários comuns
icacls "%ProgramFiles%" /deny Users:(OI)(CI)W /inheritance:r >nul 2>&1
icacls "%ProgramFiles(x86)%" /deny Users:(OI)(CI)W /inheritance:r >nul 2>&1

:: Bloquear acesso à pasta de instalação do usuário
icacls "%LOCALAPPDATA%\Programs" /deny Users:(OI)(CI)W /inheritance:r >nul 2>&1

echo    Acesso a pastas de instalacao bloqueado!

:: ============================================
:: 8. CRIAR POLITICAS DE GRUPO ADICIONAIS
:: ============================================
echo [8/8] Criando politicas de grupo adicionais...

:: Bloquear instalação de software não autorizado
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableUserInstalls /t REG_DWORD /d 1 /f >nul 2>&1

:: Bloquear instalação de software de locais não confiáveis
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v SafeForScripting /t REG_DWORD /d 0 /f >nul 2>&1

:: Bloquear instalação de software via ActiveX
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v 1201 /t REG_DWORD /d 3 /f >nul 2>&1

:: Bloquear download de arquivos executáveis
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v 1806 /t REG_DWORD /d 3 /f >nul 2>&1

echo    Politicas de grupo adicionais criadas!

:: ============================================
:: FINALIZACAO
:: ============================================
echo.
echo ============================================
echo  RESTRICAO DE INSTALACAO CONCLUIDA!
echo ============================================
echo.
echo Restricoes aplicadas:
echo  - Instalacao/desinstalacao bloqueada para usuarios comuns
echo  - Execucao de instaladores (.exe, .msi) bloqueada
echo  - Execucao de scripts (.bat, .cmd, .ps1) bloqueada
echo  - Acesso ao Painel de Controle > Programas bloqueado
echo  - Acesso ao Configuracoes > Aplicativos bloqueado
echo  - UAC configurado para bloquear elevacao
echo  - Acesso a pastas de instalacao bloqueado
echo  - Politicas de grupo aplicadas
echo.
echo IMPORTANTE: 
echo  - Apenas administradores podem instalar/desinstalar programas
echo  - Usuarios comuns nao podem executar instaladores
echo  - Usuarios comuns nao podem acessar configuracoes de programas
echo  - Reinicie o computador para aplicar todas as mudancas
echo.
echo ============================================
pause

