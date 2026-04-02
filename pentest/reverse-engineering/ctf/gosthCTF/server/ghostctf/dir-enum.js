import fs from 'fs';
import { mkdtemp, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { spawn } from 'node:child_process';

/** Listas pequenas primeiro (evita timeout de 90s no raft-medium). */
const WORDLISTS = [
  '/usr/share/seclists/Discovery/Web-Content/raft-small-directories.txt',
  '/usr/share/seclists/Discovery/Web-Content/common.txt',
  '/usr/share/wordlists/dirb/common.txt',
  '/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt',
];

function whichTool(cmd) {
  return new Promise((resolve) => {
    const finder = process.platform === 'win32' ? 'where' : 'which';
    const p = spawn(finder, [cmd], { stdio: ['ignore', 'pipe', 'pipe'] });
    p.on('error', () => resolve(false));
    p.on('close', (c) => resolve(c === 0));
  });
}

function pickFirstExisting(files) {
  for (const f of files) {
    try {
      if (fs.existsSync(f)) return f;
    } catch {
      /* */
    }
  }
  return null;
}

function runProc(cmd, args, timeoutMs) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const t = setTimeout(() => {
      try {
        child.kill('SIGKILL');
      } catch {
        /* */
      }
      reject(new Error(`${cmd} timeout (${timeoutMs}ms)`));
    }, timeoutMs);

    const out = [];
    const err = [];
    child.stdout.on('data', (d) => out.push(d));
    child.stderr.on('data', (d) => err.push(d));
    child.on('error', (e) => {
      clearTimeout(t);
      reject(e);
    });
    child.on('close', (code) => {
      clearTimeout(t);
      resolve({
        code,
        stdout: Buffer.concat(out).toString('utf8'),
        stderr: Buffer.concat(err).toString('utf8'),
      });
    });
  });
}

