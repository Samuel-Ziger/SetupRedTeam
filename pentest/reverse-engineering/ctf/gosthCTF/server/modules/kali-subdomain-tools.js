import { spawn } from 'node:child_process';

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
        /* ignore */
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
      resolve({
        code,
        stdout: Buffer.concat(out).toString('utf8'),
        stderr: Buffer.concat(err).toString('utf8'),
      });
    });
  });
}

const HOST_RE = /(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+(?:[a-zA-Z]{2,})/g;

function extractHostsFromText(text, domain) {
  const out = new Set();
  const d = String(domain || '').toLowerCase().replace(/^\*\./, '');
  if (!d) return [];
  const matches = String(text || '').match(HOST_RE) || [];
  for (const raw of matches) {
    const h = raw.trim().toLowerCase().replace(/^\*\./, '');
    if (!h) continue;
    if (h === d || h.endsWith(`.${d}`)) out.add(h);
  }
  return [...out].sort();
}

async function enumerateTool(cmd, args, domain, timeoutMs) {
  const proc = await runProc(cmd, args, timeoutMs);
  return extractHostsFromText(proc.stdout || proc.stderr || '', domain);
}

export async function enumerateSubdomainsWithSubfinder(domain, log) {
  const timeoutMs = Number(process.env.GHOSTCTF_SUBFINDER_TIMEOUT_MS ?? process.env.GHOSTRECON_SUBFINDER_TIMEOUT_MS ?? 180000);
  if (typeof log === 'function') log(`subfinder (passivo) em ${domain}...`, 'info');

  // subfinder por padrão é passivo (fontes online). `-all` aumenta cobertura (mais lento).
  const args = ['-d', domain, '-silent', '-all'];
  const hosts = await enumerateTool('subfinder', args, domain, timeoutMs);
  if (typeof log === 'function') log(`subfinder: ${hosts.length} host(s) encontrado(s)`, hosts.length ? 'success' : 'info');
  return hosts;
}

export async function enumerateSubdomainsWithAmass(domain, log) {
  const timeoutMs = Number(process.env.GHOSTCTF_AMASS_TIMEOUT_MS ?? process.env.GHOSTRECON_AMASS_TIMEOUT_MS ?? 240000);
  if (typeof log === 'function') log(`amass (passivo) em ${domain}...`, 'info');

  // `enum -passive` usa fontes passivas (sem bruteforce).
  // amass pode imprimir logs; por isso extraímos hostname com regex.
  const args = ['enum', '-passive', '-d', domain];
  const hosts = await enumerateTool('amass', args, domain, timeoutMs);
  if (typeof log === 'function') log(`amass: ${hosts.length} host(s) encontrado(s)`, hosts.length ? 'success' : 'info');
  return hosts;
}

