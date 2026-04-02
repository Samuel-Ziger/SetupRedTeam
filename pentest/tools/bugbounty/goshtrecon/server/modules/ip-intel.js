import dns from 'node:dns/promises';

/**
 * Resolve IPv4 únicos para uma lista de hosts (amostra limitada).
 */
export async function collectUniqueIpv4(hosts, maxHosts = 12, maxIps = 10) {
  const ips = new Set();
  for (const h of (hosts || []).slice(0, maxHosts)) {
    if (!h || typeof h !== 'string') continue;
    try {
      const r4 = await dns.resolve4(h.trim());
      for (const ip of r4) {
        ips.add(ip);
        if (ips.size >= maxIps) return [...ips];
      }
    } catch {
      /* ignore */
    }
  }
  return [...ips];
}

/**
 * Lookup passivo Shodan (GET /shodan/host/{ip}) — requer SHODAN_API_KEY.
 */
export async function shodanHostSummary(ip, apiKey) {
  const key = String(apiKey || '').trim();
  if (!key) return { ok: false, note: 'SHODAN_API_KEY em falta' };

  const url = `https://api.shodan.io/shodan/host/${encodeURIComponent(ip)}?key=${encodeURIComponent(key)}`;
  const res = await fetch(url, { signal: AbortSignal.timeout(15000) });
  if (!res.ok) {
    return { ok: false, note: `Shodan HTTP ${res.status}` };
  }
  const j = await res.json();

  const hostnames = Array.isArray(j.hostnames) ? j.hostnames.slice(0, 8) : [];
  const ports = Array.isArray(j.ports) ? j.ports.slice(0, 20) : [];
  const org = j.org || j.isp || '';
  const vulner = Array.isArray(j.vulns) ? j.vulns.slice(0, 5) : [];

  return {
    ok: true,
    ip,
    org,
    hostnames,
    ports,
    vulns: vulner,
    rawCount: Array.isArray(j.data) ? j.data.length : ports.length,
  };
}
