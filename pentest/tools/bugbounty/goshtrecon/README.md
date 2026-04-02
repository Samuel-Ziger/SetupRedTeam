# GHOSTRECON

Framework **passivo** de OSINT / recon para bug bounty: subdomínios (crt.sh + opcional **VirusTotal**), **enriquecimento DNS** (MX/TXT, SPF/DMARC e TXT de verificação), HTTP probing com **análise de cabeçalhos de segurança** e **inspeção TLS** (certificado), descoberta **`.well-known`** (`security.txt`, **OIDC** `openid-configuration`), Wayback (CDX) + **Common Crawl**, **robots.txt / sitemap.xml** nos hosts vivos, **RDAP** (registo de domínio), extração de parâmetros, análise heurística de JS, detecção de possíveis secrets, geração de Google Dorks (URLs de busca + abertura em abas), **opcionalmente descoberta de URLs via Google Programmable Search (Custom Search JSON API)**. Em **Kali** (modo ativo opcional): **subfinder** / **amass** (enum de subdomínios), **whois**, **wpscan** (só se o passivo indicar WordPress), **nuclei** (passagem geral + segunda passagem com `-tags xss` e `-tags sqli` sobre URLs com query vindas do corpus Wayback/Common Crawl), além de nmap/ffuf/searchsploit. Gravação em **Supabase (Postgres)** ou **SQLite** (`data/bugbounty.db`: histórico de runs + corpus **deduplicado** por alvo), **comparação entre runs** (API), **webhook** e **rate limit** opcionais na API, correlação e sugestões de vetores. Interface web dark/red team em `index.html`.

## Requisitos

- Node.js **18+** (usa `fetch` nativo)

## Execução

```bash
npm install
npm start
npm test   # testes mínimos (ex.: cabeçalhos de segurança)
```

Abra **http://127.0.0.1:3847** (porta alterável com `PORT` no `.env` ou na linha de comando, por exemplo `PORT=3000 npm start` em Linux/macOS; no PowerShell: `$env:PORT=3847; npm start`).

> A UI chama `POST /api/recon/stream`. Abrir só o arquivo `index.html` no disco **não** executa o pipeline — é necessário o servidor.

## Variáveis de ambiente

