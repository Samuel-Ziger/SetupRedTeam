import { limits } from '../config.js';
import { detectTech } from './tech.js';
import { extractHtmlSurface } from './html-surface.js';
import { stealthPause, pickStealthUserAgent } from './request-policy.js';

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

function buildRequestHeaders(auth, modules = []) {
  const h = {
    'User-Agent': pickStealthUserAgent(modules),
    Accept: 'text/html,application/xhtml+xml,*/*;q=0.8',
  };
  if (auth?.headers && typeof auth.headers === 'object') {
    for (const [k, v] of Object.entries(auth.headers)) {
      if (!k || v == null) continue;
      h[String(k)] = String(v);
    }
  }
  if (auth?.cookie) h.Cookie = String(auth.cookie);
  return h;
}

function detectWaf(headers, bodySnippet = '') {
  const blob = [
    headers.get('server') || '',
    headers.get('x-sucuri-id') || '',
    headers.get('cf-ray') || '',
    headers.get('x-akamai-request-id') || '',
    headers.get('x-cdn') || '',
    bodySnippet.slice(0, 1200),
  ]
    .join(' ')
    .toLowerCase();
  if (/cloudflare|cf-ray/.test(blob)) return 'cloudflare';
  if (/akamai/.test(blob)) return 'akamai';
  if (/sucuri/.test(blob)) return 'sucuri';
  if (/imperva|incapsula/.test(blob)) return 'imperva';
  if (/aws\s*waf|awselb/.test(blob)) return 'aws-waf';
  return '';
}

export async function probeHttp(url, opts = {}) {
  const { auth, modules = [] } = opts;
  await stealthPause(modules);
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), limits.probeTimeoutMs);
  try {
    const res = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: buildRequestHeaders(auth, modules),
    });
    const buf = await res.arrayBuffer();
    const slice = buf.byteLength > limits.maxBodySnippet ? buf.slice(0, limits.maxBodySnippet) : buf;
    const text = new TextDecoder('utf-8', { fatal: false }).decode(slice);
    const title = extractTitle(text);
    const tech = detectTech(res.headers, text);
    const securityHeaders = snapshotSecurityHeaders(res.headers);
    const waf = detectWaf(res.headers, text);
    const ct = res.headers.get('content-type') || '';
    let surface = null;
    if (/text\/html|application\/xhtml/i.test(ct)) {
      try {
        surface = extractHtmlSurface(text, res.url);
      } catch {
        surface = null;
      }
    }
    return {
      ok: true,
      url: res.url,
      status: res.status,
      title,
      tech,
      waf,
      securityHeaders,
      surface,
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
