import net from 'node:net';
import { spawn } from 'node:child_process';

export function sshPortsFromNmap(nmapRows) {
  const ports = new Set();
  for (const r of nmapRows || []) {
    if (String(r.proto || '').toLowerCase() !== 'tcp') continue;
    const p = Number(r.port);
    if (!Number.isFinite(p)) continue;
    const blob = `${r.name || ''} ${r.product || ''} ${r.extrainfo || ''}`.toLowerCase();
    if (p === 22 || /\bssh\b/.test(blob)) ports.add(p);
  }
  return [...ports].sort((a, b) => a - b);
}

function runProc(cmd, args, timeoutMs) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const out = [];
    const err = [];
    let killed = false;
    const t = setTimeout(() => {
      killed = true;
      try {
        child.kill('SIGKILL');
      } catch {
        /* */
      }
      reject(new Error(`${cmd} timeout (${timeoutMs}ms)`));
    }, timeoutMs);
    child.stdout.on('data', (d) => out.push(d));
    child.stderr.on('data', (d) => err.push(d));
    child.on('error', (e) => {
      clearTimeout(t);
      reject(e);
    });
    child.on('close', (code) => {
      clearTimeout(t);
      if (killed) return;
      resolve({ code, stdout: Buffer.concat(out).toString('utf8'), stderr: Buffer.concat(err).toString('utf8') });
    });
  });
}

async function canRun(cmd) {
  const finder = process.platform === 'win32' ? 'where' : 'which';
  try {
    const r = await runProc(finder, [cmd], 4000);
    return r.code === 0;
  } catch {
    return false;
  }
}

async function grabSshBanner({ host, port, timeoutMs }) {
  return await new Promise((resolve) => {
    const sock = net.createConnection({ host, port });
    let done = false;
    let buffer = '';

    const finish = (out) => {
      if (done) return;
      done = true;
      try {
        sock.destroy();
      } catch {
        /* */
      }
      resolve(out);
    };

    const t = setTimeout(() => finish({ ok: false, error: 'connect timeout' }), Math.min(timeoutMs, 12000));
    sock.once('connect', () => {
      clearTimeout(t);
      // Alguns servidores só respondem após o client banner.
      try {
        sock.write('SSH-2.0-GHOSTCTF_Probe\r\n', 'ascii');
      } catch {
        /* */
      }
    });
    sock.on('data', (chunk) => {
      buffer += chunk.toString('latin1');
      const idx = buffer.indexOf('\n');
      if (idx >= 0) {
        const line = buffer.slice(0, idx).replace(/\r/g, '').trim();
        if (line.startsWith('SSH-')) finish({ ok: true, banner: line });
      }
    });
    sock.once('error', (e) => finish({ ok: false, error: e?.message || String(e) }));
    sock.once('close', () => {
      if (!done) finish({ ok: false, error: 'socket closed sem banner SSH' });
    });
  });
}

async function getSshKeyscan({ host, port, timeoutMs }) {
  const has = await canRun('ssh-keyscan');
  if (!has) return { ok: false, reason: 'ssh-keyscan ausente' };
  try {
    const r = await runProc('ssh-keyscan', ['-T', String(Math.max(2, Math.floor(timeoutMs / 1000))), '-p', String(port), host], timeoutMs);
    const lines = String(r.stdout || '')
      .split(/\r?\n/)
      .map((x) => x.trim())
      .filter(Boolean)
      .filter((x) => !x.startsWith('#'))
      .slice(0, 6);
    if (!lines.length) return { ok: false, reason: 'sem hostkey no keyscan' };
    return { ok: true, lines };
  } catch (e) {
    return { ok: false, reason: e?.message || String(e) };
  }
}

export async function probeSshService({ host, port = 22, timeoutMs = 12000 } = {}) {
  const banner = await grabSshBanner({ host, port, timeoutMs });
  const keyscan = await getSshKeyscan({ host, port, timeoutMs: Math.min(timeoutMs, 10000) });
  return {
    ok: Boolean(banner.ok || keyscan.ok),
    banner: banner.banner || '',
    bannerError: banner.ok ? '' : banner.error || '',
    hostKeys: keyscan.ok ? keyscan.lines : [],
    keyscanError: keyscan.ok ? '' : keyscan.reason || '',
  };
}
