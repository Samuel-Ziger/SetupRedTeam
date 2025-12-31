@echo off
title DESBLOQUEIO COMPLETO - LIMPEZA TOTAL
color 0E

:: -------------------------
:: Verifica se é admin
:: -------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ================================================
    echo  ERRO: Execute como Administrador!
    echo ================================================
    echo Clique com o botao direito e escolha
    echo "Executar como administrador"
    pause
    exit /b 1
)

echo ================================================
echo     DESBLOQUEIO COMPLETO - LIMPEZA TOTAL
echo ================================================
echo.
echo Este script ira:
echo  - Remover TODAS as regras de firewall de bloqueio
echo  - Restaurar arquivo hosts ao padrao
echo  - Remover restricoes de execucao (SRP/Safer)
echo  - Desbloquear USB/Pendrive
echo  - Restaurar permissoes de download
echo.
pause

:: -------------------------
:: 1) RESTAURAR ARQUIVO HOSTS
:: -------------------------
echo.
echo [1/8] Restaurando arquivo hosts...
set hostsfile=%SystemRoot%\System32\drivers\etc\hosts

:: Assumir propriedade
echo    Assumindo propriedade do arquivo hosts...
takeown /f "%hostsfile%"
icacls "%hostsfile%" /grant Administrators:F

:: Escrever conteudo padrao
echo    Escrevendo conteudo padrao no hosts...
(
    echo # Copyright (c) 1993-2009 Microsoft Corp.
    echo # This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
    echo # localhost name resolution is handled within DNS itself.
    echo 127.0.0.1       localhost
    echo ::1             localhost
) > "%hostsfile%"

echo    [OK] Hosts restaurado
timeout /t 2 /nobreak >nul

:: -------------------------
:: 2) LIMPAR CACHE DNS
:: -------------------------
echo.
echo [2/8] Limpando cache DNS...
ipconfig /flushdns
echo    [OK] Cache DNS limpo
timeout /t 2 /nobreak >nul

:: -------------------------
:: 3) REMOVER REGRAS DE FIREWALL
:: -------------------------
echo.
echo [3/8] Removendo TODAS as regras de firewall de bloqueio...

:: Lista de executaveis que podem estar bloqueados
set "launchers=C:\Program Files (x86)\Steam\steam.exe"
set "launchers=%launchers% C:\Program Files (x86)\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
set "launchers=%launchers% C:\Riot Games\Riot Client\RiotClientServices.exe"
set "launchers=%launchers% C:\Program Files (x86)\Battle.net\Battle.net.exe"
set "launchers=%launchers% C:\Program Files (x86)\Garena\Garena\Garena.exe"
set "launchers=%launchers% C:\Program Files (x86)\Minecraft Launcher\MinecraftLauncher.exe"

for %%i in (%launchers%) do (
    echo    Removendo bloqueio de: %%i
    netsh advfirewall firewall delete rule name="Bloqueio %%i"
    netsh advfirewall firewall delete rule program="%%i"
)

:: Remover regras com padroes de nome
echo    Procurando outras regras com "Bloqueio" no nome...
netsh advfirewall firewall show rule name=all | findstr /i "bloqueio" >nul 2>&1
if %errorlevel% equ 0 (
    echo    Removendo regras adicionais encontradas...
    for /f "tokens=2 delims=:" %%a in ('netsh advfirewall firewall show rule name^=all ^| findstr /i /c:"Nome da Regra" /c:"Rule Name"') do (
        set rulename=%%a
        echo !rulename! | findstr /i "bloqueio" >nul
        if !errorlevel! equ 0 (
            echo    Removendo: !rulename!
            netsh advfirewall firewall delete rule name="!rulename!"
        )
    )
)

echo    [OK] Regras de firewall removidas
timeout /t 2 /nobreak >nul

:: -------------------------
:: 4) REMOVER SOFTWARE RESTRICTION POLICY (SRP)
:: -------------------------
echo.
echo [4/8] Removendo restricoes de execucao (SRP/Safer)...
echo    Removendo HKLM\Software\Policies\Microsoft\Windows\Safer...
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /f
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer" /f
reg delete "HKLM\Software\Policies\Microsoft\Windows\SrpV2" /f
reg delete "HKCU\Software\Policies\Microsoft\Windows\Safer" /f
echo    [OK] SRP removido
timeout /t 2 /nobreak >nul

:: -------------------------
:: 5) DESBLOQUEAR PENDRIVE/USB
:: -------------------------
echo.
echo [5/8] Desbloqueando dispositivos USB...
echo    Removendo politicas de RemovableStorageDevices...
reg delete "HKLM\Software\Policies\Microsoft\Windows\RemovableStorageDevices" /f
echo    Removendo StorageDevicePolicies...
reg delete "HKLM\System\CurrentControlSet\Control\StorageDevicePolicies" /f
echo    Habilitando servico USBSTOR...
reg add "HKLM\System\CurrentControlSet\Services\USBSTOR" /v Start /t REG_DWORD /d 3 /f
echo    [OK] USB desbloqueado
timeout /t 2 /nobreak >nul

:: -------------------------
:: 6) RESTAURAR DOWNLOADS
:: -------------------------
echo.
echo [6/8] Restaurando permissoes de download...
echo    Removendo restricoes em HKCU...
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /f
echo    Removendo restricoes em HKLM...
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /f
echo    [OK] Downloads restaurados
timeout /t 2 /nobreak >nul

:: -------------------------
:: 7) REMOVER APPLOCKER (se existir)
:: -------------------------
echo.
echo [7/8] Limpando AppLocker...
powershell -Command "Try { Set-AppLockerPolicy -XMLPolicy '<AppLockerPolicy Version=\"1\" />' -ErrorAction Stop; Write-Host '    AppLocker limpo' } Catch { Write-Host '    AppLocker nao estava configurado' }"
echo    [OK] AppLocker verificado
timeout /t 2 /nobreak >nul

:: -------------------------
:: 8) ATUALIZAR POLITICAS
:: -------------------------
echo.
echo [8/8] Aplicando mudancas nas politicas do sistema...
echo    Isto pode levar alguns segundos...
gpupdate /force
echo    [OK] Politicas atualizadas

:: -------------------------
:: FINALIZADO
:: -------------------------
echo.
echo ================================================
echo  DESBLOQUEIO COMPLETO FINALIZADO!
echo ================================================
echo.
echo Importante:
echo  1. REINICIE o computador agora
echo  2. Apos reiniciar, verifique se tudo funciona
echo  3. Se ainda houver bloqueios, execute este
echo     script novamente como administrador
echo.
echo Resumo do que foi feito:
echo  [OK] Arquivo hosts restaurado
echo  [OK] Cache DNS limpo
echo  [OK] Regras de firewall removidas
echo  [OK] Restricoes de execucao (SRP) removidas
echo  [OK] Dispositivos USB desbloqueados
echo  [OK] Permissoes de download restauradas
echo  [OK] AppLocker limpo
echo  [OK] Politicas do sistema atualizadas
echo.
echo ================================================
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
exit /b 0
