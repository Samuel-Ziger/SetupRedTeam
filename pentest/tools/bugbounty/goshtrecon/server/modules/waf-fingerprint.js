import { spawn } from 'node:child_process';

function runProc(cmd, args, timeoutMs = 25000) {
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

export async function wafw00fFingerprint(host) {
  if (!(await which('wafw00f'))) return null;
  try {
    const r = await runProc('wafw00f', ['-a', host], 28000);
    const text = [r.stdout, r.stderr].join('\n').toLowerCase();
    const m = text.match(/is behind (.+?)\./i) || text.match(/detected.*waf(?:.*):\s*(.+)/i);
    const waf = m ? m[1].trim() : '';
    return waf ? { tool: 'wafw00f', waf } : { tool: 'wafw00f', waf: '' };
  } catch (e) {
    return { tool: 'wafw00f', error: e.message };
  }
}
