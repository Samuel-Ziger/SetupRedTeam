import { UA, limits } from '../config.js';

/**
 * URLs históricas via índice CDX do Common Crawl (complemento ao Wayback).
 */
export async function fetchCommonCrawlUrls(domain) {
  const collRes = await fetch('https://index.commoncrawl.org/collinfo.json', {
    headers: { 'User-Agent': UA },
    signal: AbortSignal.timeout(limits.commonCrawlCollinfoTimeoutMs),
  });
  if (!collRes.ok) throw new Error(`Common Crawl collinfo HTTP ${collRes.status}`);
  const colls = await collRes.json();
  if (!Array.isArray(colls) || colls.length === 0) throw new Error('collinfo vazio');

  const main =
    colls.find((c) => c?.id && String(c.id).startsWith('CC-MAIN-')) ||
    colls.find((c) => c?.id) ||
    colls[0];
  const apiBase =
    process.env.GHOSTCTF_CC_CDX_API?.trim() ||
    process.env.GHOSTRECON_CC_CDX_API?.trim() ||
    main['cdx-api'] ||
    (main.id ? `https://index.commoncrawl.org/${main.id}-index` : null);
  if (!apiBase) throw new Error('índice CC inválido');

  const lim = Math.min(20000, Math.max(100, limits.commonCrawlLimit));
  const urlParam = `*.${domain}/*`;
  const q = `${apiBase}?url=${encodeURIComponent(urlParam)}&output=json&filter=status:200&limit=${lim}`;

  const res = await fetch(q, {
    headers: { 'User-Agent': UA },
    signal: AbortSignal.timeout(limits.commonCrawlQueryTimeoutMs),
  });
  if (!res.ok) throw new Error(`Common Crawl CDX HTTP ${res.status}`);

  const text = await res.text();
  const out = new Set();

  const eatUrl = (u) => {
    if (typeof u === 'string' && /^https?:\/\//i.test(u)) out.add(u);
  };

  const trimmed = text.trim();
  if (trimmed.startsWith('[')) {
    try {
      const data = JSON.parse(trimmed);
      if (Array.isArray(data) && data.length > 0) {
        const head = data[0];
        if (Array.isArray(head) && head.every((x) => typeof x === 'string')) {
          const urlIdx = head.indexOf('url');
          if (urlIdx >= 0) {
            for (let i = 1; i < data.length; i++) {
              const row = data[i];
              if (Array.isArray(row) && row[urlIdx]) eatUrl(row[urlIdx]);
            }
          } else {
            for (let i = 1; i < data.length; i++) {
              const row = data[i];
              if (Array.isArray(row) && row[0]) eatUrl(row[0]);
            }
          }
        } else {
          for (const row of data) {
            if (row && typeof row === 'object' && row.url) eatUrl(row.url);
          }
        }
      }
    } catch {
      /* fall through NDJSON */
    }
  }

  if (out.size === 0) {
    for (const line of trimmed.split('\n').filter(Boolean)) {
      let row;
      try {
        row = JSON.parse(line);
      } catch {
        continue;
      }
      if (Array.isArray(row)) eatUrl(row[0]);
      else if (row?.url) eatUrl(row.url);
    }
  }

  return [...out];
}
