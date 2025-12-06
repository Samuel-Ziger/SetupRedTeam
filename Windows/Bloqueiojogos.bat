@echo off
setlocal enabledelayedexpansion
title BLOQUEIO DE JOGOS - ESCOLA (APLICA A ALUNOS, ADM LIBERADO)
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
 "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"
set TLAUNCHER_RELATIVE=\.minecraft\tlauncher.exe

:: Lista extensa de sites de jogos a inserir no hosts (espacos separam)
set SITES=store.steampowered.com steamcommunity.com epicgames.com riotgames.com battle.net roblox.com minecraft.net tlauncher.org garena.com \
 poki.com crazygames.com y8.com friv.com friv2.com frivplus.com miniclip.com kizi.com armorgames.com addictinggames.com \
 kongregate.com notdoppler.com agame.com gameforge.com jogos123.com jogos360.com

:: ---------- Funcoes ----------
:menu
cls
echo ================================================
echo   BLOQUEIO DE JOGOS - ESCOLA (ADMIN LIBERADO)
echo ================================================
echo.
echo 1 ^> Aplicar bloqueio (PARA ALUNOS; ADM NAO AFETADO)
echo 2 ^> Reverter bloqueio (remover politicas aplicadas aos usuarios)
echo 3 ^> Permitir temporariamente downloads .exe para um usuario (ex: para instalar)
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
:: Carrega hive de usuario, adiciona politicas (Chrome/Edge) em HKU\<temp>
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
:: Chrome
reg add "HKU\TempHive\Software\Policies\Google\Chrome" /v DownloadRestrictions /t REG_DWORD /d 1 /f >nul 2>&1
:: Edge
reg add "HKU\TempHive\Software\Policies\Microsoft\Edge" /v DownloadRestrictions /t REG_DWORD /d 1 /f >nul 2>&1

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
reg unload "HKU\TempHive" >nul 2>&1
goto :eof

:: ---------------------------------------------------
:: Aplica hosts entries (idempotente)
:: ---------------------------------------------------
:apply_hosts
echo [Hosts] Inserindo entradas no hosts...
for %%s in (%SITES%) do (
    findstr /i "%%s" "%HOSTS_FILE%" >nul 2>&1
    if errorlevel 1 (
        echo 127.0.0.1 %%s >> "%HOSTS_FILE%"
        echo   Bloqueado: %%s
    ) else (
        echo   Ja presente: %%s
    )
)
echo [Hosts] Concluido.
goto :eof

:: ---------------------------------------------------
:: Aplica regras de firewall para launchers
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
call :apply_hosts
call :apply_firewall
call :apply_tlauncher_deny
call :apply_to_non_admin_users

echo.
echo ================================================
echo       BLOQUEIO APLICADO COM SUCESSO!
echo  Observacoes:
echo  - Administradores permanecem sem bloqueio (podem baixar .exe).
echo  - Para liberar temporariamente para um usuario, escolha a opcao 3 no menu.
echo  - Para reverter tudo, execute a opcao 2.
echo ================================================
pause
goto menu

:revert_all
echo Iniciando reversao (removendo politicas aplicadas)...
call :remove_from_non_admin_users

echo.
echo Nota: Este processo remove as politicas (Chrome/Edge) aplicadas via NTUSER.DAT.
echo Se desejar remover entradas do hosts ou firewall, faca manualmente ou use o backup.
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
 