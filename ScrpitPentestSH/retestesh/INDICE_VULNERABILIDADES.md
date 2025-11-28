# 📊 Índice de Vulnerabilidades por Alvo

## Resumo Executivo

Este documento apresenta um índice consolidado de todas as vulnerabilidades identificadas nos pentests, organizadas por alvo e nível de criticidade.

---

## 🎯 adivisao.com.br

**IP**: Cloudflare  
**Status**: Múltiplas vulnerabilidades ALTAS e CRÍTICAS

### Vulnerabilidades Identificadas:

| # | Vulnerabilidade | Criticidade | Status |
|---|----------------|-------------|---------|
| 1 | Exposição de Tokens/Chaves no Front-end | 🔴 ALTA | Pendente |
| 2 | Enumeração de Usuários via Endpoint Elasticsearch | 🔴 ALTA | Pendente |
| 3 | CORS Inconsistente/Permissivo | 🔴 ALTA → MÉDIA | Pendente |
| 4 | Cookie de Sessão sem HttpOnly | 🔴 ALTA → MÉDIA | Pendente |
| 5 | Endpoints Internos Elasticsearch Expostos | 🟡 MÉDIA | Pendente |
| 6 | CSP Apenas em Report-Only | 🟡 MÉDIA | Pendente |
| 7 | Rate Limiting Parcial | 🟡 MÉDIA | Pendente |
| 8 | Exposição de Infra e Headers Sensíveis | 🟡 BAIXA → MÉDIA | Pendente |
| 9 | Endpoint /fileupload Acessível | 🔴 CRÍTICA | Pendente |
| 10 | Portas Administrativas Expostas (2052, 2053, etc.) | 🔴 ALTA | Pendente |

**Script de Reteste**: `reteste_adivisao.sh`

---

## 🎯 divisaodeelite.com.br

**IP**: Cloudflare (Bubble.io)  
**Status**: Vulnerabilidades CRÍTICAS - Plugin malicioso detectado

### Vulnerabilidades Identificadas:

| # | Vulnerabilidade | Criticidade | Status |
|---|----------------|-------------|---------|
| 1 | Token bubble_plp_token Exposto no window | 🔴 ALTA | Pendente |
| 2 | Endpoint /version-test/api/1.1/init/data sem Auth | 🔴 ALTA | Pendente |
| 3 | Plugin Enviando Dados para railway.app | 🔴 CRÍTICA | Pendente |
| 4 | Cookies sem HttpOnly, Secure, SameSite | 🔴 ALTA | Pendente |
| 5 | Scripts de Terceiros sem SRI | 🔴 ALTA | Pendente |
| 6 | Service Worker Registrável por Qualquer Script | 🔴 ALTA | Pendente |
| 7 | Ausência Total de CSP | 🔴 ALTA | Pendente |
| 8 | CSP Permissivo - Form Hijacking | 🟡 MÉDIA | Pendente |
| 9 | Proxies JS - Risco de Prototype Pollution | 🟡 MÉDIA | Pendente |
| 10 | Fingerprinting Bubble.io (Headers Expostos) | 🟡 MÉDIA | Pendente |
| 11 | Dependência Excessiva de CDNs | 🟡 MÉDIA | Pendente |

**Script de Reteste**: `reteste_divisaodeelite.sh`

---

## 🎯 acheumveterano.com.br / app.acheumveterano.com.br

**IP**: 72.60.255.201 (srv1061782.hstgr.cloud)  
**Status**: SSH vulnerável + WordPress exposto

### Vulnerabilidades Identificadas:

| # | Vulnerabilidade | Criticidade | Status |
|---|----------------|-------------|---------|
| 1 | OpenSSH 10.0p2 com CVEs (CVE-2025-61985/61984) | 🔴 CRÍTICA | Pendente |
| 2 | Arquivo wp-app.log Exposto no Webroot | 🔴 ALTA | Pendente |
| 3 | WordPress Endpoints Sensíveis Expostos | 🔴 ALTA | Pendente |
| 4 | Ausência de Headers Anti-Clickjacking | 🟡 MÉDIA | Pendente |
| 5 | Compressão HTTP - Risco BREACH | 🟡 MÉDIA | Pendente |
| 6 | Cookies sem Flags de Proteção | 🟡 MÉDIA | Pendente |
| 7 | Diretórios Sensíveis Acessíveis | 🟡 MÉDIA | Pendente |
| 8 | Protocolos TLS Obsoletos (se presentes) | 🟡 MÉDIA | Validar |

**Script de Reteste**: `reteste_acheumveterano.sh`

---

## 🎯 idivis.ao / 31.97.27.219

**IP Principal**: 31.97.27.219 (Hostinger BR)  
**IP SSH**: 31.97.27.129  
**Status**: Servidor de desenvolvimento exposto

### Vulnerabilidades Identificadas:

| # | Vulnerabilidade | Criticidade | Status |
|---|----------------|-------------|---------|
| 1 | Porta 3000 (Next.js Dev) Exposta | 🔴 CRÍTICA | Pendente |
| 2 | .mysql_history Exposto | 🔴 CRÍTICA | Pendente |
| 3 | .ssh/ Directory Exposto | 🔴 CRÍTICA | Pendente |
| 4 | .bash_history Exposto | 🔴 CRÍTICA | Pendente |
| 5 | _backup/ Directory Exposto | 🔴 CRÍTICA | Pendente |
| 6 | _db_backups/ Directory Exposto | 🔴 CRÍTICA | Pendente |
| 7 | SSH Acessível (31.97.27.129:22) | 🔴 ALTA | Pendente |
| 8 | Ausência de HSTS | 🔴 ALTA | Pendente |
| 9 | Ausência de CSP | 🟡 MÉDIA | Pendente |
| 10 | Ausência de Referrer-Policy | 🟡 MÉDIA | Pendente |
| 11 | Endpoints Administrativos Expostos | 🟡 MÉDIA | Pendente |

**Script de Reteste**: `reteste_idivis.sh`

---

## 🎯 planodechamadas.com.br / lp.planodechamadas.com.br

**IP**: 31.97.27.219 (Hostinger)  
**Status**: Exposição de IP real + Next.js sem proteção

### Vulnerabilidades Identificadas:

| # | Vulnerabilidade | Criticidade | Status |
|---|----------------|-------------|---------|
| 1 | Exposição Direta do IP (Bypass CDN/WAF) | 🔴 CRÍTICA | Pendente |
| 2 | Next.js sem Segurança - SSRF/LFI/RFI | 🔴 CRÍTICA | Pendente |
| 3 | Headers Incomuns Revelando Tecnologias | 🔴 ALTA | Pendente |
| 4 | Ausência de HSTS | 🔴 ALTA | Pendente |
| 5 | Ausência de X-Frame-Options | 🔴 ALTA | Pendente |
| 6 | Ausência de CSP | 🔴 ALTA | Pendente |
| 7 | APIs Next.js Expostas | 🟡 MÉDIA | Pendente |
| 8 | CORS Permissivo (se aplicável) | 🟡 MÉDIA | Validar |
| 9 | Rate Limiting Ausente | 🟡 MÉDIA | Validar |