export function urlDedupDirEnum(href) {
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

function parseGobusterHits(stdout, stderr, baseUrl) {
  const base = String(baseUrl || '').replace(/\/$/, '');
  const text = `${stdout}\n${stderr}`;
  const hits = new Set();
  for (const line of text.split(/\r?\n/)) {
    const m1 = line.match(/^(https?:\/\/\S+)/);
    if (m1) {
      hits.add(m1[1].replace(/[\])}'"]+$/, ''));
      continue;
    }
    const m2 = line.match(/^\s*(\/?[^\s(]+)\s*\(Status:\s*\d+/);
    if (m2) {
      try {
        hits.add(new URL(m2[1], `${base}/`).href);
      } catch {
        /* */
      }
    }
  }
  return [...hits];
}

function parseDirbHits(stdout) {
  const hits = new Set();
  for (const line of String(stdout).split(/\r?\n/)) {
    const m = line.match(/^\+\s+(https?:\/\/\S+)/);
    if (!m) continue;
    let u = m[1];
    const pipe = u.indexOf('|');
    if (pipe !== -1) u = u.slice(0, pipe);
    hits.add(u.trim());
  }
  return [...hits];
}

/**
 * ffuf — pastas; opcionalmente -e para extensões (.php,.html,...).
 */
export async function ffufDirEnum({
  baseUrl,
  timeoutMs = 180000,
  log,
  maxResults = 160,
  extensions = null,
  label = 'ffuf',
} = {}) {
  const ffufOk = await whichTool('ffuf');
  if (!ffufOk) return { ok: false, tool: label, urls: [], hint: 'ffuf não encontrado no PATH' };
  const wordlist = pickFirstExisting(WORDLISTS);
  if (!wordlist) return { ok: false, tool: label, urls: [], hint: 'wordlist não encontrada (Seclists/dirb)' };

  const dir = await mkdtemp(join(tmpdir(), 'ghffuf-'));
  const outPath = join(dir, 'out.json');
  const u = String(baseUrl || '').replace(/\/$/, '');

  const args = [
    '-u',
    `${u}/FUZZ`,
    '-w',
    wordlist,
    '-mc',
    '200,204,301,302,307,401,403',
    '-t',
    '24',
    '-timeout',
    '12',
    '-maxtime',
    '180',
    '-of',
    'json',
    '-o',
    outPath,
    '-s',
  ];
  if (extensions) {
    args.push('-e', extensions);
  }

  try {
    if (typeof log === 'function') log(`ffuf [${label}]: ${u}/ ${extensions ? `(ext ${extensions})` : '(dirs)'}`, 'info');
    await runProc('ffuf', args, timeoutMs);
    const raw = await fs.promises.readFile(outPath, 'utf8');
    const j = JSON.parse(raw);
    const urls = (j.results || [])
      .map((r) => r.url)
      .filter(Boolean)
      .slice(0, maxResults);
    return { ok: urls.length > 0, tool: label, urls };
  } catch (e) {
    if (typeof log === 'function') log(`ffuf [${label}] erro: ${e.message}`, 'warn');
    return { ok: false, tool: label, urls: [], hint: e.message };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

/**
 * gobuster dir: extensões úteis em CTF (php, ficheiros, backup).
 */
export async function gobusterDirEnum({
  baseUrl,
  wordlist,
  timeoutMs = 180000,
  log,
  maxResults = 160,
  extensions = 'php,html,txt,bak,zip,old,conf',
  label = 'gobuster',
} = {}) {
  const ok = await whichTool('gobuster');
  if (!ok) return { ok: false, tool: label, urls: [], hint: 'gobuster não encontrado no PATH' };
  if (!wordlist) return { ok: false, tool: label, urls: [], hint: 'sem wordlist' };

  const u = String(baseUrl || '').replace(/\/$/, '');
  const target = `${u}/`;

  const args = [
    'dir',
    '-u',
    target,
    '-w',
    wordlist,
    '-t',
    '20',
    '-k',
    '-q',
    '--no-progress',
    '-s',
    '200,204,301,302,307,401,403',
  ];
  if (extensions) {
    args.push('-x', extensions);
  }

  try {
    if (typeof log === 'function') {
      log(`gobuster [${label}]: ${target} -x ${extensions || '—'}`, 'info');
    }
    const { stdout, stderr, code } = await runProc('gobuster', args, timeoutMs);
    const urls = parseGobusterHits(stdout, stderr, u).slice(0, maxResults);
    if (code !== 0 && !urls.length && typeof log === 'function') {
      log(`gobuster: código ${code} (sem hits ou flags incompatíveis com esta versão)`, 'info');
    }
    return { ok: urls.length > 0, tool: label, urls };
  } catch (e) {
    if (typeof log === 'function') log(`gobuster erro: ${e.message}`, 'warn');
    return { ok: false, tool: label, urls: [], hint: e.message };
  }
}

/**
 * dirb -r -S -w; opcional -X para extensões (.php,.phtml ou .txt,.bak,...).
 */
export async function dirbDirEnum({
  baseUrl,
  wordlist,
  timeoutMs = 180000,
  log,
  maxResults = 160,
  extensionX = null,
  label = 'dirb',
} = {}) {
  const ok = await whichTool('dirb');
  if (!ok) return { ok: false, tool: label, urls: [], hint: 'dirb não encontrado no PATH' };
  if (!wordlist) return { ok: false, tool: label, urls: [], hint: 'sem wordlist' };

  const u = String(baseUrl || '').replace(/\/$/, '');
  const target = `${u}/`;

  const args = [target, wordlist, '-S', '-r', '-w'];
  if (extensionX) {
    args.push('-X', extensionX);
  }

  try {
    if (typeof log === 'function') {
      log(`dirb [${label}]: ${target}${extensionX ? ` -X ${extensionX}` : ''}`, 'info');
    }
    const { stdout } = await runProc('dirb', args, timeoutMs);
    const urls = parseDirbHits(stdout).slice(0, maxResults);
    return { ok: urls.length > 0, tool: label, urls };
  } catch (e) {
    if (typeof log === 'function') log(`dirb [${label}] erro: ${e.message}`, 'warn');
    return { ok: false, tool: label, urls: [], hint: e.message };
  }
}

function pushListMerged(list, seen, merged, maxMergedUrls) {
  for (const x of list || []) {
    if (!x) continue;
    const key = urlDedupDirEnum(String(x));
    if (seen.has(key)) continue;
    seen.add(key);
    merged.push(String(x).split('#')[0]);
    if (merged.length >= maxMergedUrls) return true;
  }
  return false;
}

/**
 * Em paralelo: ffuf (dirs), ffuf (ext), gobuster (-x), dirb (dirs), dirb (php), dirb (ficheiros).
 */
export async function dirEnumAllTools({ baseUrl, log, timeoutMs = 180000, maxMergedUrls = 120 } = {}) {
  const wordlist = pickFirstExisting(WORDLISTS);
  if (!wordlist) {
    if (typeof log === 'function') log('dir enum: nenhuma wordlist em /usr/share/seclists ou dirb', 'warn');
    return { ok: false, urls: [], tools: {}, hint: 'wordlist não encontrada' };
  }

  const perMs = Math.max(120000, Math.min(Number(timeoutMs) || 180000, 300000));
  const u = String(baseUrl || '').replace(/\/$/, '');

  const runners = [
    ffufDirEnum({
      baseUrl: u,
      log,
      timeoutMs: perMs,
      label: 'ffuf-dirs',
    }),
    ffufDirEnum({
      baseUrl: u,
      log,
      timeoutMs: perMs,
      extensions: '.php,.html,.txt,.bak,.zip,.old,.conf,.sql,.log',
      label: 'ffuf-ext',
    }),
    gobusterDirEnum({
      baseUrl: u,
      wordlist,
      log,
      timeoutMs: perMs,
      extensions: 'php,html,txt,bak,zip,old,conf,sql',
      label: 'gobuster',
    }),
    dirbDirEnum({
      baseUrl: u,
      wordlist,
      log,
      timeoutMs: perMs,
      extensionX: null,
      label: 'dirb-dirs',
    }),
    dirbDirEnum({
      baseUrl: u,
      wordlist,
      log,
      timeoutMs: perMs,
      extensionX: '.php,.phtml,.php5',
      label: 'dirb-php',
    }),
    dirbDirEnum({
      baseUrl: u,
      wordlist,
      log,
      timeoutMs: perMs,
      extensionX: '.txt,.bak,.zip,.sql,.old,.conf,.log,.json,.xml',
      label: 'dirb-files',
    }),
  ];

  const settled = await Promise.allSettled(runners);

  const seen = new Set();
  const merged = [];
  const tools = {};

  const tags = ['ffuf-dirs', 'ffuf-ext', 'gobuster', 'dirb-dirs', 'dirb-php', 'dirb-files'];
  settled.forEach((s, idx) => {
    const tag = tags[idx] || `job-${idx}`;
    if (s.status === 'rejected') {
      const err = String(s.reason?.message || s.reason);
      tools[tag] = { n: 0, err };
      if (typeof log === 'function') log(`dir enum [${tag}] falhou: ${err}`, 'warn');
      return;
    }
    const r = s.value;
    const n = r.urls?.length || 0;
    tools[tag] = { n };
    pushListMerged(r.urls, seen, merged, maxMergedUrls);
  });

  const urls = merged.slice(0, maxMergedUrls);

  if (typeof log === 'function') {
    const parts = Object.entries(tools)
      .map(([k, v]) => `${k}=${v.n}`)
      .join(' ');
    if (urls.length) {
      log(`dir enum merge: ${urls.length} URL(s) únicas — ${parts}`, 'success');
    } else {
      log(`dir enum: 0 URLs — ${parts}`, 'warn');
    }
  }

  return { ok: urls.length > 0, urls, tools };
}
