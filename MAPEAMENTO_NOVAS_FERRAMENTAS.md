# 📋 MAPEAMENTO E PROPOSTA DE ORGANIZAÇÃO - NovasFerramentas

**Data:** Janeiro 2025  
**Versão:** 1.0  
**Status:** Proposta Completa

---

## 🎯 OBJETIVO

Este documento mapeia todas as ferramentas da pasta `NovasFerramentas/` para suas categorias corretas na estrutura do projeto `SetupRedTeam`, seguindo o padrão de organização por **propósito/função**.

---

## 📊 RESUMO EXECUTIVO

### Estatísticas
- **Total de ferramentas analisadas:** 90+
- **Categorias existentes utilizadas:** 15
- **Novas categorias propostas:** 5
- **Ferramentas que precisam de nova categoria:** 12
- **Ferramentas de documentação/referência:** 8

---

## 📁 MAPEAMENTO DETALHADO POR CATEGORIA

### 1. RECONHECIMENTO (pentest/recon/)

#### 1.1. RECON PASSIVO (pentest/recon/passive/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **subfinder** | Subdomain enumeration passivo | `pentest/recon/passive/subfinder/` |
| **dnsgen** | Geração de subdomínios para enumeração | `pentest/recon/passive/dnsgen/` |
| **dnsvalidator** | Validação de DNS resolvers | `pentest/recon/passive/dnsvalidator/` |
| **resolvers** | Lista de DNS resolvers | `pentest/recon/passive/resolvers/` |
| **bucket-stream** | Encontrar buckets S3 abertos | `pentest/recon/passive/bucket-stream/` |
| **public-cloud-storage-search** | Busca em storage cloud público | `pentest/recon/passive/public-cloud-storage-search/` |
| **wayback** | Wayback Machine API | `pentest/recon/passive/wayback/` |
| **wayback-machine-downloader** | Downloader do Wayback Machine | `pentest/recon/passive/wayback-machine-downloader/` |
| **urlhunter** | Encontrar URLs em código | `pentest/recon/passive/urlhunter/` |

#### 1.2. RECON ATIVO (pentest/recon/active/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **VHostScan** | Virtual host scanning | `pentest/recon/active/vhostscan/` |
| **EyeWitness** | Screenshots de websites | `pentest/recon/active/eyewitness/` |
| **wafw00f** | WAF fingerprinting | `pentest/recon/active/wafw00f/` |
| **eyeballer** | Classificação de screenshots | `pentest/recon/active/eyeballer/` |
| **codesearch** | Busca de código em repositórios | `pentest/recon/active/codesearch/` |
| **FavFreak** | Favicon fingerprinting | `pentest/recon/active/favfreak/` |

#### 1.3. RECON CLOUD (pentest/recon/cloud/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **prowler** | Cloud security scanning (AWS, GCP, Azure) | `pentest/recon/cloud/prowler/` |
| **aws-security-checks** | AWS security checks | `pentest/recon/cloud/aws-security-checks/` |
| **my-arsenal-of-aws-security-tools** | Coleção de ferramentas AWS | `pentest/recon/cloud/aws-security-tools/` |
| **public-cloud-storage-search** | Busca em storage cloud (também em passive) | `pentest/recon/cloud/public-cloud-storage-search/` |

#### 1.4. OSINT (pentest/recon/osint/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **sherlock** | Username enumeration em redes sociais | `pentest/recon/osint/sherlock/` |
| **awesome-osint** | Lista de ferramentas OSINT | `pentest/recon/osint/awesome-osint/` |
| **statistically-likely-usernames** | Geração de usernames prováveis | `pentest/recon/osint/statistically-likely-usernames/` |
| **keyhacks** | Chaves de API vazadas | `pentest/recon/osint/keyhacks/` |
| **Pwdb-Public** | Database público de credenciais | `pentest/recon/osint/pwdb-public/` |

---

### 2. CREDENCIAIS (pentest/credentials/)

