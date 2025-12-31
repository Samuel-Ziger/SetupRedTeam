# Scripts de Exploração SQL Injection - BancoCN

Scripts automatizados para realizar ataques de SQL injection e exploração no site bancocn.com usando sqlmap.

## ⚠️ AVISO LEGAL

**ESTES SCRIPTS SÃO APENAS PARA FINS EDUCACIONAIS E TESTES DE SEGURANÇA AUTORIZADOS.**

O uso de sqlmap para atacar alvos sem consentimento prévio mútuo é ilegal. É responsabilidade do usuário final obedecer todas as leis locais, estaduais e federais aplicáveis. Os desenvolvedores não assumem nenhuma responsabilidade e não são responsáveis por qualquer uso indevido ou dano causado por estes programas.

## 📋 Pré-requisitos

- **sqlmap** instalado
  ```bash
  # Kali Linux / Debian
  sudo apt-get install sqlmap
  
  # Ou via pip
  pip install sqlmap
  ```

- **Python 3** (para o script Python)
  ```bash
  python3 --version
  ```

## 🚀 Uso

### Scripts Básicos (Apenas Leitura)

#### Script Bash
```bash
./exploit_bancocn.sh
```

#### Script Python
```bash
python3 exploit_bancocn.py
```

### Scripts Avançados (Modificação de Dados) ⚠️

**ATENÇÃO: Estes scripts MODIFICAM dados no banco de dados!**

#### Script Python Avançado
```bash
python3 exploit_avancado.py
```

#### Script Bash Avançado
```bash
./exploit_avancado.sh
```

Os scripts avançados realizam:
- ✅ Modificação de senhas de usuários
- ✅ Criação de novos usuários
- ✅ Alteração de conteúdo do site
- ✅ Tentativas de escrita de arquivos (webshells)
- ✅ Tentativas de leitura de arquivos do sistema
- ✅ Manipulação de estatísticas e logs

## 📝 O que os scripts fazem

### Scripts Básicos (`exploit_bancocn.*`)

Os scripts básicos automatizam as seguintes etapas (apenas leitura):

1. **Detecção de SQL Injection** - Identifica a vulnerabilidade no parâmetro `id`
2. **Listagem de Bancos de Dados** - Lista todos os bancos de dados disponíveis
3. **Listagem de Tabelas** - Lista todas as tabelas do banco `bancocn`
4. **Listagem de Colunas** - Lista as colunas das tabelas
5. **Dump de Dados** - Extrai dados das tabelas:
   - `users` (credenciais)
   - `pictures` (imagens)
   - `categories` (categorias)
   - `stats` (estatísticas)
6. **Informações do Sistema** - Coleta informações sobre o banco de dados
7. **SQL Shell Interativo** - Abre um shell SQL para queries personalizadas

### Scripts Avançados (`exploit_avancado.*`)

Os scripts avançados realizam exploração completa e modificação de dados:

#### Fase 1: Validação e Reconhecimento
- Detecção avançada de SQL Injection (nível 3, risco 2)
- Coleta completa de informações do sistema
- Mapeamento completo do banco de dados
- Backup de todas as tabelas antes de modificar

#### Fase 2: Exploração e Modificação
- **Modificação de credenciais**: Altera senha do admin
- **Criação de usuários**: Insere novos usuários no sistema
- **Modificação de conteúdo**: Altera textos das categorias
- **Manipulação de dados**: Modifica estatísticas e registros

#### Fase 3: Escalação de Privilégios
- Verificação de privilégios de escrita de arquivo
- Tentativas de escrita de webshells PHP
- Tentativas de leitura de arquivos do sistema (`/etc/passwd`, arquivos de configuração)
- Tentativas de execução de comandos do sistema

#### Fase 4: Persistência e Cobertura
- Criação de backdoors na tabela de usuários
- Limpeza de logs e rastros
- Verificação final das modificações

## 🔧 Configuração

Você pode modificar as variáveis no início dos scripts:

### Script Bash (`exploit_bancocn.sh`)
```bash
URL="http://www.bancocn.com/cat.php?id=1"
PARAM="id"
DB="bancocn"
TABLE_USERS="users"
TABLE_PICTURES="pictures"
```

### Script Python (`exploit_bancocn.py`)
```python
URL = "http://www.bancocn.com/cat.php?id=1"
PARAM = "id"
DB = "bancocn"
TABLES = ["users", "pictures", "categories", "stats"]
```

## 📊 Resultados

Os dados extraídos são salvos em:
```
~/.local/share/sqlmap/output/www.bancocn.com/
```

Estrutura de arquivos:
```
output/www.bancocn.com/
├── dump/
│   └── bancocn/
│       ├── users.csv
│       ├── pictures.csv
│       ├── categories.csv
│       └── stats.csv
└── log
```

## 🔍 Queries SQL Úteis

Quando o SQL shell interativo estiver aberto, você pode executar:

```sql
-- Informações do banco
SELECT @@version;
SELECT @@hostname;
SELECT USER();
SELECT DATABASE();

-- Listar tabelas
SELECT table_name FROM information_schema.tables WHERE table_schema='bancocn';

-- Listar colunas
SELECT column_name, data_type FROM information_schema.columns WHERE table_name='users';

-- Consultar dados
SELECT * FROM users;
SELECT * FROM pictures;
SELECT * FROM categories;
SELECT * FROM stats;

-- Informações de segurança
SELECT @@secure_file_priv;
SELECT @@datadir;
SELECT @@basedir;
SHOW GRANTS FOR CURRENT_USER();
```

## 🛠️ Troubleshooting

### sqlmap não encontrado
```bash
# Verificar instalação
which sqlmap

# Instalar se necessário
sudo apt-get install sqlmap
```

### Erro de permissão
```bash
chmod +x exploit_bancocn.sh exploit_bancocn.py
```

### Timeout ou conexão recusada
- Verifique se o site está acessível
- Verifique sua conexão com a internet
- O site pode ter implementado proteções WAF/IPS

## 📚 Referências

- [sqlmap Documentation](https://sqlmap.org/)
- [OWASP SQL Injection](https://owasp.org/www-community/attacks/SQL_Injection)

## ⚠️ Avisos Importantes

### Scripts Avançados

Os scripts `exploit_avancado.*` são **destrutivos** e irão:
- Modificar dados no banco de dados
- Alterar senhas de usuários
- Tentar escrever arquivos no servidor
- Tentar ler arquivos sensíveis do sistema

**NUNCA use estes scripts em sistemas sem autorização explícita!**

### Credenciais Padrão Criadas

Os scripts avançados criam/modificam as seguintes credenciais:
- **Admin modificado**: `admin` / `hacked123`
- **Novo usuário**: `hacker` / `pwned2024`

Altere essas credenciais no código se necessário.

## 📄 Licença

Este projeto é fornecido "como está", sem garantias de qualquer tipo.

