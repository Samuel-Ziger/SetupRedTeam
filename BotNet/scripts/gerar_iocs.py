#!/usr/bin/env python3
"""
Gera Indicadores de Comprometimento (IOCs) do DarkDDoSer
Cria arquivos YARA, Sigma e lista de IOCs
"""

import hashlib
import os
from pathlib import Path
import json


def calculate_file_hash(file_path, algorithm='sha256'):
    """Calcula hash de um arquivo"""
    hash_obj = hashlib.new(algorithm)
    with open(file_path, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            hash_obj.update(chunk)
    return hash_obj.hexdigest()


def generate_yara_rule():
    """Gera regra YARA para detecção"""
    yara_rule = """
rule DarkDDoSer_Malware {
    meta:
        description = "Detects DarkDDoSer DDoS malware"
        author = "Malware Analyst"
        date = "2024"
        threat_type = "DDoS Tool"
    
    strings:
        $s1 = "DaRKDDoSeR" nocase
        $s2 = "login.ini"
        $s3 = "settings.ini"
        $s4 = "floodtype"
        $s5 = "darkddoser" nocase
        $s6 = "UDP"
        $s7 = "strength"
        $s8 = "vcl_skins"
    
    condition:
        4 of them
}
"""
    return yara_rule.strip()


def generate_sigma_rule():
    """Gera regra Sigma para SIEM"""
    sigma_rule = {
        "title": "DarkDDoSer DDoS Tool Execution",
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "description": "Detects execution of DarkDDoSer DDoS malware",
        "references": [
            "https://github.com/ytisf/theZoo"
        ],
        "author": "Malware Analyst",
        "date": "2024/01/01",
        "tags": [
            "attack.impact",
            "attack.ddos"
        ],
        "logsource": {
            "category": "process_creation",
            "product": "windows"
        },
        "detection": {
            "selection": {
                "Image|endswith": "DaRKDDoSeR.exe"
            },
            "condition": "selection"
        },
        "level": "high"
    }
    return sigma_rule


def generate_ioc_list(base_path):
    """Gera lista completa de IOCs"""
    iocs = {
        "malware_name": "DarkDDoSer",
        "type": "DDoS Tool",
        "platform": "Windows",
        "iocs": []
    }
    
    exe_path = base_path / "DaRKDDoSeR.exe"
    if exe_path.exists():
        md5 = calculate_file_hash(exe_path, 'md5')
        sha256 = calculate_file_hash(exe_path, 'sha256')
        
        file_size = exe_path.stat().st_size
        
        iocs["iocs"].append({
            "type": "file",
            "value": "DaRKDDoSeR.exe",
            "md5": md5,
            "sha256": sha256,
            "size": file_size,
            "description": "Main executable"
        })
    
    # Process names
    iocs["iocs"].append({
        "type": "process",
        "value": "DaRKDDoSeR.exe",
        "description": "Main process name"
    })
    
    # File paths
    file_paths = [
        "login.ini",
        "settings.ini",
        "vcl_skins",
        "Backgrounds",
        "Icons"
    ]
    
    for path in file_paths:
        full_path = base_path / path
        if full_path.exists():
            iocs["iocs"].append({
                "type": "filepath",
                "value": str(path),
                "description": f"Configuration/Resource file: {path}"
            })
    
    # Network indicators
    iocs["iocs"].append({
        "type": "network",
        "protocol": "UDP",
        "port": 3074,
        "description": "Default attack port (Xbox Live)"
    })
    
    # Registry (possible)
    iocs["iocs"].append({
        "type": "registry",
        "value": "HKEY_CURRENT_USER\\Software\\DarkDDoSer",
        "description": "Possible registry location (not confirmed)"
    })
    
    return iocs


def main():
    base_path = Path("theZoo/darkddoser/darkddoser/DarkDDoSer")
    
    if not base_path.exists():
        print(f"❌ Erro: Diretório não encontrado: {base_path}")
        return
    
    # Criar diretório de saída
    output_dir = Path("iocs")
    output_dir.mkdir(exist_ok=True)
    
    print("🔍 Gerando Indicadores de Comprometimento...")
    
    # Gerar regra YARA
    yara_rule = generate_yara_rule()
    yara_file = output_dir / "darkddoser.yara"
    with open(yara_file, 'w', encoding='utf-8') as f:
        f.write(yara_rule)
    print(f"✓ Regra YARA gerada: {yara_file}")
    
    # Gerar regra Sigma
    sigma_rule = generate_sigma_rule()
    sigma_file = output_dir / "darkddoser.yml"
    with open(sigma_file, 'w', encoding='utf-8') as f:
        import yaml
        try:
            yaml.dump(sigma_rule, f, default_flow_style=False, sort_keys=False)
            print(f"✓ Regra Sigma gerada: {sigma_file}")
        except ImportError:
            # Se PyYAML não estiver instalado, salvar como JSON
            import json
            with open(output_dir / "darkddoser_sigma.json", 'w') as f2:
                json.dump(sigma_rule, f2, indent=2)
            print(f"✓ Regra Sigma gerada (JSON): {output_dir / 'darkddoser_sigma.json'}")
    
    # Gerar lista de IOCs
    ioc_list = generate_ioc_list(base_path)
    ioc_file = output_dir / "iocs.json"
    with open(ioc_file, 'w', encoding='utf-8') as f:
        json.dump(ioc_list, f, indent=2, ensure_ascii=False)
    print(f"✓ Lista de IOCs gerada: {ioc_file}")
    
    # Gerar relatório de IOCs em texto
    report_file = output_dir / "iocs_report.txt"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("=" * 60 + "\n")
        f.write("INDICADORES DE COMPROMETIMENTO - DarkDDoSer\n")
        f.write("=" * 60 + "\n\n")
        
        for ioc in ioc_list["iocs"]:
            f.write(f"Tipo: {ioc['type']}\n")
            f.write(f"Valor: {ioc.get('value', ioc.get('port', 'N/A'))}\n")
            if 'md5' in ioc:
                f.write(f"MD5: {ioc['md5']}\n")
            if 'sha256' in ioc:
                f.write(f"SHA256: {ioc['sha256']}\n")
            if 'description' in ioc:
                f.write(f"Descrição: {ioc['description']}\n")
            f.write("\n" + "-" * 60 + "\n\n")
    
    print(f"✓ Relatório de IOCs gerado: {report_file}")
    print(f"\n✅ Todos os IOCs foram gerados em: {output_dir}/")


if __name__ == "__main__":
    main()

