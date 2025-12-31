# Scripts de Teste e Exploração - BancoCN

Scripts Python para testar e explorar a vulnerabilidade SQL Injection no site bancocn.com (lab da Solyd).

## ⚠️ AVISO LEGAL

Estes scripts são apenas para fins educacionais e devem ser usados apenas em ambientes autorizados (labs de segurança). O uso não autorizado é ilegal.

## Requisitos

```bash
pip install requests
```

## Scripts

### 1. `test_banco_cn.py` - Script de Teste/Validação

Refaz todos os testes realizados com sqlmap para validar a vulnerabilidade.

**Uso:**
```bash
python test_banco_cn.py
```

**O que faz:**
- Testa injeção SQL básica (aspas simples)
- Testa injeção error-based (FLOOR)
- Testa injeção time-based (SLEEP)
- Testa injeção UNION
- Obtém nome do banco de dados
- Lista tabelas
- Obtém dados das tabelas (users, categories, pictures)
- Obtém informações do banco (versão, usuário, etc.)

### 2. `exploit_banco_cn.py` - Script de Exploração

Modifica dados no banco de dados através de SQL Injection.

**Uso:**
```bash
python exploit_banco_cn.py
```

**Opções disponíveis:**

1. **Exploração completa automatizada** - Executa todas as modificações:
   - Deface da homepage (modifica todas as categorias)
   - Altera senha do admin
   - Cria usuário backdoor
   - Adiciona categoria maliciosa
   - Limpa estatísticas

2. **Modificar categoria específica** - Altera título e/ou texto de uma categoria

3. **Alterar senha do admin** - Muda a senha do usuário admin

4. **Criar usuário backdoor** - Insere novo usuário no banco

5. **Adicionar nova categoria** - Insere categoria maliciosa

6. **Deface homepage** - Modifica todas as categorias principais

## Vulnerabilidade

**URL vulnerável:** `http://www.bancocn.com/cat.php?id=1`

**Tipo:** SQL Injection (MySQL/MariaDB)

**Técnicas funcionais:**
- Error-based (FLOOR)
- Time-based (SLEEP)
- UNION query (3 colunas)

**Database:** `bancocn`

**Tabelas:**
- `users` (id, login, password)
- `categories` (id, title, txt)
- `pictures` (id, cat, img, title)
- `stats` (ip, count)

## Exemplo de Payload

```sql
-- UNION Injection
-1267 UNION ALL SELECT NULL,NULL,CONCAT(...)-- -

-- Error-based
1 AND (SELECT 4853 FROM(SELECT COUNT(*),CONCAT(0x7178787871,(SELECT (ELT(4853=4853,1))),0x7171627a71,FLOOR(RAND(0)*2))x FROM INFORMATION_SCHEMA.PLUGINS GROUP BY x)a)

-- Time-based
1 AND (SELECT 7689 FROM (SELECT(SLEEP(5)))eSPr)
```

## Notas Importantes

1. **Stacked Queries**: O script tenta usar stacked queries (`;`) para UPDATE/INSERT/DELETE. Isso pode não funcionar dependendo da configuração do PHP (mysql_query vs mysqli_multi_query).

2. **Verificação**: Algumas operações podem não retornar confirmação visual. Verifique manualmente acessando o site.

3. **Rate Limiting**: O script inclui delays entre requisições para evitar sobrecarga.

4. **Senhas**: As senhas são armazenadas como MD5 no banco. O script gera o hash automaticamente.

## Estrutura do Projeto

```
bancoCN/
├── test_banco_cn.py      # Script de teste/validação
├── exploit_banco_cn.py   # Script de exploração
├── BancoCNsql.txt        # Log do sqlmap original
└── README.md             # Este arquivo
```

## Troubleshooting

**Erro de conexão:**
- Verifique se o site está acessível
- Verifique sua conexão com a internet

**Modificações não aparecem:**
- Stacked queries podem não estar habilitadas
- Tente verificar diretamente no banco ou no site
- Algumas modificações podem precisar de refresh da página

**Timeout:**
- Aumente o timeout nas requisições
- Verifique se o site está respondendo

## Autor

Criado para fins educacionais - Lab Solyd.one


