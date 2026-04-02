import { curlWebSingle } from './web-curl-single.js';

/** @typedef {{ pathPattern: string, extras: string[], rawLine: string }} RobotsDisallowEntry */

/**
 * Extrai linhas Disallow: do robots.txt. O primeiro token após os dois-pontos é o path;
 * tokens extra (ex.: chave após `/book_to_read.txt`) ficam em `extras`.
 * @param {string} bodyText
 * @returns {RobotsDisallowEntry[]}
 */
export function extractRobotsDisallowEntries(bodyText) {
  const out = [];
  const lines = String(bodyText || '').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = String(line || '').trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const m = trimmed.match(/^disallow:\s*(.*)$/i);
    if (!m) continue;
    const rest = String(m[1] || '').trim();
    if (!rest) continue;
    const tokens = rest.split(/\s+/).filter(Boolean);
    if (!tokens.length) continue;
    const pathPattern = tokens[0];
    const extras = tokens.slice(1);
    out.push({ pathPattern, extras, rawLine: trimmed });
  }
  return out;
}

function disallowPatternToUrl(origin, pathPattern) {
  const o = String(origin || '').replace(/\/$/, '');
  let p = String(pathPattern || '').trim();
  if (!p) return null;
  if (!p.startsWith('/')) p = `/${p}`;
  try {
    return new URL(p, `${o}/`).href;
  } catch {
    return null;
  }
}

function compactBodyPreview(text, maxChars = 360) {
  const one = String(text || '')
    .replace(/\s+/g, ' ')
    .trim();
  if (!one) return '';
  return one.length > maxChars ? `${one.slice(0, maxChars)}…` : one;
}

/**
 * GET nos paths indicados em Disallow (mesma origem do robots.txt).
 * @param {object} opts
 * @param {string} opts.origin ex. https://host:8443
 * @param {string} opts.robotsUrl URL completa do robots (para logs)
 * @param {string} opts.bodyText corpo do robots.txt
 * @param {unknown[]} opts.webResponses array mutável
 * @param {Function} [opts.log]
 * @param {number} [opts.timeoutMs]
 * @param {number} [opts.maxBodyBytes]
 * @param {number} [opts.maxUrls]
 */
