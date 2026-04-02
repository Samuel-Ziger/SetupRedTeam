import { UA, limits } from '../config.js';

/**
 * Subdomínios reportados pelo VirusTotal (requer API key).
 */
export async function fetchVirustotalSubdomains(domain, apiKey) {
  if (!apiKey?.trim()) {
    return { ok: false, note: 'defina VIRUSTOTAL_API_KEY', items: [] };
  }
  const maxTotal = limits.virustotalSubdomainMax;
  const out = new Set();
  let url = `https://www.virustotal.com/api/v3/domains/${encodeURIComponent(domain)}/subdomains?limit=40`;

  while (url && out.size < maxTotal) {
    const res = await fetch(url, {
      headers: { 'x-apikey': apiKey.trim(), 'User-Agent': UA },
      signal: AbortSignal.timeout(22000),
    });
    if (res.status === 401 || res.status === 403) {
      return { ok: false, note: 'VirusTotal: chave inválida ou sem permissão', items: [] };
    }
    if (res.status === 429) {
      return { ok: false, note: 'VirusTotal: rate limit (429)', items: [...out] };
    }
    if (!res.ok) {
      return { ok: false, note: `VirusTotal HTTP ${res.status}`, items: [...out] };
    }
    const j = await res.json();
    for (const it of j.data || []) {
      const id = it.id;
      if (id) out.add(String(id).toLowerCase());
      if (out.size >= maxTotal) break;
    }
    url = j.links?.next || null;
  }

  return { ok: true, items: [...out].slice(0, maxTotal) };
}
