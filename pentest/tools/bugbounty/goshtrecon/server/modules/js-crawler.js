import { spawn } from 'node:child_process';

function runProc(cmd, args, timeoutMs = 120000) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const out = [];
    const err = [];
    let killed = false;
    const t = setTimeout(() => {
      killed = true;
      try {
        child.kill('SIGKILL');
      } catch {}
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
      resolve({
        code,
        stdout: Buffer.concat(out).toString('utf8'),
        stderr: Buffer.concat(err).toString('utf8'),
      });
    });
  });
}

async function which(cmd) {
  try {
    const finder = process.platform === 'win32' ? 'where' : 'which';
    const r = await runProc(finder, [cmd], 6000);
    return r.code === 0;
  } catch {
    return false;
  }
}

export async function crawlWithKatana(seedUrl, { depth = 2 } = {}) {
  if (!(await which('katana'))) return { ok: false, reason: 'katana_not_found', urls: [] };
  try {
    const r = await runProc('katana', ['-u', seedUrl, '-d', String(depth), '-silent'], 150000);
    const urls = [...new Set(
      String(r.stdout || '')
        .split('\n')
        .map((x) => x.trim())
        .filter((x) => /^https?:\/\//i.test(x)),
    )];
    return { ok: true, urls };
  } catch (e) {
    return { ok: false, reason: e.message, urls: [] };
  }
}