async function fetchDisallowPathsFromRobots({
  origin,
  robotsUrl,
  bodyText,
  webResponses,
  log,
  timeoutMs = 10000,
  maxBodyBytes = 220000,
  maxUrls = 28,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const entries = extractRobotsDisallowEntries(bodyText);
  if (!entries.length) return { fetched: 0, tried: 0 };

  /** @type {Set<string>} */
  const seen = new Set();
  let fetched = 0;
  let tried = 0;

  for (const ent of entries) {
    if (tried >= maxUrls) break;
    const targetUrl = disallowPatternToUrl(origin, ent.pathPattern);
    if (!targetUrl || !/^https?:\/\//i.test(targetUrl)) continue;
    if (seen.has(targetUrl)) continue;
    seen.add(targetUrl);
    tried += 1;

    if (ent.extras.length) {
      const extra = ent.extras.join(' ');
      logger(
        `robots.txt Disallow “${ent.pathPattern}” tem texto extra na linha — ${extra.slice(0, 200)}${extra.length > 200 ? '…' : ''}`,
        'find',
      );
    }

    try {
      logger(`[http] robots Disallow → GET ${targetUrl} (robots=${robotsUrl} · path=${ent.pathPattern})`, 'info');
      const resp = await curlWebSingle({ url: targetUrl, timeoutMs, maxBodyBytes });
      resp.__via = 'robots-disallow';
      resp.__robotsSource = robotsUrl;
      resp.__disallowPath = ent.pathPattern;
      resp.__robotsDisallowLine = ent.rawLine;
      webResponses.push(resp);

      const st = resp.status || 0;
      const preview = compactBodyPreview(resp.bodyText || '', 380);
      if (st === 200) {
        fetched += 1;
        logger(
          `robots Disallow: OK (200) — ${targetUrl}${preview ? ` · corpo: ${preview}` : ''}`,
          'success',
        );
      } else if (st) {
        logger(
          `robots Disallow: HTTP ${st} — ${targetUrl}${preview ? ` · corpo: ${preview}` : ''}`,
          st === 403 || st === 401 ? 'warn' : 'info',
        );
      } else {
        logger(`robots Disallow: sem status — ${targetUrl}`, 'info');
      }
    } catch (e) {
      logger(`robots Disallow: erro ${targetUrl} — ${e?.message || e}`, 'info');
    }
  }

  return { fetched, tried };
}

function compactRobotsPreview(bodyText, maxLines = 12, maxChars = 420) {
  const lines = String(bodyText || '')
    .split(/\r?\n/)
    .map((x) => String(x || '').trim())
    .filter((x) => x && !x.startsWith('#'))
    .slice(0, Math.max(1, maxLines));
  const joined = lines.join(' | ');
  if (!joined) return '';
  return joined.length > maxChars ? `${joined.slice(0, maxChars)}...` : joined;
}

/**
 * Para cada origem (protocolo + host:porta) onde já houve resposta HTTP no recon,
 * pede `/robots.txt`. Se não houver origens (curl falhou em tudo), tenta
 * `http://IP/robots.txt` (sem duplicar https no fallback), salvo `skipIpFallback`:
 * aí pode usar-se `originHostFallbacks` (ex. nomes /etc/hosts) em vez do IP.
 * Só acrescenta ao array quando o servidor responde **200** (ficheiro existe).
 */
export async function appendRobotsTxtResponses(webResponses, {
  ip,
  log,
  timeoutMs = 10000,
  maxBodyBytes = 128000,
  followDisallow = true,
  disallowTimeoutMs,
  disallowMaxBodyBytes,
  maxDisallowUrls = 28,
  /** Se true, não faz fallback `http://IP/robots.txt` quando não há origens (ex.: modo só hostnames). */
  skipIpFallback = false,
  /**
   * Com `skipIpFallback` e sem origens nas respostas: tentar `http://<host>/robots.txt`
   * para estes nomes (ex. lista /etc/hosts), em vez do IP.
   */
  originHostFallbacks = [],
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  /** @type {Set<string>} */
  const origins = new Set();

  for (const r of webResponses || []) {
    if (!r?.url || !r.status) continue;
    try {
      const u = new URL(String(r.url));
      origins.add(`${u.protocol}//${u.host}`);
    } catch {
      /* ignorar */
    }
  }

  if (origins.size === 0 && ip && !skipIpFallback) origins.add(`http://${ip}`);
  if (origins.size === 0 && skipIpFallback && Array.isArray(originHostFallbacks)) {
    for (const h of originHostFallbacks) {
      const hh = String(h || '').trim().toLowerCase();
      if (!hh) continue;
      origins.add(`http://${hh}`);
    }
  }

  const tried = new Set();
  let fetched = 0;
  let disallowFetched = 0;

  for (const origin of origins) {
    const base = String(origin).replace(/\/$/, '');
    const robotsUrl = `${base}/robots.txt`;
    if (tried.has(robotsUrl)) continue;
    tried.add(robotsUrl);

    try {
      logger(`[http] robots.txt GET ${robotsUrl}`, 'info');
      const resp = await curlWebSingle({ url: robotsUrl, timeoutMs, maxBodyBytes });
      if (resp.status === 200) {
        resp.__via = 'robots.txt';
        webResponses.push(resp);
        fetched += 1;
        logger(`robots.txt: OK (200) — ${robotsUrl}`, 'success');
        const preview = compactRobotsPreview(resp.bodyText, 12, 420);
        if (preview) logger(`robots.txt conteúdo: ${preview}`, 'find');
        else logger('robots.txt conteúdo: (vazio ou só comentários)', 'info');

        if (followDisallow) {
          const d = await fetchDisallowPathsFromRobots({
            origin: base,
            robotsUrl,
            bodyText: resp.bodyText,
            webResponses,
            log: logger,
            timeoutMs: disallowTimeoutMs ?? Math.max(timeoutMs, 12000),
            maxBodyBytes: disallowMaxBodyBytes ?? Math.max(maxBodyBytes, 180000),
            maxUrls: maxDisallowUrls,
          });
          disallowFetched += Number(d.fetched || 0);
          if (Number(d.tried || 0) > 0) {
            logger(
              `robots Disallow: ${d.tried} URL(s) testada(s) · ${d.fetched} com HTTP 200`,
              'info',
            );
          }
        }
      } else {
        logger(`robots.txt: sem ficheiro ou negado — HTTP ${resp.status || '?'} @ ${robotsUrl}`, 'info');
      }
    } catch (e) {
      logger(`robots.txt: erro @ ${robotsUrl} — ${e?.message || e}`, 'info');
    }
  }

  return { fetched, disallowFetched };
}
