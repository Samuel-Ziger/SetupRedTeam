import { UA } from '../config.js';

/**
 * Passivo: Certificate Transparency via crt.sh
 */
export async function fetchCrtShSubdomains(domain) {
  const url = `https://crt.sh/?q=%25.${encodeURIComponent(domain)}&output=json`;
  const res = await fetch(url, {
    headers: { 'User-Agent': UA, Accept: 'application/json' },
    signal: AbortSignal.timeout(90000),
  });
  if (!res.ok) throw new Error(`crt.sh HTTP ${res.status}`);
  const rows = await res.json();
  if (!Array.isArray(rows)) return [];

  const set = new Set();
  for (const row of rows) {
    const name = row.name_value;
    if (!name) continue;
    for (const part of String(name).split('\n')) {
      const h = part.trim().toLowerCase().replace(/^\*\./, '');
      if (h.endsWith(domain.toLowerCase()) || h === domain.toLowerCase()) {
        set.add(h);
      }
    }
  }
  return [...set].sort();
}
