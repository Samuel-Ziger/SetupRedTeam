import { spawn } from 'node:child_process';

function runProc(cmd, args, timeoutMs = 60000) {
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

function parseParamsFromArjunOutput(text) {
  const out = new Set();
  for (const line of String(text || '').split('\n')) {
    const m = line.match(/(\w+)\s*=/) || line.match(/param:\s*([a-z0-9_]+)/i);
    if (m?.[1]) out.add(m[1]);
  }
  return [...out];
}

function parseParamsFromX8Output(text) {
  const out = new Set();
  for (const line of String(text || '').split('\n')) {
    const m = line.match(/param(?:eter)?:\s*([a-z0-9_]+)/i) || line.match(/([a-z0-9_]+)=X8/i);
    if (m?.[1]) out.add(m[1]);
  }
  return [...out];
}

export async function discoverParamsActive(url, { timeoutMs = 60000 } = {}) {
  if (await which('arjun')) {
    try {
      const r = await runProc('arjun', ['-u', url, '-m', 'GET', '-t', '20', '--stable'], timeoutMs);
      const params = parseParamsFromArjunOutput(r.stdout);
      return { tool: 'arjun', params };
    } catch (e) {
      return { tool: 'arjun', params: [], error: e.message };
    }
  }
  if (await which('x8')) {
    try {
      const r = await runProc('x8', ['-u', url], timeoutMs);
      const params = parseParamsFromX8Output(r.stdout);
      return { tool: 'x8', params };
    } catch (e) {
      return { tool: 'x8', params: [], error: e.message };
    }
  }
  return { tool: 'none', params: [] };
}
