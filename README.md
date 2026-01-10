# Setup Red Team - Repositório Profissional de Pentest

![Setup Red Team](./setup.png)

![Version](https://img.shields.io/badge/version-2.1.0-blue)
![Tools](https://img.shields.io/badge/tools-90%2B-orange)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Kali%20Linux-lightgrey)
![License](https://img.shields.io/badge/license-Educational-yellow)

> ⚠️ **AVISO LEGAL:** Este repositório é destinado EXCLUSIVAMENTE para testes de penetração autorizados e pesquisa em segurança. Use apenas com autorização formal por escrito.

---

## 🎯 Visão Geral

Repositório profissional de scripts e ferramentas para configuração de ambientes de **Penetration Testing** e **Red Team Operations**, suportando Windows e Kali Linux.

**Estrutura organizada por propósito/função** - Todas as ferramentas agrupadas logicamente para facilitar navegação e escalabilidade.

### 📊 Estatísticas do Projeto

- 🛠️ **90+ ferramentas** organizadas por categoria
- 📁 **5 novas categorias** criadas (Mobile, Reverse Engineering, Static Analysis, GraphQL, API)
- 📚 **26 ferramentas de Recon** (Passive, Active, Cloud, OSINT)
- 🔓 **18 ferramentas de Exploitation Web** (Generic, GraphQL, API)
- 📱 **4 ferramentas Mobile Security** (Android, iOS, Messaging)
- 🔧 **6 ferramentas Reverse Engineering** (CTF, Debuggers, Frameworks)
- 🔍 **4 ferramentas Static Analysis** (Java, Ruby, PHP)

---

## 📚 Documentação

- 📖 **[Índice Completo](./INDEX.md)** - Navegação rápida por todo o repositório
- 📝 **[Changelog](./CHANGELOG.md)** - Histórico de atualizações
- ⚠️ **[Aviso Legal](./DISCLAIMER.md)** - Leia antes de usar
- 🔒 **[Política de Segurança](./SECURITY.md)** - Reporte de vulnerabilidades
- 🤝 **[Contribuindo](./CONTRIBUTING.md)** - Guia para contribuidores
- 🗺️ **[Roadmap](./ROADMAP.md)** - Direções futuras do projeto

---

## 🚀 Início Rápido

### Windows

```powershell
cd setup/windows
.\setup-attackbox.ps1
```

**Ou para Notebook 2 (AD/Lateral Movement):**
```powershell
.\setup-notebook2.ps1
```

📖 **Documentação completa:** [docs/setup/](./docs/setup/)

### Kali Linux

```bash
cd setup/kali
sudo ./setup-kali.sh
```

**Ou para Notebook 1 (Stealth Box):**
```bash
sudo ./setup-notebook1.sh
```

---

## 📁 Estrutura do Repositório

```
SetupRedTeam/
├── setup/              # Setup de ambientes
│   ├── kali/           # Scripts Kali Linux
│   └── windows/        # Scripts Windows
│
├── pentest/            # Pentest completo (organizado por propósito)
│   ├── recon/          # Reconhecimento
│   │   ├── passive/    # Recon passivo (subfinder, dnsgen, wayback)
│   │   ├── active/     # Recon ativo (VHostScan, EyeWitness, wafw00f)
│   │   ├── cloud/      # Cloud recon (prowler, aws-security-checks)
│   │   └── osint/      # OSINT (sherlock, awesome-osint, keyhacks)
│   │
│   ├── credentials/    # Credentials
│   │   ├── brute-force/# Brute force (bruteforce-lists, crowbar)
│   │   ├── spraying/   # Password spraying
│   │   ├── hashes/     # Hash tools (Name-That-Hash, Ciphey, pyWhat)
│   │   └── tokens/     # Token manipulation
│   │
│   ├── social-engineering/
│   ├── c2-rats/
│   │
│   ├── exploitation/   # Exploração
│   │   ├── network/    # Camada de rede (ssh, telnet, smtp, dns, wifi)
│   │   └── web/        # Camada de aplicação
│   │       ├── sql/    # SQL injection
│   │       ├── mysql/  # MySQL specific
│   │       ├── joomla/ # Joomla exploitation
│   │       ├── email/  # Email exploitation
│   │       ├── generic/# Generic web tools (wfuzz, Arjun, domdig, tplmap)
│   │       ├── graphql/# GraphQL security (clairvoyance, inql) ⭐ NOVO
│   │       └── api/    # API security tools ⭐ NOVO
│   │
│   ├── mobile-security/# Mobile Security ⭐ NOVO
│   │   ├── android/    # Android tools (apkleaks, andriller)
│   │   ├── ios/        # iOS tools (unc0ver)
│   │   └── messaging/  # Messaging apps (SlackPirate)
│   │
│   ├── reverse-engineering/ # Reverse Engineering ⭐ NOVO
│   │   ├── ctf/        # CTF tools (katana, ctf-katana, pwntools)
│   │   ├── debuggers/  # Debuggers (dnSpy, Sourcetrail)
│   │   └── frameworks/ # Frameworks (pwntools)
│   │
│   ├── static-analysis/# Static Analysis ⭐ NOVO
│   │   ├── java/       # Java (find-sec-bugs)
│   │   ├── ruby/       # Ruby (brakeman)
│   │   └── php/        # PHP (phan, php-exploit-scripts)
│   │
│   ├── malware-analysis/
│   ├── ddos/
│   ├── privacy-anonymity/
│   ├── ai-security/
│   └── tools/          # Utilitários diversos
│
├── retest/             # Retestes automatizados
├── output/             # Output padronizado (recon, exploits, creds, screenshots, reports)
├── lib/                # Bibliotecas reutilizáveis
├── docs/               # Documentação centralizada
│   └── references/     # Referências e recursos ⭐ NOVO
└── legacy/             # Código depreciado
```

📖 **Estrutura detalhada:** [ESTRUTURA_FINAL.md](./ESTRUTURA_FINAL.md)

---

## 🛠️ Principais Funcionalidades

### 🆕 Novidades na Versão 2.1.0

- ✅ **90+ novas ferramentas organizadas** da pasta `NovasFerramentas/`
- ✅ **5 novas categorias principais:**
  - Mobile Security (Android, iOS, Messaging)
  - Reverse Engineering (CTF, Debuggers, Frameworks)
  - Static Analysis (Java, Ruby, PHP)
  - GraphQL Security Tools
  - API Security Tools
- ✅ **26 ferramentas de Recon** organizadas em 4 subcategorias
- ✅ **18 ferramentas de Exploitation Web** incluindo GraphQL e API
- ✅ **Documentação completa** com READMEs nas novas categorias

### Setup de Ambientes
- ✅ Setup automatizado para Windows e Kali Linux
- ✅ Configuração de ferramentas essenciais
- ✅ Scripts de bloqueio/desbloqueio (ambientes controlados)

### Pentest Profissional
- ✅ Scripts de pentest completo (v4.0)
- ✅ **90+ ferramentas organizadas** por propósito/função
- ✅ Reconhecimento subcategorizado (passive, active, cloud, osint)
  - Passive: subfinder, dnsgen, wayback, urlhunter
  - Active: VHostScan, EyeWitness, wafw00f, eyeballer
  - Cloud: prowler, aws-security-checks
  - OSINT: sherlock, awesome-osint, keyhacks
- ✅ Credentials organizados por técnica
  - Hashes: Name-That-Hash, Search-That-Hash, Ciphey, pyWhat
  - Brute-force: bruteforce-lists, crowbar
- ✅ Exploitation separado por camada (network vs web)
  - Web Generic: wfuzz, Arjun, domdig, tplmap, fuxploider
  - **GraphQL:** clairvoyance, inql ⭐ NOVO
  - **API:** public-apis ⭐ NOVO
- ✅ **Mobile Security** (Android, iOS, Messaging) ⭐ NOVO
  - Android: apkleaks, andriller
  - iOS: unc0ver
- ✅ **Reverse Engineering** (CTF, Debuggers, Frameworks) ⭐ NOVO
  - CTF: katana, ctf-katana, pwntools
  - Debuggers: dnSpy, Sourcetrail
- ✅ **Static Analysis** (Java, Ruby, PHP) ⭐ NOVO
  - Java: find-sec-bugs
  - Ruby: brakeman
  - PHP: phan, php-exploit-scripts
- ✅ Social engineering, C2/RATs, malware analysis

### Retestes Automatizados
- ✅ Scripts de reteste para múltiplos alvos
- ✅ Validação de correções de vulnerabilidades
- ✅ Relatórios automatizados

### Bibliotecas Reutilizáveis
- ✅ OPSEC (segurança operacional)
- ✅ Backup automatizado
- ✅ Geração de relatórios
- ✅ Verificação de recursos

---

## ⚠️ Avisos Importantes

- ❌ **NÃO use sem autorização expressa**
- ✅ **Use apenas em ambientes controlados**
- 🔒 **Respeite leis locais e internacionais**
- 📋 **Leia [DISCLAIMER.md](./DISCLAIMER.md) antes de usar**

---

## 🔥 Ferramentas Destaque (Novas)

### Reconhecimento
- **subfinder** - Enumeração passiva de subdomínios (`recon/passive/subfinder/`)
- **prowler** - Cloud security scanner AWS/GCP/Azure (`recon/cloud/prowler/`)
- **sherlock** - Username enumeration em redes sociais (`recon/osint/sherlock/`)
- **VHostScan** - Virtual host scanning (`recon/active/VHostScan/`)
- **EyeWitness** - Screenshots de websites (`recon/active/EyeWitness/`)

### Exploitation Web
- **wfuzz** - Web fuzzing (`exploitation/web/generic/wfuzz/`)
- **Arjun** - HTTP parameter discovery (`exploitation/web/generic/Arjun/`)
- **domdig** - DOM XSS scanner (`exploitation/web/generic/domdig/`)
- **tplmap** - Template injection exploitation (`exploitation/web/generic/tplmap/`)
- **clairvoyance** - GraphQL schema extraction (`exploitation/web/graphql/clairvoyance/`) ⭐ NOVO

### Mobile Security
- **apkleaks** - Análise de APK para secrets (`mobile-security/android/apkleaks/`) ⭐ NOVO
- **andriller** - Android forensics (`mobile-security/android/andriller/`) ⭐ NOVO

### Reverse Engineering
- **pwntools** - CTF framework (`reverse-engineering/frameworks/pwntools/`) ⭐ NOVO
- **dnSpy** - .NET debugger/editor (`reverse-engineering/debuggers/dnspy/`) ⭐ NOVO
- **katana** - CTF automation tool (`reverse-engineering/ctf/katana/`) ⭐ NOVO

### Credentials
- **Name-That-Hash** - Identificação de tipos de hash (`credentials/hashes/name-that-hash/`)
- **Ciphey** - Descriptografia/decodificação automática (`credentials/hashes/ciphey/`)
- **pyWhat** - Identificação de tipos de dados (`credentials/hashes/pywhat/`)

### Static Analysis
- **find-sec-bugs** - Static analysis para Java (`static-analysis/java/find-sec-bugs/`) ⭐ NOVO
- **brakeman** - Static analysis para Ruby (`static-analysis/ruby/brakeman/`) ⭐ NOVO
- **phan** - Static analysis para PHP (`static-analysis/php/phan/`) ⭐ NOVO

📖 **Ver todas as ferramentas:** [Mapeamento Completo](./MAPEAMENTO_NOVAS_FERRAMENTAS.md)

---

## 📖 Documentação por Categoria

### Setup
- [Setup Kali Linux](./docs/setup/executar-setup-kali.md)
- [Setup Windows](./docs/setup/) (em desenvolvimento)

### Pentest
- [Guia Completo de Pentest](./docs/pentest/guia-completo.md)
- [Quick Start](./docs/pentest/quick-start.md)
- [Checklist Pentest](./pentest/CHECKLIST_PENTEST.md)
- [Mobile Security](./pentest/mobile-security/README.md) ⭐ NOVO
- [Reverse Engineering](./pentest/reverse-engineering/README.md) ⭐ NOVO
- [Static Analysis](./pentest/static-analysis/README.md) ⭐ NOVO
- [GraphQL Security](./pentest/exploitation/web/graphql/README.md) ⭐ NOVO

### Retest
- [Retestes Automatizados](./retest/README_PENTEST.md)
- [Múltiplos Alvos](./retest/README_TODOS_ALVOS.md)

### OPSEC
- [Checklist OPSEC](./docs/opsec/opsec-checklist.md)

### Guias
- [Estratégia de Backup](./docs/guides/backup-strategy.md)
- [Guia de Upgrade](./docs/guides/upgrade-guide.md)
- [Notebook 2 Completo](./docs/guides/notebook2-completo.md)

---

## 🎯 Organização por Propósito

**Diferencial:** Todas as ferramentas são agrupadas por **propósito/função**, não por origem.

**Exemplos:**
- `pentest/recon/osint/` - Contém sherlock, awesome-osint (externos) + scripts autorais
- `pentest/recon/passive/` - Contém subfinder, dnsgen, wayback (externos) + scripts autorais
- `pentest/social-engineering/` - Contém zphisher (externo) + rubber-ducky (autoral)
- `pentest/exploitation/web/generic/` - Contém wfuzz, Arjun, domdig, tplmap (externos) + scripts autorais
- `pentest/exploitation/web/graphql/` - Contém clairvoyance, inql (externos) ⭐ NOVO
- `pentest/mobile-security/android/` - Contém apkleaks, andriller (externos) ⭐ NOVO
- `pentest/reverse-engineering/ctf/` - Contém katana, ctf-katana, pwntools (externos) ⭐ NOVO

**Benefícios:**
- ✅ Facilita encontrar ferramentas por função
- ✅ Escala melhor quando o repositório cresce (90+ ferramentas organizadas)
- ✅ Navegação intuitiva para novos usuários
- ✅ Facilita automação
- ✅ Separação clara por camada/tecnologia (network vs web, mobile vs desktop)

---

## 📊 Output Padronizado

Todos os resultados são salvos em `output/` de forma padronizada:

```
output/
├── recon/          # Resultados de reconhecimento
├── exploits/       # Resultados de exploração
├── creds/          # Credenciais encontradas
├── screenshots/    # Screenshots/evidências
└── reports/        # Relatórios finais
```

📖 **Mais informações:** [output/README.md](./output/README.md)

---

## 🔧 Pré-requisitos

### Windows
- Windows 10/11 (versão 1903+)
- Permissões de Administrador
- Conexão com internet
- 20GB+ de espaço livre

### Kali Linux
- Kali Linux 2020.1+
- Acesso root
- Conexão com internet
- 30GB+ de espaço livre

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](./CONTRIBUTING.md) para diretrizes.

---

## 📄 Licença

Este projeto é fornecido "como está", sem garantias. Use por sua conta e risco.

**O autor não se responsabiliza por uso indevido destes scripts.**

---

## 🔗 Links Úteis

- [Índice Completo](./INDEX.md)
- [Changelog](./CHANGELOG.md)
- [Roadmap](./ROADMAP.md)
- [Estrutura Final](./ESTRUTURA_FINAL.md)
- [Mapeamento NovasFerramentas](./MAPEAMENTO_NOVAS_FERRAMENTAS.md) - Organização completa das 90+ ferramentas
- [Organização Realizada](./ORGANIZACAO_REALIZADA.md) - Resumo da organização

---

## 👤 Autor

**Samuel Ziger**
- GitHub: [@Samuel-Ziger](https://github.com/Samuel-Ziger)

---

**Última atualização:** 10 de Janeiro de 2026  
**Versão:** 2.1.0 (Organização NovasFerramentas - 90+ ferramentas)
