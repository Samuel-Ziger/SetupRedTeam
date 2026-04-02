/**
 * Sugestões semi-automáticas (heurísticas) — não substituem teste manual.
 */
export function suggestVectors({ findings, selectedMods }) {
  const lines = [];
  const textBlob = findings.map((f) => f.value).join(' ').toLowerCase();

  if (selectedMods.includes('sqlerrors') || textBlob.includes('sql')) {
    lines.push('SQL errors na superfície → validar inputs dinâmicos (SQLi) em endpoints com parâmetros.');
  }
  if (/redirect|url=|next=|return_url|dest=/i.test(textBlob)) {
    lines.push('Parâmetros de redirecionamento → Open Redirect / SSRF (cadeia com fetch interno).');
  }
  if (/admin|dashboard|wp-admin|phpmyadmin/i.test(textBlob)) {
    lines.push('Superfície administrativa → autenticação, IDOR em painéis, CSRF.');
  }
  if (/\.env|\.git|api_key|secret|token/i.test(textBlob)) {
    lines.push('Possível exposição de config/secrets → rotação de credenciais e escopo de vazamento.');
  }
  if (/api\/v\d|graphql|swagger/i.test(textBlob)) {
    lines.push('APIs documentadas ou versionadas → autorização, rate limit, mass assignment.');
  }
  if (lines.length === 0) {
    lines.push('Poucos sinais automáticos — priorizar endpoints HIGH e parâmetros de controle (id, role, file).');
  }
  return lines;
}

/**
 * Checklist de testes manuais (workflow) — direto e agressivo no sentido de cobertura, não de exploit automático.
 */
export function buildExploitChecklist(findings) {
  const items = [];
  const paramVals = findings.filter((f) => f.type === 'param').map((f) => String(f.value || '').toLowerCase());
  const urls = findings
    .filter((f) => f.type === 'endpoint' || f.type === 'js')
    .map((f) => String(f.url || f.value || ''));

  const hasParam = (re) => paramVals.some((p) => re.test(p));
  const hasUrl = (re) => urls.some((u) => re.test(u));

  if (hasParam(/\b(id|user_id|uid|account|order_id)=/i) || hasUrl(/[?&](id|user_id|uid)=/i)) {
    items.push('IDOR: trocar IDs numéricos/UUID em ?id= / user_id em sessão autenticada.');
  }
  if (hasParam(/redirect|url|next|return|dest|callback|goto/i) || hasUrl(/[?&](url|redirect|next|return)=/i)) {
    items.push('Open Redirect / SSRF: payloads em parâmetros de URL/redirect; encadear com webhooks internos.');
  }
  if (hasParam(/file|path|doc|page|template|include|load/i) || hasUrl(/[?&](file|path|page)=/i)) {
    items.push('LFI / path traversal: ../ sequences, wrappers php://, paths relativos.');
  }
  if (hasParam(/q|query|search|keyword|s=/i) || hasUrl(/\/search|\/query|\?q=/i)) {
    items.push('XSS refletido: quebras em campos de pesquisa e parâmetros refletidos no HTML.');
  }
  if (hasUrl(/api\/|graphql|\/v\d\//i)) {
    items.push('API: SQLi/NoSQLi em filtros, mass assignment, rate limit, quebra de autorização por método HTTP.');
  }
  if (hasParam(/token|jwt|session|auth|password|secret|key/i)) {
    items.push('Sessão/auth: fixation, weak JWT (alg none), leakage em logs/referer, replay.');
  }
  if (findings.some((f) => f.type === 'js')) {
    items.push('JS: XSS armazenado em bundles, source maps expostos, chaves em variáveis globais.');
  }
  if (findings.some((f) => f.meta && /github/i.test(f.meta))) {
    items.push('GitHub: credenciais revogadas, histórico de commits, forks com secrets.');
  }

  if (items.length === 0) {
    items.push('Mapear inputs refletidos; fuzz leve em parâmetros GET/POST; rever headers de cache e CORS.');
  }

  return items;
}
