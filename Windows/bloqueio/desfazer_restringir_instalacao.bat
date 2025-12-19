@echo off
:: ============================================
:: Script de Desfazer Restrição de Instalação
:: Windows 10/11 - Remover Restrições
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
echo  DESFAZER RESTRICOES DE INSTALACAO
echo  Revertendo Configuracoes
echo ============================================
echo.

:: ============================================
:: 1. REMOVER BLOQUEIOS DE INSTALACAO
:: ============================================
echo [1/8] Removendo bloqueios de instalacao...

:: Remover restrições do Windows Installer
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableMSI /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v AlwaysInstallElevated /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v DisableUserInstalls /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer" /v SafeForScripting /f >nul 2>&1

:: Remover restrições de drivers
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DriverInstall\Restrictions" /v DenyUnsignedInstallation /f >nul 2>&1

:: Remover restrições de Appx
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /v AllowAllTrustedApps /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Appx" /v BlockNonAdminUserInstall /f >nul 2>&1

:: Reabilitar Microsoft Store
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v RemoveWindowsStore /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" /v DisableStoreApps /f >nul 2>&1

echo    Bloqueios de instalacao removidos!

:: ============================================
:: 2. REMOVER BLOQUEIOS DE EXECUCAO DE INSTALADORES
:: ============================================
echo [2/8] Removendo bloqueios de execucao de instaladores...

:: Remover restrições de execução de arquivos
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /f >nul 2>&1

:: Remover lista de bloqueio de execução
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v DisallowRun /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun" /f >nul 2>&1

:: Restaurar política de execução do PowerShell
reg delete "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /f >nul 2>&1

:: Remover bloqueio de scripts
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v ScriptExecution /f >nul 2>&1

echo    Bloqueios de execucao removidos!

:: ============================================
:: 3. RESTAURAR ACESSO AO PAINEL DE CONTROLE > PROGRAMAS
:: ============================================
echo [3/8] Restaurando acesso ao Painel de Controle > Programas...

:: Restaurar acesso ao Painel de Controle
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v DisallowCpl /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowCpl" /f >nul 2>&1

:: Restaurar acesso ao applet de desinstalação
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddRemovePrograms /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoRemovePage /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoAddPage /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /v NoWindowsSetupPage /f >nul 2>&1

echo    Acesso ao Painel de Controle > Programas restaurado!

:: ============================================
:: 4. RESTAURAR ACESSO AO CONFIGURACOES > APLICATIVOS
:: ============================================
echo [4/8] Restaurando acesso ao Configuracoes > Aplicativos...

:: Restaurar acesso às Configurações do Windows
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSettingsApp /f >nul 2>&1

echo    Acesso ao Configuracoes > Aplicativos restaurado!

:: ============================================
:: 5. RESTAURAR CONFIGURACOES DE UAC
:: ============================================
echo [5/8] Restaurando configuracoes de UAC...

:: Restaurar UAC para configurações padrão (nível médio)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorUser /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableInstallerDetection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f >nul 2>&1

echo    UAC restaurado para configuracoes padrao!

:: ============================================
:: 6. RESTAURAR EXECUCAO DE SCRIPTS
:: ============================================
echo [6/8] Restaurando execucao de scripts...

:: Restaurar política de execução do PowerShell para padrão
reg add "HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" /v ExecutionPolicy /t REG_SZ /d "RemoteSigned" /f >nul 2>&1

echo    Execucao de scripts restaurada!

:: ============================================
:: 7. RESTAURAR ACESSO A PASTAS DE INSTALACAO
:: ============================================
echo [7/8] Restaurando acesso a pastas de instalacao...

:: Restaurar acesso à pasta Program Files
icacls "%ProgramFiles%" /remove:d Users /inheritance:e >nul 2>&1
icacls "%ProgramFiles(x86)%" /remove:d Users /inheritance:e >nul 2>&1

:: Restaurar acesso à pasta de instalação do usuário
icacls "%LOCALAPPDATA%\Programs" /remove:d Users /inheritance:e >nul 2>&1

echo    Acesso a pastas de instalacao restaurado!

:: ============================================
:: 8. REMOVER POLITICAS DE GRUPO ADICIONAIS
:: ============================================
echo [8/8] Removendo politicas de grupo adicionais...

:: Remover bloqueios de ActiveX e downloads
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v 1201 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /v 1806 /f >nul 2>&1

echo    Politicas de grupo adicionais removidas!

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
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Uninstall" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" /f >nul 2>&1

echo    Limpeza concluida!

:: ============================================
:: FINALIZACAO
:: ============================================
echo.
echo ============================================
echo  DESFAZER RESTRICOES CONCLUIDO!
echo ============================================
echo.
echo Alteracoes revertidas:
echo  - Bloqueios de instalacao removidos
echo  - Bloqueios de execucao de instaladores removidos
echo  - Acesso ao Painel de Controle > Programas restaurado
echo  - Acesso ao Configuracoes > Aplicativos restaurado
echo  - UAC restaurado para padrao
echo  - Execucao de scripts restaurada
echo  - Acesso a pastas de instalacao restaurado
echo  - Politicas de grupo removidas
echo.
echo IMPORTANTE: 
echo  - Todas as restricoes foram removidas
echo  - Usuarios podem instalar programas normalmente
echo  - Usuarios podem acessar configuracoes de programas
echo  - Reinicie o computador para aplicar todas as mudancas
echo.
echo ============================================
pause

