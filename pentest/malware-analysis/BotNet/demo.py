#!/usr/bin/env python3
"""
Script de Demonstração Rápida
==============================
Facilita a execução da demonstração durante a palestra.
"""

import subprocess
import sys
import time
import os

def print_header():
    print("""
    ╔══════════════════════════════════════════════════════════╗
    ║     DEMONSTRAÇÃO EDUCACIONAL - BOTNET E DDOS            ║
    ╚══════════════════════════════════════════════════════════╝
    
    AVISO: Apenas para fins educacionais!
    """)

def main():
    print_header()
    
    print("Escolha uma opção:")
    print("1. Iniciar Servidor Alvo (porta 8080)")
    print("2. Iniciar Servidor C&C (porta 9999)")
    print("3. Conectar Bot (especificar nome)")
    print("4. Sair")
    
    choice = input("\nOpção: ").strip()
    
    if choice == '1':
        print("\n[+] Iniciando servidor alvo em 127.0.0.1:8080...")
        subprocess.run([sys.executable, 'target_server.py'])
    
    elif choice == '2':
        print("\n[+] Iniciando servidor C&C em 127.0.0.1:9999...")
        subprocess.run([sys.executable, 'cc_server.py'])
    
    elif choice == '3':
        bot_name = input("Nome do bot: ").strip() or f"Bot-{int(time.time())}"
        print(f"\n[+] Conectando bot '{bot_name}' ao C&C...")
        subprocess.run([sys.executable, 'bot.py', bot_name])
    
    elif choice == '4':
        print("Encerrando...")
        sys.exit(0)
    
    else:
        print("Opção inválida!")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n[+] Encerrado pelo usuário")

