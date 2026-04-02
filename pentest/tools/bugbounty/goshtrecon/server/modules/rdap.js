import { UA } from '../config.js';

/**
 * RDAP via bootstrap IANA (redirect para o servidor do TLD).
 */
export async function fetchRdapSummary(domain) {
  const u = `https://rdap.iana.org/domain/${encodeURIComponent(domain)}`;
  const res = await fetch(u, {
    headers: { Accept: 'application/rdap+json, application/json, */*', 'User-Agent': UA },
    signal: AbortSignal.timeout(22000),
    redirect: 'follow',
  });
  if (!res.ok) throw new Error(`RDAP HTTP ${res.status}`);
  const j = await res.json();
  const handle = j.ldhName || domain;
  const statuses = Array.isArray(j.status)
    ? j.status
        .map((s) => (typeof s === 'string' ? s.split('/').pop() : ''))
        .filter(Boolean)
        .join(', ')
    : '';
  const ns = (j.nameservers || [])
    .map((n) => n.ldhName || n.unicodeName || n.handle)
    .filter(Boolean);
  const events = (j.events || [])
    .filter((e) => e.eventAction && e.eventDate)
    .slice(0, 6)
    .map((e) => `${e.eventAction}: ${e.eventDate}`);
  return { handle, statuses, nameservers: ns, events, links: j.links || [] };
}
