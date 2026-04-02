import { UA } from '../config.js';

/**
 * Google Programmable Search (Custom Search JSON API) — forma suportada pelo Google
 * de obter URLs a partir de queries tipo dork (sem scraping da página HTML do Google).
 *
 * Requer GOOGLE_CSE_KEY + GOOGLE_CSE_CX e motor de pesquisa configurado em
 * https://programmablesearchengine.google.com/ (podes usar "Search the entire web").
 */
export async function googleCseSearch(query, apiKey, cx) {
  const u = new URL('https://www.googleapis.com/customsearch/v1');
  u.searchParams.set('key', apiKey);
  u.searchParams.set('cx', cx);
  u.searchParams.set('q', query);
  u.searchParams.set('num', '10');

  const res = await fetch(u.toString(), {
    headers: { 'User-Agent': UA },
    signal: AbortSignal.timeout(45000),
  });

  const text = await res.text();
  if (!res.ok) {
    let msg = `HTTP ${res.status}`;
    try {
      const j = JSON.parse(text);
      if (j.error?.message) msg = j.error.message;
    } catch {
      msg = text.slice(0, 200);
    }
    throw new Error(msg);
  }

  const data = JSON.parse(text);
  const items = data.items || [];
  return items.map((it) => ({
    link: it.link,
    title: it.title || '',
    snippet: it.snippet || '',
  }));
}

export function urlMatchesTarget(urlStr, domain) {
  const d = domain.toLowerCase();
  try {
    const h = new URL(urlStr).hostname.toLowerCase();
    return h === d || h.endsWith(`.${d}`);
  } catch {
    return false;
  }
}
