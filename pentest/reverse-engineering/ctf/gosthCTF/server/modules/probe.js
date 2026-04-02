import { UA, limits } from '../config.js';
import { detectTech } from './tech.js';

function extractTitle(html) {
  const m = html.match(/<title[^>]*>([^<]{0,300})/i);
  return m ? m[1].trim().replace(/\s+/g, ' ') : '';
}

/** Cabeçalhos relevantes para análise de superfície (sem armazenar corpo). */
export function snapshotSecurityHeaders(headers) {
  const get = (n) => headers.get(n) || '';
  const snap = {
    strictTransportSecurity: get('strict-transport-security'),
    contentSecurityPolicy: get('content-security-policy'),
    xFrameOptions: get('x-frame-options'),
    xContentTypeOptions: get('x-content-type-options'),
    permissionsPolicy: get('permissions-policy'),
    referrerPolicy: get('referrer-policy'),
    crossOriginOpenerPolicy: get('cross-origin-opener-policy'),
    crossOriginEmbedderPolicy: get('cross-origin-embedder-policy'),
    server: get('server'),
    setCookieSample: [],
  };
  if (typeof headers.getSetCookie === 'function') {
    snap.setCookieSample = headers.getSetCookie().slice(0, 6);
  } else {
    const sc = get('set-cookie');
    if (sc) snap.setCookieSample = [sc];
  }
  return snap;
}

export async function probeHttp(url) {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), limits.probeTimeoutMs);
  try {
    const res = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: {
        'User-Agent': UA,
        Accept: 'text/html,application/xhtml+xml,*/*;q=0.8',
      },
    });
    const buf = await res.arrayBuffer();
    const slice = buf.byteLength > limits.maxBodySnippet ? buf.slice(0, limits.maxBodySnippet) : buf;
    const text = new TextDecoder('utf-8', { fatal: false }).decode(slice);
    const title = extractTitle(text);
    const tech = detectTech(res.headers, text);
    const securityHeaders = snapshotSecurityHeaders(res.headers);
    return {
      ok: true,
      url: res.url,
      status: res.status,
      title,
      tech,
      securityHeaders,
    };
  } catch (e) {
    return {
      ok: false,
      url,
      error: e.name === 'AbortError' ? 'timeout' : String(e.message || e),
    };
  } finally {
    clearTimeout(t);
  }
}

export async function mapPool(items, concurrency, fn) {
  const results = [];
  let i = 0;
  async function worker() {
    while (i < items.length) {
      const idx = i++;
      results[idx] = await fn(items[idx], idx);
    }
  }
  const workers = Array.from({ length: Math.min(concurrency, items.length) }, () => worker());
  await Promise.all(workers);
  return results;
}
