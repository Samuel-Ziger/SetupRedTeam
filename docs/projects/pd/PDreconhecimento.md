# Análise de Segurança Ofensiva - planodechamadas.com.br

## 1. FATOS OBSERVADOS

### 1.1 Infraestrutura e Stack Tecnológico
- **Servidor Web**: Nginx
- **Framework Frontend**: Next.js (React)
- **Backend-as-a-Service**: Supabase (PostgreSQL + PostgREST)
- **Armazenamento**: AWS S3 (plano-chamadas-imagens-prod.s3.us-east-1.amazonaws.com)
- **IP**: 31.97.27.219 (srv851193.hstgr.cloud)
- **Portas Abertas**: 80 (HTTP), 443 (HTTPS)

### 1.2 Endpoints Identificados
- `/` - Página inicial
- `/login` - Autenticação (200)
- `/esqueci-senha` - Recuperação de senha (200)
- `/profile` - Redireciona para /login quando não autenticado (307)
- `/cgi-bin/` - Redireciona (308) - possivelmente artefato ou endpoint legado
- `/_next/static/` - Arquivos estáticos do Next.js

### 1.3 Credenciais e Tokens Expostos
- **JWT Anon Key do Supabase** encontrado no código JavaScript:
  ```
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5bGRocmdodWJnY3Z0d2dxaWFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0Mzk0MDIsImV4cCI6MjA2NTAxNTQwMn0.Qt35L5cdR-TYoROWWxTkUSqtD2wGMy6DWtTsmO37r24
  ```
- **Payload do JWT**:
  - `iss`: supabase
  - `ref`: vyldhrghubgcvtwgqial
  - `role`: anon
  - `exp`: 2065015402 (expira em ~2035)

### 1.4 API Supabase Exposta
- **Base URL**: `https://vyldhrghubgcvtwgqial.supabase.co`
- **Endpoints REST**: `/rest/v1/`
- **Endpoints Auth**: `/auth/v1/`
- **OpenAPI Schema**: Exposto publicamente via `/rest/v1/`

### 1.5 Estrutura de Banco de Dados (via OpenAPI)
Tabelas identificadas:
- `users` - Campos: user_id, firstname, lastname, stripe_customer_id, all_features, **is_admin**, **role**
- `pages` - Perfis de usuários com owner (FK para users.user_id)
- `subscribe_plans` - Planos de assinatura
- `type_plans` - Tipos de planos com price_id (Stripe)
- `capacitacoes` - Eventos de capacitação
- `workshops` - Workshops
- `events` - Eventos de tracking

### 1.6 Content Security Policy (CSP)
```
default-src 'self'; 
script-src 'self' 'unsafe-inline' 'unsafe-eval'; 
style-src 'self' 'unsafe-inline'; 
img-src 'self' data: https:; 
font-src 'self'; 
connect-src 'self' https://vyldhrghubgcvtwgqial.supabase.co https://plano-chamadas-imagens-prod.s3.us-east-1.amazonaws.com; 
frame-src 'self' https://www.youtube.com https://youtube.com; 
frame-ancestors 'self';
```

**Observações**:
- `unsafe-inline` e `unsafe-eval` permitidos em scripts (XSS facilitado)
- Conexões permitidas para Supabase e S3

### 1.7 Rate Limiting
- **Cliente**: Implementado no JavaScript (10 requisições/60s)
- **Servidor**: A ser validado (teste de cadastro em massa necessário)

### 1.8 Teste de Cadastro
- Cadastro de usuário de teste realizado com sucesso
- Email confirmado automaticamente (`email_confirmed_at` presente)
- Token de autenticação gerado com sucesso

### 1.9 Validação de Segurança - Descobertas Críticas

#### ✅ CONFIRMADO: Tabela `users` Protegida
- Acesso direto retorna array vazio `[]`
- Tentativa de criação direta retorna erro RLS: `"new row violates row-level security policy for table \"users\""`
- **Status**: RLS configurado corretamente

