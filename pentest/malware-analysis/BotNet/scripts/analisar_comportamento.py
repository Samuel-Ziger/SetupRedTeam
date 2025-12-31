#!/usr/bin/env python3
"""
Análise de Comportamento Esperado - DarkDDoSer
Simula e documenta o comportamento esperado do malware
"""

import json
from pathlib import Path
from datetime import datetime


class BehaviorAnalyzer:
    """Analisa o comportamento esperado do malware"""
    
    def __init__(self):
        self.behaviors = []
    
    def analyze_network_behavior(self):
        """Analisa comportamento de rede"""
        network = {
            "category": "network",
            "description": "Comportamento de rede esperado",
            "behaviors": [
                {
                    "type": "outbound_connection",
                    "protocol": "UDP",
                    "port": 3074,
                    "description": "Conexões UDP para porta de destino",
                    "frequency": "Alta (milhares de pacotes por segundo)",
                    "detection": "Fácil - tráfego UDP anômalo detectável"
                },
                {
                    "type": "data_exfiltration",
                    "protocol": "Possível HTTP/HTTPS",
                    "description": "Sistema de atualizações pode comunicar com C&C",
                    "detection": "Verificar conexões HTTP/HTTPS desconhecidas"
                }
            ]
        }
        return network
    
    def analyze_file_system_behavior(self):
        """Analisa comportamento no sistema de arquivos"""
        filesystem = {
            "category": "filesystem",
            "description": "Operações no sistema de arquivos",
            "behaviors": [
                {
                    "type": "file_read",
                    "files": [
                        "login.ini",
                        "settings.ini"
                    ],
                    "description": "Lê configurações na inicialização"
                },
                {
                    "type": "file_write",
                    "files": [
                        "login.ini",
                        "settings.ini"
                    ],
                    "description": "Pode modificar configurações durante execução"
                },
                {
                    "type": "directory_access",
                    "directories": [
                        "vcl_skins/",
                        "Backgrounds/",
                        "Icons/"
                    ],
                    "description": "Acessa recursos visuais"
                }
            ]
        }
        return filesystem
    
    def analyze_process_behavior(self):
        """Analisa comportamento de processos"""
        process = {
            "category": "process",
            "description": "Comportamento de processos",
            "behaviors": [
                {
                    "type": "process_creation",
                    "name": "DaRKDDoSeR.exe",
                    "description": "Processo principal do malware"
                },
                {
                    "type": "thread_creation",
                    "count": 6,
                    "description": "Cria múltiplas threads para paralelizar ataques"
                },
                {
                    "type": "socket_creation",
                    "count": 55,
                    "description": "Cria múltiplos sockets para distribuir carga"
                },
                {
                    "type": "high_cpu_usage",
                    "description": "Uso intenso de CPU devido a múltiplas threads"
                },
                {
                    "type": "high_network_usage",
                    "description": "Alto uso de largura de banda (até ~72 Mbps teórico)"
                }
            ]
        }
        return process
    
    def analyze_registry_behavior(self):
        """Analisa comportamento no registro do Windows"""
        registry = {
            "category": "registry",
            "description": "Operações no registro do Windows",
            "behaviors": [
                {
                    "type": "registry_read",
                    "keys": [
                        "HKEY_CURRENT_USER\\Software\\DarkDDoSer",
                        "HKEY_LOCAL_MACHINE\\Software\\DarkDDoSer"
                    ],
                    "description": "Possível leitura de configurações no registro (não confirmado)"
                },
                {
                    "type": "persistence",
                    "possible_locations": [
                        "HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                        "HKEY_LOCAL_MACHINE\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
                    ],
                    "description": "Pode tentar adicionar entrada para persistência (não confirmado)"
                }
            ]
        }
        return registry
    
    def generate_mitigation_recommendations(self):
        """Gera recomendações de mitigação"""
        mitigations = {
            "network": [
                "Implementar rate limiting em portas UDP",
                "Monitorar tráfego UDP anômalo",
                "Configurar regras de firewall para bloquear tráfego não autorizado",
                "Usar DDoS protection em serviços críticos"
            ],
            "filesystem": [
                "Monitorar criação/modificação de arquivos .ini no diretório do malware",
                "Configurar alertas para acesso a arquivos de configuração",
                "Implementar controle de integridade de arquivos"
            ],
            "process": [
                "Monitorar criação de processos com nome 'DaRKDDoSeR.exe'",
                "Alertar sobre processos com múltiplas threads de rede",
                "Configurar limites de recursos (CPU, rede) por processo"
            ],
            "registry": [
                "Monitorar modificações no registro relacionadas ao malware",
                "Alertar sobre tentativas de persistência automática",
                "Implementar whitelist de processos que podem modificar Run keys"
            ]
        }
        return mitigations
    
    def generate_detection_signatures(self):
        """Gera assinaturas de detecção"""
        signatures = {
            "yara": "Use a regra gerada por gerar_iocs.py",
            "sigma": "Use a regra gerada por gerar_iocs.py",
            "snort": [
                "alert udp any any -> any 3074 (msg:\"Possible DarkDDoSer UDP flood\"; threshold:type both, track by_src, count 1000, seconds 10;)"
            ],
            "suricata": [
                "alert udp any any -> any 3074 (msg:\"Possible DarkDDoSer UDP flood\"; threshold:type both, track by_src, count 1000, seconds 10;)"
            ]
        }
        return signatures
    
    def generate_full_report(self):
        """Gera relatório completo de comportamento"""
        report = {
            "malware": "DarkDDoSer",
            "analysis_date": datetime.now().isoformat(),
            "behaviors": {
                "network": self.analyze_network_behavior(),
                "filesystem": self.analyze_file_system_behavior(),
                "process": self.analyze_process_behavior(),
                "registry": self.analyze_registry_behavior()
            },
            "mitigations": self.generate_mitigation_recommendations(),
            "detection_signatures": self.generate_detection_signatures(),
            "risk_level": "HIGH",
            "recommendations": [
                "Implementar detecção baseada em comportamento",
                "Configurar monitoramento de rede em tempo real",
                "Usar sandboxing para análise de novos binários",
                "Manter sistemas de detecção atualizados"
            ]
        }
        return report


def main():
    analyzer = BehaviorAnalyzer()
    report = analyzer.generate_full_report()
    
    # Salvar relatório JSON
    output_file = Path("analise_comportamento.json")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    
    print("=" * 60)
    print("ANÁLISE DE COMPORTAMENTO - DarkDDoSer")
    print("=" * 60)
    print(f"\n📊 Relatório gerado: {output_file}\n")
    
    # Exibir resumo
    print("🔍 COMPORTAMENTOS IDENTIFICADOS:\n")
    
    for category, data in report["behaviors"].items():
        print(f"  {category.upper()}:")
        for behavior in data.get("behaviors", []):
            print(f"    • {behavior.get('type', 'N/A')}: {behavior.get('description', '')}")
        print()
    
    print("🛡️ RECOMENDAÇÕES DE MITIGAÇÃO:\n")
    for category, mitigations in report["mitigations"].items():
        print(f"  {category.upper()}:")
        for mitigation in mitigations:
            print(f"    • {mitigation}")
        print()
    
    print(f"✅ Análise completa salva em: {output_file}")


if __name__ == "__main__":
    main()