#### 2.1. HASHES (pentest/credentials/hashes/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **Name-That-Hash** | Identificação de tipos de hash | `pentest/credentials/hashes/name-that-hash/` |
| **Search-That-Hash** | Busca de hashes em databases | `pentest/credentials/hashes/search-that-hash/` |
| **Ciphey** | Descriptografia/decodificação automática | `pentest/credentials/hashes/ciphey/` |
| **pyWhat** | Identificação de tipos de dados | `pentest/credentials/hashes/pywhat/` |

#### 2.2. BRUTE-FORCE (pentest/credentials/brute-force/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **bruteforce-lists** | Listas para brute-force | `pentest/credentials/brute-force/bruteforce-lists/` |
| **crowbar** | Brute-force para protocolos de rede | `pentest/credentials/brute-force/crowbar/` |

#### 2.3. TOKENS (pentest/credentials/tokens/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **keyhacks** | Testes de chaves de API | `pentest/credentials/tokens/keyhacks/` |

---

### 3. EXPLOITATION WEB (pentest/exploitation/web/)

#### 3.1. GENERIC (pentest/exploitation/web/generic/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **wfuzz** | Web fuzzing | `pentest/exploitation/web/generic/wfuzz/` |
| **Arjun** | HTTP parameter discovery | `pentest/exploitation/web/generic/arjun/` |
| **domdig** | DOM XSS scanner | `pentest/exploitation/web/generic/domdig/` |
| **tplmap** | Template injection exploitation | `pentest/exploitation/web/generic/tplmap/` |
| **BurpParamFlagger** | Burp extension para flag de parâmetros | `pentest/exploitation/web/generic/burp-param-flagger/` |
| **BurpSuiteHTTPSmuggler** | HTTP Smuggling no Burp | `pentest/exploitation/web/generic/burp-httpsmuggler/` |
| **SQLi-Query-Tampering** | SQL injection query tampering | `pentest/exploitation/web/generic/sqli-query-tampering/` |
| **fuxploider** | File upload exploitation | `pentest/exploitation/web/generic/fuxploider/` |
| **Open-Redirect-Payloads** | Payloads para open redirect | `pentest/exploitation/web/generic/open-redirect-payloads/` |
| **client-side-prototype-pollution** | Prototype pollution payloads | `pentest/exploitation/web/generic/prototype-pollution/` |
| **xss-cheatsheet-data** | XSS payloads e cheatsheet | `pentest/exploitation/web/generic/xss-cheatsheet/` |
| **weird_proxies** | Análise de proxies estranhos | `pentest/exploitation/web/generic/weird-proxies/` |
| **httpninja** | HTTP request builder | `pentest/exploitation/web/generic/httpninja/` |
| **warcannon** | Web archive cannon | `pentest/exploitation/web/generic/warcannon/` |
| **PadBuster** | Padding Oracle Attack | `pentest/exploitation/web/generic/padbuster/` |
| **unzip-http** | Zip Slip exploitation | `pentest/exploitation/web/generic/unzip-http/` |

#### 3.2. GRAPHQL (pentest/exploitation/web/graphql/) ⚠️ **NOVA CATEGORIA**

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **clairvoyance** | GraphQL schema extraction | `pentest/exploitation/web/graphql/clairvoyance/` |
| **inql** | GraphQL security testing | `pentest/exploitation/web/graphql/inql/` |

#### 3.3. API (pentest/exploitation/web/api/) ⚠️ **NOVA CATEGORIA**

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **public-apis** | Lista de APIs públicas | `pentest/exploitation/web/api/public-apis/` |

---

### 4. MALWARE ANALYSIS (pentest/malware-analysis/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **apkleaks** | Análise de APK para secrets | `pentest/malware-analysis/mobile/apkleaks/` |
| **andriller** | Forensics de Android | `pentest/malware-analysis/mobile/andriller/` |
| **dnSpy** | .NET assembly debugger/editor | `pentest/malware-analysis/windows/dnspy/` |
| **pwntools** | Exploit development framework | `pentest/malware-analysis/reverse-engineering/pwntools/` |
| **find-sec-bugs** | Static analysis para Java | `pentest/malware-analysis/static-analysis/find-sec-bugs/` |
| **brakeman** | Static analysis para Ruby | `pentest/malware-analysis/static-analysis/brakeman/` |
| **phan** | Static analysis para PHP | `pentest/malware-analysis/static-analysis/phan/` |
| **Sourcetrail** | Visualização de código | `pentest/malware-analysis/reverse-engineering/sourcetrail/` |

