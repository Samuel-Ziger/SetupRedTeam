/**
 * Normaliza lista de hostnames para o módulo /etc/hosts.
 * O curl web em si usa `curlWebFromNmapForHost` em web-curl.js (mesma lógica que o IP).
 */

export function normalizeExtraHostnames(raw) {
  const list = Array.isArray(raw) ? raw : String(raw || '').split(/[\n,;]+/);
  const out = [];
  const seen = new Set();
  for (const item of list) {
    const s = String(item || '')
      .trim()
      .toLowerCase()
      .replace(/^https?:\/\//, '')
      .split('/')[0]
      .split(':')[0];
    if (!s || seen.has(s)) continue;
    if (s.length > 253) continue;
    if (!/^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$/i.test(s)) continue;
    seen.add(s);
    out.push(s);
    if (out.length >= 24) break;
  }
  return out;
}
