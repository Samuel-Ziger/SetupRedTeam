import { UA, limits, interestingPathRe, sensitiveExtRe } from '../config.js';

export async function fetchWaybackUrls(domain) {
  const u = `https://web.archive.org/cdx/search/cdx?url=*.${encodeURIComponent(domain)}/*&output=json&fl=original&collapse=urlkey&filter=statuscode:200&limit=${limits.waybackCollapseLimit}`;
  const res = await fetch(u, {
    headers: { 'User-Agent': UA },
    signal: AbortSignal.timeout(120000),
  });
  if (!res.ok) throw new Error(`Wayback CDX HTTP ${res.status}`);
  const data = await res.json();
  if (!Array.isArray(data) || data.length < 2) return [];
  return [...new Set(data.slice(1).map((row) => row[0]).filter(Boolean))];
}

export function filterInterestingUrls(urls) {
  return urls.filter((url) => {
    try {
      const p = new URL(url).pathname;
      if (interestingPathRe.test(p)) return true;
      if (sensitiveExtRe.test(p)) return true;
      if (/\/(api|admin|login)/i.test(p)) return true;
    } catch {
      return false;
    }
    return false;
  });
}

export function extractJsUrls(urls, limit = 80) {
  const js = urls.filter((u) => /\.js(\?|$)/i.test(u));
  return [...new Set(js)].slice(0, limit);
}
