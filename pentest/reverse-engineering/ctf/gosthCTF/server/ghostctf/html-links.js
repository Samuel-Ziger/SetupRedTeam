import dns from 'node:dns/promises';
import { bodyLooksHtmlish, effectiveUrlAfterRedirects } from './http-body.js';
import { curlWebSingle } from './web-curl-single.js';

export function urlDedupKey(href) {
  try {
    const u = new URL(href);
    u.hash = '';
    let path = u.pathname;
    if (path.length > 1 && path.endsWith('/')) path = path.slice(0, -1);
    u.pathname = path || '/';
    return u.href;
  } catch {
    return String(href || '');
  }
}

/** Normaliza hostname (IPv6 sem colchetes para comparação). */
export function normalizeHostname(hostname) {
  return String(hostname || '')
    .toLowerCase()
    .replace(/^\[|\]$/g, '');
}

/**
 * Hostnames já vistos nas URLs que o próprio framework pediu (IP literal,
 * nome no URL do curl, etc.).
 */
export function buildAllowedHostnames(ip, webResponses) {
  const s = new Set();
  const add = (h) => {
    const n = normalizeHostname(h);
    if (n) s.add(n);
  };
  add(ip);
  for (const r of webResponses || []) {
    try {
      add(new URL(String(r.url)).hostname);
    } catch {
      /* */
    }
  }
  return s;
}

function hostnameInSet(hostname, allowed) {
  return allowed.has(normalizeHostname(hostname));
}

/**
 * Verifica se o hostname resolve para o IP do alvo (vhost apontando ao mesmo host).
 * Resultados memorizados em dnsCache (Map string -> boolean).
 */
async function hostResolvesToTarget(hostname, targetIp, dnsCache, timeoutMs = 2000) {
  const th = normalizeHostname(targetIp);
  const hh = normalizeHostname(hostname);
  if (!th || !hh) return false;
  if (hh === th) return true;

  const key = `${hh}|${th}`;
  if (dnsCache.has(key)) return dnsCache.get(key);

  let ok = false;
  try {
    const results = await Promise.race([
      dns.lookup(hh, { all: true }),
      new Promise((_, rej) => setTimeout(() => rej(new Error('dns-timeout')), timeoutMs)),
    ]);
    for (const x of results || []) {
      const addr = normalizeHostname(x.address);
      if (addr === th || addr.replace(/^::ffff:/, '') === th) {
        ok = true;
        break;
      }
    }
  } catch {
    ok = false;
  }
  dnsCache.set(key, ok);
  return ok;
}

export function extractBaseHref(html) {
  const m = String(html).match(
    /<base\b[^>]*\bhref\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))/i,
  );
  if (!m) return null;
  const val = String(m[1] ?? m[2] ?? m[3] ?? '').trim();
  return val || null;
}

/** URL alvo para resolver links relativos (<base> tem prioridade). */
export function resolveLinkBase(pageUrl, html) {
  const baseHref = extractBaseHref(html);
  if (!baseHref) return String(pageUrl);
  try {
    return new URL(baseHref, pageUrl).href;
  } catch {
    return String(pageUrl);
  }
}

/**
 * Extrai valores brutos de href/action, iframe src, meta refresh, area href.
 */
