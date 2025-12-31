#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de Identificação e Análise de Serviço Telnet
Coleta informações sobre o serviço Telnet, incluindo banner e versão
"""

import socket
import sys
import re
import time
from typing import Optional, Dict

class TelnetInfo:
    def __init__(self, host: str, port: int = 23, timeout: int = 10):
        """
        Inicializa o objeto TelnetInfo
        
        Args:
            host: Endereço IP ou hostname do alvo
            port: Porta do serviço Telnet (padrão: 23)
            timeout: Timeout para conexões (padrão: 10 segundos)
        """
        self.host = host
        self.port = port
        self.timeout = timeout
        self.banner = None
        self.version = None
        self.info = {}
    
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
            print(f"[!] Timeout ao conectar em {self.host}:{self.port}")
            return None
        except socket.error as e:
            print(f"[!] Erro ao conectar: {e}")
            return None
        except Exception as e:
            print(f"[!] Erro inesperado: {e}")
            return None
    
    def grab_banner(self) -> Optional[str]:
        """
        Coleta o banner do serviço Telnet
        
        Returns:
            Banner coletado ou None em caso de erro
        """
        sock = self.connect()
        if not sock:
            return None
        
        try:
            # Aguarda um pouco para receber o banner
            time.sleep(0.5)
            
            # Recebe dados do banner
            sock.settimeout(2)
            banner_data = b""
            
            try:
                while True:
                    data = sock.recv(4096)
                    if not data:
                        break
                    banner_data += data
                    # Limite de 10KB para evitar buffer overflow
                    if len(banner_data) > 10240:
                        break
            except socket.timeout:
                pass  # Timeout esperado após receber o banner
            
            if banner_data:
                # Tenta decodificar como UTF-8, fallback para latin-1
                try:
                    banner = banner_data.decode('utf-8', errors='ignore')
                except:
                    banner = banner_data.decode('latin-1', errors='ignore')
                
                self.banner = banner
                return banner
            else:
                print("[!] Nenhum banner recebido")
                return None
                
        except Exception as e:
            print(f"[!] Erro ao coletar banner: {e}")
            return None
        finally:
            sock.close()
    
    def extract_version(self, banner: str) -> Optional[str]:
        """
        Extrai informações de versão do banner
        
        Args:
            banner: Banner coletado
            
        Returns:
            Versão identificada ou None
        """
        if not banner:
            return None
        
        # Padrões comuns para identificar versão
        patterns = [
            r'telnetd\s+([\d.]+[-\w]*)',
            r'version\s+([\d.]+)',
            r'v([\d.]+)',
            r'([\d.]+[\w-]*)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, banner, re.IGNORECASE)
            if match:
                version = match.group(1)
                self.version = version
                return version
        
        return None
    
    def analyze(self) -> Dict:
        """
        Realiza análise completa do serviço Telnet
        
        Returns:
            Dicionário com informações coletadas
        """
        print(f"[*] Conectando em {self.host}:{self.port}...")
        
        banner = self.grab_banner()
        if banner:
            print("[+] Banner coletado:")
            print("-" * 60)
            print(banner)
            print("-" * 60)
            
            # Extrai versão
            version = self.extract_version(banner)
            if version:
                print(f"[+] Versão identificada: {version}")
            
            # Detecta características específicas
            characteristics = []
            if 'root' in banner.lower() or 'username' in banner.lower():
                characteristics.append("Requer autenticação")
            if 'zte' in banner.lower():
                characteristics.append("Dispositivo ZTE")
            if 'router' in banner.lower():
                characteristics.append("Roteador")
            
            if characteristics:
                print(f"[+] Características: {', '.join(characteristics)}")
            
            self.info = {
                'host': self.host,
                'port': self.port,
                'banner': banner,
                'version': version,
                'characteristics': characteristics
            }
        else:
            print("[!] Não foi possível coletar o banner")
            self.info = {
                'host': self.host,
                'port': self.port,
                'banner': None,
                'version': None,
                'characteristics': []
            }
        
        return self.info


def main():
    """Função principal"""
    if len(sys.argv) < 2:
        print("Uso: python telnet_info.py <IP> [porta]")
        print("Exemplo: python telnet_info.py 192.168.1.1 23")
        sys.exit(1)
    
    host = sys.argv[1]
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 23
    
    analyzer = TelnetInfo(host, port)
    info = analyzer.analyze()
    
    print("\n[*] Análise concluída!")
    return info


if __name__ == "__main__":
    main()

