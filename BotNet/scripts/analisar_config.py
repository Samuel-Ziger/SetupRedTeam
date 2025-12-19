#!/usr/bin/env python3
"""
Script de Análise de Configurações - DarkDDoSer
Extrai e analisa parâmetros dos arquivos INI
"""

import configparser
import os
import json
from pathlib import Path


class DarkDDoSerAnalyzer:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.login_ini = self.base_path / "login.ini"
        self.settings_ini = self.base_path / "settings.ini"
    
    def parse_login(self):
        """Analisa o arquivo login.ini"""
        if not self.login_ini.exists():
            return None
        
        config = configparser.ConfigParser()
        config.read(self.login_ini, encoding='utf-8')
        
        login_data = {}
        if 'login' in config:
            login_data = {
                'username': config.get('login', 'username', fallback=''),
                'password': config.get('login', 'password', fallback=''),
                'updates': config.get('login', 'updates', fallback='No').lower() == 'yes'
            }
            
            # Análise de segurança
            login_data['security_issues'] = []
            if login_data['username'] == 'login' and login_data['password'] == 'pass':
                login_data['security_issues'].append('Credenciais padrão detectadas')
            if login_data['updates']:
                login_data['security_issues'].append('Sistema de atualizações ativo (possível vetor C&C)')
        
        return login_data
    
    def parse_settings(self):
        """Analisa o arquivo settings.ini"""
        if not self.settings_ini.exists():
            return None
        
        config = configparser.ConfigParser()
        config.read(self.settings_ini, encoding='utf-8')
        
        settings_data = {}
        
        # Seção [flood]
        if 'flood' in config:
            flood = {}
            flood['type'] = config.get('flood', 'floodtype', fallback='UNKNOWN')
            flood['port'] = config.getint('flood', 'port', fallback=0)
            flood['packets'] = config.getint('flood', 'packets', fallback=0)
            flood['packet_size'] = config.getint('flood', 'packetsize', fallback=0)
            flood['sockets'] = config.getint('flood', 'sockets', fallback=0)
            flood['threads'] = config.getint('flood', 'threads', fallback=0)
            flood['timer_enabled'] = config.getint('flood', 'timer', fallback=0) != 0
            flood['timer_seconds'] = config.getint('flood', 'timersec', fallback=0)
            flood['strength'] = config.getint('flood', 'strength', fallback=0)
            
            # Cálculos de capacidade
            if flood['timer_seconds'] > 0:
                packets_per_second = flood['packets'] / flood['timer_seconds']
                bandwidth_mbps = (packets_per_second * flood['packet_size'] * 8) / 1_000_000
                total_connections = flood['sockets'] * flood['threads']
                
                flood['metrics'] = {
                    'packets_per_second': round(packets_per_second, 2),
                    'bandwidth_mbps': round(bandwidth_mbps, 2),
                    'total_connections': total_connections,
                    'bytes_per_cycle': flood['packets'] * flood['packet_size']
                }
            
            settings_data['flood'] = flood
        
        # Seção [settings]
        if 'settings' in config:
            ui_settings = {}
            ui_settings['ports'] = config.get('settings', 'ports', fallback='')
            ui_settings['skin'] = config.get('settings', 'skin', fallback='')
            ui_settings['background'] = config.get('settings', 'background', fallback='')
            
            settings_data['ui'] = ui_settings
        
        return settings_data
    
    def analyze(self):
        """Executa análise completa"""
        result = {
            'login': self.parse_login(),
            'settings': self.parse_settings(),
            'files_found': {
                'login_ini': self.login_ini.exists(),
                'settings_ini': self.settings_ini.exists(),
                'executable': (self.base_path / "DaRKDDoSeR.exe").exists()
            }
        }
        return result
    
    def generate_report(self):
        """Gera relatório em formato legível"""
        analysis = self.analyze()
        
        report = []
        report.append("=" * 60)
        report.append("RELATÓRIO DE ANÁLISE - DarkDDoSer")
        report.append("=" * 60)
        report.append("")
        
        # Informações de Login
        if analysis['login']:
            report.append("📋 CONFIGURAÇÕES DE LOGIN")
            report.append("-" * 60)
            report.append(f"Usuário: {analysis['login']['username']}")
            report.append(f"Senha: {analysis['login']['password']}")
            report.append(f"Atualizações: {'Sim' if analysis['login']['updates'] else 'Não'}")
            
            if analysis['login']['security_issues']:
                report.append("\n⚠️ PROBLEMAS DE SEGURANÇA:")
                for issue in analysis['login']['security_issues']:
                    report.append(f"  • {issue}")
            report.append("")
        
        # Configurações de Ataque
        if analysis['settings'] and 'flood' in analysis['settings']:
            flood = analysis['settings']['flood']
            report.append("⚙️ CONFIGURAÇÕES DE ATAQUE")
            report.append("-" * 60)
            report.append(f"Tipo de Ataque: {flood['type']}")
            report.append(f"Porta Alvo: {flood['port']}")
            report.append(f"Pacotes por Ciclo: {flood['packets']:,}")
            report.append(f"Tamanho do Pacote: {flood['packet_size']:,} bytes")
            report.append(f"Sockets: {flood['sockets']}")
            report.append(f"Threads: {flood['threads']}")
            report.append(f"Intensidade: {flood['strength']}/100")
            
            if 'metrics' in flood:
                metrics = flood['metrics']
                report.append("\n📊 MÉTRICAS CALCULADAS:")
                report.append(f"  • Pacotes/segundo: {metrics['packets_per_second']:,}")
                report.append(f"  • Largura de banda: ~{metrics['bandwidth_mbps']:.2f} Mbps")
                report.append(f"  • Conexões totais: {metrics['total_connections']}")
                report.append(f"  • Bytes por ciclo: {metrics['bytes_per_cycle']:,}")
            report.append("")
        
        # Status dos Arquivos
        report.append("📁 ARQUIVOS ENCONTRADOS")
        report.append("-" * 60)
        for file_type, exists in analysis['files_found'].items():
            status = "✓" if exists else "✗"
            report.append(f"{status} {file_type}")
        
        report.append("")
        report.append("=" * 60)
        
        return "\n".join(report)


def main():
    # Caminho padrão
    default_path = Path("theZoo/darkddoser/darkddoser/DarkDDoSer")
    
    import sys
    if len(sys.argv) > 1:
        base_path = Path(sys.argv[1])
    else:
        base_path = default_path
    
    if not base_path.exists():
        print(f"❌ Erro: Diretório não encontrado: {base_path}")
        return
    
    analyzer = DarkDDoSerAnalyzer(base_path)
    
    # Gerar relatório
    print(analyzer.generate_report())
    
    # Salvar JSON
    analysis = analyzer.analyze()
    output_file = Path("analise_config.json")
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(analysis, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 Análise completa salva em: {output_file}")


if __name__ == "__main__":
    main()

