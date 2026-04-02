import crypto from 'crypto';

export function norm(s) {
  return String(s ?? '')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

export function normalizeForKnowledge(s) {
  let x = norm(s);
  if (!x) return '';
  // remove urls host parts and query noise
  x = x.replace(/https?:\/\/[^\s/]+/g, 'http://<host>');
  // remove ipv4
  x = x.replace(/\b(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b/g, '<ip>');
  // remove standalone ports
  x = x.replace(/\b:\d{2,5}\b/g, ':<port>');
  // collapse hex-ish ids / hashes
  x = x.replace(/\b[0-9a-f]{8,64}\b/g, '<hex>');
  // collapse long numbers
  x = x.replace(/\b\d{4,}\b/g, '<n>');
  // trim repeated placeholders/spaces
  x = x.replace(/\s+/g, ' ').trim();
  return x;
}

export function knowledgeKeyFromFinding(f) {
  const type = norm(f?.type || '');
  const val = normalizeForKnowledge(f?.value || '');
  const meta = normalizeForKnowledge(f?.meta || '');
  const url = normalizeForKnowledge(f?.url || '');
  const blob = [val, meta, url].filter(Boolean).join(' | ').slice(0, 500);
  if (!type || !blob) return null;
  return `${type}|${blob}`;
}

export function fingerprintFinding(target, f) {
  const raw = `${norm(target)}|${norm(f.type)}|${norm(f.value)}|${norm(f.url)}`;
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