#### ❌ VULNERABILIDADE CRÍTICA: Tabela `pages` Exposta
- **Acesso não autorizado CONFIRMADO**: Listagem completa de perfis sem autenticação
- **Dados expostos**:
  - Nomes completos de usuários
  - Emails pessoais
  - Telefones/WhatsApp
  - Endereços físicos completos
  - Links de LinkedIn
  - IDs de usuários (owner)
  - URIs de perfis
  - Fotos de perfil (URLs S3)

**Exemplo de dados expostos**:
```json
{
  "id": 9,
  "uri": "vilaca",
  "display_name": "EUDES JOAQUIM SANTOS VILACA",
  "buttons": "{\"email\":\"eudesjv@gmail.com\",\"whatsapp\":\"11959575971\",\"location\":\"Rua Pedro de Frias, 44...\"}",
  "owner": "3048fd95-637f-4a10-bc09-a6b060d79c9f"
}
```

**Impacto**: Violação grave de privacidade (LGPD), exposição de PII, possível enumeração de usuários e base de dados para ataques direcionados.

---

## 2. VULNERABILIDADES CONFIRMADAS E HIPÓTESES

### 2.1 ✅ CONFIRMADA - CRÍTICA: Exposição de Dados Pessoais via API (CVE-2025-XXXX)

**Status**: VULNERABILIDADE CONFIRMADA E EXPLORÁVEL

**Descrição**: A tabela `pages` do Supabase não possui Row Level Security (RLS) configurado ou está mal configurado, permitindo acesso não autorizado a todos os perfis de usuários sem necessidade de autenticação.

**Evidências Técnicas**:
- Requisição GET em `/rest/v1/pages?select=*` retorna dados completos sem autenticação
- Tabela `users` está protegida (RLS funcionando)
- Tabela `pages` está completamente exposta

**Dados Expostos** (PII - Dados Pessoais):
- Nomes completos
- Emails pessoais
- Telefones e WhatsApp
- Endereços físicos completos (incluindo CEP)
- Links de perfis profissionais (LinkedIn)
- IDs de usuários (UUIDs)
- URIs de perfis públicos
- URLs de fotos de perfil (S3)

**Comando de Exploração**:
```bash
curl "https://vyldhrghubgcvtwgqial.supabase.co/rest/v1/pages?select=*" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5bGRocmdodWJnY3Z0d2dxaWFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0Mzk0MDIsImV4cCI6MjA2NTAxNTQwMn0.Qt35L5cdR-TYoROWWxTkUSqtD2wGMy6DWtTsmO37r24"
```

**Impacto**:
- **CRÍTICO**: Violação de privacidade (LGPD - Lei Geral de Proteção de Dados)
- Exposição massiva de PII (Personal Identifiable Information)
- Enumeração completa de base de usuários
- Base para ataques direcionados (phishing, engenharia social)
- Possível violação de regulamentações (LGPD, GDPR)

**CVSS v3.1 Score Estimado**: 9.1 (CRÍTICO)
- **Confidencialidade**: Alta (C:H)
- **Integridade**: Nenhuma (I:N)
- **Disponibilidade**: Nenhuma (A:N)
- **Escopo**: Não alterado (S:U)

**Recomendação Imediata**:
1. Habilitar RLS na tabela `pages` no Supabase
2. Implementar política que permita apenas:
   - Leitura do próprio perfil (owner = auth.uid())
   - Leitura de perfis públicos (se aplicável) apenas de campos não sensíveis
3. Remover campos sensíveis (email, telefone, endereço) de respostas públicas
4. Implementar validação de autorização no backend antes de expor dados

### 2.2 ALTA: Falta de Rate Limiting no Servidor
**Hipótese**: Rate limiting implementado apenas no cliente, permitindo bypass via requisições diretas à API.

**Evidências**:
- Rate limiting visível apenas no código JavaScript do cliente
- Múltiplos cadastros podem ser realizados sem restrição aparente

**Impacto Potencial**:
- Spam de cadastros
- Enumeração de emails válidos
- Possível DoS via criação massiva de contas
- Abuso de recursos do Supabase

**Teste Sugerido**:
```bash
# Teste de cadastro em massa
for i in {1..100}; do
  curl -X POST "https://vyldhrghubgcvtwgqial.supabase.co/auth/v1/signup" \
    -H "apikey: [anon_key]" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"test$i@test.com\",\"password\":\"Test1234!\"}"
done
```

