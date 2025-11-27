@echo off
title DESFAZER GERAL - REVERT ALL BLOCKS
color 0A

:: -------------------------
:: Verifica se é admin
:: -------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Este script precisa ser executado como Administrador.
    echo Clique com o direito e escolha "Executar como administrador".
    pause
    exit /b 1
)

echo ================================================
echo        DESFAZER GERAL - INICIANDO
echo ================================================
echo.

:: -------------------------
:: 1) RESTAURAR ARQUIVO HOSTS AO PADRAO
:: -------------------------
echo [1/9] Restaurando arquivo hosts para padrao...
set hostsfile=%SystemRoot%\System32\drivers\etc\hosts

:: assumir propriedade e permissao
takeown /f "%hostsfile%" >nul 2>&1
icacls "%hostsfile%" /grant Administrators:F >nul 2>&1

:: escrever conteudo padrao (mantem localhost IPv4 e IPv6)
(
    echo # Copyright (c) 1993-2009 Microsoft Corp.
    echo # This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
    echo # localhost name resolution is handled within DNS itself.
    echo 127.0.0.1       localhost
    echo ::1             localhost
) > "%hostsfile%"

echo    hosts restaurado.

:: -------------------------
:: 2) REMOVER REGRAS DE FIREWALL ADICIONADAS PELO SCRIPT
:: -------------------------
echo [2/9] Removendo regras de firewall personalizadas...

:: tenta remover regras com nome comecando por "Bloqueio" ou contendo "Bloqueio"
netsh advfirewall firewall delete rule name="Bloqueio*" >nul 2>&1
netsh advfirewall firewall delete rule name="Bloqueio-*" >nul 2>&1
netsh advfirewall firewall delete rule name="Bloqueio-Jogo-*" >nul 2>&1
netsh advfirewall firewall delete rule name="Bloqueio %SystemRoot%" >nul 2>&1

:: remove regras criadas por caminho de executavel (tentativa direta)
for %%P in (
    "C:\Program Files (x86)\Steam\steam.exe"
    "C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
    "C:\Riot Games\Riot Client\RiotClientServices.exe"
    "C:\Program Files (x86)\Battle.net\Battle.net.exe"
    "C:\Program Files (x86)\Garena\Garena\Garena.exe"
    "C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"
) do (
    netsh advfirewall firewall delete rule program="%%~P" >nul 2>&1
)

:: Reinicia firewall para garantir remoção de bloqueios profundos
echo    Resetando firewall para configuracao padrao...
netsh advfirewall reset >nul 2>&1
echo    Regras de firewall removidas/resetadas.

:: -------------------------
:: 3) REMOVER POLITICAS SRP / SAFER (Software Restriction Policy)
:: -------------------------
echo [3/9] Removendo Software Restriction Policy (Safer / SRP)...
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer" /f >nul 2>&1
reg delete "HKLM\Software\Policies\Microsoft\Windows\SrpV2" /f >nul 2>&1

:: -------------------------
:: 4) REMOVER BLOQUEIOS DE PENDRIVE
:: -------------------------
echo [4/9] Removendo politicas de RemovableStorageDevices...
reg delete "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /f >nul 2>&1

:: -------------------------
:: 5) REMOVER ATTACHMENTS (Bloqueio de downloads)
:: -------------------------
echo [5/9] Removendo politicas de Attachments (Download/Scan) no HKCU e HKLM...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /f >nul 2>&1

:: -------------------------
:: 6) TENTAR REMOVER APPLOCKER (SE HOUVER)
:: -------------------------
echo [6/9] Tentando remover politicas AppLocker (se existirem)...
:: Usa PowerShell para limpar AppLocker (requer modulo e privilegios). Pode falhar silenciosamente se nao existir.
powershell -Command "Try { Set-AppLockerPolicy -XMLPolicy '<AppLockerPolicy Version=`\"1`\" />' -ErrorAction Stop } Catch { }" >nul 2>&1

:: -------------------------
:: 7) REMOVER REGRAS ADICIONADAS AO HOSTS (caso existentes em formatos variados)
:: -------------------------
echo [7/9] Limpando entradas 127.0.0.1 repetidas e entradas de bloqueio de jogos (caso tenham sido adicionadas a mais)...
:: já reescrevemos o hosts no passo 1, esse passo verifica se existe copia alternativa e garante limpeza

:: -------------------------
:: 8) RESETAR PERMISSOES NEGADAS (ICACLS) EM POSSIVEIS EXECUTAVEIS BLOQUEADOS
:: -------------------------
echo [8/9] Resetando permissoes em caminhos comuns de jogos e em %APPDATA%...
:: Tenta resetar permissoes de arquivos que possivelmente tiveram ACE Deny aplicadas
set targets=%APPDATA%\.minecraft %APPDATA%\TLauncher "%ProgramFiles(x86)%\Steam" "%ProgramFiles(x86)%\Epic Games" "%ProgramFiles(x86)%\Battle.net" "%ProgramFiles%\Steam" "%ProgramFiles%\Epic Games"

for %%T in (%targets%) do (
    if exist "%%~T" (
        icacls "%%~T" /reset /T >nul 2>&1
    )
)

:: Adicional: reseta permissão específica do launcher se existir
if exist "%APPDATA%\.minecraft\launcher.exe" (
    icacls "%APPDATA%\.minecraft\launcher.exe" /reset >nul 2>&1
)
if exist "%APPDATA%\.minecraft\tlauncher.exe" (
    icacls "%APPDATA%\.minecraft\tlauncher.exe" /reset >nul 2>&1
)

:: -------------------------
:: 9) REMOCAO DE OUTRAS CHAVES DE POLITICA QUE PODEM TER SIDO ALTERADAS
:: -------------------------
echo [9/9] Removendo chaves especificas de Politicas de bloqueio...
:: NAO deletar toda a arvore de politicas do Windows, apenas as especificas criadas
reg delete "HKLM\System\CurrentControlSet\Control\StorageDevicePolicies" /v WriteProtect /f >nul 2>&1

:: OBS: Evitamos deletar HKLM\Software\Policies\Microsoft\Windows inteiro pois pode afetar outras configuracoes do sistema

echo.
echo Aplicando gpupdate para garantir que politicas locais sejam recarregadas...
gpupdate /force >nul 2>&1

echo.
echo ================================================
echo    AÇÃO CONCLUÍDA: TENTE REINICIAR O COMPUTADOR
echo ================================================
echo.
echo Recomendo reiniciar agora para validar tudo.
pause
exit /b 0
