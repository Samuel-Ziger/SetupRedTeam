#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script Principal para Análise e Exploração de Serviço Telnet
Orquestra todas as funcionalidades: identificação, análise e bruteforce
"""

import sys
import argparse
from telnet_info import TelnetInfo
from telnet_bruteforce import TelnetBruteforce
from telnet_default_passwords import test_default_passwords

def print_banner():
    """Imprime banner do script"""
    banner = """
    ╔══════════════════════════════════════════════════════════╗
    ║     TelNet Analyzer & Bruteforcer - ZTE Router          ║
    ║     Análise e Exploração de Serviço Telnet              ║
    ╚══════════════════════════════════════════════════════════╝
    """
    print(banner)

def main():
    """Função principal"""
    parser = argparse.ArgumentParser(
        description='Ferramenta de análise e bruteforce para serviço Telnet',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:
  # Apenas análise/informações
  python telnet_main.py --info 192.168.1.1
  
  # Bruteforce completo
  python telnet_main.py --bruteforce 192.168.1.1 xato_net_passwords.txt
  
  # Análise + Bruteforce
  python telnet_main.py --all 192.168.1.1 xato_net_passwords.txt
  
  # Testar senhas padrão primeiro (mais rápido)
  python telnet_main.py --defaults 192.168.1.1
  
  # Com opções customizadas
  python telnet_main.py --bruteforce 192.168.1.1 xato_net_passwords.txt --username admin --threads 10
        """
    )
    
    parser.add_argument('host', nargs='?', help='Endereço IP ou hostname do alvo')
    parser.add_argument('wordlist', nargs='?', help='Caminho para arquivo de wordlist')
    
    # Modos de operação
    mode_group = parser.add_mutually_exclusive_group(required=True)
    mode_group.add_argument('--info', action='store_true', 
                           help='Apenas coletar informações/banner')
    mode_group.add_argument('--bruteforce', action='store_true',
                           help='Apenas realizar bruteforce')
    mode_group.add_argument('--all', action='store_true',
                           help='Análise completa + bruteforce')
    mode_group.add_argument('--defaults', action='store_true',
                           help='Testar apenas senhas padrão comuns')
    
    # Opções gerais
    parser.add_argument('--port', type=int, default=23,
                       help='Porta do serviço Telnet (padrão: 23)')
    parser.add_argument('--username', type=str, default='root',
                       help='Nome de usuário para bruteforce (padrão: root)')
    parser.add_argument('--threads', type=int, default=5,
                       help='Número de threads para bruteforce (padrão: 5)')
    parser.add_argument('--delay', type=float, default=0.5,
                       help='Delay entre tentativas em segundos (padrão: 0.5)')
    parser.add_argument('--timeout', type=int, default=10,
                       help='Timeout para conexões em segundos (padrão: 10)')
    
    args = parser.parse_args()
    
    print_banner()
    
    # Validação de argumentos
    if not args.host:
        parser.error("Host é obrigatório")
    
    if (args.bruteforce or args.all) and not args.wordlist:
        parser.error("Wordlist é obrigatória para modo bruteforce")
    
    host = args.host
    port = args.port
    
    # Modo: Apenas informações
    if args.info:
        print(f"[*] Modo: Coleta de Informações")
        print(f"[*] Alvo: {host}:{port}\n")
        
        analyzer = TelnetInfo(host, port, args.timeout)
        info = analyzer.analyze()
        
        print("\n[*] Informações coletadas:")
        print(f"    Host: {info.get('host')}")
        print(f"    Porta: {info.get('port')}")
        print(f"    Versão: {info.get('version', 'Não identificada')}")
        print(f"    Características: {', '.join(info.get('characteristics', []))}")
        
        return 0
    
    # Modo: Apenas bruteforce
    if args.bruteforce:
        print(f"[*] Modo: Bruteforce")
        print(f"[*] Alvo: {host}:{port}")
        print(f"[*] Usuário: {args.username}\n")
        
        bruteforcer = TelnetBruteforce(
            host, port, args.username, 
            timeout=args.timeout, 
            delay=args.delay
        )
        result = bruteforcer.bruteforce(args.wordlist, args.threads)
        
        if result:
            print(f"\n[+] Credenciais encontradas:")
            print(f"    Usuário: {args.username}")
            print(f"    Senha: {result}")
            return 0
        else:
            return 1
    
    # Modo: Testar senhas padrão
    if args.defaults:
        print(f"[*] Modo: Teste de Senhas Padrão")
        print(f"[*] Alvo: {host}:{port}")
        print(f"[*] Usuário: {args.username}\n")
        
        result = test_default_passwords(
            host, port, args.username,
            timeout=args.timeout,
            delay=args.delay
        )
        
        if result:
            print(f"\n[+] Credenciais encontradas:")
            print(f"    Usuário: {args.username}")
            print(f"    Senha: {result}")
            return 0
        else:
            return 1
    
    # Modo: Tudo (análise + bruteforce)
    if args.all:
        print(f"[*] Modo: Análise Completa")
        print(f"[*] Alvo: {host}:{port}\n")
        
        # Primeiro: Análise
        print("=" * 60)
        print("ETAPA 1: COLETA DE INFORMAÇÕES")
        print("=" * 60)
        analyzer = TelnetInfo(host, port, args.timeout)
        info = analyzer.analyze()
        
        print("\n" + "=" * 60)
        print("ETAPA 2: BRUTEFORCE")
        print("=" * 60)
        
        # Segundo: Bruteforce
        bruteforcer = TelnetBruteforce(
            host, port, args.username,
            timeout=args.timeout,
            delay=args.delay
        )
        result = bruteforcer.bruteforce(args.wordlist, args.threads)
        
        print("\n" + "=" * 60)
        print("RESUMO FINAL")
        print("=" * 60)
        print(f"Host: {host}:{port}")
        print(f"Versão: {info.get('version', 'Não identificada')}")
        if result:
            print(f"[+] Credenciais encontradas:")
            print(f"    Usuário: {args.username}")
            print(f"    Senha: {result}")
            return 0
        else:
            print("[!] Senha não encontrada na wordlist")
            return 1
    
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n[!] Interrompido pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n[!] Erro inesperado: {e}")
        sys.exit(1)