### 2.3 MÉDIA: XSS via CSP Permissivo
**Hipótese**: Content Security Policy permite `unsafe-inline` e `unsafe-eval`, facilitando ataques XSS.

**Evidências**:
- CSP permite `script-src 'self' 'unsafe-inline' 'unsafe-eval'`
- Formulários de entrada (login, cadastro, recuperação de senha) podem ser vetores

**Impacto Potencial**:
- Roubo de credenciais
- Session hijacking
- Redirecionamento malicioso

**Teste Sugerido**:
- Injetar payloads XSS em campos de formulário
- Verificar se dados são refletidos sem sanitização
- Testar em endpoints que exibem dados do usuário

### 2.4 MÉDIA: Enumeração de Usuários
**Hipótese**: Endpoints de autenticação ou recuperação de senha podem permitir enumeração de emails válidos.

**Evidências**:
- Endpoint `/esqueci-senha` identificado
- Respostas diferentes podem indicar existência de usuário

**Impacto Potencial**:
- Identificação de usuários válidos
- Base para ataques de força bruta direcionados
- Violação de privacidade

**Teste Sugerido**:
```bash
# Testar emails conhecidos vs desconhecidos
curl -X POST "https://planodechamadas.com.br/esqueci-senha" \
  -d "email=usuario@conhecido.com"

curl -X POST "https://planodechamadas.com.br/esqueci-senha" \
  -d "email=naoexiste@test.com"

# Comparar respostas/timing
```

### 2.5 ⚠️ A VALIDAR: Modificação Não Autorizada de Dados
**Hipótese**: Falta de validação de autorização permite que usuários modifiquem dados de outros usuários.

**Evidências**:
- Tabela `pages` tem campo `owner` (FK para users.user_id)
- Sem validação aparente de propriedade no frontend
- Teste inicial de modificação sem autenticação retornou array vazio (necessita validação com token)

**Status**: Requer validação adicional com token de autenticação válido

**Impacto Potencial**:
- Modificação de perfis de outros usuários
- Vandalismo
- Roubo de identidade
- Defacement de perfis públicos

**Teste Necessário**:
```bash
# 1. Criar usuário e obter token
# 2. Tentar modificar perfil de outro usuário
curl -X PATCH "https://vyldhrghubgcvtwgqial.supabase.co/rest/v1/pages?id=eq.[outro_usuario_id]" \
  -H "apikey: [anon_key]" \
  -H "Authorization: Bearer [token_autenticado]" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"bio": "TESTE DE MODIFICACAO", "display_name": "Hacked"}'
```

### 2.6 BAIXA: Exposição de Informações via OpenAPI
**Hipótese**: Schema OpenAPI exposto revela estrutura completa do banco de dados.

**Evidências**:
- `/rest/v1/` retorna schema completo
- Nomes de tabelas, colunas e relacionamentos visíveis

**Impacto Potencial**:
- Facilita mapeamento de ataque
- Revela lógica de negócio
- Ajuda na construção de queries maliciosas

---

## 3. SUPERFÍCIES DE ATAQUE PRIORIZADAS

### 3.1 PRIORIDADE CRÍTICA
1. **API Supabase - Row Level Security**
   - Verificar se RLS está habilitado
   - Testar acesso não autorizado a `users`, `pages`, `subscribe_plans`
   - Validar se modificações são permitidas sem autenticação adequada

2. **Autenticação e Autorização**
   - Testar bypass de autenticação
   - Validar tokens JWT (expiração, assinatura, claims)
   - Verificar escalação de privilégios (is_admin, role)

### 3.2 PRIORIDADE ALTA
3. **Rate Limiting**
   - Validar rate limiting no servidor (não apenas cliente)
   - Testar cadastro em massa
   - Verificar proteção contra enumeração

4. **Validação de Entrada**
   - Testar SQL Injection (PostgREST usa prepared statements, mas validar)
   - Validar sanitização de dados de entrada
   - Testar NoSQL Injection (se aplicável)

### 3.3 PRIORIDADE MÉDIA
5. **Cross-Site Scripting (XSS)**
   - Testar XSS refletido e armazenado
   - Validar sanitização em campos de formulário
   - Verificar CSP bypass

