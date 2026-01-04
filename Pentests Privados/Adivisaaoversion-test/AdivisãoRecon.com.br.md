# Relatório de Reconhecimento - adivisao.com.br
**Data:** 27/12/2025  
**Metodologia:** Caixa-preta total (Black-box)  
**Autorização:** Escopo irrestrito - ambiente laboratorial

---

## 1. RESUMO EXECUTIVO

Aplicação web identificada como plataforma **Bubble.io** (no-code) hospedada atrás do **Cloudflare**, utilizando **Supabase** como backend de banco de dados. Identificadas múltiplas superfícies de ataque e vulnerabilidades de exposição de dados sensíveis.

**Severidade Geral:** ALTA

---

## 2. FATOS OBSERVADOS

### 2.1 Infraestrutura e Stack Tecnológico

#### DNS e Rede
- **Domínio:** adivisao.com.br
- **IPs Resolvidos:**
  - 104.21.77.46 (Cloudflare)
  - 172.67.204.122 (Cloudflare)
  - 2606:4700:3037::ac43:cc7a (IPv6)
  - 2606:4700:3035::6815:4d2e (IPv6)
- **CDN/WAF:** Cloudflare (proteção ativa)
- **Portas Abertas:** 80 (HTTP → HTTPS redirect), 443 (HTTPS)

#### Stack Tecnológico Confirmado
- **Plataforma:** Bubble.io (no-code platform)
- **Backend:** Express.js (Node.js)
- **Banco de Dados:** Supabase (PostgreSQL)
- **Frontend:** jQuery, HTML5
- **Analytics:** Google Tag Manager (GTM-N58W6JWF), Facebook Pixel (3890020117941227)
- **Maps:** Google Maps API

#### Headers HTTP Observados
```
x-powered-by: Express
x-content-type-options: nosniff
referrer-policy: origin
x-frame-options: DENY
content-security-policy: frame-ancestors 'none';
cache-control: no-store
x-bubble-perf: {...}  # Métricas de performance expostas
x-bubble-capacity-used: 0.153 unit-seconds used
```

### 2.2 Informações Sensíveis Expostas no Frontend

