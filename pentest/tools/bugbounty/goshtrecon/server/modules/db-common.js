import crypto from 'crypto';

export function norm(s) {
  return String(s ?? '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

/** Tipos em que URL equivalente com query reordenada deve colapsar no dedupe */
const FINGERPRINT_URL_NORMALIZE_TYPES = new Set([
  'endpoint',
  'param',
  'js',
  'security',
  'tls',
  'nuclei',
  'xss',
  'sqli',
  'dalfox',
  'wpscan',
  'intel',
]);

/**
 * Normaliza URL para dedupe: remove fragmento, ordena chaves de query.
 */
export function normUrlForFingerprint(u) {
  if (!u) return '';
  try {
    const x = new URL(String(u));
    x.hash = '';
    const keys = [...new Set([...x.searchParams.keys()])].sort();
    const sp = new URLSearchParams();
    for (const k of keys) {
      for (const v of x.searchParams.getAll(k)) sp.append(k, v);
    }
    const q = sp.toString();
    x.search = q ? `?${q}` : '';
    return x.href.toLowerCase();
  } catch {
    return norm(u);
  }
}

export function fingerprintFinding(target, f) {
  const urlPart = FINGERPRINT_URL_NORMALIZE_TYPES.has(f.type) ? normUrlForFingerprint(f.url) : norm(f.url);
  const raw = `${norm(target)}|${norm(f.type)}|${norm(f.value)}|${urlPart}`;
  return crypto.createHash('sha256').update(raw).digest('hex');
}

/**
 * A tabela `findings` deve persistir apenas domínio e subdomínios.
 * Mantém um registro explícito do domínio raiz e deduplica subdomínios.
 */
export function findingsForRunsTable(target, findings) {
  const t = norm(target);
  const out = [
    {
      type: 'domain',
      prio: 'low',
      score: 20,
      value: t,
      meta: 'domínio alvo',
      url: `https://${t}`,
    },
  ];

  const seenSubs = new Set();
  for (const f of findings || []) {
    if (!f || f.type !== 'subdomain') continue;
    const sub = norm(f.value);
    if (!sub || seenSubs.has(sub)) continue;
    seenSubs.add(sub);
    out.push({
      type: 'subdomain',
      prio: f.prio ?? 'med',
      score: f.score ?? 52,
      value: sub,
      meta: f.meta ?? null,
      url: f.url ?? `https://${sub}`,
    });
  }
  return out;
}
