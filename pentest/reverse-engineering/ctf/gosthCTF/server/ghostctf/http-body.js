import zlib from 'node:zlib';

/** HTTP :80 / HTTPS :443 omitidos (menos confusão; igual à barra de endereços). */
export function stripDefaultPortsFromUrl(href) {
  try {
    const u = new URL(String(href || ''));
    if (u.protocol === 'http:' && u.port === '80') u.port = '';
    else if (u.protocol === 'https:' && u.port === '443') u.port = '';
    return u.href;
  } catch {
    return String(href || '');
  }
}

/**
 * Segue encadeamento de cabeçalhos `-D` do curl com `-L` (vários blocos HTTP).
 * Devolve o URL final para resolver href relativos correctamente.
 */
export function effectiveUrlAfterRedirects(requestUrl, fullHeadersDump) {
  let u = stripDefaultPortsFromUrl(String(requestUrl || ''));
  const blocks = String(fullHeadersDump || '')
    .split(/\r?\n\r?\n/)
    .map((b) => b.trim())
    .filter(Boolean);
  for (const block of blocks) {
    const m = block.match(/^Location:\s*(.+)$/im);
    if (!m) continue;
    const loc = m[1].trim().replace(/\r$/, '');
    if (!loc) continue;
    try {
      u = new URL(loc, u).href;
    } catch {
      break;
    }
  }
  return stripDefaultPortsFromUrl(u);
}

/**
 * Corpo gravado em ficheiro pelo curl: gzip/deflate/br ou texto UTF-8.
 */
export function decodeBodyBufferToUtf8(bodyBuf, lastHeaderBlockText) {
  if (!bodyBuf || !bodyBuf.length) return '';
  const heads = String(lastHeaderBlockText || '').toLowerCase();
  const encLine = heads.match(/content-encoding:\s*([^\s]+)/i);
  const enc = encLine ? encLine[1].trim() : '';

  if (enc === 'gzip' || (bodyBuf[0] === 0x1f && bodyBuf[1] === 0x8b)) {
    try {
      return zlib.gunzipSync(bodyBuf).toString('utf8');
    } catch {
      /* continua para utf8 */
    }
  }
  if (enc === 'deflate' || enc === 'x-deflate') {
    try {
      return zlib.inflateSync(bodyBuf).toString('utf8');
    } catch {
      try {
        return zlib.inflateRawSync(bodyBuf).toString('utf8');
      } catch {
        /* */
      }
    }
  }
  if (enc === 'br') {
    try {
      if (typeof zlib.brotliDecompressSync === 'function') {
        return zlib.brotliDecompressSync(bodyBuf).toString('utf8');
      }
    } catch {
      /* */
    }
  }

  return bodyBuf.toString('utf8');
}

/** Janela maior que 16k: páginas com <head>/scripts longos tinham o primeiro <a> fora do slice e o crawl era ignorado. */
const HTMLISH_SCAN_MAX = 500_000;

export function bodyLooksHtmlish(text) {
  const full = String(text || '');
  if (full.length < 6) return false;
  const s = full.length <= HTMLISH_SCAN_MAX ? full : full.slice(0, HTMLISH_SCAN_MAX);
  return (
    /<(html|head|body|!DOCTYPE|a[\s>]|div[\s>]|span[\s>]|nav[\s>]|ul[\s>]|\?php)/i.test(s) ||
    /\bhref\s*=/i.test(s) ||
    /<\s*link\s+/i.test(s)
  );
}
