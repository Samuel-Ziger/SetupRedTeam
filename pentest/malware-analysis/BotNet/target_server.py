#!/usr/bin/env python3
"""
SERVIDOR ALVO DE TESTE - APENAS PARA FINS DE DEMONSTRAÇÃO
=========================================================
Este servidor simula um servidor web que será o alvo do ataque DDoS
em uma demonstração educacional controlada.
"""

import socket
import threading
import time
from datetime import datetime

class TargetServer:
    def __init__(self, host='127.0.0.1', port=8080):
        self.host = host
        self.port = port
        self.request_count = 0
        self.start_time = None
        self.server_socket = None
        
    def handle_client(self, client_socket, address):
        """Gerencia requisições de clientes"""
        self.request_count += 1
        current_time = datetime.now().strftime("%H:%M:%S")
        
        print(f"[{current_time}] Requisição #{self.request_count} de {address[0]}:{address[1]}")
        
        try:
            # Simula processamento
            response = f"""HTTP/1.1 200 OK
Content-Type: text/html

<html>
<head><title>Servidor de Teste</title></head>
<body>
    <h1>Servidor de Teste Educacional</h1>
    <p>Requisição #{self.request_count}</p>
    <p>Hora: {current_time}</p>
    <p>Este é um servidor de demonstração para fins educacionais.</p>
</body>
</html>
"""
            client_socket.send(response.encode('utf-8'))
        except:
            pass
        finally:
            client_socket.close()
    
    def start(self):
        """Inicia o servidor"""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(10)
        
        self.start_time = time.time()
        
        print("=" * 60)
        print("SERVIDOR ALVO DE TESTE INICIADO")
        print("=" * 60)
        print(f"Escutando em {self.host}:{self.port}")
        print("Este servidor será o alvo do ataque DDoS simulado")
        print("=" * 60)
        print("\nMonitorando requisições...\n")
        
        # Thread para estatísticas
        def show_stats():
            while True:
                time.sleep(5)
                elapsed = time.time() - self.start_time
                rps = self.request_count / elapsed if elapsed > 0 else 0
                print(f"\n[Estatísticas] Requisições: {self.request_count} | RPS: {rps:.2f}\n")
        
        stats_thread = threading.Thread(target=show_stats)
        stats_thread.daemon = True
        stats_thread.start()
        
        try:
            while True:
                client_socket, address = self.server_socket.accept()
                client_thread = threading.Thread(
                    target=self.handle_client,
                    args=(client_socket, address)
                )
                client_thread.daemon = True
                client_thread.start()
        except KeyboardInterrupt:
            print("\n[+] Servidor encerrado")
            elapsed = time.time() - self.start_time
            print(f"Total de requisições recebidas: {self.request_count}")
            print(f"Tempo total: {elapsed:.2f} segundos")
            if elapsed > 0:
                print(f"Requisições por segundo: {self.request_count/elapsed:.2f}")

def main():
    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║      SERVIDOR ALVO DE TESTE - DEMONSTRAÇÃO EDUCACIONAL   ║
    ╚══════════════════════════════════════════════════════════╝
    
    Este servidor simula um alvo para demonstração de ataques DDoS.
    Use apenas em ambiente controlado e isolado.
    
    """)
    
    server = TargetServer(host='127.0.0.1', port=8080)
    server.start()

if __name__ == '__main__':
    main()

