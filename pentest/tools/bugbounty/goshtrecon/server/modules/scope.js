/**
 * Escopo do engagement: domínio raiz + subdomínios, com exclusões opcionais (fora de escopo).
 */

/** Limite de entradas vindas da UI / API (por pedido). */
export const OUT_OF_SCOPE_CLIENT_MAX = 120;

export function hostnameInScope(hostname, rootDomain) {
  const h = String(hostname || '')
    .toLowerCase()
    .replace(/^\[|\]$/g, '');
  const r = String(rootDomain).toLowerCase();
  return h === r || h.endsWith(`.${r}`);
}

/**
 * @param {string} raw ex. env GHOSTRECON_OUT_OF_SCOPE
 * @returns {string[]} hostnames normalizados (únimos)
 */
export function parseOutOfScopeEnv(raw) {
  if (raw == null || typeof raw !== 'string') return [];
  return [
    ...new Set(
      raw
        .split(/[\s,]+/)
        .map((s) => s.trim().toLowerCase())
        .filter((s) => s.length > 0 && !s.startsWith('#')),
    ),
  ];
}

/**
 * Uma linha da lista (hostname, URL ou *.wildcard.host).
 */
export function normalizeOutOfScopeToken(token) {
  const raw = String(token || '').trim();
  if (!raw || raw.startsWith('#')) return '';
  if (raw.toLowerCase().startsWith('*.')) return raw.toLowerCase();
  try {
    if (/^https?:\/\//i.test(raw)) {
      return new URL(raw).hostname.toLowerCase();
    }
  } catch {
    return '';
  }
  const first = raw.split(/[/?#]/)[0].replace(/:\d+$/, '').trim();
  if (!first) return '';
  return first.toLowerCase();
}

/**
 * Textarea / JSON: linhas e vírgulas; aceita URLs completas.
 * @param {string|string[]|null|undefined} value
 */
export function parseOutOfScopeClientInput(value, maxEntries = OUT_OF_SCOPE_CLIENT_MAX) {
  if (value == null) return [];
  const chunks = Array.isArray(value) ? value : [value];
  const tokens = [];
  for (const chunk of chunks) {
    for (const line of String(chunk).split(/\r?\n/)) {
      for (const part of line.split(',')) {
        const t = part.trim();
        if (t) tokens.push(t);
      }
    }
  }
  const out = [];
  const seen = new Set();
  for (const tok of tokens) {
    const n = normalizeOutOfScopeToken(tok);
    if (!n || seen.has(n)) continue;
    seen.add(n);
    out.push(n);
    if (out.length >= maxEntries) break;
  }
  return out;
}

export function mergeOutOfScopeLists(envList, clientList) {
  return [...new Set([...(envList || []), ...(clientList || [])])];
}

/**
 * Regra opcional com wildcard: "*.cdn.example.com" ou "*cdn.example.com" → sufixo DNS.
 */
export function hostnameMatchesOutOfScope(hostname, rules) {
  const h = String(hostname || '')
    .toLowerCase()
    .replace(/^\[|\]$/g, '');
  if (!h || !rules.length) return false;
  for (let r of rules) {
    if (!r) continue;
    if (r.startsWith('*.')) {
      r = r.slice(2);
      if (!r) continue;
      if (h === r || h.endsWith(`.${r}`)) return true;
      continue;
    }
    if (h === r || h.endsWith(`.${r}`)) return true;
  }
  return false;
}

export function hostInReconScope(hostname, rootDomain, outOfScopeRules = []) {
  if (!hostnameInScope(hostname, rootDomain)) return false;
  if (hostnameMatchesOutOfScope(hostname, outOfScopeRules)) return false;
  return true;
}

export function urlInReconScope(urlStr, rootDomain, outOfScopeRules = []) {
  try {
    const h = new URL(urlStr).hostname;
    return hostInReconScope(h, rootDomain, outOfScopeRules);
  } catch {
    return false;
  }
}
