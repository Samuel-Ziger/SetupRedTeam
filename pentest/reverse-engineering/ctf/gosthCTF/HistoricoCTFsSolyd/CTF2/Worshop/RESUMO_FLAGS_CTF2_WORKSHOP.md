# CTF2 Workshop – Empreendedorismo em Foco (44.211.59.106)

## Resumo

- **Alvo:** http://44.211.59.106/
- **Usuário criado:** teste@gmail.com / senha: teste
- **Email do site:** empreendedorismoemfoco@company.com.br

---

## Flags encontradas (3 de 4)

### Flag 1 (você já tinha)
- **Onde:** No PDF baixado na página inicial (formulário “Baixar” e-book).
- **Como:** Baixar o PDF em “Baixe o e-book prévia do workshop” e ler (primeira flag).

### Flag 2
- **Flag:** `Solyd{4-digit-code-is-just-not-secure-enough}`
- **Onde:** Área restrita (após login na plataforma).
- **Como:**
  1. Fazer login em **Acesso** (acesso.php) com teste@gmail.com / teste.
  2. No menu, ir em **Área restrita** (admin/area.php).
  3. Informar o **código de acesso de 4 dígitos:** **0625** (descoberto por força bruta 0000–9999).
  4. Ser redirecionado para admin/restrita.php; a flag aparece na mensagem de sucesso.

### Flag 3
- **Flag:** `Solyd{f1ltters_f1llters__allow_source_read}`
- **Onde:** Conteúdo do arquivo `admin/list.php` (incluído via LFI).
- **Como:**
  1. Estar logado e já ter validado o código 0625 na área restrita (como na Flag 2).
  2. Explorar a **LFI** em:  
     `http://44.211.59.106/admin/restrita.php?input=php://filter/convert.base64-encode/resource=list.php`
  3. Decodificar o trecho em base64 da resposta; no código de `list.php` aparece a flag (e credenciais de BD: tabata / tabata#123).

---

## Onde procurar a 4ª flag

1. **Virtual host / email (company.com.br)**  
   No PDF há um “email estranho” com final **company.com.br**. Você comentou que colocou “esse final” no `/etc/hosts` e nada mudou. Vale testar o **domínio completo do email** no `/etc/hosts`, por exemplo:
   - `44.211.59.106  empreendedorismoemfoco.company.com.br`
   Depois acesse no navegador:
   - `http://empreendedorismoemfoco.company.com.br/`
   - `http://empreendedorismoemfoco.company.com.br/control/`
   Em alguns CTFs a 4ª flag só aparece quando o `Host` é exatamente o configurado no servidor.

2. **De novo o PDF**  
   Conferir se não há **outra flag** no mesmo PDF (outra página ou perto do email no final).

3. **Outros arquivos via LFI**  
   Com a mesma sessão (logado + código 0625), você pode tentar outros arquivos no parâmetro `input`, por exemplo:
   - `../control/GenericDAO.php`
   - Outros paths que apareçam em includes no código já lido.

---

## Resumo técnico

| # | Flag | Local |
|---|------|--------|
| 1 | (no PDF) | E-book prévia do workshop |
| 2 | `Solyd{4-digit-code-is-just-not-secure-enough}` | admin/area.php → código **0625** → restrita.php |
| 3 | `Solyd{f1ltters_f1llters__allow_source_read}` | LFI em restrita.php?input=.../list.php (base64) |
| 4 | ? | Virtual host (domínio do email) ou PDF/outros arquivos |

---

## Rotas úteis

- **Página inicial:** / index.php  
- **Cadastro:** index.php#cadastro (POST nome, login, senha, perfil)  
- **Login:** acesso.php (POST entrar, email, senha)  
- **Área logada:** admin/inicio.php, admin/material.php, admin/sobre.php, admin/tutorial.php, admin/area.php  
- **Área restrita (após código 0625):** admin/restrita.php (LFI em `?input=`)  
- **Logout:** control/logout.php  

Se encontrar a 4ª flag (por vhost ou no PDF), pode completar a tabela acima.