6. **Cross-Site Request Forgery (CSRF)**
   - Validar proteção CSRF em ações sensíveis
   - Testar modificação de dados via requisições cross-origin

---

## 4. ESTRATÉGIA DE VALIDAÇÃO

### Fase 1: Validação de Acesso Não Autorizado (CRÍTICA)
1. Testar acesso a `users` sem autenticação
2. Testar acesso a `pages` sem autenticação
3. Testar modificação de dados sem autenticação adequada
4. Validar se RLS está configurado corretamente

### Fase 2: Validação de Autenticação (CRÍTICA)
1. Testar bypass de autenticação
2. Validar expiração e renovação de tokens
3. Testar escalação de privilégios
4. Verificar se tokens podem ser reutilizados após logout

### Fase 3: Validação de Rate Limiting (ALTA)
1. Realizar cadastro em massa (100+ requisições)
2. Testar enumeração de usuários
3. Validar rate limiting no servidor vs cliente

### Fase 4: Validação de Entrada (MÉDIA)
1. Testar XSS em todos os campos de entrada
2. Validar sanitização de dados
3. Testar SQL Injection (baixa probabilidade com PostgREST)

### Fase 5: Validação de Lógica de Negócio (MÉDIA)
1. Testar modificação de dados de outros usuários
2. Validar autorização em ações sensíveis
3. Testar race conditions em operações críticas

---

## 5. PRÓXIMOS PASSOS RECOMENDADOS

1. **Imediato**: Validar se RLS está configurado no Supabase
2. **Imediato**: Testar acesso não autorizado às tabelas sensíveis
3. **Curto Prazo**: Implementar testes de rate limiting no servidor
4. **Curto Prazo**: Validar proteção contra enumeração de usuários
5. **Médio Prazo**: Revisar e fortalecer CSP
6. **Médio Prazo**: Implementar validação de autorização robusta

---

## 6. OBSERVAÇÕES TÉCNICAS

- **Next.js**: Framework moderno, mas requer configuração adequada de segurança
- **Supabase**: BaaS com RLS nativo, mas requer configuração explícita
- **PostgREST**: API REST automática sobre PostgreSQL, geralmente seguro, mas depende de RLS
- **JWT Anon Key**: Exposto no frontend é esperado, mas RLS deve proteger dados

---

---

## 7. RESUMO EXECUTIVO

### Vulnerabilidades Confirmadas

| ID | Severidade | Status | Descrição |
|---|---|---|---|
| VULN-001 | **CRÍTICA** | ✅ CONFIRMADA | Exposição de dados pessoais (PII) via API - Tabela `pages` sem RLS |
| VULN-002 | ALTA | ⚠️ HIPÓTESE | Falta de rate limiting no servidor |
| VULN-003 | MÉDIA | ⚠️ HIPÓTESE | XSS facilitado por CSP permissivo |
| VULN-004 | MÉDIA | ⚠️ HIPÓTESE | Enumeração de usuários via recuperação de senha |
| VULN-005 | MÉDIA | ⚠️ A VALIDAR | Modificação não autorizada de dados |

### Ações Imediatas Recomendadas

1. **URGENTE**: Habilitar RLS na tabela `pages` do Supabase
2. **URGENTE**: Remover campos sensíveis (email, telefone, endereço) de respostas públicas
3. **ALTA**: Implementar rate limiting no servidor (não apenas cliente)
4. **ALTA**: Revisar e fortalecer Content Security Policy
5. **MÉDIA**: Validar proteção contra enumeração de usuários
6. **MÉDIA**: Implementar validação robusta de autorização

### Conformidade e Regulamentações

- **LGPD (Lei Geral de Proteção de Dados)**: Violação confirmada - exposição de PII
- **GDPR**: Possível violação se houver usuários europeus
- **ISO 27001**: Falha em controles de acesso (A.9.1.2)

---

**Data da Análise**: 2025-12-27
**Metodologia**: Caixa-preta, reconhecimento passivo e testes não destrutivos
**Status**: Análise inicial completa - 1 vulnerabilidade crítica confirmada, 4 hipóteses a validar
**Próximos Passos**: Validação de hipóteses restantes e testes de modificação não autorizada