export function extractRawUrlAttributes(html) {
  const out = [];
  const h = String(html);

  const pushRe = (re) => {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(h)) !== null) {
      const val = String(m[1] ?? m[2] ?? m[3] ?? '').trim();
      if (val) out.push(val);
    }
  };

  // href/action sem exigir \b antes (HTML minificado / edge cases)
  pushRe(/href\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>"']+))/gi);
  pushRe(/action\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>"']+))/gi);
  pushRe(/<iframe\b[^>]*\bsrc\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>"']+))/gi);
  pushRe(/<area\b[^>]*\bhref\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>"']+))/gi);
  pushRe(
    /<meta\b[^>]*\bhttp-equiv\s*=\s*["']?\s*refresh\s*["']?[^>]*\bcontent\s*=\s*["']?\s*\d+\s*;\s*(?:url|URL)\s*=\s*([^"'>\s]+)/gi,
  );
  pushRe(
    /<meta\b[^>]*\bcontent\s*=\s*["']?\s*\d+\s*;\s*(?:url|URL)\s*=\s*([^"'>\s]+)[^>]*\bhttp-equiv\s*=\s*["']?\s*refresh/gi,
  );

  return out;
}

export function decodeBasicHtmlEntities(s) {
  return String(s)
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&apos;/gi, "'")
    .replace(/&#0*39;/g, "'")
    .replace(/&#0*34;/g, '"')
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>');
}

function shouldSkipScheme(raw) {
  const low = String(raw).trim().toLowerCase();
  return (
    !low ||
    low.startsWith('#') ||
    low.startsWith('javascript:') ||
    low.startsWith('mailto:') ||
    low.startsWith('tel:') ||
    low.startsWith('data:') ||
    low.startsWith('blob:') ||
    low.startsWith('about:')
  );
}

/**
 * Resolve URLs http(s) “no âmbito” do alvo: mesmo hostname conhecido OU hostname que resolve para o IP.
 */
export async function collectInScopeHttpUrls(html, pageUrl, allowedHosts, targetIp, dnsCache) {
  const out = new Set();
  const base = resolveLinkBase(pageUrl, html);
  const rawList = extractRawUrlAttributes(html);

  for (let raw of rawList) {
    raw = decodeBasicHtmlEntities(raw).trim();
    if (shouldSkipScheme(raw)) continue;
    let abs;
    try {
      abs = new URL(raw, base);
    } catch {
      continue;
    }
    if (abs.protocol !== 'http:' && abs.protocol !== 'https:') continue;
    const host = abs.hostname;
    let inScope = hostnameInSet(host, allowedHosts);
    if (!inScope && targetIp) {
      inScope = await hostResolvesToTarget(host, targetIp, dnsCache);
      if (inScope) allowedHosts.add(normalizeHostname(host));
    }
    if (!inScope) continue;
    abs.hash = '';
    out.add(abs.href);
  }

  return [...out];
}

/** @deprecated usar collectInScopeHttpUrls; mantido para testes locais síncronos */
export function extractInScopeHttpUrls(html, baseUrl, targetIp) {
  const allowed = buildAllowedHostnames(targetIp, [{ url: baseUrl }]);
  const syncOut = new Set();
  const base = resolveLinkBase(baseUrl, html);
  for (let raw of extractRawUrlAttributes(html)) {
    raw = decodeBasicHtmlEntities(raw).trim();
    if (shouldSkipScheme(raw)) continue;
    let abs;
    try {
      abs = new URL(raw, base);
    } catch {
      continue;
    }
    if (abs.protocol !== 'http:' && abs.protocol !== 'https:') continue;
    if (!hostnameInSet(abs.hostname, allowed)) continue;
    abs.hash = '';
    syncOut.add(abs.href);
  }
  return [...syncOut];
}

/**
 * Faz curl em páginas descobertas por links no HTML (BFS por profundidade).
 * Altera webResponses in-place (push dos novos curl).
 */
function responseOkForLinkParsing(r) {
  if (!r || !r.url) return false;
  const bt = String(r.bodyText || '');
  if (bt.length < 6) return false;
  if (!bodyLooksHtmlish(bt)) return false;
  const st = Number(r.status);
  // 401/403/404 às vezes devolvem HTML com menu; gzip já vem como texto após decode no curl
  if (st >= 200 && st < 600) return true;
  if ((st === 0 || !st) && bt.length > 24) return true;
  return false;
}

export async function expandWebResponsesWithLinkCrawl(webResponses, {
  ip,
  log,
  maxDepth = 3,
  maxNewFetches = 80,
  timeoutMs = 12000,
  maxBodyBytes = 250_000,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const dnsCache = new Map();
  const allowedHosts = buildAllowedHostnames(ip, webResponses);

  const seen = new Set();
  for (const r of webResponses || []) {
    if (r?.url) seen.add(urlDedupKey(r.url));
  }

  let fetched = 0;
  let frontier = (webResponses || []).filter(responseOkForLinkParsing);

  for (let d = 0; d < maxDepth && fetched < maxNewFetches; d += 1) {
    const nextFrontier = [];
    for (const r of frontier) {
      const pageBase =
        String(r.finalUrl || '').trim() ||
        effectiveUrlAfterRedirects(String(r.url), String(r.headersText || ''));
      const links = await collectInScopeHttpUrls(
        String(r.bodyText),
        pageBase,
        allowedHosts,
        ip,
        dnsCache,
      );
      for (const link of links) {
        if (fetched >= maxNewFetches) break;
        const k = urlDedupKey(link);
        if (seen.has(k)) continue;
        seen.add(k);
        try {
          logger(`[http] link do HTML (nível ${d + 1}): ${link}`, 'info');
          const resp = await curlWebSingle({ url: link, timeoutMs, maxBodyBytes });
          fetched += 1;
          webResponses.push(resp);
          try {
            allowedHosts.add(normalizeHostname(new URL(String(resp.url)).hostname));
          } catch {
            /* */
          }
          if (responseOkForLinkParsing(resp)) nextFrontier.push(resp);
        } catch {
          /* ignorar timeouts / falhas de rede */
        }
      }
      if (fetched >= maxNewFetches) break;
    }
    frontier = nextFrontier;
  }

  return { fetched };
}