**Pontos Positivos**:
- ✅ Certificado TLS válido (Let's Encrypt)
- ✅ TLS 1.2 e 1.3 ativos
- ✅ Cipher suites fortes

**Script de Reteste**: `reteste_planodechamadas.sh`

---

## 🎯 0fc5d3bbe18c.ngrok-free.app

**Tipo**: URL Temporária Ngrok  
**Status**: Headers de segurança ausentes

### Vulnerabilidades Identificadas:

| # | Vulnerabilidade | Criticidade | Status |
|---|----------------|-------------|---------|
| 1 | Ausência de X-Frame-Options | 🟡 MÉDIA | Pendente |
| 2 | Ausência de X-Content-Type-Options | 🟡 MÉDIA | Pendente |
| 3 | Ausência de HSTS | 🟡 MÉDIA | Pendente |
| 4 | Ausência de CSP | 🟡 MÉDIA | Pendente |
| 5 | Cookies sem Proteção (se aplicável) | 🟡 MÉDIA | Validar |

**Observações**:
- ⚠️ URL temporária - pode expirar
- 🔧 Ambiente de desenvolvimento/teste
- 🔒 Ngrok fornece HTTPS mas não headers de segurança

**Script de Reteste**: `reteste_ngrok.sh`

---

## 📊 Estatísticas Gerais

### Por Criticidade:

| Criticidade | Quantidade | Percentual |
|-------------|-----------|------------|
| 🔴 CRÍTICA | 15 | 28% |
| 🔴 ALTA | 19 | 36% |
| 🟡 MÉDIA | 19 | 36% |
| **TOTAL** | **53** | **100%** |

### Por Categoria:

| Categoria | Quantidade |
|-----------|-----------|
| Headers de Segurança | 15 |
| Exposição de Arquivos/Dados | 12 |
| Configuração de Serviços | 8 |
| Autenticação/Sessão | 7 |
| Infraestrutura | 6 |
| APIs/Endpoints | 5 |

### Por Alvo:

| Alvo | CRÍTICA | ALTA | MÉDIA | Total |
|------|---------|------|-------|-------|
| idivis.ao | 6 | 2 | 3 | 11 |
| divisaodeelite.com.br | 1 | 6 | 4 | 11 |
| adivisao.com.br | 2 | 4 | 4 | 10 |
| acheumveterano.com.br | 1 | 3 | 4 | 8 |
| planodechamadas.com.br | 2 | 4 | 3 | 9 |
| ngrok URL | 0 | 0 | 5 | 5 |

---

## 🎯 Prioridades de Correção

### 🔴 Prioridade CRÍTICA (Imediata - 24h):

1. **idivis.ao**:
   - Fechar porta 3000
   - Remover arquivos sensíveis (.mysql_history, .ssh, .bash_history)
   - Proteger diretórios de backup

2. **divisaodeelite.com.br**:
   - Remover plugin malicioso (railway.app)

3. **acheumveterano.com.br**:
   - Atualizar OpenSSH 10.0p2
   - Remover wp-app.log do webroot

4. **adivisao.com.br**:
   - Rotacionar tokens expostos
   - Proteger endpoint /fileupload

5. **planodechamadas.com.br**:
   - Implementar WAF para evitar bypass de IP
   - Validar APIs Next.js

### 🔴 Prioridade ALTA (48-72h):

- Implementar headers de segurança em todos os alvos
- Configurar cookies com flags corretas
- Implementar CSP em todos os sites
- Fechar portas administrativas desnecessárias
- Atualizar WordPress e plugins

### 🟡 Prioridade MÉDIA (1-2 semanas):

- Implementar rate limiting
- Remover fingerprinting de tecnologias
- Configurar CORS adequadamente
- Implementar SRI em scripts externos
- Desabilitar compressão em endpoints sensíveis

---

## 🔄 Processo de Reteste

1. **Aplicar correções** seguindo as prioridades
2. **Aguardar propagação** (DNS, CDN, etc.)
3. **Executar scripts de reteste**:
   ```bash
   cd retestesh
   chmod +x *.sh
   ./executar_todos_retestes.sh
   ```
4. **Analisar relatórios gerados**
5. **Documentar correções bem-sucedidas**
6. **Identificar pendências**
7. **Repetir processo até 100% de correção**

---

## 📝 Notas

- Todas as vulnerabilidades foram identificadas em testes **autorizados**
- Scripts de reteste são **não-destrutivos** (somente leitura)
- Relatórios devem ser mantidos **confidenciais**
- Retestes devem ser executados **após cada correção**

---

**Última atualização**: 28/11/2025  
**Próxima revisão**: Após aplicação de correções
