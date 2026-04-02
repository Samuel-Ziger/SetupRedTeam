/**
 * Extração leve de href/action a partir de HTML (superfície passiva).
 */
export function extractHtmlSurface(html, baseUrl, opts = {}) {
  const maxLinks = opts.maxLinks ?? 48;
  const maxForms = opts.maxForms ?? 16;
  const links = new Set();
  const formActions = new Set();

  const s = String(html || '');
  const hrefRe = /href\s*=\s*["']([^"'<>]+)["']/gi;
  let m;
  while ((m = hrefRe.exec(s)) !== null && links.size < maxLinks) {
    const raw = m[1].trim();
    if (!raw || raw.startsWith('javascript:') || raw.startsWith('mailto:') || raw.startsWith('#')) continue;
    try {
      const abs = new URL(raw, baseUrl).href;
      if (/^https?:\/\//i.test(abs)) links.add(abs);
    } catch {
      /* ignore */
    }
  }

  const actRe = /<form[^>]*\saction\s*=\s*["']([^"'<>]+)["']/gi;
  while ((m = actRe.exec(s)) !== null && formActions.size < maxForms) {
    const raw = m[1].trim();
    if (!raw) continue;
    try {
      formActions.add(new URL(raw, baseUrl).href);
    } catch {
      /* ignore */
    }
  }

  return { links: [...links], formActions: [...formActions] };
}
