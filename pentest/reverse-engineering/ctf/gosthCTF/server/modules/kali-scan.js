import fs from 'fs';
import { readFile, writeFile, mkdtemp, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { spawn } from 'node:child_process';
import { limits } from '../config.js';
import { runWpscanJson, extractWpscanFindings } from './wpscan.js';

const WORDLISTS = [
  '/usr/share/seclists/Discovery/Web-Content/raft-small-words.txt',
  '/usr/share/seclists/Discovery/Web-Content/common.txt',
  '/usr/share/wordlists/dirb/common.txt',
];

function sanitizeHost(h) {
  if (typeof h !== 'string' || h.length > 253 || h.length < 3) return null;
  const s = h.trim().toLowerCase();
  if (!/^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$/.test(s)) return null;
  return s;
}

async function pathWhich(cmd) {
  return new Promise((resolve) => {
    const finder = process.platform === 'win32' ? 'where' : 'which';
    const p = spawn(finder, [cmd], { stdio: ['ignore', 'pipe', 'pipe'] });
    // No Windows (e ambientes sem PATH completo), spawn pode falhar (ex.: "which" não existe).
    // A detecção de ferramentas é opcional; não pode derrubar o servidor.
    p.on('error', () => resolve(false));
    p.on('close', (c) => resolve(c === 0));
  });
}

export async function getKaliCapabilities() {
  const force = (process.env.GHOSTCTF_FORCE_KALI ?? process.env.GHOSTRECON_FORCE_KALI) === '1';
  let distroKali = false;
  try {
    const rel = fs.readFileSync('/etc/os-release', 'utf8');
    if (/\bID=kali\b/i.test(rel)) distroKali = true;
    else if (/PRETTY_NAME=.*[Kk]ali/i.test(rel)) distroKali = true;
  } catch {
    /* não-Linux ou sem os-release */
  }

  const qualifyDistro = distroKali || force;
  const tools = {
    nmap: await pathWhich('nmap'),
    nuclei: await pathWhich('nuclei'),
    ffuf: await pathWhich('ffuf'),
    searchsploit: await pathWhich('searchsploit'),
    wpscan: await pathWhich('wpscan'),
    whois: await pathWhich('whois'),
    john: await pathWhich('john'),
  };

  const ready = qualifyDistro && tools.nmap;
  let message = 'Modo agressivo disponível.';
  if (!qualifyDistro) {
    message = 'Não é Kali Linux. Usa Kali ou define GHOSTCTF_FORCE_KALI=1 (apenas testes).';
  } else if (!tools.nmap) {
    message = 'nmap não encontrado no PATH.';
  }

  return {
    kali: ready,
    kaliDistro: distroKali,
    forced: force,
    qualifyDistro,
    tools,
    message,
  };
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

function getAttr(attrStr, key) {
  const m = attrStr.match(new RegExp(`${key}="([^"]*)"`));
  return m ? m[1] : '';
}

export function parseNmapXml(xml) {
  const rows = [];
  const parts = xml.split(/<host[\s>]/);
  for (let i = 1; i < parts.length; i++) {
    const hc = parts[i];
    const hostLabel =
      (hc.match(/<hostname name="([^"]+)"/) || [])[1] ||
      (hc.match(/<address addr="([^"]+)" addrtype="ipv4"/) || [])[1] ||
      (hc.match(/<address addr="([^"]+)" addrtype="ipv6"/) || [])[1] ||
      'unknown';

    // Alguns nmap XML trazem <service .../> e outros <service ...>...</service>.
    // Além disso pode haver tags intermédias dentro de <port>, então fazemos parsing por bloco.
    const portBlockRe = /<port\b([^>]*)>([\s\S]*?)<\/port>/g;
    let m;
    while ((m = portBlockRe.exec(hc)) !== null) {
      const portAttrs = m[1] || '';
      const portBody = m[2] || '';
      const stateOpen = /<state\b[^>]*\bstate="open"[^>]*\/?>/i.test(portBody);
      if (!stateOpen) continue;

      const proto = getAttr(portAttrs, 'protocol');
      const port = getAttr(portAttrs, 'portid');
      if (!proto || !port) continue;

      const svc = portBody.match(/<service\b([^>]*?)(?:\/>|>[\s\S]*?<\/service>)/i);
      const svcAttrs = svc ? svc[1] : '';
      const name = getAttr(svcAttrs, 'name');
      const product = getAttr(svcAttrs, 'product');
      const version = getAttr(svcAttrs, 'version');
      const extrainfo = getAttr(svcAttrs, 'extrainfo');
      const searchBlob = [product, version, name, extrainfo].filter(Boolean).join(' ').trim();

      rows.push({
        host: hostLabel,
        port,
        proto,
        name,
        product,
        version,
        extrainfo,
        searchBlob,
      });
    }
  }
  return rows;
}

async function runNmapOnHosts(hosts, log) {
  const dir = await mkdtemp(join(tmpdir(), 'ghnr-'));
  const xmlPath = join(dir, 'nmap.xml');
  const extra = (process.env.GHOSTCTF_NMAP_ARGS ?? process.env.GHOSTRECON_NMAP_ARGS ?? '-sV -Pn --host-timeout 180s')
    .split(/\s+/)
    .filter(Boolean);
  const args = [...extra, '-oX', xmlPath, ...hosts];
  log(`nmap ${args.slice(0, -hosts.length).join(' ')} [${hosts.length} hosts]`, 'info');
  try {
    const proc = await runProc('nmap', args, 660000);
    if (proc.code !== 0) {
      log(`nmap terminou com código ${proc.code}`, 'warn');
    }
    const xml = await readFile(xmlPath, 'utf8');
    return parseNmapXml(xml);
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

async function searchExploitDbOne(query, log) {
  const q = query.slice(0, 100).trim();
  if (q.length < 2) return [];
  const tryJson = async (args) => {
    const r = await runProc('searchsploit', args, 40000);
    if (!r.stdout.trim()) return [];
    try {
      const j = JSON.parse(r.stdout);
      if (Array.isArray(j)) return j.slice(0, 8);
      if (j.RESULTS_EXPLOIT && Array.isArray(j.RESULTS_EXPLOIT)) return j.RESULTS_EXPLOIT.slice(0, 8);
      if (j.RESULTS_SHELLCODE && Array.isArray(j.RESULTS_SHELLCODE)) return j.RESULTS_SHELLCODE.slice(0, 8);
      if (j.results && Array.isArray(j.results)) return j.results.slice(0, 8);
    } catch {
      /* texto */
    }
    return [];
  };
  try {
    let rows = await tryJson(['--json', q]);
    if (rows.length) return rows;
    rows = await tryJson(['-j', q]);
    return rows;
  } catch (e) {
    log(`searchsploit "${q.slice(0, 40)}…": ${e.message}`, 'warn');
    return [];
  }
}

function exploitTitle(row) {
  if (typeof row === 'string') return row;
  return row.Title || row.title || row.Path || row['EDB-ID'] || row.EDB_ID || JSON.stringify(row).slice(0, 120);
}

function exploitUrl(row) {
  const id = row['EDB-ID'] || row.EDB_ID || row.id || row['edb-id'];
  if (id) return `https://www.exploit-db.com/exploits/${id}`;
  return row.url || '';
}

async function runFfuf200(baseUrl, log) {
  const wl = WORDLISTS.find((p) => fs.existsSync(p));
  if (!wl) {
    log('ffuf: nenhuma wordlist em /usr/share/seclists ou dirb', 'warn');
    return [];
  }
  const dir = await mkdtemp(join(tmpdir(), 'ghff-'));
  const out = join(dir, 'out.json');
  const base = baseUrl.replace(/\/$/, '');
  try {
    const args = [
      '-u',
      `${base}/FUZZ`,
      '-w',
      wl,
      '-mc',
      '200',
      '-t',
      '32',
      '-timeout',
      '8',
      '-maxtime',
      '120',
      '-of',
      'json',
      '-o',
      out,
      '-s',
    ];
    await runProc('ffuf', args, 135000);
    const raw = await readFile(out, 'utf8');
    const j = JSON.parse(raw);
    return (j.results || []).map((r) => r.url).filter(Boolean);
  } catch (e) {
    log(`ffuf ${base}: ${e.message}`, 'warn');
    return [];
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

async function runNucleiList(urls, log) {
  if (!urls.length) return [];
  const dir = await mkdtemp(join(tmpdir(), 'ghnu-'));
  const listFile = join(dir, 'targets.txt');
  const outFile = join(dir, 'out.jsonl');
  await writeFile(listFile, [...new Set(urls)].slice(0, 18).join('\n'), 'utf8');
  try {
    await runProc(
      'nuclei',
      ['-l', listFile, '-jsonl', '-o', outFile, '-silent', '-rate-limit', '35', '-timeout', '8'],
      320000,
    );
    let text = '';
    try {
      text = await readFile(outFile, 'utf8');
    } catch {
      return [];
    }
    return text
      .trim()
      .split('\n')
      .filter(Boolean)
      .map((line) => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      })
      .filter(Boolean);
  } catch (e) {
    log(`nuclei: ${e.message}`, 'warn');
    return [];
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

async function runNucleiTags(urls, tagsCsv, log) {
  if (!urls.length) return [];
  const dir = await mkdtemp(join(tmpdir(), 'ghnu-'));
  const listFile = join(dir, 'targets.txt');
  const outFile = join(dir, 'out.jsonl');
  await writeFile(listFile, [...new Set(urls)].slice(0, 30).join('\n'), 'utf8');
  try {
    await runProc(
      'nuclei',
      [
        '-l',
        listFile,
        '-jsonl',
        '-o',
        outFile,
        '-silent',
        '-rate-limit',
        '25',
        '-timeout',
        '8',
        '-tags',
        tagsCsv,
      ],
      360000,
    );
    let text = '';
    try {
      text = await readFile(outFile, 'utf8');
    } catch {
      return [];
    }
    return text
      .trim()
      .split('\n')
      .filter(Boolean)
      .map((line) => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      })
      .filter(Boolean);
  } catch (e) {
    log(`nuclei(${tagsCsv}): ${e.message}`, 'warn');
    return [];
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

function pickFirstMatch(re, text) {
  const m = String(text || '').match(re);
  return m?.[1] ? String(m[1]).trim() : null;
}

function pickAllMatches(re, text, limit = 8) {
  const out = [];
  const s = String(text || '');
  let m;
  // eslint-disable-next-line no-constant-condition
  while ((m = re.exec(s)) !== null) {
    if (m[1]) out.push(String(m[1]).trim());
    if (out.length >= limit) break;
  }
  return out;
}

function parseWhoisText(domainOrHost, whoisText) {
  // Formatos variam por registrar; usamos regexes comuns.
  const registrar = pickFirstMatch(/Registrar:\s*(.+)$/im, whoisText) || pickFirstMatch(/registrar:\s*(.+)$/im, whoisText);
  const registrantCountry =
    pickFirstMatch(/Registrant Country:\s*(.+)$/im, whoisText) || pickFirstMatch(/country:\s*(.+)$/im, whoisText);
  const created =
    pickFirstMatch(/Creation Date:\s*(.+)$/im, whoisText) ||
    pickFirstMatch(/created on:\s*(.+)$/im, whoisText) ||
    pickFirstMatch(/Created:\s*(.+)$/im, whoisText);
  const updated =
    pickFirstMatch(/Updated Date:\s*(.+)$/im, whoisText) || pickFirstMatch(/updated on:\s*(.+)$/im, whoisText);
  const expires =
    pickFirstMatch(/Registry Expiry Date:\s*(.+)$/im, whoisText) ||
    pickFirstMatch(/Expiry Date:\s*(.+)$/im, whoisText) ||
    pickFirstMatch(/expires on:\s*(.+)$/im, whoisText);

  // Alguns whois usam "Name Server:" e outros "nserver:".
  const nameServers =
    pickAllMatches(/Name Server:\s*(.+)$/gim, whoisText, 10).length
      ? pickAllMatches(/Name Server:\s*(.+)$/gim, whoisText, 10)
      : pickAllMatches(/nserver:\s*(.+)$/gim, whoisText, 10);

  // Se quase nada vier, não cria achado “vazio”.
  const hasSomething = Boolean(registrar || created || expires || nameServers.length);
  return {
    hasSomething,
    registrar,
    registrantCountry,
    created,
    updated,
    expires,
    nameServers,
    domainOrHost,
  };
}

async function runWhoisJsonLike({ target, timeoutMs, log }) {
  // quem usa whois no Kali geralmente tem o CLI "whois".
  // Não normalizamos em JSON: apenas parseamos texto com regexes.
  const proc = await runProc('whois', [target], timeoutMs);
  const text = [proc.stdout, proc.stderr].filter(Boolean).join('\n').slice(0, 220_000);
  if (typeof log === 'function' && text.includes('No match')) log(`whois: sem match para ${target}`, 'info');
  return { ok: proc.code === 0, text };
}

/**
 * Scan ativo: nmap → searchsploit (heurístico) → ffuf (só HTTP 200) → nuclei.
 */
export async function runKaliAggressiveScan({
  domain,
  subdomainsAlive,
  cap,
  log,
  addFinding,
  wordpressTargets,
  paramUrls,
}) {
  const rawHosts = [domain, ...(subdomainsAlive || [])].map(sanitizeHost).filter(Boolean);
  const hosts = [...new Set(rawHosts)].slice(0, 22);

  log('═══ MODO KALI / SCAN ATIVO ═══', 'section');
  log('Apenas em alvos com autorização explícita (bug bounty / pentest autorizado).', 'warn');
  log(`Alvos nmap (${hosts.length}): ${hosts.join(', ')}`, 'info');

  const baseUrlsForFfuf = [
    `https://${domain}/`,
    `http://${domain}/`,
  ];
  const seenQueries = new Set();

  if (cap.tools.nmap) {
    try {
      const rows = await runNmapOnHosts(hosts, log);
      log(`nmap: ${rows.length} serviço(s) em portas abertas`, 'success');
      for (const row of rows) {
        const line = `${row.proto}/${row.port} ${row.host} — ${row.name || '?'} ${row.product || ''} ${row.version || ''}`.trim();
        let url = null;
        if (row.port === '443') url = `https://${row.host}/`;
        else if (row.port === '80') url = `http://${row.host}/`;
        addFinding({
          type: 'nmap',
          prio: 'med',
          score: 56,
          value: line,
          meta: row.searchBlob || row.name || 'nmap',
          url,
        });

        if (cap.tools.searchsploit && row.searchBlob && seenQueries.size < 12) {
          const key = row.searchBlob.toLowerCase().slice(0, 60);
          if (seenQueries.has(key)) continue;
          seenQueries.add(key);
          const hits = await searchExploitDbOne(row.searchBlob, log);
          for (const hit of hits.slice(0, 4)) {
            const title = exploitTitle(hit);
            addFinding({
              type: 'exploit',
              prio: 'high',
              score: 82,
              value: title,
              meta: `Exploit-DB / searchsploit — ref. a «${row.searchBlob.slice(0, 50)}»`,
              url: exploitUrl(hit) || undefined,
            });
          }
          if (hits.length) log(`searchsploit: ${hits.length} entrada(s) para «${row.searchBlob.slice(0, 40)}…»`, 'find');
        }
      }
      for (const row of rows) {
        if (row.port === '443' || row.port === '80') {
          const u = row.port === '443' ? `https://${row.host}/` : `http://${row.host}/`;
          if (!baseUrlsForFfuf.includes(u)) baseUrlsForFfuf.push(u);
        }
      }
    } catch (e) {
      log(`nmap: ${e.message}`, 'error');
    }
  }

  // ── WHOIS (Kali) ──
  // WHOIS é leitura externa (não é exploit), mas ainda assim é "ativo". Mantemos só quando ferramenta existe
  // e com amostra limitada de subdomínios para não explodir tempo.
  if (cap.tools.whois) {
    log('═══ whois (registo domínio) ═══', 'section');

    const whoisTargets = [domain, ...(subdomainsAlive || [])]
      .map(sanitizeHost)
      .filter(Boolean)
      .slice(
        0,
        1 +
          (process.env.GHOSTCTF_WHOIS_SUBDOMAINS_MAX
            ? Number(process.env.GHOSTCTF_WHOIS_SUBDOMAINS_MAX)
            : process.env.GHOSTRECON_WHOIS_SUBDOMAINS_MAX
              ? Number(process.env.GHOSTRECON_WHOIS_SUBDOMAINS_MAX)
              : limits.whoisSubdomainsMax),
      );

    // Normalmente whois em subdomínios devolve o mesmo registo do domínio raiz.
    // Ainda assim, seguimos a tua ideia e executamos numa amostra pequena.
    for (const t of whoisTargets) {
      try {
        const { text } = await runWhoisJsonLike({ target: t, timeoutMs: limits.whoisTimeoutMs, log });
        const parsed = parseWhoisText(t, text);
        if (!parsed.hasSomething) continue;
        const ns = parsed.nameServers?.slice(0, 6) || [];
        const valueParts = [
          parsed.registrar ? `Registrar: ${parsed.registrar}` : null,
          parsed.expires ? `Expires: ${parsed.expires}` : null,
          parsed.created ? `Created: ${parsed.created}` : null,
        ].filter(Boolean);

        addFinding(
          {
            type: 'whois',
            prio: 'low',
            score: 26,
            value: valueParts.length ? valueParts.join(' | ') : `whois: ${t}`,
            meta: [
              parsed.domainOrHost ? `Target: ${parsed.domainOrHost}` : null,
              parsed.registrantCountry ? `Country: ${parsed.registrantCountry}` : null,
              ns.length ? `NS: ${ns.join(', ')}` : null,
              parsed.updated ? `Updated: ${parsed.updated}` : null,
            ]
              .filter(Boolean)
              .join(' • '),
            url: null,
          },
          null,
        );
      } catch (e) {
        log(`whois ${t}: ${e.message}`, 'warn');
      }
    }
  }

  if (cap.tools.ffuf) {
    log('═══ ffuf (apenas HTTP 200) ═══', 'section');
    const uniqBases = [...new Set(baseUrlsForFfuf)].slice(0, 5);
    for (const u of uniqBases) {
      const paths = await runFfuf200(u, log);
      for (const p of paths) {
        addFinding(
          {
            type: 'endpoint',
            prio: 'high',
            score: 72,
            value: p,
            meta: 'ffuf • código 200',
            url: p,
          },
          'endpoints',
        );
      }
      if (paths.length) log(`ffuf ${u} → ${paths.length} caminho(s) 200`, 'success');
    }
  }

  if (cap.tools.nuclei) {
    log('═══ nuclei ═══', 'section');
    const targets = [...new Set(baseUrlsForFfuf.map((b) => b.replace(/\/$/, '')))].slice(0, 15);
    try {
      const findings = await runNucleiList(targets, log);
      for (const f of findings) {
        const matched = f['matched-at'] || f.host || f.url || '';
        const tid = f['template-id'] || f.templateID || 'template';
        const sev = f.info?.severity || f.severity || 'info';
        addFinding({
          type: 'nuclei',
          prio: ['critical', 'high'].includes(String(sev).toLowerCase()) ? 'high' : 'med',
          score: sev === 'critical' ? 95 : sev === 'high' ? 88 : 60,
          value: `${tid} @ ${matched}`,
          meta: `nuclei • ${sev}`,
          url: matched.startsWith('http') ? matched : null,
        });
      }
      log(`nuclei: ${findings.length} finding(s)`, findings.length ? 'warn' : 'info');
    } catch (e) {
      log(`nuclei: ${e.message}`, 'warn');
    }
  }

  // XSS/SQLi via nuclei tags contra URLs com query string (vindas do corpus passivo)
  if (cap.tools.nuclei && Array.isArray(paramUrls) && paramUrls.length) {
    const urls = [...new Set(paramUrls)].slice(0, 30);
    log(`═══ nuclei (xss/sqli) em URLs com parâmetros (${urls.length}) ═══`, 'section');

    try {
      const xss = await runNucleiTags(urls, 'xss', log);
      for (const f of xss) {
        const matched = f['matched-at'] || f.host || f.url || '';
        const tid = f['template-id'] || f.templateID || 'template';
        const sev = f.info?.severity || f.severity || 'info';
        addFinding({
          type: 'xss',
          prio: ['critical', 'high'].includes(String(sev).toLowerCase()) ? 'high' : 'med',
          score: sev === 'critical' ? 95 : sev === 'high' ? 90 : 70,
          value: `${tid} @ ${matched}`,
          meta: `nuclei:xss • ${sev}`,
          url: matched.startsWith('http') ? matched : null,
        });
      }
      if (xss.length) log(`XSS: ${xss.length} finding(s)`, 'warn');
    } catch (e) {
      log(`XSS nuclei: ${e.message}`, 'warn');
    }

    try {
      const sqli = await runNucleiTags(urls, 'sqli', log);
      for (const f of sqli) {
        const matched = f['matched-at'] || f.host || f.url || '';
        const tid = f['template-id'] || f.templateID || 'template';
        const sev = f.info?.severity || f.severity || 'info';
        addFinding({
          type: 'sqli',
          prio: ['critical', 'high'].includes(String(sev).toLowerCase()) ? 'high' : 'med',
          score: sev === 'critical' ? 98 : sev === 'high' ? 92 : 72,
          value: `${tid} @ ${matched}`,
          meta: `nuclei:sqli • ${sev}`,
          url: matched.startsWith('http') ? matched : null,
        });
      }
      if (sqli.length) log(`SQLi: ${sqli.length} finding(s)`, 'warn');
    } catch (e) {
      log(`SQLi nuclei: ${e.message}`, 'warn');
    }
  }

  if (cap.tools.wpscan) {
    const detectionMode =
      process.env.GHOSTCTF_WPSCAN_DETECTION_MODE ??
      process.env.GHOSTRECON_WPSCAN_DETECTION_MODE ??
      'mixed';
    const timeoutMs = Number(
      process.env.GHOSTCTF_WPSCAN_TIMEOUT_MS ??
        process.env.GHOSTRECON_WPSCAN_TIMEOUT_MS ??
        240000,
    );

    log('═══ wpscan (WordPress enumeration) ═══', 'section');
    const targets = Array.isArray(wordpressTargets) ? wordpressTargets : null;

    if (!targets || targets.length === 0) {
      log('wpscan: WordPress não confirmado no passivo — skip', 'info');
    } else {
      const uniqTargets = [...new Set(targets)].slice(0, 6);
      log(`wpscan: ${uniqTargets.length} target(s) (WordPress)`, 'info');
      for (const t of uniqTargets) {
        const res = await runWpscanJson({ targetUrl: t, detectionMode, timeoutMs, log });
        if (res?.json) {
          const findings = extractWpscanFindings({ targetUrl: t, wpscanJson: res.json });
          if (findings.length) log(`wpscan ${t} → ${findings.length} finding(s)`, 'success');
          for (const f of findings) addFinding(f, null);
        } else {
          addFinding({
            type: 'wpscan',
            prio: 'low',
            score: 10,
            value: `wpscan failed @ ${t}`,
            meta: res?.error || 'unknown error',
            url: t,
          });
          log(`wpscan ${t}: sem JSON (${res?.error || 'unknown'})`, 'warn');
        }
      }
    }
  }

  log('═══ Fim modo Kali ═══', 'section');
}
