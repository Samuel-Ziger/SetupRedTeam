/**
 * Extrai produto + versão a partir de headers e HTML (heurístico).
 */
export function parseVersionsFromServerHeader(server) {
  const s = String(server || '');
  if (!s) return [];
  const out = [];
  const parts = s.split(/,\s*/);
  for (const p of parts) {
    const m = p.trim().match(/^([a-zA-Z][a-zA-Z0-9._-]*)\/(\d+\.\d+(?:\.\d+)?(?:[a-z0-9.-]*)?)/);
    if (m) out.push({ product: m[1], version: m[2], raw: p.trim() });
  }
  return out;
}

export function parseGeneratorMeta(html) {
  const m = String(html || '').match(/<meta[^>]+name=["']generator["'][^>]+content=["']([^"']+)["']/i);
  if (!m) return null;
  const c = m[1];
  const vm = c.match(/([\w\s]+)\s+(\d+\.\d+(?:\.\d+)?)/);
  if (vm) return { product: vm[1].trim(), version: vm[2], raw: c };
  return { product: c, version: null, raw: c };
}

/**
 * Enriquece lista detectTech com linhas de versão explícitas.
 */
export function enrichTechWithVersions(headers, bodySnippet, existingList) {
  const list = [...(existingList || [])];
  const server = headers.get('server');
  for (const v of parseVersionsFromServerHeader(server)) {
    list.push(`${v.product}/${v.version} (banner)`);
  }
  const gen = parseGeneratorMeta(bodySnippet);
  if (gen?.version) list.push(`Generator: ${gen.product} ${gen.version}`);
  else if (gen) list.push(`Generator: ${gen.raw}`);
  return [...new Set(list)];
}
