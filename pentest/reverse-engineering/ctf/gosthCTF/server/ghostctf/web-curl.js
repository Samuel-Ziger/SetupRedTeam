import fs from 'fs';
import { mkdtemp, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { UA } from '../config.js';
import { detectTech } from '../modules/tech.js';
import { decodeBodyBufferToUtf8, effectiveUrlAfterRedirects, stripDefaultPortsFromUrl } from './http-body.js';

function parseHttpHeadersBlock(raw) {
  const out = new Map();
  const lines = String(raw || '').split(/\r?\n/).filter(Boolean);
  for (const line of lines) {
    const idx = line.indexOf(':');
    if (idx <= 0) continue;
    const k = line.slice(0, idx).trim().toLowerCase();
    const v = line.slice(idx + 1).trim();
    out.set(k, v);
  }
  return out;
}

function extractLastHeaderBlock(bufText) {
  // Em -D - + redirects, pode ter múltiplos blocos.
  const t = String(bufText || '');
  const parts = t.split(/\r?\n\r?\n/);
  // remove blocos finais vazios
  for (let i = parts.length - 1; i >= 0; i--) {
    if (parts[i].trim()) return parts[i];
  }
  return '';
}

function parseStatusCode(headersText) {
  const firstLine = String(headersText || '').split(/\r?\n/)[0] || '';
  // curl com HTTP/2 usa "HTTP/2 200", não "HTTP/1.1 200"
  const m = firstLine.match(/HTTP\/\d(?:\.\d)?\s+(\d{3})\b/i);
  return m ? Number(m[1]) : null;
}

async function runCurl({ url: urlIn, timeoutMs = 12000, maxBodyBytes = 250_000 }) {
  const url = stripDefaultPortsFromUrl(urlIn);
  const dir = await mkdtemp(join(tmpdir(), 'ghcurl-'));
  const headersPath = join(dir, 'headers.txt');
  const bodyPath = join(dir, 'body.bin');

  // -k: ignora TLS invalid (muitos CTFs têm cert self-signed)
  // --compressed: pede/descomprime gzip (senão o ficheiro -o pode vir binário e o HTML “some”)
  // -L: segue redirects (path final correcto para href relativos)
  const args = [
    '-k',
    '-sS',
    '--compressed',
    '-L',
    '--max-redirs',
    '8',
    '--connect-timeout',
    String(Math.max(1, Math.floor(timeoutMs / 1000))),
    '--max-time',
    String(Math.max(1, Math.floor(timeoutMs / 1000))),
    '-A',
    UA,
    '-D',
    headersPath,
    '-o',
    bodyPath,
    url,
  ];

  const { spawn } = await import('node:child_process');
  const proc = await new Promise((resolve, reject) => {
    const child = spawn('curl', args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const errChunks = [];
    child.stderr.on('data', (d) => errChunks.push(d));
    child.on('error', reject);
    child.on('close', (code) => {
      resolve({ code, stderr: Buffer.concat(errChunks).toString('utf8') });
    });
  });

  let headersText = '';
  let bodyBuf = Buffer.alloc(0);
  try {
    headersText = await fs.promises.readFile(headersPath, 'utf8');
    bodyBuf = await fs.promises.readFile(bodyPath);
  } catch {
    // ignore
  } finally {
    await rm(dir, { recursive: true, force: true });
  }

  const lastHeaders = extractLastHeaderBlock(headersText);
  const headersMap = parseHttpHeadersBlock(lastHeaders);
  const status = parseStatusCode(lastHeaders);
  const finalUrl = effectiveUrlAfterRedirects(url, headersText);

  const bodySlice = bodyBuf.length > maxBodyBytes ? bodyBuf.slice(0, maxBodyBytes) : bodyBuf;
  const bodyText = decodeBodyBufferToUtf8(bodySlice, lastHeaders);
  const techHints = detectTech(
    {
      get: (n) => headersMap.get(String(n || '').toLowerCase()) || '',
    },
    bodyText,
  );

  return {
    ok: true,
    url,
    finalUrl,
    status: status ?? 0,
    headersText,
    headers: headersMap,
    bodyText,
    tech: techHints,
    curlExitCode: proc.code,
    curlStderr: proc.stderr || '',
  };
}

function isProbablyWebPort(port) {
  const p = Number(port);
  if (!Number.isFinite(p)) return false;
  return [80, 443, 8000, 8008, 8080, 8081, 8088, 8443, 9443, 3000, 5000, 5001, 8888].includes(p);
}

function isProbablyHttpService(name, product) {
  const s = `${name || ''} ${product || ''}`.toLowerCase();
  return s.includes('http') || s.includes('https') || s.includes('nginx') || s.includes('apache') || s.includes('ssl/http');
}

/** Uma porta → um esquema: TLS explícito ou 443/8443 → https; caso contrário http (sem duplicar os dois na mesma porta). */
export function rowPrefersHttps(port, name, product, extrainfo) {
  const p = Number(port);
  // Na 80 o browser e a maioria dos CTFs falam HTTP; nmap "ssl/http" na 80 gerava https://IP:80/ (inútil e falha link crawl).
  if (p === 80) return false;
  const s = `${name || ''} ${product || ''} ${extrainfo || ''}`.toLowerCase();
  if (p === 443 || p === 8443) return true;
  if (/\bssl\b|https|tls/.test(s)) return true;
  return false;
}

/**
 * URL canónica para IP ou hostname; 80/443 sem :porto no texto.
 * Mesma regra para `1.2.3.4` e `challenge.ctf`.
 */
export function webOriginUrlForTarget(host, port, useHttps) {
  const h = String(host || '').trim();
  const p = Number(port);
  if (useHttps) {
    if (p === 443) return `https://${h}/`;
    return `https://${h}:${p}/`;
  }
  if (p === 80) return `http://${h}/`;
  return `http://${h}:${p}/`;
}

/** @deprecated use webOriginUrlForTarget — mantido para imports antigos */
export function webOriginUrl(ip, port, useHttps) {
  return webOriginUrlForTarget(ip, port, useHttps);
}

/**
 * Curl nas mesmas portas web que o nmap sugere — **idêntico** para IP ou hostname.
 * O nmap corre sempre contra o IP; as portas aplicam-se ao hostname via /etc/hosts.
 */
const DEFAULT_WEB_PORT_TRIES = [
  { port: 80, https: false },
  { port: 443, https: true },
  { port: 8080, https: false },
  { port: 8081, https: false },
  { port: 8000, https: false },
  { port: 8443, https: true },
];

export async function curlWebFromNmapForHost({
  host,
  nmapRows,
  timeoutMs,
  maxBodyBytes,
  log,
  /** Só para o log (ex.: mesmo host com contexto diferente). */
  hostLabel,
  /**
   * Se true, junta sempre a lista de portas HTTP “típicas” às inferidas do nmap
   * (útil no modo só hostnames: o nmap pode não classificar um serviço como http).
   */
  alwaysIncludeDefaultWebPorts = false,
} = {}) {
  const label = hostLabel != null ? String(hostLabel) : String(host || '');
  const webCandidates = [];
  const seen = new Set();

  for (const r of nmapRows || []) {
    if (String(r.proto).toLowerCase() !== 'tcp') continue;
    const port = Number(r.port);
    if (!Number.isFinite(port)) continue;

    const name = r.name || '';
    const product = r.product || '';
    const extra = r.extrainfo || '';
    if (!isProbablyWebPort(port) && !isProbablyHttpService(name, product) && !isProbablyHttpService(extra, name)) continue;

    const https = rowPrefersHttps(port, name, product, extra);
    const u = webOriginUrlForTarget(host, port, https);
    if (seen.has(u)) continue;
    seen.add(u);
    webCandidates.push({ url: u, port, portName: name, proto: 'tcp' });
  }

  if (!webCandidates.length || alwaysIncludeDefaultWebPorts) {
    for (const d of DEFAULT_WEB_PORT_TRIES) {
      const u = webOriginUrlForTarget(host, d.port, d.https);
      if (seen.has(u)) continue;
      seen.add(u);
      webCandidates.push({ url: u, port: d.port, proto: 'tcp' });
    }
  }

  const seedRoot = `http://${host}/`;
  if (!seen.has(seedRoot)) {
    seen.add(seedRoot);
    webCandidates.unshift({ url: seedRoot, port: 80, portName: 'seed-http-root', proto: 'tcp' });
  }

  const saneCandidates = webCandidates.filter((c) => {
    try {
      const u = new URL(String(c.url));
      if (u.protocol !== 'https:') return true;
      const p = u.port;
      return p !== '80';
    } catch {
      return true;
    }
  });

  const out = [];
  for (const c of saneCandidates) {
    try {
      if (typeof log === 'function') {
        log(
          `[http] GET ${c.url} · alvo=${label} (repro: curl -k -sS --compressed -L '${c.url}')`,
          'info',
        );
      }
      const r = await runCurl({ url: c.url, timeoutMs, maxBodyBytes });
      out.push({
        port: c.port,
        url: c.url,
        finalUrl: r.finalUrl || c.url,
        status: r.status,
        headersText: r.headersText,
        bodyText: r.bodyText,
        tech: r.tech,
      });
    } catch (e) {
      out.push({ port: c.port, url: c.url, status: 0, headersText: '', bodyText: '', tech: [] });
    }
  }

  return out;
}

export async function curlWebFromNmap({ ip, nmapRows, timeoutMs, maxBodyBytes, log }) {
  return curlWebFromNmapForHost({
    host: ip,
    nmapRows,
    timeoutMs,
    maxBodyBytes,
    log,
    hostLabel: ip,
  });
}