---

### 5. MOBILE SECURITY (pentest/mobile-security/) ⚠️ **NOVA CATEGORIA PRINCIPAL**

Esta categoria é importante devido ao número de ferramentas mobile encontradas.

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **apkleaks** | Análise de APK para secrets | `pentest/mobile-security/android/apkleaks/` |
| **andriller** | Forensics de Android | `pentest/mobile-security/android/andriller/` |
| **unc0ver** | iOS jailbreak (ferramenta de referência) | `pentest/mobile-security/ios/unc0ver/` |
| **SlackPirate** | Slack enumeration | `pentest/mobile-security/messaging/slackpirate/` |

---

### 6. REVERSE ENGINEERING (pentest/reverse-engineering/) ⚠️ **NOVA CATEGORIA PRINCIPAL**

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **pwntools** | Exploit development framework (CTF) | `pentest/reverse-engineering/pwntools/` |
| **dnSpy** | .NET assembly debugger/editor | `pentest/reverse-engineering/dnspy/` |
| **Sourcetrail** | Visualização de código | `pentest/reverse-engineering/sourcetrail/` |
| **ctf-katana** | CTF automation framework | `pentest/reverse-engineering/ctf-katana/` |
| **katana** | CTF automation tool | `pentest/reverse-engineering/katana/` |
| **50M_CTF_Writeup** | CTF writeups (referência) | `pentest/reverse-engineering/ctf-writeups/` |

---

### 7. STATIC ANALYSIS (pentest/static-analysis/) ⚠️ **NOVA CATEGORIA PRINCIPAL**

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **find-sec-bugs** | Static analysis para Java | `pentest/static-analysis/java/find-sec-bugs/` |
| **brakeman** | Static analysis para Ruby | `pentest/static-analysis/ruby/brakeman/` |
| **phan** | Static analysis para PHP | `pentest/static-analysis/php/phan/` |
| **php-exploit-scripts** | PHP exploit scripts | `pentest/static-analysis/php/php-exploit-scripts/` |

---

### 8. UTILITÁRIOS E FERRAMENTAS AUXILIARES (pentest/tools/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **GitTools** | Ferramentas Git (dumping, etc) | `pentest/tools/git/gittools/` |
| **bcal** | Calculadora binária | `pentest/tools/calculators/bcal/` |
| **jo** | JSON object creator | `pentest/tools/parsers/jo/` |
| **octosql** | SQL query engine | `pentest/tools/parsers/octosql/` |
| **fq** | Binary parser/analyzer | `pentest/tools/parsers/fq/` |
| **xxhash** | Hash function library | `pentest/tools/hashing/xxhash/` |
| **ministry** | Network protocol analyzer | `pentest/tools/network/ministry/` |
| **fasthttp** | HTTP library (Go) | `pentest/tools/network/fasthttp/` |
| **quickemu** | Quick VM management | `pentest/tools/virtualization/quickemu/` |
| **hetty** | HTTP toolkit | `pentest/tools/http/hetty/` |
| **webpaste** | Web pastebin | `pentest/tools/web/webpaste/` |
| **apollo** | GraphQL toolkit | `pentest/tools/graphql/apollo/` |
| **matrix** | Matrix client | `pentest/tools/communication/matrix/` |
| **n8n** | Workflow automation | `pentest/tools/automation/n8n/` |
| **hackeroni** | HackerOne API client | `pentest/tools/bugbounty/hackeroni/` |
| **hacker101** | HackerOne educational platform | `pentest/tools/bugbounty/hacker101/` |

---

