# Setup Red Team - Repositório Profissional de Pentest

<p align="center">
  <img src="./setup.png" alt="Setup Red Team — repositório profissional de pentest" width="900" />
</p>

![Version](https://img.shields.io/badge/version-2.2.0-blue)
![Tools](https://img.shields.io/badge/tools-arsenal%20extenso-orange)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Kali%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-MIT%20%28original%29-blue)

> ⚠️ **AVISO LEGAL:** Este repositório é destinado EXCLUSIVAMENTE para testes de penetração autorizados e pesquisa em segurança. Use apenas com autorização formal por escrito.

---

## Visão geral

Repositório profissional de scripts e ferramentas para **Penetration Testing** e **Red Team**, com foco em ambientes **Windows** e **Kali Linux**. O conteúdo está organizado por **função** (recon, exploração, credenciais, CTF, etc.) dentro de `pentest/`, complementado por **setup** automatizado, **scripts legados** em `Kali/` e `ScrpitPentestSH/`, e documentação em `docs/`.

### O que o repositório contém (resumo)

- **`pentest/`** — núcleo do arsenal: exploração web (inclui GraphQL e API), credenciais, mobile, engenharia reversa, análise estática, ferramentas diversas em `tools/`, **recon** (`recon/passive`, `recon/osint`), pós-exploração em `exploitation/Pos Explotation/`, entre outras áreas.
- **`setup/`** — scripts de preparação de máquinas (Windows e Kali).
- **`Kali/`** e **`ScrpitPentestSH/`** — scripts e pacotes adicionais (ver também **[INDEX.md](./INDEX.md)**).
- **`docs/`** — guias, referências (cheatsheets, recursos), templates e OPSEC.
- **`retest/`** — retestes automatizados.
- **`output/`** — saída padronizada de trabalhos (recon, exploits, relatórios, etc.).
- **`wordlists/`** — wordlists para uso local.
- **`lib/`** — bibliotecas e utilitários reutilizáveis.
- **`legacy/`** — material deprecado ou histórico.

Muitas pastas sob `pentest/` são **clones completos** de projetos upstream (com dependências e submódulos). O tamanho total reflete isso; para contagens exatas de “ferramentas”, considere cada projeto de primeiro nível dentro de cada categoria.

---

## Documentação

| Recurso | Descrição |
|--------|-----------|
| **[INDEX.md](./INDEX.md)** | Índice de navegação (Kali, Windows, ScrpitPentestSH) |
| **[GUIA_CTF_FERRAMENTAS.md](./GUIA_CTF_FERRAMENTAS.md)** | Ferramentas úteis para CTF no repositório |
| **[AUDITORIA_COMPLETA.md](./AUDITORIA_COMPLETA.md)** | Auditoria / inventário do repositório |
| **[CHANGELOG.md](./CHANGELOG.md)** | Histórico de alterações |
| **[DISCLAIMER.md](./DISCLAIMER.md)** | Aviso legal |
| **[SECURITY.md](./SECURITY.md)** | Política de segurança e reporte |
| **[CONTRIBUTING.md](./CONTRIBUTING.md)** | Como contribuir |
| **[ROADMAP.md](./ROADMAP.md)** | Direções futuras |
| **[docs/setup/executar-setup-kali.md](./docs/setup/executar-setup-kali.md)** | Execução do setup Kali |
| **[docs/pentest/guia-completo.md](./docs/pentest/guia-completo.md)** | Guia de pentest |
| **[docs/pentest/quick-start.md](./docs/pentest/quick-start.md)** | Início rápido |
| **[pentest/CHECKLIST_PENTEST.md](./pentest/CHECKLIST_PENTEST.md)** | Checklist de pentest |
| **[output/README.md](./output/README.md)** | Convenções da pasta `output/` |

READMEs por categoria (quando aplicável): [mobile-security](./pentest/mobile-security/README.md), [reverse-engineering](./pentest/reverse-engineering/README.md), [static-analysis](./pentest/static-analysis/README.md), [GraphQL](./pentest/exploitation/web/graphql/README.md), [API](./pentest/exploitation/web/api/README.md).

---

## Início rápido

### Windows

```powershell
cd setup/windows
.\setup-attackbox.ps1
```

**Notebook 2 (AD / lateral movement):**

```powershell
.\setup-notebook2.ps1
```

Mais detalhes: [docs/setup/](./docs/setup/).

### Kali Linux

```bash
cd setup/kali
sudo ./setup-kali.sh
```

**Notebook 1 (Stealth Box):**

```bash
sudo ./setup-notebook1.sh
```

---

## Estrutura do repositório

Visão **alinhada ao estado atual do disco** (abril de 2026). Algumas ramificações do README antigo (ex.: `recon/active`, `recon/cloud`) são **slots lógicos** para futura organização; hoje, em `recon/`, existem sobretudo `passive/` e `osint/`.

```
SetupRedTeam/
├── setup/                    # Setup Windows / Kali
│   ├── kali/
│   └── windows/
├── Kali/                     # Scripts e ferramentas Kali (ver INDEX.md)
├── ScrpitPentestSH/          # Scripts shell de pentest / reteste
├── pentest/                  # Arsenal principal (por função)
│   ├── recon/
│   │   ├── passive/          # Ex.: redsubv3 (enumeração de subdomínios)
│   │   └── osint/            # Ex.: RedRecon (dorks / OSINT passivo)
│   ├── credentials/
│   │   ├── brute-force/
│   │   ├── spraying/
│   │   ├── hashes/           # ciphey, name-that-hash, pywhat, search-that-hash
│   │   └── tokens/
│   ├── exploitation/
│   │   ├── network/
│   │   ├── web/
│   │   │   ├── sql/ mysql/ joomla/ email/
│   │   │   ├── generic/      # wfuzz, Arjun, domdig, tplmap, redsmell, …
│   │   │   ├── graphql/      # clairvoyance, inql
│   │   │   └── api/          # public-apis, …
│   │   └── Pos Explotation/  # PEAS, enumeração Linux, wikis, …
│   ├── mobile-security/      # android, ios, messaging
│   ├── reverse-engineering/
│   │   ├── ctf/              # katana, ctf-katana, gosthCTF, writeups, …
│   │   ├── debuggers/
│   │   └── frameworks/       # pwntools, …
│   ├── static-analysis/      # java, ruby, php
│   ├── social-engineering/
│   ├── c2-rats/
│   ├── malware-analysis/
│   ├── ddos/
│   ├── privacy-anonymity/
│   ├── ai-security/
│   ├── tools/                # bugbounty, parsers, http, CTF, infra, …
│   ├── PainelAdmimPHP/       # Projeto local (nome da pasta no repo)
│   ├── CHECKLIST_PENTEST.md
│   └── …
├── docs/                     # Guias, OPSEC, referências, templates
│   ├── setup/
│   ├── pentest/
│   ├── opsec/
│   ├── guides/
│   └── references/
├── retest/
├── output/
├── wordlists/
├── lib/
├── legacy/
├── Pentests Privados/        # Pasta local (sensível); listada no .gitignore — não vai para o Git
├── .github/
├── README.md
├── INDEX.md
├── GUIA_CTF_FERRAMENTAS.md
├── AUDITORIA_COMPLETA.md
└── …
```

---

## Ferramentas em destaque (caminhos verificados em `pentest/`)

### Reconhecimento e OSINT

- **RedSub v3** — enumeração de subdomínios (Go): `pentest/recon/passive/redsubv3/`
- **RedRecon** — motor de dorks / recon passivo (Next.js; projeto em `RedRecon/RedRecon/`): `pentest/recon/osint/RedRecon/`
- **GHOSTRECON** — framework passivo de OSINT / bug bounty (Node, UI + API, SQLite/Supabase, modo Kali opcional): `pentest/tools/bugbounty/goshtrecon/`

### Web e exploração

- **RedSmell** — filtro de URLs/parâmetros por classe de vulnerabilidade (Go): `pentest/exploitation/web/generic/redsmell/`
- **wfuzz**, **Arjun**, **domdig**, **tplmap** — `pentest/exploitation/web/generic/`
- **clairvoyance**, **inql** — `pentest/exploitation/web/graphql/`
- **public-apis** — `pentest/exploitation/web/api/public-apis/`

### CTF e automação

- **GHOSTCTF** — consola web e API para pipeline CTF por IP e recon por domínio (Node); histórico local em `HistoricoCTFsSolyd/` **dentro do mesmo projeto**: `pentest/reverse-engineering/ctf/gosthCTF/`
- **katana**, **ctf-katana** — `pentest/reverse-engineering/ctf/`

### Mobile, RE, análise estática, credenciais

- **apkleaks**, **andriller** — `pentest/mobile-security/android/`
- **pwntools**, **dnSpy**, **Sourcetrail** — `pentest/reverse-engineering/`
- **find-sec-bugs**, **brakeman**, **phan** — `pentest/static-analysis/`
- **Name-That-Hash**, **Ciphey**, **pyWhat**, **Search-That-Hash** — `pentest/credentials/hashes/`

---

## Funcionalidades principais

### Setup de ambientes

- Scripts para Windows e Kali, incluindo variantes “notebook” quando aplicável.
- Documentação em `docs/setup/`.

### Pentest e arsenal

- Organização por **propósito** dentro de `pentest/` (rede vs web, credenciais, CTF, etc.).
- **Pós-exploração** agregada em `pentest/exploitation/Pos Explotation/` (ferramentas e notas).
- **Bug bounty / automação**: pasta `pentest/tools/bugbounty/` (inclui GHOSTRECON).

### Retestes

- Fluxos em `retest/`; ver READMEs nessa pasta para alvos e modos de execução.

### Bibliotecas e saída

- **`lib/`** — utilitários partilhados.
- **`output/`** — estrutura sugerida para artefactos (ver `output/README.md`).

---

## Output padronizado

Resultados típicos podem ser guardados em `output/`:

```
output/
├── recon/
├── exploits/
├── creds/
├── screenshots/
└── reports/
```

Detalhes: [output/README.md](./output/README.md).

---

## Pré-requisitos

### Windows

- Windows 10/11 (build recente recomendado)
- Permissões de administrador para scripts de setup
- Espaço em disco generoso (dezenas de GB, conforme clones instalados)

### Kali Linux

- Kali recente, acesso `root`/`sudo` para setup
- Espaço em disco generoso

---

## Contribuir

Ver [CONTRIBUTING.md](./CONTRIBUTING.md).

---

## Licença e responsabilidade

- **Licença do trabalho original (mantenedor):** [LICENSE](./LICENSE) (MIT), com o âmbito e excepções descritos no próprio ficheiro (ferramentas de terceiros mantêm as licenças nos respectivos subdiretórios).
- **Ferramentas incluídas:** cada projeto em `pentest/`, `Kali/`, etc. pode ter **a sua própria licença** (`LICENSE`, `COPYING`, …) na pasta correspondente.
- **Uso e responsabilidade:** o autor **não** se responsabiliza por uso indevido. Leia [DISCLAIMER.md](./DISCLAIMER.md).

---

## Links úteis no repositório

- [INDEX.md](./INDEX.md)
- [GUIA_CTF_FERRAMENTAS.md](./GUIA_CTF_FERRAMENTAS.md)
- [AUDITORIA_COMPLETA.md](./AUDITORIA_COMPLETA.md)
- [CHANGELOG.md](./CHANGELOG.md)
- [ROADMAP.md](./ROADMAP.md)

---

## Autor

**Samuel Ziger**  
GitHub: [@Samuel-Ziger](https://github.com/Samuel-Ziger)

---

**Última atualização:** 2 de abril de 2026  
**Versão do README:** 2.2.0 (estrutura `pentest/recon`, ferramentas integradas, links e árvore sincronizados com o repositório)
