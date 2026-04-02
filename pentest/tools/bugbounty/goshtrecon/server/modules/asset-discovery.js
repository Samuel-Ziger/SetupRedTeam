import dns from 'node:dns/promises';
import { collectUniqueIpv4 } from './ip-intel.js';

async function fetchIpRdap(ip) {
  try {
    const res = await fetch(`https://rdap.org/ip/${encodeURIComponent(ip)}`, {
      signal: AbortSignal.timeout(10000),
      headers: { Accept: 'application/rdap+json, application/json, */*' },
    });
    if (!res.ok) return null;
    const j = await res.json();
    const asn = j?.handle || j?.name || '';
    return asn ? { ip, asn: String(asn).slice(0, 120) } : { ip, asn: '' };
  } catch {
    return null;
  }
}

export async function discoverAssetHints(domain, subdomainsAlive = [], tlsSanHosts = []) {
  const hints = [];

  try {
    const ns = await dns.resolveNs(domain);
    if (ns?.length) {
      hints.push({
        type: 'asset',
        prio: 'low',
        score: 34,
        value: `NS records: ${ns.slice(0, 8).join(', ')}`,
        meta: 'asset_discovery=ns',
      });
    }
  } catch {
    /* ignore */
  }

  const ips = await collectUniqueIpv4([domain, ...subdomainsAlive], 20, 12);
  for (const ip of ips.slice(0, 8)) {
    const rd = await fetchIpRdap(ip);
    hints.push({
      type: 'asset',
      prio: 'low',
      score: 38,
      value: `IP asset: ${ip}`,
      meta: rd?.asn ? `asset_discovery=ip_asn • asn=${rd.asn}` : 'asset_discovery=ip',
      url: `https://rdap.org/ip/${ip}`,
    });
  }

  for (const h of tlsSanHosts.slice(0, 20)) {
    if (h === domain || h.endsWith(`.${domain}`)) continue;
    hints.push({
      type: 'asset',
      prio: 'med',
      score: 60,
      value: `Potential related asset from SAN: ${h}`,
      meta: 'asset_discovery=tls_san • validate scope',
      url: `https://${h}/`,
    });
  }

  return hints;
}

export function detectTakeoverCandidates(findings = []) {
  const out = [];
  for (const f of findings) {
    if (f?.type !== 'subdomain') continue;
    const meta = String(f.meta || '').toLowerCase();
    if (/github\.io|herokudns|azurewebsites\.net|fastly|cloudfront|s3-website/.test(meta)) {
      out.push({
        type: 'takeover',
        prio: 'med',
        score: 66,
        value: `Potential subdomain takeover candidate: ${f.value}`,
        meta: 'takeover_candidate=provider_cname • confirmar dangling DNS',
        url: f.url || null,
      });
    }
  }
  return out;
}