#### Chaves e Tokens Expostos
1. **Supabase URL e API Key (anon):**
   - URL: `https://vyldhrghubgcvtwgqial.supabase.co`
   - API Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5bGRocmdodWJnY3Z0d2dxaWFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0Mzk0MDIsImV4cCI6MjA2NTAxNTQwMn0.Qt35L5cdR-TYoROWWxTkUSqtD2wGMy6DWtTsmO37r24`

2. **Google Maps API Key:**
   - `AIzaSyAlT1MzDJL1hTzjgn_-PbAD3NQEIKjcJi4`

3. **Bubble Tokens:**
   - `bubble_plp_token`: `msO+oM5LoK4a6L+mcUx/v8jHvIb5HQtnTV3HbdgQ/dY=`
   - `bubble_page_load_id`: `1766878483829x585`
   - `app_version`: `live`
   - `last_change`: `41859372238`

4. **App ID:** `divisao-12018`

#### Endpoints Identificados
- `/api/1.1/init/data?location=...` - Inicialização de dados
- `/user/m` (POST) - Métricas/telemetria
- `/version-test/` - Ambiente de teste (bloqueado em robots.txt)
- `/robots.txt` - Contém: `Disallow: /version-test/`

### 2.3 Estrutura do Banco de Dados (Supabase)

#### Tabelas Identificadas via OpenAPI/Swagger
1. **`users`** - Dados de usuários
   - Campos: `user_id`, `firstname`, `lastname`, `stripe_customer_id`, `is_admin`, `role`, `all_features`
   - **Status RLS:** ✅ Protegido (teste de POST retornou erro 42501)

2. **`subscribe_plans`** - Planos de assinatura
   - Campos: `id`, `user_id`, `type_plan_id`, `is_active`, `stripe_transaction_id`, `subscribe_since`, `due_date`
   - **Status RLS:** ✅ Protegido (retorna array vazio)

3. **`type_plans`** - Tipos de planos
   - Campos: `id`, `name`, `value`, `recurrency`, `price_id` (Stripe)
   - **Status RLS:** ❌ **ACESSÍVEL PUBLICAMENTE**
   - **Dados Expostos:** IDs de preços do Stripe, valores monetários

4. **`pages`** - Páginas de perfil de usuários
   - Campos: `id`, `uri`, `display_name`, `location`, `bio`, `buttons`, `links`, `owner`, `profile_picture`
   - **Status RLS:** ❌ **ACESSÍVEL PUBLICAMENTE**
   - **Dados Expostos:** Ver seção 2.4

5. **`capacitacoes`** - Eventos/capacitações
   - Campos: `id`, `titulo_evento`, `data_evento`, `link_evento`, `fornecido_por`, `status`
   - **Status RLS:** ❌ **ACESSÍVEL PUBLICAMENTE**

6. **`workshops`** - Workshops
   - Campos: `id`, `tipo_evento`, `data_evento`, `titulo_evento`, `link_evento`
   - **Status RLS:** Não testado

7. **`events`** - Eventos gerais
   - Campos: `id`, `type`, `page`, `uri`, `link_id`
   - **Status RLS:** Não testado

### 2.4 Dados Pessoais Expostos (VULNERABILIDADE CONFIRMADA)

#### Tabela `pages` - Exposição de PII
**Endpoint:** `GET /rest/v1/pages?select=*`

**Dados Sensíveis Identificados:**
- **Nomes Completos:**
  - EUDES JOAQUIM SANTOS VILACA
  - José Maurício Vieira Santa Maria
  - Leonardo FONTES
  - Cristiane Braz da Silva
  - Lucas Lima

- **Emails Pessoais:**
  - eudesjv@gmail.com
  - leo221985@gmail.com

- **Telefones/WhatsApp:**
  - 11959575971
  - 21982163491
  - +55 21982163491

- **Endereços Físicos:**
  - Rua Pedro de Frias, 44 - Recanto Silvestre I - Fazendinha - Santana de Parnaíba CEP: 06530-250
  - Avenida Henrique Valadares 1365, Engenho do Porto, Rio de Janeiro, CEP25015-302

- **Links de Redes Sociais:**
  - LinkedIn: https://www.linkedin.com/in/leonardo-fontes-46a313217
  - Instagram: https://www.instagram.com/astatonn/

- **UUIDs de Proprietários (owner):**
  - 3048fd95-637f-4a10-bc09-a6b060d79c9f
  - c72bd443-f32e-4321-9b28-fb705632872c
  - 0f6d5f18-11f1-4cf7-9e7e-1114e6eb2e80
  - f722e9dd-5664-4ff8-bc25-b9ae5aa3d3fa
  - 0c7ab2ce-a70a-4d8c-b3ac-7a91911f7dbc

**Impacto:** Violação de LGPD/GDPR - Dados pessoais acessíveis sem autenticação.

---

## 3. HIPÓTESES DE VULNERABILIDADES

### 3.1 Vulnerabilidades Confirmadas

#### 🔴 CRÍTICA: Exposição de Dados Pessoais (PII)
- **Tipo:** Information Disclosure
- **Severidade:** ALTA
- **Evidência:** Tabela `pages` acessível publicamente via API Supabase
- **Dados Expostos:** Nomes, emails, telefones, endereços, UUIDs de usuários
- **Conformidade:** Violação de LGPD Art. 46, GDPR Art. 32

#### 🟠 MÉDIA: Exposição de Estrutura de Planos e Preços
- **Tipo:** Information Disclosure
- **Severidade:** MÉDIA
- **Evidência:** Tabela `type_plans` acessível publicamente
- **Dados Expostos:** IDs de preços Stripe, valores monetários, recorrência
- **Impacto:** Possível análise competitiva, manipulação de preços

#### 🟡 BAIXA: Exposição de Chaves de API no Frontend
- **Tipo:** Credential Exposure
- **Severidade:** BAIXA-MÉDIA (depende do escopo das chaves)
- **Evidência:** Google Maps API Key, Supabase anon key expostas no JavaScript
- **Impacto Potencial:**
  - Google Maps: Uso não autorizado (quota/custos)
  - Supabase: Já explorado (acesso a dados)

### 3.2 Hipóteses a Validar

#### 🔵 HIPÓTESE 1: Bypass de Row Level Security (RLS)
- **Descrição:** Possibilidade de acessar dados protegidos através de manipulação de parâmetros ou autenticação
- **Teste Sugerido:**
  1. Tentar acessar `users` com diferentes filtros
  2. Testar injeção de parâmetros na query string
  3. Verificar se há endpoints alternativos que bypassam RLS
  4. Testar com diferentes headers (Authorization, X-Client-Info)

#### 🔵 HIPÓTESE 2: Inserção Não Autorizada de Dados
- **Descrição:** Possibilidade de criar registros em tabelas protegidas
- **Evidência Parcial:** POST em `users` foi bloqueado (RLS funcionando)
- **Teste Sugerido:**
  1. Tentar POST em outras tabelas (`pages`, `events`, `workshops`)
  2. Testar com diferentes payloads e estruturas
  3. Verificar validação de campos obrigatórios

#### 🔵 HIPÓTESE 3: Enumeração de Usuários Administradores
- **Descrição:** Identificar usuários com `is_admin=true` ou `role=admin`
- **Teste Sugerido:**
  1. Correlacionar UUIDs de `pages.owner` com possíveis admins
  2. Buscar padrões em `pages` que indiquem contas administrativas
  3. Verificar se há endpoints que exponham metadados de usuários

#### 🔵 HIPÓTESE 4: Manipulação de Planos de Assinatura
- **Descrição:** Modificar ou criar planos de assinatura não autorizados
- **Teste Sugerido:**
  1. Tentar PATCH em `subscribe_plans` (se RLS permitir)
  2. Verificar se `type_plan_id` pode ser manipulado
  3. Testar criação de planos com valores alterados

#### 🔵 HIPÓTESE 5: Acesso a Ambiente de Teste
- **Descrição:** Acessar `/version-test/` apesar do bloqueio em robots.txt
- **Teste Sugerido:**
  1. Acessar diretamente `/version-test/`
  2. Verificar se há subdiretórios ou endpoints relacionados
  3. Testar com diferentes métodos HTTP

#### 🔵 HIPÓTESE 6: Vulnerabilidades na API Bubble
- **Descrição:** Falhas na API `/api/1.1/` do Bubble
- **Teste Sugerido:**
  1. Enumerar endpoints da API Bubble
  2. Testar parâmetros de `location` para SSRF
  3. Verificar se há endpoints de autenticação expostos
  4. Testar rate limiting e autenticação

#### 🔵 HIPÓTESE 7: Exposição de Dados via Service Worker
- **Descrição:** Service Worker pode expor informações ou ser manipulado
- **Status:** Service Worker básico, sem lógica crítica aparente
- **Teste Sugerido:**
  1. Verificar se há endpoints sensíveis no cache
  2. Testar manipulação do cache do Service Worker

---

## 4. SUPERFÍCIES DE ATAQUE PRIORIZADAS

### 4.1 Prioridade ALTA

1. **API Supabase - Tabela `pages`**
   - Acesso não autorizado a dados pessoais
   - Enumeração de usuários
   - Correlação de UUIDs com outras tabelas

2. **API Supabase - Tabela `type_plans`**
   - Exposição de estrutura de preços
   - IDs do Stripe expostos

3. **Chaves de API Expostas**
   - Google Maps API Key
   - Supabase anon key (já explorada)

### 4.2 Prioridade MÉDIA

1. **API Bubble (`/api/1.1/`)**
   - Endpoints não documentados
   - Possível SSRF via parâmetro `location`
   - Autenticação/autorização

2. **Tabelas Supabase Adicionais**
   - `capacitacoes`, `workshops`, `events`
   - Verificar RLS e possíveis bypasses

3. **Endpoint `/user/m`**
   - Telemetria/métricas
   - Possível injeção de dados ou XSS

### 4.3 Prioridade BAIXA

1. **Service Worker**
   - Cache manipulation
   - Offline functionality

2. **Manifest.json**
   - PWA configuration
   - Possível exposição de recursos

---

## 5. ESTRATÉGIA DE VALIDAÇÃO PROGRESSIVA

### Fase 1: Validação de RLS e Acesso a Dados (Imediata)
1. ✅ **CONCLUÍDO:** Teste de acesso público a `pages` - **VULNERABILIDADE CONFIRMADA**
2. ✅ **CONCLUÍDO:** Teste de acesso público a `type_plans` - **VULNERABILIDADE CONFIRMADA**
3. ⏳ **PENDENTE:** Teste de enumeração completa de `pages` (pagination)
4. ⏳ **PENDENTE:** Teste de acesso a `users` com diferentes filtros
5. ⏳ **PENDENTE:** Teste de correlação `pages.owner` → `users.user_id`

### Fase 2: Testes de Inserção e Modificação (Baixo Risco)
1. ⏳ **PENDENTE:** Tentar POST em `pages` (criação de perfil falso)
2. ⏳ **PENDENTE:** Tentar PATCH em `pages` existentes (modificação não autorizada)
3. ⏳ **PENDENTE:** Tentar POST/PATCH em `capacitacoes`, `workshops`, `events`
4. ⏳ **PENDENTE:** Verificar validação de campos obrigatórios

### Fase 3: Análise de API Bubble (Médio Risco)
1. ⏳ **PENDENTE:** Enumeração de endpoints `/api/1.1/*`
2. ⏳ **PENDENTE:** Teste de SSRF via parâmetro `location`
3. ⏳ **PENDENTE:** Análise de autenticação/autorização
4. ⏳ **PENDENTE:** Teste de rate limiting

### Fase 4: Análise de Chaves Expostas (Baixo Risco)
1. ⏳ **PENDENTE:** Verificar escopo da Google Maps API Key
2. ⏳ **PENDENTE:** Testar uso não autorizado da chave
3. ⏳ **PENDENTE:** Verificar se há outras chaves no código-fonte

### Fase 5: Testes de Ambiente de Teste (Baixo Risco)
1. ⏳ **PENDENTE:** Acesso a `/version-test/` e subdiretórios
2. ⏳ **PENDENTE:** Verificar se há diferenças de configuração

---

## 6. CRITÉRIOS DE VALIDAÇÃO

### Para Confirmar Vulnerabilidade:
- ✅ **Dados Acessíveis:** Resposta HTTP 200 com dados sensíveis
- ✅ **Sem Autenticação:** Requisição sem tokens de autenticação válidos
- ✅ **RLS Bypass:** Acesso a tabelas que deveriam estar protegidas
- ⏳ **Inserção Não Autorizada:** POST/PATCH bem-sucedido sem autenticação
- ⏳ **Modificação Não Autorizada:** Alteração de dados de outros usuários

### Para Descartar Hipótese:
- ❌ **RLS Funcionando:** Erro 42501 (row-level security policy violation)
- ❌ **Autenticação Obrigatória:** Erro 401/403
- ❌ **Validação de Dados:** Erro 400 com mensagem de validação
- ❌ **Endpoint Inexistente:** Erro 404

---

## 7. RECOMENDAÇÕES IMEDIATAS

### 7.1 Correções Críticas (Urgente)

1. **Implementar RLS na Tabela `pages`**
   - Restringir acesso apenas a usuários autenticados
   - Permitir leitura apenas do próprio perfil (`owner = auth.uid()`)
   - Implementar políticas de leitura pública apenas para campos não sensíveis

2. **Revisar RLS na Tabela `type_plans`**
   - Se dados devem ser públicos: OK
   - Se não: Implementar RLS adequado
   - Considerar ocultar `price_id` do Stripe se não necessário

3. **Remover Chaves de API do Frontend**
   - Mover Google Maps API Key para backend
   - Implementar proxy para requisições de Maps
   - Revisar necessidade de expor Supabase anon key (se necessário, validar RLS)

### 7.2 Melhorias de Segurança

1. **Implementar Rate Limiting**
   - Na API Supabase (via Supabase Dashboard)
   - Na aplicação Bubble

2. **Revisar Exposição de Headers**
   - Remover `x-powered-by: Express`
   - Considerar remover `x-bubble-perf` (informação sensível)

3. **Implementar Content Security Policy (CSP)**
   - Restringir fontes de scripts
   - Prevenir XSS

4. **Auditoria de Conformidade**
   - Revisar exposição de dados conforme LGPD
   - Implementar consentimento explícito para dados pessoais

---

## 8. PRÓXIMOS PASSOS

1. **Validação Adicional:**
   - Executar testes da Fase 1-3 da estratégia de validação
   - Documentar todas as descobertas

2. **Análise Profunda:**
   - Revisar código-fonte JavaScript para outras chaves/tokens
   - Analisar fluxo de autenticação completo
   - Mapear todos os endpoints da API

3. **Exploração de Vulnerabilidades Lógicas:**
   - Testar fluxos de autenticação/autorização
   - Verificar possíveis IDOR (Insecure Direct Object Reference)
   - Testar lógica de negócio (planos, assinaturas)

---

## 9. CONCLUSÃO

A aplicação apresenta **vulnerabilidades críticas de exposição de dados pessoais** através da API Supabase. A tabela `pages` está acessível publicamente, expondo informações sensíveis de usuários (nomes, emails, telefones, endereços).

**Status:** Vulnerabilidades confirmadas exigem correção imediata.

**Risco Geral:** ALTO - Dados pessoais expostos, possível violação de LGPD/GDPR.

---

**Fim do Relatório**