| Variável | Uso |
|----------|-----|
| `PORT` | Porta HTTP (padrão `3847`) |
| `GITHUB_TOKEN` | Token fine-grained ou classic para aumentar limite da [GitHub Code Search API](https://docs.github.com/en/rest/search/search?apiVersion=2022-11-28#search-code) |
| `GOOGLE_CSE_KEY` | Chave da [Custom Search JSON API](https://developers.google.com/custom-search/v1/overview) |
| `GOOGLE_CSE_CX` | ID do motor (**cx**) em [Programmable Search Engine](https://programmablesearchengine.google.com/) — podes ativar “Search the entire web” |
| `GHOSTRECON_DB` | Caminho opcional do SQLite (padrão `data/bugbounty.db`) — ignorado se `DATABASE_URL` ou API Supabase estiver definida |
| `DATABASE_URL` | **Postgres direto** (string do dashboard: *Connect → Node.js → Direct* ou **Session pooler** se estiveres em rede só IPv4). Tem prioridade sobre `SUPABASE_URL` + chave. |
| `SUPABASE_URL` | URL do projeto para cliente REST (ex. `https://xxxx.supabase.co`) — usado só se **não** existir `DATABASE_URL` |
| `SUPABASE_ANON_KEY` | Chave **anon** (JWT) do dashboard — uso típico no servidor com `.env` (não commits) |
| `SUPABASE_PUBLISHABLE_KEY` | Alternativa à anon, se usares a chave publishable do projeto |
| `SUPABASE_SERVICE_ROLE_KEY` | Opcional: no **servidor** apenas; ignora RLS — preferível em produção com políticas restritas |
| `VIRUSTOTAL_API_KEY` | Subdomínios via API (módulo **virustotal** na UI) |
| `GHOSTRECON_WEBHOOK_URL` | `POST` JSON após recon gravado (`runId`, `target`, `stats`, …) |
| `GHOSTRECON_RL_MAX` | Máx. recons por IP por janela (predef. `12`; `0` = desligado) |
| `GHOSTRECON_RL_WINDOW_MS` | Janela do rate limit em ms (predef. `60000`) |
| `GHOSTRECON_CC_CDX_API` | URL do índice CDX Common Crawl (opcional; senão usa `collinfo.json`) |
| `GHOSTRECON_WPSCAN_DETECTION_MODE` | Modo do [WPScan](https://github.com/wpscannerteam/wpscan) em JSON (predef. `mixed`) — só no **Modo Kali** e quando o passivo indicar WordPress |
| `GHOSTRECON_WPSCAN_TIMEOUT_MS` | Timeout do `wpscan` em ms (predef. `240000`) |
| `GHOSTRECON_WHOIS_SUBDOMAINS_MAX` | Quantidade extra de subdomínios (além do domínio raiz) a consultar com `whois` no Kali (senão usa `whoisSubdomainsMax` em `server/config.js`) |
| `GHOSTRECON_SUBFINDER_TIMEOUT_MS` | Timeout do `subfinder` em ms (predef. `180000`) — módulo **subfinder** + **Modo Kali** |
| `GHOSTRECON_AMASS_TIMEOUT_MS` | Timeout do `amass enum -passive` em ms (predef. `240000`) — módulo **amass** + **Modo Kali** |

### Supabase

#### Opção A — CLI (migrações versionadas, recomendado)

1. **Login** (uma vez): `npx supabase login` — abre o browser para gerar o token.
2. **Ligar o projeto** (na pasta do repo):
   ```bash
   npm run db:link -- --password "A_TUA_DATABASE_PASSWORD"
   ```
   A password está em **Project Settings → Database → Database password** no dashboard.  
   Comando equivalente: `npx supabase link --project-ref lchttisqazjuapczstkm --password "..."`  
   (`npm run db:link` já inclui o `project-ref` deste projeto.)
3. **Aplicar migrações** no remoto:
   ```bash
   npm run db:push
   ```
   A migração inicial **GosthRecon** está em `supabase/migrations/20250325181000_gosthrecon_initial.sql`.
4. **Nova migração** (quando alterares o schema):
   ```bash
   npm run db:migration:new -- nome_descritivo
   ```
   (Se o comando `migration new` bloquear no Windows, cria manualmente um ficheiro `supabase/migrations/YYYYMMDDHHMMSS_nome.sql`.)

5. Copia `.env.example` para **`.env`**. Para o servidor Node, o mais simples é **`DATABASE_URL`** (pacote `postgres`, ver `server/modules/db-pg.js`). Se a password tiver caracteres especiais (`@`, `#`, etc.), usa `encodeURIComponent` na password dentro da URI. Em rede **só IPv4**, o Supabase indica **Session pooler** em vez de “Direct connection”. Alternativa sem `DATABASE_URL`: `SUPABASE_URL` + `SUPABASE_ANON_KEY`. Depois `npm start`.

#### Opção B — SQL Editor (sem CLI)

No dashboard: **SQL** → **New query**. Copia **todo** o ficheiro **`supabase/COPIAR_PARA_SQL_EDITOR.sql`** (a primeira linha deve ser `create table`). **Não** colas o caminho do ficheiro como texto na query.

**Segurança:** não commits chaves; o schema inclui políticas RLS permissivas para `anon` (ok se a chave só existir no servidor). Para produção, prefere `SUPABASE_SERVICE_ROLE_KEY` no Node e políticas mais restritas.

### Google Hacking (URLs reais)

Sem API, a ferramenta só **monta as queries** e pode **abrir o Google** nas abas (como antes). **Não** faz scraping da página de resultados (instável e contra os ToS).

Com **Google CSE** ativado na sidebar e variáveis `GOOGLE_CSE_KEY` + `GOOGLE_CSE_CX`, o servidor executa cada dork (até `googleCseMaxQueries` por run, ver `server/config.js`) na API oficial e adiciona **endpoints** reais cujo host coincide com o alvo. A quota gratuita é tipicamente **100 queries/dia**.

### SQLite (`bugbounty.db`)

Ficheiro predefinido: **`data/bugbounty.db`**. Tabelas:

- **`runs` + `findings`** — cada execução completa (histórico auditável, como antes).
- **`bounty_intel`** — corpus **único por alvo** (dedupe por hash de tipo + valor + URL). Novos recons **acrescentam** só o que ainda não existia; entradas repetidas **atualizam** `last_seen` e `last_run_id`. A UI mostra um aviso abaixo do histórico com quantos artefactos novos foram guardados.

API: `GET /api/intel/:target` — lista o corpus deduplicado para o domínio.

> Se tinhas `data/ghostrecon.db`, o novo ficheiro é outro; usa `GHOSTRECON_DB=.../ghostrecon.db` para continuar na base antiga, ou copia/mescla manualmente.

### Módulos OSINT adicionais (UI)

Na secção **OSINT Sources** podes ativar:

- **DNS TXT/MX (SPF/DMARC)** (`dns_enrichment`) — MX, SPF, DMARC (`_dmarc.`), TXT de verificação comuns.
- **`.well-known/security.txt`** (`wellknown_security_txt`) — GET com concorrência limitada nos origins vivos.
- **`.well-known/openid-configuration`** (`wellknown_openid`) — descoberta OIDC; endpoints aparecem como `finding` tipo `endpoint`.

Estes blocos usam limites em `server/config.js` (timeouts, concorrência, tamanhos).

### Modo Kali (scan ativo — opcional)

Em **Kali Linux**, com `nmap` no PATH, a UI permite **Modo Kali**. O recon **passivo e a enumeração habitual (crt.sh, etc.) continuam a correr primeiro**; depois, se as ferramentas existirem no `PATH`, o servidor pode executar:

**Enumeração de subdomínios (complementar ao crt.sh/VT)** — marcar na UI **Subfinder (Kali)** e/ou **Amass (Kali)**; só efeito com **Modo Kali** ligado. Os hostnames obtidos são mesclados com a lista atual, resolvidos por DNS e seguem o pipeline (probing, etc.). Implementação: `server/modules/kali-subdomain-tools.js` (por defeito `subfinder -d … -silent -all`; `amass enum -passive -d …`).

**Após a fase passiva / probing:**

- **nmap** — `-sV` por defeito (personalizável com `GHOSTRECON_NMAP_ARGS`, ex. `-A -Pn -T4` — mais lento)
- **whois** — no domínio raiz e numa amostra limitada de subdomínios vivos; `findings` tipo `whois` (campos principais: registrar, datas, NS, país quando existir no texto)
- **searchsploit** — consultas heurísticas a partir de produto/versão do nmap
- **ffuf** — wordlist comum, **apenas respostas HTTP 200**
- **nuclei** — templates contra URLs base (https/http do alvo e hosts com 80/443 no nmap)
- **nuclei (XSS / SQLi)** — após o nuclei geral, se existirem candidatos: o pipeline recolhe até ~40 URLs com parâmetros (`?key=value`) do **corpus Wayback + Common Crawl** (o mesmo `urlCorpus` dessa execução) e corre `nuclei` com `-tags xss` e `-tags sqli` sobre uma amostra (até ~30 URLs por passagem). Os achados aparecem como `finding` tipo **`xss`** ou **`sqli`** e a UI tem filtros **XSS** / **SQLI**. Para haver candidatos, activa normalmente **Wayback** e/ou **Common Crawl**; o resultado depende dos **templates Nuclei** instalados e actualizados no Kali.
- **wpscan** — só se `wpscan` estiver no PATH **e** o passivo tiver indicado WordPress (`tech`); output JSON é parseado para core, tema e plugins (`findings` tipo `wpscan`)

Requisitos típicos no Kali: `nmap`, `ffuf`, `nuclei`, `searchsploit`, `whois`, `wpscan` (opcional), `subfinder` / `amass` (opcional), wordlists em `/usr/share/seclists` ou `dirb`.

| Variável | Uso |
|----------|-----|
| `GHOSTRECON_FORCE_KALI` | `1` = tratar como Kali (testes em WSL/outra distro com ferramentas) |
| `GHOSTRECON_NMAP_ARGS` | Argumentos extra do nmap (substitui o padrão `-sV -Pn -T4 --host-timeout 180s`) |

Ver também a tabela de variáveis acima (`GHOSTRECON_WPSCAN_*`, `GHOSTRECON_WHOIS_SUBDOMAINS_MAX`, `GHOSTRECON_SUBFINDER_TIMEOUT_MS`, `GHOSTRECON_AMASS_TIMEOUT_MS`).

**Aviso:** isto é **recon/scan ativo**. Usa apenas em **alvos autorizados**.

## Estrutura do projeto

```
goshtrecon/
├── index.html          # Frontend (visual + consumo NDJSON)
├── package.json
├── .env.example
├── supabase/
│   ├── config.toml     # Config local da CLI
│   ├── migrations/                 # Migrações versionadas (`npm run db:push`)
│   └── COPIAR_PARA_SQL_EDITOR.sql  # DDL para colar no dashboard (sem duplicar caminho na query)
├── README.md
└── server/
    ├── index.js        # Express, rota de streaming, orquestração do pipeline
    ├── config.js       # Limites, User-Agent, regex de “interesting”
    └── modules/
        ├── dorks.js    # Templates de dorks (extensível)
        ├── subdomains.js
        ├── dns.js
        ├── probe.js
        ├── tech.js
        ├── wayback.js
        ├── params.js
        ├── js-analyzer.js
        ├── secrets.js
        ├── github.js
        ├── google-cse.js
        ├── kali-scan.js
        ├── kali-subdomain-tools.js  # subfinder / amass (Kali + módulos UI)
        ├── wpscan.js                 # WPScan JSON → findings (Kali)
        ├── dns-enrichment.js        # MX/TXT/SPF/DMARC
        ├── wellknown.js             # security.txt + openid-configuration
        ├── prioritization.js
        ├── cve-hints.js
        ├── db.js           # Fachada: Supabase se env definido, senão SQLite
        ├── db-sqlite.js
        ├── db-supabase.js   # Cliente REST (@supabase/supabase-js)
        ├── db-pg.js         # Postgres direto (DATABASE_URL + postgres)
        ├── db-common.js
        ├── scoring.js
        ├── correlation.js
        ├── intelligence.js
        ├── security-headers.js
        ├── tls-cert.js
        ├── robots-sitemap.js
        ├── commoncrawl.js
        ├── rdap.js
        ├── virustotal.js
        ├── db-compare.js
        └── webhook-notify.js
```

## Como expandir

### Novos dorks

Edite `server/modules/dorks.js`:

1. Adicione uma chave em `DORK_TEMPLATES` com array de funções `(domínioComAspasSeNecessário) => string de query`.
2. Se for categoria de alto risco, inclua o id do módulo no `Set` `HIGH_DORK`.
3. No `index.html`, adicione um checkbox com `class="mod"` e `value="seu_id"` igual à chave.

### Novas fontes passivas

Crie `server/modules/minha-fonte.js` exportando funções puras/async, importe em `server/index.js` e chame no `runPipeline` após emitir logs/`pipe` coerentes com a barra da UI.

### Limites e performance

Ajuste `server/config.js` (`waybackCollapseLimit`, `maxJsFetch`, `probeConcurrency`, `probeTimeoutMs`, `googleCseMaxQueries`, `googleCseDelayMs`, limites DNS enrichment, `/.well-known`, WHOIS no Kali, `htmlSurfaceMaxEndpoints`, Shodan, etc.).

### Modo Kali: wordlists e gating

- **ffuf** usa a primeira wordlist disponível nesta ordem: `/usr/share/seclists/Discovery/Web-Content/raft-small-words.txt`, `.../common.txt`, `/usr/share/wordlists/dirb/common.txt`. Sem ficheiro → o scan ffuf é ignorado com aviso no log.
- **Scans pesados XSS/SQLi** (nuclei com `-tags xss` / `-tags sqli`, e **dalfox**) só correm se existirem **sinais passivos**: parâmetros típicos nas URLs do corpus (`id`, `q`, `search`, etc.) ou findings `intel` «XSS/SQLi candidate param» gerados na fase de parâmetros.
- Variáveis úteis: `GHOSTRECON_NMAP_ARGS`, `GHOSTRECON_DALFOX_MAX_URLS`, `GHOSTRECON_DALFOX_TIMEOUT_MS`, `GHOSTRECON_WPSCAN_*`, `GHOSTRECON_FORCE_KALI`.

### Verify (evidence-guided)

A pipeline inclui fase **Verify** para classificar candidatos em **`confirmed`**, **`probable`** ou **`noisy`** nos tipos:

- `xss`
- `sqli`
- `open_redirect`
- `idor`
- `lfi` (path traversal / file inclusion)

Cada resultado leva evidência mínima (`requestSnippet`, `responseSnippet`, `status`, `timestamp`, `source`) e é incluído na priorização.

### Perfis de execução

Define no browser (localStorage) para ajustar cobertura/tempo:

```js
localStorage.setItem('ghostrecon_profile', 'quick');    // quick | standard | deep
```

- `quick`: menor cobertura, mais rápido
- `standard`: equilíbrio
- `deep`: maior cobertura (inclui fontes CLI como `gau` / `waybackurls` quando disponíveis)

### Fase 3 (tools)

- **Katana (crawl JS/headless)**: no perfil `deep`, tenta expandir corpus via `katana` (se presente no PATH).
- **Nuclei profiles**: variável `GHOSTRECON_NUCLEI_PROFILE` com opções:
  - `safe`
  - `bb-passive` (default)
  - `bb-active`
  - `high-impact`
- **Secret live/dead**: findings `secret` passam por validação HTTP e geram `secret_validation` (`live`, `probable`, `dead`).

### Auth opcional para programas privados

Para mapear superfície autenticada, podes definir no browser:

```js
localStorage.setItem('ghostrecon_auth_json', JSON.stringify({
  headers: { Authorization: 'Bearer <TOKEN>' },
  cookie: 'session=<COOKIE>'
}));
```

A UI envia isso em `auth` no `POST /api/recon/stream`, usado em probe/verify.

### Shodan (passivo)

Ativa o módulo `shodan` no recon e define `SHODAN_API_KEY`. O servidor resolve IPv4 para uma amostra de hosts vivos e consulta `api.shodan.io/shodan/host/{ip}` (limite em `server/config.js`).

### Webhook pós-recon

`GHOSTRECON_WEBHOOK_URL` recebe JSON com `stats`, `findingsByType`, `highCount` e, quando há run anterior do **mesmo** alvo na base, `runDiffSummary` (contagens e amostras de `added`/`removed`).

## API

- `GET /api/health` — status.
- `GET /api/capabilities` — deteta Kali + ferramentas (`nmap`, `ffuf`, `nuclei`, `searchsploit`, `wpscan`, `whois`, etc.).
- `GET /api/runs?limit=50` — lista recons gravados (metadados + stats).
- `GET /api/runs/:id` — recon completo com `findings`.
- `GET /api/runs/:newerId/diff/:baselineId` — compara dois runs do **mesmo** alvo: `added` / `removed` (fingerprints iguais ao corpus `bounty_intel`).
- `GET /api/intel/:domain` — artefactos únicos acumulados para o alvo (`bounty_intel`).
- `POST /api/recon/stream` — corpo JSON `{ "domain": "example.com", "exactMatch": false, "kaliMode": false, "modules": ["subdomains", "shodan", "dns_enrichment", ...] }`. Resposta **NDJSON**: `log`, `progress`, `pipe`, `stats`, `finding` (com `fingerprint` para dedupe/dismiss na UI), `dork`, `intel`, `done` (inclui `runId` se gravado), `error`. Rate limit opcional: `GHOSTRECON_RL_MAX` / `GHOSTRECON_RL_WINDOW_MS`. Os módulos `subfinder` e `amass` só complementam subdomínios quando `kaliMode` é `true` e a ferramenta existe no sistema.

## Docker

Na raiz do repo (expõe a porta `3847`; define `DATABASE_URL` ou SQLite montado em `data/`):

```bash
docker build -t ghostrecon .
docker run --rm -p 3847:3847 --env-file .env ghostrecon
```

## Exportação

O browser gera **JSON**, **Markdown** e **TXT** a partir dos achados acumulados na sessão (relatório inclui resumo de alto risco e URLs para reprodução quando existirem).

## Aviso legal

Use apenas em alvos que você tem **autorização** para testar. O projeto prioriza técnicas passivas; HTTP GET para probing e CDX ainda são solicitações ativas leves — respeite termos de uso dos serviços (Google, Archive.org, crt.sh, GitHub) e políticas do programa de bug bounty.
