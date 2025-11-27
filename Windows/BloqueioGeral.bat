@echo off
title BLOQUEIO TOTAL POR LISTA BRANCA (WHITELIST)
color 0C

echo ================================================
echo      APLICANDO BLOQUEIO TOTAL (WHITELIST)
echo ================================================
echo.

set hostsfile=%SystemRoot%\System32\drivers\etc\hosts

echo [1/4] Limpando hosts antigo...
takeown /f %hostsfile% >nul
icacls %hostsfile% /grant administrators:F >nul

del %hostsfile% >nul
echo > %hostsfile%

echo [2/4] Adicionando localhost (nao pode ser bloqueado)...
echo 127.0.0.1 localhost >> %hostsfile%
echo ::1 localhost >> %hostsfile%

echo.
echo [3/4] Definindo LISTA BRANCA DE SITES PERMITIDOS...

:: ================================
::   ADICIONE OS SITES PERMITIDOS
:: ================================
set allowed=chat.openai.com ^
 gemini.google.com ^
 github.com ^
 linkedin.com ^
 code.visualstudio.com ^
 cursor.sh ^
 nodejs.org ^
 npmjs.com

for %%s in (%allowed%) do (
    echo Permitido: %%s
)

echo.
echo [4/4] Bloqueando TUDO exceto Lista Branca...

(
    echo # BLOQUEIO GLOBAL - SOMENTE SITES PERMITIDOS
    echo 127.0.0.1 localhost
    echo ::1 localhost
    echo.
    echo # SITES PERMITIDOS
    for %%s in (%allowed%) do (
        echo 0.0.0.0 %%s # liberado via regra inversa
    )
    echo.
    echo # BLOQUEIO PADRAO (TUDO O MAIS É BLOQUEADO)
    echo 0.0.0.0 0.0.0.0
) > %hostsfile%

echo.
echo ================================================
echo  BLOQUEIO TOTAL ATIVADO!
echo  Somente sites da LISTA BRANCA estao acessiveis.
echo ================================================
pause
exit
