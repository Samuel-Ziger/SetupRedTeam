# CTF Imobiliária – Resumo e flags

**Alvo:** 44.202.186.132 (atualizado; antes 100.55.88.158)  
**Host no /etc/hosts:** `imobiliarians.solyd` → 44.202.186.132  
**URL base:** http://imobiliarians.solyd:8081/

---

## Flags encontradas (2 de 4)

### Flag 1 (você já tinha)
- **Onde:** Comentário HTML no final de `index.php`
- **Como:** `view-source:http://imobiliarians.solyd:8081/index.php` ou curl e ver o final do HTML
- **Flag:** `Solyd{virtual_hosts_are_a_thing_for_sure}`

### Flag 2
- **Onde:** Comentário na página `admin/home.php`
- **Como:** Acessar http://imobiliarians.solyd:8081/admin/home.php (o admin não exige login nesse cenário) e ver o código-fonte
- **Flag:** `Solyd{local_or_remote_brute_force?}`

---

## Onde procurar as outras 2 flags

### 1. Brute force no login (acesso.php)
A flag 2 fala em “local_or_remote_brute_force?”. O login está em:
- **URL:** http://imobiliarians.solyd:8081/acesso.php  
- **Campos:** `usuario`, `senha`, botão `entrar=entrar`  
- **Ideia:** Descobrir usuário/senha (ex.: com Hydra ou lista de senhas comuns) e, após logar, acessar `/control/` (redirect para `../index.php` quando não autenticado). Pode haver flag em alguma página após o login.

Exemplo Hydra:
```bash
hydra -l admin -P /usr/share/wordlists/rockyou.txt imobiliarians.solyd -s 8081 http-post-form "/acesso.php:usuario=^USER^&senha=^PASS^&entrar=entrar:F=incorretos"
# ou com -L para lista de usuários
```

### 2. Código do cadastro (cadastro.php)
- **URL:** http://imobiliarians.solyd:8081/cadastro.php  
- **Campo:** `code` (senha/código), botão `validar=validar`  
- **Ideia:** O “código de acesso” pode estar em comentário em alguma página, no rodapé, em nome de imóvel, ou ser um número/string de CTF. Vale procurar por “code”, “código” ou números no HTML/JS do site. Se achar o código e validar, pode aparecer outra flag ou redirecionamento útil.

### 3. Upload no admin (upload.php / uploadim.php)
- **URLs:** http://imobiliarians.solyd:8081/admin/upload.php e admin/uploadim.php  
- **Diretório listado:** http://imobiliarians.solyd:8081/admin/uploads/ (vazio por enquanto)  
- **Ideia:** Testar upload de arquivo (ex.: .php ou .phtml) e acesso em `/admin/uploads/arquivo.php`. Em alguns CTFs a flag está em comportamento do upload ou em arquivo já presente depois de explorar o upload.

### 4. SQL no admin (imovel.php / proposta.php)
- **Observação:** Em `admin/imovel.php` e `admin/proposta.php` aparece erro MySQL:  
  `Syntax error or access violation: 1064 ... near '' at line 1`  
  Isso indica uso de SQL; não ficou claro se há parâmetro injetável (ex.: `id`). Vale testar com sqlmap ou manualmente com `id=1'`, `id=1 OR 1=1`, etc. Se houver SQLi, pode dar para extrair dados (ex.: tabela com flag).

### 5. Outras rotas
- **Gobuster** já encontrou: `/admin/`, `/control/`, `/assets/`, `index.php`.  
- **control/:** retorna 302 para `../index.php` sem sessão; após login pode haver páginas com flag.  
- Continuar varrendo com gobuster/ffuf em `/` e em `/admin/` (outras extensões ou wordlists) pode revelar arquivos como `.php.bak`, `flag.txt`, `config.php`, etc.

---

## Resumo rápido

| # | Flag | Local |
|---|------|--------|
| 1 | `Solyd{virtual_hosts_are_a_thing_for_sure}` | view-source de `index.php` |
| 2 | `Solyd{local_or_remote_brute_force?}` | view-source de `admin/home.php` |
| 3 | ? | Sugestão: login (brute force) + área `/control/` ou cadastro |
| 4 | ? | Sugestão: código do cadastro, upload admin ou SQLi no admin |

Se quiser, posso focar em um desses caminhos (por exemplo só brute force no login ou só cadastro/upload) e te passar comandos ou passos mais detalhados.

---

## Ataque no novo IP (44.202.186.132) – o que foi testado

- **Conectividade:** OK; mesmas páginas e flags 1 e 2.
- **Brute force (Hydra):** `admin` + top 500 rockyou (e outros usuários: consultor, imobiliaria, solyd, etc.) → 0 senha válida. Rodar com rockyou completo ou lista maior.
- **Cadastro (code):** Várias tentativas (imovelns, 1234, 8081, 2020, new_solyd, etc.) → nenhum redirect nem flag. O texto do cadastro diz que o código é enviado por e-mail (imovelns@imobiliarians.solyd). Em CTF o código pode estar em outro serviço (e-mail/DB) ou ser uma string específica do desafio.
- **SQLi:** Login (acesso.php) com `' OR '1'='1` → ainda retorna “incorretos”. admin/imovel.php e proposta.php mostram erro MySQL mas o “near ''” parece ser variável vazia interna, não GET id.
- **Descoberta:** Gobuster na raiz e em /control/ — mesma estrutura; nenhum arquivo novo encontrado.
- **Próximos passos sugeridos:** 1) Hydra com rockyou inteiro ou lista custom (ex.: palavras do site). 2) Se tiver acesso ao “e-mail” do desafio (serviço de mail do CTF), obter o código e usar no cadastro. 3) Explorar SQLi no admin com sqlmap (POST/GET) em todos os parâmetros.