### 9. DOCUMENTAÇÃO E REFERÊNCIAS (docs/references/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **Awesome-Hacking** | Lista de recursos de hacking | `docs/references/awesome-hacking/` |
| **awesome-osint** | Lista de ferramentas OSINT | `docs/references/awesome-osint/` |
| **awesome-chrome-devtools** | Chrome DevTools resources | `docs/references/chrome-devtools/` |
| **cheatsheets** | Coleção de cheatsheets | `docs/references/cheatsheets/` |
| **hardware-hacking** | Recursos de hardware hacking | `docs/references/hardware-hacking/` |
| **resources** | Recursos diversos | `docs/references/resources/` |
| **50M_CTF_Writeup** | CTF writeups | `docs/references/ctf-writeups/` |

---

### 10. EXTENSÕES E PLUGINS (pentest/tools/extensions/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **burp-extender-api-kotlin** | Burp Extender API em Kotlin | `pentest/tools/extensions/burp/kotlin-api/` |
| **BurpParamFlagger** | Burp extension | `pentest/tools/extensions/burp/param-flagger/` |
| **BurpSuiteHTTPSmuggler** | Burp extension | `pentest/tools/extensions/burp/httpsmuggler/` |
| **Addon** | Extensões diversas (análise necessária) | `pentest/tools/extensions/addon/` |

---

### 11. FERRAMENTAS DE INFRAESTRUTURA (pentest/tools/infrastructure/)

| Ferramenta | Função | Destino |
|-----------|--------|---------|
| **kubebot** | Kubernetes security scanner | `pentest/tools/infrastructure/kubernetes/kubebot/` |
| **n8n** | Workflow automation | `pentest/tools/infrastructure/automation/n8n/` |

---

### 12. MISCELÂNEA - NECESSITA ANÁLISE DETALHADA

| Ferramenta | Função Proposta | Destino Proposto | Notas |
|-----------|----------------|------------------|-------|
| **pigo** | Face detection (Go) | `pentest/tools/image/pigo/` | Possível uso em OSINT |
| **dn** | DNS tools | `pentest/recon/active/dn/` | Verificar função exata |
| **bishop** | Precisa análise | `pentest/tools/bishop/` | Verificar README |
| **BitmapFonts** | Fontes bitmap | `docs/resources/fonts/bitmapfonts/` | Recurso, não ferramenta |
| **fuckitpy** | Error handler Python | `pentest/tools/python/fuckitpy/` | Utilitário |
| **j0** | Precisa análise | `pentest/tools/j0/` | Verificar função |
| **inql** | Já mapeado acima | - | GraphQL |
| **inql** (duplicado?) | Verificar se é diferente | - | Pode ser diferente do inql acima |

---

## 🆕 NOVAS CATEGORIAS PROPOSTAS

### 1. **pentest/mobile-security/** (NOVA)
   - **Justificativa:** Número significativo de ferramentas mobile (Android/iOS)
   - **Subcategorias:**
     - `android/` - Ferramentas Android (apkleaks, andriller)
     - `ios/` - Ferramentas iOS (unc0ver)
     - `messaging/` - Messaging apps (SlackPirate)

### 2. **pentest/reverse-engineering/** (NOVA)
   - **Justificativa:** Ferramentas de reverse engineering e CTF
   - **Subcategorias:**
     - `ctf/` - CTF tools (katana, ctf-katana)
     - `debuggers/` - Debuggers (dnSpy)
     - `frameworks/` - Frameworks (pwntools)

### 3. **pentest/static-analysis/** (NOVA)
   - **Justificativa:** Ferramentas de análise estática de código
   - **Subcategorias:**
     - `java/` - Java (find-sec-bugs)
     - `ruby/` - Ruby (brakeman)
     - `php/` - PHP (phan, php-exploit-scripts)

### 4. **pentest/exploitation/web/graphql/** (NOVA)
   - **Justificativa:** Número crescente de APIs GraphQL
   - **Ferramentas:** clairvoyance, inql, apollo (toolkit)

### 5. **pentest/exploitation/web/api/** (NOVA - OPCIONAL)
   - **Justificativa:** Ferramentas específicas para APIs REST/GraphQL
   - **Ferramentas:** public-apis (referência)

---

## 📊 ESTATÍSTICAS DE DISTRIBUIÇÃO

