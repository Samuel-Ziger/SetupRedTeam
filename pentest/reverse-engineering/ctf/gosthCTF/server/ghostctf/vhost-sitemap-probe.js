import dns from 'node:dns/promises';
import { spawn } from 'node:child_process';
import tls from 'node:tls';
import { curlWebSingle } from './web-curl-single.js';
import { bodyLooksHtmlish } from './http-body.js';

function normalizeHost(h) {
  return String(h || '').trim().toLowerCase().replace(/^\[|\]$/g, '');
}

function collectOrigins(webResponses, ip, { skipIpFallback = false, hostFallbacks = [] } = {}) {
  const origins = new Set();
  for (const r of webResponses || []) {
    if (!r?.url || !r?.status) continue;
    try {
      const u = new URL(String(r.url));
      origins.add(`${u.protocol}//${u.host}`);
    } catch {
      // ignore
    }
  }
  if (!origins.size && ip && !skipIpFallback) origins.add(`http://${ip}`);
  if (!origins.size && skipIpFallback && Array.isArray(hostFallbacks)) {
    for (const h of hostFallbacks) {
      const hh = normalizeHost(h);
      if (hh) origins.add(`http://${hh}`);
    }
  }
  return [...origins];
}

function collectHostCandidates(webResponses, ip) {
  const out = new Set();
  const ipNorm = normalizeHost(ip);
  const add = (h) => {
    const n = normalizeHost(h);
    if (!n || n === ipNorm) return;
    if (/^\d{1,3}(?:\.\d{1,3}){3}$/.test(n)) return;
    if (!/^[a-z0-9.-]+\.[a-z]{2,}$/i.test(n)) return;
    out.add(n);
  };

  for (const r of webResponses || []) {
    try {
      const u = new URL(String(r?.url || ''));
      add(u.hostname);
    } catch {
      // ignore
    }
    const bt = String(r?.bodyText || '');
    if (!bt) continue;
    const abs = bt.match(/https?:\/\/([a-z0-9.-]+\.[a-z]{2,})/gi) || [];
    for (const x of abs) {
      try {
        add(new URL(x).hostname);
      } catch {
        // ignore
      }
    }

    // Hostnames em comentários/robots/sitemap/listas textuais
    const plainHosts = bt.match(/\b([a-z0-9.-]+\.[a-z]{2,})\b/gi) || [];
    for (const h of plainHosts.slice(0, 120)) add(h);

    // Header dump do curl (Location absoluto, etc.)
    const ht = String(r?.headersText || '');
    const locs = ht.match(/location:\s*https?:\/\/([a-z0-9.-]+\.[a-z]{2,})/gi) || [];
    for (const x of locs) {
      const m = x.match(/https?:\/\/([a-z0-9.-]+\.[a-z]{2,})/i);
      if (m?.[1]) add(m[1]);
    }
  }
  return [...out].slice(0, 30);
}

function parseTlsAltNames(subjectAltName) {
  const out = [];
  const s = String(subjectAltName || '');
  const re = /DNS:([a-z0-9*.-]+\.[a-z]{2,})/gi;
  let m;
  while ((m = re.exec(s)) !== null) {
    const host = String(m[1] || '').replace(/^\*\./, 'www.');
    if (host) out.push(host);
    if (out.length >= 40) break;
  }
  return [...new Set(out)];
}

async function fetchTlsSanHostnames(ip, port, timeoutMs = 5000) {
  return await new Promise((resolve) => {
    const sock = tls.connect(
      {
        host: ip,
        port,
        rejectUnauthorized: false,
        servername: ip,
      },
      () => {
        try {
          const cert = sock.getPeerCertificate(true);
          const names = parseTlsAltNames(cert?.subjectaltname);
          sock.end();
          resolve(names);
        } catch {
          try {
            sock.end();
          } catch {
            // ignore
          }
          resolve([]);
        }
      },
    );
    const t = setTimeout(() => {
      try {
        sock.destroy();
      } catch {
        // ignore
      }
      resolve([]);
    }, Math.max(1500, timeoutMs));
    sock.once('error', () => {
      clearTimeout(t);
      resolve([]);
    });
    sock.once('close', () => clearTimeout(t));
  });
}

async function resolvesToIp(hostname, ip, cache) {
  const key = `${hostname}|${ip}`;
  if (cache.has(key)) return cache.get(key);
  let ok = false;
  try {
    const rows = await dns.lookup(hostname, { all: true });
    const target = normalizeHost(ip);
    ok = rows.some((r) => {
      const a = normalizeHost(r.address).replace(/^::ffff:/, '');
      return a === target;
    });
  } catch {
    ok = false;
  }
  cache.set(key, ok);
  return ok;
}

function runCurlRaw(url, args, timeoutMs = 12000) {
  return new Promise((resolve, reject) => {
    const sec = String(Math.max(2, Math.floor(timeoutMs / 1000)));
    const finalArgs = ['-k', '-sS', '--compressed', '-L', '--max-redirs', '6', '--connect-timeout', sec, '--max-time', sec, ...args, url];
    const child = spawn('curl', finalArgs, { stdio: ['ignore', 'pipe', 'pipe'] });
    const out = [];
    const err = [];
    child.stdout.on('data', (d) => out.push(d));
    child.stderr.on('data', (d) => err.push(d));
    child.on('error', reject);
    child.on('close', (code) => {
      resolve({
        code,
        stdout: Buffer.concat(out).toString('utf8'),
        stderr: Buffer.concat(err).toString('utf8'),
      });
    });
  });
}

