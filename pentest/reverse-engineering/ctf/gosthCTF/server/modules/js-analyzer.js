import { UA, limits } from '../config.js';

const PATH_PATTERNS = [
  /["'`](\/api\/[a-zA-Z0-9_\-/.{}]+)["'`]/g,
  /["'`](\/v\d\/[a-zA-Z0-9_\-/.]+)["'`]/g,
  /fetch\(\s*["'`]([^"'`]+)["'`]/g,
  /axios\.[a-z]+\(\s*["'`]([^"'`]+)["'`]/g,
  /endpoint\s*[:=]\s*["'`]([^"'`]+)["'`]/gi,
  /baseURL\s*[:=]\s*["'`]([^"'`]+)["'`]/gi,
];

export async function analyzeJsUrl(jsUrl) {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), limits.probeTimeoutMs);
  try {
    const res = await fetch(jsUrl, {
      signal: controller.signal,
      headers: { 'User-Agent': UA, Accept: '*/*' },
    });
    if (!res.ok) return { ok: false, status: res.status, endpoints: [], snippet: '' };
    const text = await res.text();
    const cap = text.length > 500_000 ? text.slice(0, 500_000) : text;
    const endpoints = new Set();
    for (const re of PATH_PATTERNS) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(cap)) !== null) {
        const p = m[1];
        if (typeof p === 'string' && p.startsWith('/') && p.length < 400) endpoints.add(p.split('?')[0]);
      }
    }
    return { ok: true, status: res.status, endpoints: [...endpoints], body: cap };
  } catch (e) {
    return { ok: false, error: e.name === 'AbortError' ? 'timeout' : String(e.message || e), endpoints: [], body: '' };
  } finally {
    clearTimeout(t);
  }
}