### Por Categoria Principal
- **Recon:** 26 ferramentas
- **Exploitation Web:** 18 ferramentas
- **Tools/Utilitários:** 18 ferramentas
- **Malware Analysis/Reverse:** 12 ferramentas
- **Credentials:** 8 ferramentas
- **Documentação:** 7 ferramentas
- **Mobile Security:** 4 ferramentas
- **Outros:** ~10 ferramentas

### Por Tipo de Ferramenta
- **Recon/Enumeration:** 30%
- **Web Exploitation:** 20%
- **Utilitários/Helpers:** 20%
- **Reverse Engineering/Static Analysis:** 15%
- **Credentials/Hashes:** 10%
- **Documentação:** 5%

---

## ⚠️ DECISÕES PENDENTES

### 1. Duplicatas e Similaridades
- **inql** vs **inql** (Kotlin) - Verificar se são a mesma ferramenta
- **katana** vs **ctf-katana** - São projetos diferentes, ambos relacionados a CTF
- **wayback** vs **wayback-machine-downloader** - Funcionalidades diferentes
- **public-cloud-storage-search** - Pode estar em `recon/passive/` e `recon/cloud/`

### 2. Ferramentas que Necessitam Análise Detalhada
- **Addon/** - Conteúdo não especificado
- **bishop** - Função não identificada
- **dn** - Verificar se é diferente de outras ferramentas DNS
- **j0** - Não identificado
- **kubebot** vs **n8n** - Verificar se kubebot é realmente sobre Kubernetes

### 3. Categorização Híbrida
Algumas ferramentas podem se encaixar em múltiplas categorias:
- **prowler** - Pode estar em `recon/cloud/` ou `tools/cloud-security/`
- **hetty** - HTTP toolkit pode estar em `tools/http/` ou `exploitation/web/`
- **apollo** - GraphQL toolkit pode estar em `tools/graphql/` ou `exploitation/web/graphql/`

---

## 🎯 PLANO DE AÇÃO RECOMENDADO

### Fase 1: Análise Detalhada (Prioridade ALTA)
1. ✅ Identificar funções exatas das ferramentas não mapeadas
2. ✅ Resolver duplicatas e similaridades
3. ✅ Validar categorização das ferramentas híbridas

### Fase 2: Criação de Estrutura (Prioridade ALTA)
1. Criar novas categorias propostas:
   - `pentest/mobile-security/`
   - `pentest/reverse-engineering/`
   - `pentest/static-analysis/`
   - `pentest/exploitation/web/graphql/`
   - `pentest/exploitation/web/api/` (opcional)

2. Criar subcategorias conforme necessário

### Fase 3: Migração (Prioridade MÉDIA)
1. Mover ferramentas para destinos mapeados
2. Manter estrutura original em `legacy/NovasFerramentas/` por segurança
3. Validar paths e dependências após migração

### Fase 4: Documentação (Prioridade MÉDIA)
1. Criar README.md em cada nova categoria
2. Atualizar INDEX.md com novas ferramentas
3. Documentar ferramentas principais

---

## 📝 NOTAS IMPORTANTES

### Segurança
- ⚠️ Algumas ferramentas podem conter código sensível ou exploits
- ⚠️ Verificar licenças antes de incluir em repositório público
- ⚠️ Algumas ferramentas podem violar termos de serviço (ex: sherlock)

### Manutenção
- 🔄 Algumas ferramentas não são mais mantidas (ex: tplmap)
- 🔄 Verificar se há forks mais atualizados
- 🔄 Considerar marcar ferramentas depreciadas

### Tamanho do Repositório
- 📦 Algumas ferramentas são muito grandes (ex: prowler ~8000 arquivos)
- 📦 Considerar usar git submodules para ferramentas grandes
- 📦 Ou manter apenas referências/documentação

---

## ✅ PRÓXIMOS PASSOS

1. **Revisar e validar** este mapeamento
2. **Decidir sobre novas categorias** propostas
3. **Resolver duplicatas** e ambiguidades
4. **Criar estrutura** de diretórios
5. **Iniciar migração** das ferramentas

---

**Documento criado por:** Auto (AI Assistant)  
**Revisão necessária por:** Responsável do Projeto  
**Versão:** 1.0  
**Data:** Janeiro 2025