export function parseSitemapUrls(xmlText, max = 60) {
  const out = [];
  const re = /<loc>\s*([^<\s]+)\s*<\/loc>/gi;
  let m;
  while ((m = re.exec(String(xmlText || ''))) !== null) {
    const u = String(m[1] || '').trim();
    if (!u) continue;
    if (!/^https?:\/\//i.test(u)) continue;
    out.push(u);
    if (out.length >= max) break;
  }
  return [...new Set(out)];
}

export async function runVhostAndSitemapProbe(webResponses, {
  ip,
  log,
  timeoutMs = 12000,
  maxBodyBytes = 220000,
  /** Nomes extra (ex. /etc/hosts) para candidatos a vhost mesmo sem FQDN no HTML. */
  seedHostnames = [],
  /** Modo só hostnames: não usar `http://IP` como origem vazia para sitemap/.well-known. */
  skipIpOriginFallback = false,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const dnsCache = new Map();
  const seen = new Set((webResponses || []).map((r) => String(r?.url || '')).filter(Boolean));

  let vhostFetched = 0;
  let sitemapFetched = 0;
  let wellKnownFetched = 0;

  const candidates = collectHostCandidates(webResponses, ip);
  const seeded = (Array.isArray(seedHostnames) ? seedHostnames : []).map((h) => normalizeHost(h)).filter(Boolean);
  const tlsCandidates = [];
  for (const p of [443, 8443]) {
    const names = await fetchTlsSanHostnames(ip, p, Math.min(timeoutMs, 6000));
    for (const n of names) tlsCandidates.push(n);
  }
  const mergedCandidates = [...new Set([...seeded, ...candidates, ...tlsCandidates])].slice(0, 40);
  const inScopeHosts = [];
  for (const h of mergedCandidates) {
    if (await resolvesToIp(h, ip, dnsCache)) inScopeHosts.push(h);
  }

  // VHOST probe com --resolve forçado para o IP alvo.
  for (const host of inScopeHosts.slice(0, 10)) {
    for (const scheme of ['http', 'https']) {
      const port = scheme === 'https' ? 443 : 80;
      const url = `${scheme}://${host}/`;
      try {
        logger(`[vhost] GET ${url} --resolve ${host}:${port}:${ip}`, 'info');
        const raw = await runCurlRaw(url, ['--resolve', `${host}:${port}:${ip}`], timeoutMs);
        const bodyText = String(raw.stdout || '').slice(0, maxBodyBytes);
        if (!bodyText || !bodyLooksHtmlish(bodyText)) continue;
        if (seen.has(url)) continue;
        seen.add(url);
        webResponses.push({
          ok: true,
          url,
          finalUrl: url,
          status: 200,
          headersText: '',
          headers: new Map(),
          bodyText,
          tech: [],
          __via: 'vhost-probe',
        });
        vhostFetched += 1;
      } catch {
        // ignore
      }
    }
  }

  // Sitemap / well-known por origem já validada.
  const origins = collectOrigins(webResponses, ip, {
    skipIpFallback: skipIpOriginFallback,
    hostFallbacks: seeded,
  });
  const sitemapPaths = ['/sitemap.xml', '/sitemap_index.xml'];
  const wkPaths = ['/.well-known/security.txt', '/.well-known/openid-configuration'];

  for (const origin of origins.slice(0, 16)) {
    const base = String(origin).replace(/\/$/, '');
    for (const p of sitemapPaths) {
      const u = `${base}${p}`;
      try {
        const r = await curlWebSingle({ url: u, timeoutMs, maxBodyBytes });
        if (r.status !== 200 || !r.bodyText) continue;
        if (!seen.has(u)) {
          seen.add(u);
          r.__via = 'sitemap';
          webResponses.push(r);
          sitemapFetched += 1;
        }
        const locs = parseSitemapUrls(r.bodyText, 40);
        for (const loc of locs) {
          if (seen.has(loc)) continue;
          try {
            const rr = await curlWebSingle({ url: loc, timeoutMs, maxBodyBytes });
            seen.add(loc);
            rr.__via = 'sitemap:loc';
            webResponses.push(rr);
            sitemapFetched += 1;
          } catch {
            // ignore
          }
        }
      } catch {
        // ignore
      }
    }
    for (const p of wkPaths) {
      const u = `${base}${p}`;
      try {
        const r = await curlWebSingle({ url: u, timeoutMs, maxBodyBytes });
        if (r.status === 200 && !seen.has(u)) {
          seen.add(u);
          r.__via = 'well-known';
          webResponses.push(r);
          wellKnownFetched += 1;
        }
      } catch {
        // ignore
      }
    }
  }

  return {
    vhostFetched,
    sitemapFetched,
    wellKnownFetched,
    hostsTested: inScopeHosts.length,
  };
}

