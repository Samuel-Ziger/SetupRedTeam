#!/usr/bin/env python3
"""
Script para escanear dispositivos Bluetooth próximos
Identifica caixas de som e outros dispositivos Bluetooth
"""

import bluetooth
import sys
import time

def scan_devices(duration=10):
    """
    Escaneia dispositivos Bluetooth por um período determinado
    
    Args:
        duration: Tempo de escaneamento em segundos (padrão: 10)
    """
    print(f"[*] Escaneando dispositivos Bluetooth por {duration} segundos...")
    print("[*] Certifique-se de que o Bluetooth está ativado na caixa de som\n")
    
    devices = bluetooth.discover_devices(
        duration=duration,
        lookup_names=True,
        flush_cache=True
    )
    
    if not devices:
        print("[-] Nenhum dispositivo encontrado")
        print("[!] Verifique se:")
        print("    - O Bluetooth está ativado nos dispositivos")
        print("    - Os dispositivos estão no modo pareamento")
        print("    - O adaptador Bluetooth está funcionando (hciconfig)")
        return []
    
    print(f"[+] {len(devices)} dispositivo(s) encontrado(s):\n")
    
    device_list = []
    for i, (addr, name) in enumerate(devices, 1):
        try:
            services = bluetooth.find_service(address=addr)
            device_type = "Desconhecido"
            
            # Tentar identificar tipo de dispositivo
            if name:
                name_lower = name.lower()
                if any(word in name_lower for word in ['speaker', 'som', 'sound', 'audio', 'jbl', 'bose', 'sony']):
                    device_type = "🎵 Caixa de Som"
                elif any(word in name_lower for word in ['phone', 'celular', 'mobile', 'iphone', 'android']):
                    device_type = "📱 Celular"
                elif any(word in name_lower for word in ['headphone', 'fone', 'earbud']):
                    device_type = "🎧 Fone de Ouvido"
            
            print(f"[{i}] {device_type}")
            print(f"    Nome: {name or 'Sem nome'}")
            print(f"    MAC:  {addr}")
            print(f"    Serviços: {len(services)}")
            print()
            
            device_list.append({
                'name': name,
                'mac': addr,
                'type': device_type,
                'services': len(services)
            })
            
        except Exception as e:
            print(f"[!] Erro ao processar {addr}: {e}")
    
    return device_list

def main():
    print("=" * 60)
    print("    ESCANEADOR BLUETOOTH - Laboratório de Segurança")
    print("=" * 60)
    print()
    
    try:
        # Verificar se o Bluetooth está disponível
        import subprocess
        result = subprocess.run(['hciconfig'], capture_output=True, text=True)
        if 'hci0' not in result.stdout:
            print("[!] AVISO: Adaptador Bluetooth não encontrado!")
            print("[!] Execute: sudo hciconfig hci0 up")
            print()
        
        # Escanear dispositivos
        devices = scan_devices(duration=10)
        
        if devices:
            print("\n" + "=" * 60)
            print("RESUMO:")
            print("=" * 60)
            for dev in devices:
                print(f"MAC: {dev['mac']} | {dev['type']} | {dev['name']}")
            print("\n[+] Use o endereço MAC com os scripts de ataque")
        
    except KeyboardInterrupt:
        print("\n\n[!] Escaneamento interrompido pelo usuário")
        sys.exit(0)
    except Exception as e:
        print(f"\n[!] Erro: {e}")
        print("[!] Certifique-se de que:")
        print("    1. O Bluetooth está instalado: sudo apt install bluez python3-bluez")
        print("    2. Você tem permissões: sudo usermod -aG bluetooth $USER")
        print("    3. O serviço está rodando: sudo systemctl start bluetooth")
        sys.exit(1)

if __name__ == "__main__":
    main()

