import 'dotenv/config';
import express from 'express';
import { createServer } from 'node:http';
import path from 'path';
import crypto from 'node:crypto';
import fs from 'node:fs';
import { mkdtemp, rm, writeFile } from 'node:fs/promises';
import readline from 'node:readline';
import { spawn } from 'node:child_process';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'url';
import { fetchCrtShSubdomains } from './modules/subdomains.js';
import { resolves } from './modules/dns.js';
import { probeHttp, mapPool } from './modules/probe.js';
import { analyzeSecurityHeaders } from './modules/security-headers.js';
import { peekTlsCertificate } from './modules/tls-cert.js';
import { crawlRobotsAndSitemapsForOrigin, hostnameInScope } from './modules/robots-sitemap.js';
import { fetchCommonCrawlUrls } from './modules/commoncrawl.js';
import { fetchRdapSummary } from './modules/rdap.js';
import { fetchVirustotalSubdomains } from './modules/virustotal.js';
import { compareRuns } from './modules/db-compare.js';
import { postReconWebhook } from './modules/webhook-notify.js';
import { fetchWaybackUrls, filterInterestingUrls, extractJsUrls } from './modules/wayback.js';
import { extractParamsFromUrls } from './modules/params.js';
import { analyzeJsUrl } from './modules/js-analyzer.js';
import { scanSecrets } from './modules/secrets.js';
import { githubCodeSearch } from './modules/github.js';
import { buildDorks } from './modules/dorks.js';
import { scoreEndpointPath, scoreParamName } from './modules/scoring.js';
import { correlate } from './modules/correlation.js';
import { suggestVectors, buildExploitChecklist } from './modules/intelligence.js';
import { applyPrioritizationV2, topHighProbability } from './modules/prioritization.js';
import { extractCveHintsFromTechStrings } from './modules/cve-hints.js';
import { fetchDnsEnrichment } from './modules/dns-enrichment.js';
import { fetchWellKnownSecurityTxt, fetchWellKnownOpenIdConfiguration } from './modules/wellknown.js';
import { limits, reconRateLimitConfig } from './config.js';
import {
  saveRun,
  listRuns,
  getRunById,
  listIntelForTarget,
  intelCountForTarget,
  listKnowledge,
  storageLabel,
} from './modules/db.js';
import { googleCseSearch, urlMatchesTarget } from './modules/google-cse.js';
import { getKaliCapabilities, runKaliAggressiveScan } from './modules/kali-scan.js';
import { enumerateSubdomainsWithSubfinder, enumerateSubdomainsWithAmass } from './modules/kali-subdomain-tools.js';
import { runGhostCtfPipeline } from './ghostctf/pipeline.js';
import { getPlatform } from './ghostctf/platforms.js';
import { attachShellWebSocket } from './ghostctf/shell-ws.js';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const reconRlHits = new Map();

function allowReconRequest(req) {
  const { max, windowMs } = reconRateLimitConfig();
  if (max <= 0) return true;
  const ip = String(
    req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || '_',
  );
  const now = Date.now();
  const arr = (reconRlHits.get(ip) || []).filter((t) => now - t < windowMs);
  if (arr.length >= max) return false;
  arr.push(now);
  reconRlHits.set(ip, arr);
  return true;
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..');

const app = express();

app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') {
    res.sendStatus(204);
    return;
  }
  next();
});

app.use(express.json({ limit: '200kb' }));

function isValidDomain(d) {
  return /^[a-zA-Z0-9][a-zA-Z0-9-.]+\.[a-zA-Z]{2,}$/.test(d);
}

function normDomain(d) {
  return d.trim().toLowerCase().replace(/^https?:\/\//, '').split('/')[0];
}

function isValidIpv4(ip) {
  return /^(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}$/.test(
    String(ip || '').trim(),
  );
}

function normIp(ip) {
  return String(ip || '').trim();
}

async function runPipeline(ctx) {
  const { domain, exactMatch, modules, emit, kaliMode = false } = ctx;
  const domainStr = exactMatch ? `"${domain}"` : domain;
  const findings = [];
  const stats = { subs: 0, endpoints: 0, params: 0, secrets: 0, dorks: 0, high: 0 };

  const addFinding = (f, statKey) => {
    if (statKey) stats[statKey] = (stats[statKey] || 0) + 1;
    findings.push(f);
    if (f.prio === 'high') stats.high += 1;
    emit({ type: 'finding', finding: f });
    emit({ type: 'stats', stats: { ...stats } });
  };

  const log = (msg, level = 'info') => emit({ type: 'log', msg, level });
  const pipe = (name, state) => emit({ type: 'pipe', name, state });
  const progress = (p) => emit({ type: 'progress', pct: p });

  let subdomainsAlive = [];
  const probedHosts = new Set();
  const seenEp = new Set();
  let vtHostnames = [];

  log(`Alvo: ${domain} | Módulos: ${modules.join(', ')}`, 'info');
  log(exactMatch ? 'Modo: exact match (aspas nos dorks)' : 'Modo: broad match', 'info');

  // ── INPUT ─────────────────────────────────────
  pipe('input', 'active');
  progress(5);
  pipe('input', 'done');

  // ── SUBDOMAINS ──────────────────────────────
  if (modules.includes('virustotal')) {
    const vt = await fetchVirustotalSubdomains(domain, process.env.VIRUSTOTAL_API_KEY);
    if (vt.ok && vt.items?.length) {
      vtHostnames = vt.items;
      log(`VirusTotal: ${vtHostnames.length} hostname(s)`, 'success');
    } else {
      log(vt.note || 'VirusTotal: sem dados', vt.ok ? 'info' : 'warn');
    }
  }

  let allSubs = [];
  const runCrtSubdomains = modules.includes('subdomains');
  const runKaliSubfinderAmass = Boolean(kaliMode) && (modules.includes('subfinder') || modules.includes('amass'));
  if (runCrtSubdomains || runKaliSubfinderAmass) {
    pipe('subdomains', 'active');
    progress(12);
    if (runCrtSubdomains) {
      log('Consultando crt.sh (Certificate Transparency)...', 'info');
      try {
        allSubs = await fetchCrtShSubdomains(domain);
        log(`${allSubs.length} nomes únicos em CT logs`, 'success');
      } catch (e) {
        log(`crt.sh: ${e.message}`, 'warn');
      }
      if (vtHostnames.length) {
        const before = allSubs.length;
        allSubs = [...new Set([...allSubs, ...vtHostnames])];
        if (allSubs.length > before) log(`VirusTotal fundido em enum: +${allSubs.length - before} nome(s)`, 'info');
      }
    } else {
      log('crt.sh (subdomains) desativado — usando enum Kali (se selecionado).', 'info');
    }

    if (runKaliSubfinderAmass) {
      if (modules.includes('subfinder')) {
        try {
          const extra = await enumerateSubdomainsWithSubfinder(domain, log);
          if (extra.length) {
            allSubs = [...new Set([...allSubs, ...extra])];
          }
        } catch (e) {
          log(`subfinder: ${e.message}`, 'warn');
        }
      }
      if (modules.includes('amass')) {
        try {
          const extra = await enumerateSubdomainsWithAmass(domain, log);
          if (extra.length) {
            allSubs = [...new Set([...allSubs, ...extra])];
          }
        } catch (e) {
          log(`amass: ${e.message}`, 'warn');
        }
      }
    }

    const capped = allSubs.filter((s) => s !== domain).slice(0, 150);
    log(`Resolvendo DNS (máx. ${capped.length} hosts)...`, 'info');
    for (const host of capped) {
      const r = await resolves(host);
      if (r.ok) {
        log(`✓ ${host} → ${r.records.slice(0, 2).join(', ')}`, 'success');
        const { score, prio } = { score: 52, prio: 'med' };
        addFinding(
          {
            type: 'subdomain',
            prio,
            score,
            value: host,
            meta: `DNS: ${r.records.join(', ')}`,
            url: `https://${host}`,
          },
          'subs',
        );
        subdomainsAlive.push(host);
        probedHosts.add(host);
      } else {
        log(`✗ ${host} (sem A/AAAA)`, 'warn');
      }
    }
    pipe('subdomains', 'done');
  } else {
    log('Subdomain discovery desativado', 'info');
    pipe('subdomains', 'done');
  }

  // ── DNS ENRICHMENT (TXT/MX/SPF/DMARC) ─────────
  if (modules.includes('dns_enrichment')) {
    pipe('dns_enrichment', 'active');
    progress(14);
    log('Enriquecimento DNS (MX/TXT/SPF/DMARC)...', 'info');
    try {
      const { findings } = await fetchDnsEnrichment(domain, subdomainsAlive, { maxHosts: limits.dnsEnrichMaxHosts });
      if (findings.length) log(`DNS intel: ${findings.length} achado(s)`, 'success');
      for (const f of findings) addFinding(f, null);
    } catch (e) {
      log(`DNS Enrichment: ${e.message}`, 'warn');
    }
    pipe('dns_enrichment', 'done');
  }

  if (modules.includes('rdap')) {
    pipe('rdap', 'active');
    progress(18);
    log('Consultando RDAP (registo de domínio)...', 'info');
    try {
      const rd = await fetchRdapSummary(domain);
      addFinding(
        {
          type: 'rdap',
          prio: 'low',
          score: 24,
          value: rd.handle || domain,
          meta: `Estado: ${rd.statuses || '—'} · NS: ${(rd.nameservers || []).slice(0, 10).join(', ') || '—'}`,
        },
        null,
      );
      if (rd.events?.length) log(`RDAP: ${rd.events.join(' | ')}`, 'info');
    } catch (e) {
      log(`RDAP: ${e.message}`, 'warn');
    }
    pipe('rdap', 'done');
  } else {
    emit({ type: 'pipe', name: 'rdap', state: 'skip' });
  }

  // ── ALIVE / PROBE ───────────────────────────
  pipe('alive', 'active');
  progress(28);
  const hostsToProbe = [
    domain,
    ...new Set([...subdomainsAlive, ...(modules.includes('subdomains') ? [] : vtHostnames)]),
  ].slice(0, 80);
  const urlsToProbe = [];
  for (const h of hostsToProbe) {
    urlsToProbe.push(`https://${h}/`, `http://${h}/`);
  }
  log(`HTTP probing em ${hostsToProbe.length} hosts (GET, timeout ${limits.probeTimeoutMs}ms)...`, 'info');

  const probeResults = await mapPool(urlsToProbe, limits.probeConcurrency, async (u) => {
    const r = await probeHttp(u);
    return { u, r };
  });

  const seenTech = new Set();
  for (const { r } of probeResults) {
    if (!r.ok) continue;
    const host = new URL(r.url).hostname;
    if (r.status > 0 && r.status < 500) {
      log(`ALIVE ${r.url} → ${r.status} ${r.title ? `"${r.title.slice(0, 60)}"` : ''}`, 'success');
      for (const t of r.tech || []) {
        const tk = `${host}::${t}`;
        if (seenTech.has(tk)) continue;
        seenTech.add(tk);
        addFinding({
          type: 'tech',
          prio: 'low',
          score: 28,
          value: t,
          meta: `Detectado em ${host}`,
        });
      }
    }
  }

  if (modules.includes('security_headers')) {
    for (const { r } of probeResults) {
      if (!r.ok || !r.securityHeaders) continue;
      if (r.status <= 0 || r.status >= 500) continue;
      let host;
      try {
        host = new URL(r.url).hostname;
      } catch {
        continue;
      }
      for (const issue of analyzeSecurityHeaders(r.url, r.securityHeaders)) {
        addFinding(
          {
            type: 'security',
            prio: issue.prio,
            score: issue.score,
            value: `${issue.text} @ ${host}`,
            meta: `HTTP ${r.status}`,
            url: r.url,
          },
          null,
        );
      }
    }
  }

  const originByHost = new Map();
  for (const { r } of probeResults) {
    if (!r.ok || r.status <= 0 || r.status >= 500) continue;
    let u;
    try {
      u = new URL(r.url);
    } catch {
      continue;
    }
    if (!hostnameInScope(u.hostname, domain)) continue;
    const prefer = u.protocol === 'https:' ? 2 : 1;
    const cur = originByHost.get(u.hostname);
    if (!cur || prefer > cur.prefer) {
      const port = u.port ? `:${u.port}` : '';
      originByHost.set(u.hostname, { origin: `${u.protocol}//${u.hostname}${port}/`, prefer });
    }
  }

  const runWellKnown = modules.includes('wellknown_security_txt') || modules.includes('wellknown_openid');
  const runSurface =
    modules.includes('security_headers') || modules.includes('robots_sitemap') || runWellKnown;
  if (runSurface) {
    pipe('surface', 'active');
    progress(33);
    if (modules.includes('security_headers')) {
      const hostsTls = [...originByHost.entries()].filter(([, v]) => v.prefer === 2).map(([h]) => h);
      if (hostsTls.length) log(`Inspeção TLS (${hostsTls.length} host HTTPS)...`, 'info');
      await mapPool(hostsTls, limits.surfaceConcurrency, async (hostname) => {
        const cert = await peekTlsCertificate(hostname, 443, limits.tlsProbeTimeoutMs);
        if (cert.ok) {
          const soon = cert.daysLeft != null && cert.daysLeft < 30;
          addFinding(
            {
              type: 'tls',
              prio: soon ? 'med' : 'low',
              score: soon ? 52 : 28,
              value: `${hostname} — cert válido até ${cert.validTo || '?'}`,
              meta: `Assunto: ${cert.subject || '—'} · Emissor: ${cert.issuer || '—'}${cert.daysLeft != null ? ` · ~${cert.daysLeft}d` : ''}`,
              url: `https://${hostname}/`,
            },
            null,
          );
        }
      });
    }
    if (modules.includes('robots_sitemap')) {
      const bases = [...originByHost.values()].map((v) => v.origin);
      log(`robots.txt / sitemap (${bases.length} origem(ns))...`, 'info');
      await mapPool(bases, limits.surfaceConcurrency, async (baseOrigin) => {
        const crawl = await crawlRobotsAndSitemapsForOrigin(baseOrigin, domain);
        for (const p of (crawl.disallowHints || []).slice(0, 20)) {
          addFinding(
            {
              type: 'intel',
              prio: 'low',
              score: 36,
              value: `robots Disallow: ${p}`,
              meta: crawl.robotsUrl || baseOrigin,
              url: crawl.robotsUrl || baseOrigin,
            },
            null,
          );
        }
        for (const pageUrl of crawl.pageUrls || []) {
          let pathname = '/';
          try {
            pathname = new URL(pageUrl).pathname;
          } catch {
            continue;
          }
          const { score, prio } = scoreEndpointPath(pathname);
          if (seenEp.has(pageUrl)) continue;
          seenEp.add(pageUrl);
          addFinding(
            {
              type: 'endpoint',
              prio,
              score: Math.max(score, 44),
              value: pageUrl,
              meta: `robots/sitemap • ${new URL(baseOrigin).hostname}`,
              url: pageUrl,
            },
            'endpoints',
          );
        }
      });
    }

    // ── /.well-known (security.txt + OIDC discovery) ──
    if (runWellKnown) {
      const origins = [...originByHost.values()].map((v) => v.origin).slice(0, limits.wellKnownMaxHosts);
      if (origins.length) log(`/.well-known (${origins.length} origem(ns))...`, 'info');

      await mapPool(origins, limits.wellKnownConcurrency, async (baseOrigin) => {
        if (modules.includes('wellknown_security_txt')) {
          try {
            const sec = await fetchWellKnownSecurityTxt(baseOrigin);
            if (sec.ok && sec.findings?.length) {
              for (const f of sec.findings) addFinding(f, null);
            }
          } catch (e) {
            log(`security.txt: ${e.message}`, 'warn');
          }
        }

        if (modules.includes('wellknown_openid')) {
          try {
            const oid = await fetchWellKnownOpenIdConfiguration(baseOrigin);
            if (oid.ok && oid.endpoints?.length) {
              for (const ep of oid.endpoints) {
                let pathname = '/';
                try {
                  pathname = new URL(ep.url).pathname;
                } catch {
                  // keep default
                }
                const { score, prio } = scoreEndpointPath(pathname);
                addFinding(
                  {
                    type: 'endpoint',
                    prio: prio === 'low' ? 'med' : prio,
                    score: Math.max(score, 55),
                    value: ep.url,
                    meta: `OIDC discovery (.well-known) • ${ep.label}`,
                    url: ep.url,
                  },
                  'endpoints',
                );
              }
            }
          } catch (e) {
            log(`OIDC discovery: ${e.message}`, 'warn');
          }
        }
      });
    }
    pipe('surface', 'done');
  } else {
    emit({ type: 'pipe', name: 'surface', state: 'skip' });
  }

  pipe('alive', 'done');
  progress(40);

  // ── WAYBACK / URLS ──────────────────────────
  let waybackUrls = [];
  pipe('urls', 'active');
  if (modules.includes('wayback')) {
    log('Coletando URLs do Wayback Machine (CDX)...', 'info');
    try {
      waybackUrls = await fetchWaybackUrls(domain);
      log(`${waybackUrls.length} URLs únicas (200) no escopo *.${domain}`, 'success');
    } catch (e) {
      log(`Wayback: ${e.message}`, 'warn');
    }
  } else {
    log('Wayback desativado', 'info');
  }

  let ccUrls = [];
  if (modules.includes('common_crawl')) {
    log('Common Crawl (índice CDX)...', 'info');
    try {
      ccUrls = await fetchCommonCrawlUrls(domain);
      log(`${ccUrls.length} URLs únicas (200) no Common Crawl`, 'success');
    } catch (e) {
      log(`Common Crawl: ${e.message}`, 'warn');
    }
  }

  const urlCorpus = [...new Set([...waybackUrls, ...ccUrls])];
  const waybackSet = new Set(waybackUrls);
  const ccSet = new Set(ccUrls);
  const interesting = filterInterestingUrls(urlCorpus);
  log(`${interesting.length} URLs marcadas como interessantes (filtro heurístico)`, 'info');

  // URLs com query string (bons alvos para templates de XSS/SQLi no modo Kali)
  const paramUrlsForKali = [...new Set(urlCorpus.filter((u) => /\?.+=/i.test(u)))].slice(0, 40);

  for (const rawUrl of interesting.slice(0, 400)) {
    let pathname = '/';
    try {
      pathname = new URL(rawUrl).pathname;
    } catch {
      continue;
    }
    const { score, prio } = scoreEndpointPath(pathname);
    if (seenEp.has(rawUrl)) continue;
    seenEp.add(rawUrl);
    const src = waybackSet.has(rawUrl) ? 'Wayback' : ccSet.has(rawUrl) ? 'Common Crawl' : 'arquivo web';
    addFinding(
      {
        type: 'endpoint',
        prio,
        score,
        value: rawUrl,
        meta: `Score ${score}/100 • ${src}`,
        url: rawUrl,
      },
      'endpoints',
    );
  }
  pipe('urls', 'done');
  progress(52);

  // ── PARAMS ──────────────────────────────────
  pipe('params', 'active');
  const paramRows = extractParamsFromUrls(urlCorpus.length ? urlCorpus : interesting);
  for (const { name, count, sampleUrl } of paramRows.slice(0, 60)) {
    const { score, prio } = scoreParamName(name);
    const vuln =
      ['redirect', 'url', 'file', 'path', 'callback'].includes(name.toLowerCase()) ? ' → Open Redirect/SSRF?' : '';
    addFinding(
      {
        type: 'param',
        prio,
        score,
        value: `?${name}=`,
        meta: `~${count} ocorrências em URLs${vuln}`,
        url: sampleUrl || undefined,
      },
      'params',
    );

    // Heurística (passivo): marcar parâmetros comuns para XSS / SQLi como candidatos (não confirmados)
    const n = String(name).toLowerCase();
    const xssCandidates = new Set(['q', 'query', 'search', 's', 'keyword', 'term', 'message', 'comment', 'title', 'name']);
    const sqliCandidates = new Set(['id', 'ids', 'user', 'user_id', 'uid', 'account', 'order', 'order_id', 'page', 'sort', 'filter', 'where']);
    if (xssCandidates.has(n)) {
      addFinding(
        {
          type: 'intel',
          prio: prio === 'high' ? 'med' : 'low',
          score: 54,
          value: `XSS candidate param: ?${name}=`,
          meta: 'Heurístico (passivo) — priorizar testes de reflexão/encoding',
          url: sampleUrl || undefined,
        },
        null,
      );
    }
    if (sqliCandidates.has(n)) {
      addFinding(
        {
          type: 'intel',
          prio: prio === 'high' ? 'med' : 'low',
          score: 56,
          value: `SQLi candidate param: ?${name}=`,
          meta: 'Heurístico (passivo) — priorizar filtros/IDs/ordenação',
          url: sampleUrl || undefined,
        },
        null,
      );
    }
  }
  log(`${paramRows.length} nomes de parâmetros distintos (amostra Wayback)`, 'success');
  pipe('params', 'done');
  progress(60);

  // ── JS ANALYSIS ─────────────────────────────
  pipe('js', 'active');
  const jsList = extractJsUrls(urlCorpus.length ? urlCorpus : [], 120).slice(0, limits.maxJsFetch);
  log(`Analisando ${jsList.length} arquivos JS (passivo)...`, 'info');
  for (const jsUrl of jsList) {
    const a = await analyzeJsUrl(jsUrl);
    if (!a.ok) {
      log(`JS skip: ${jsUrl} (${a.error || a.status})`, 'warn');
      continue;
    }
    for (const ep of a.endpoints.slice(0, 25)) {
      const { score, prio } = scoreEndpointPath(ep);
      addFinding(
        {
          type: 'js',
          prio: prio === 'low' ? 'med' : prio,
          score: Math.max(score, 55),
          value: ep,
          meta: `Extraído de ${jsUrl}`,
          url: jsUrl,
        },
        'endpoints',
      );
    }
    const sec = scanSecrets(a.body || '');
    for (const s of sec) {
      addFinding(
        {
          type: 'secret',
          prio: 'high',
          score: 92,
          value: `[${s.kind}] ${s.masked}`,
          meta: `Possível segredo em JS (verificar falso positivo)`,
          url: jsUrl,
        },
        'secrets',
      );
    }
  }
  pipe('js', 'done');
  progress(72);

  // ── DORKS (URLs apenas) ─────────────────────
  pipe('dorks', 'active');
  const dorks = buildDorks(domainStr, modules);
  for (const d of dorks) {
    emit({
      type: 'dork',
      googleUrl: d.googleUrl,
      query: d.query,
      mod: d.mod,
      prio: d.prio,
    });
    addFinding(
      {
        type: 'dork',
        prio: d.prio,
        score: d.prio === 'high' ? 68 : 55,
        value: d.query,
        meta: `Categoria: ${d.mod}`,
        url: d.googleUrl,
      },
      'dorks',
    );
  }
  log(`${dorks.length} dorks gerados (abertura no browser com fila configurável)`, 'success');

  if (modules.includes('google_cse')) {
    const gKey = process.env.GOOGLE_CSE_KEY;
    const gCx = process.env.GOOGLE_CSE_CX;
    if (!gKey || !gCx) {
      log(
        'Google CSE desativado: defina GOOGLE_CSE_KEY e GOOGLE_CSE_CX (Programmable Search Engine) para descobrir URLs reais via API.',
        'warn',
      );
    } else if (dorks.length === 0) {
      log('Google CSE: nenhum dork gerado — ative categorias de dork na sidebar.', 'warn');
    } else {
      log(
        `Google Custom Search: até ${limits.googleCseMaxQueries} queries neste run (quota diária típica 100 grátis).`,
        'info',
      );
      const seenG = new Set();
      const slice = dorks.slice(0, limits.googleCseMaxQueries);
      for (let i = 0; i < slice.length; i++) {
        const d = slice[i];
        if (i > 0) await sleep(limits.googleCseDelayMs);
        try {
          const items = await googleCseSearch(d.query, gKey, gCx);
          for (const it of items) {
            if (!urlMatchesTarget(it.link, domain)) continue;
            if (seenG.has(it.link)) continue;
            seenG.add(it.link);
            let pathname = '/';
            try {
              pathname = new URL(it.link).pathname;
            } catch {
              continue;
            }
            const { score, prio } = scoreEndpointPath(pathname);
            addFinding(
              {
                type: 'endpoint',
                prio,
                score: Math.max(score, 62),
                value: it.link,
                meta: `Google CSE • ${d.mod} • ${it.title ? it.title.slice(0, 60) : d.query.slice(0, 60)}`,
                url: it.link,
              },
              'endpoints',
            );
            log(`CSE → ${it.link}`, 'find');
          }
        } catch (e) {
          log(`CSE [${d.mod}]: ${e.message}`, 'warn');
        }
      }
      log(`${seenG.size} URL(s) no alvo descoberta(s) via Google CSE`, seenG.size ? 'success' : 'info');
    }
  }

  pipe('dorks', 'done');
  progress(82);

  // ── GITHUB API (opcional) ───────────────────
  pipe('secrets', 'active');
  if (modules.includes('github')) {
    log('GitHub Code Search (API pública, rate limit)...', 'info');
    const gh = await githubCodeSearch(domain, process.env.GITHUB_TOKEN);
    if (gh.ok && gh.items?.length) {
      for (const it of gh.items) {
        addFinding(
          {
            type: 'secret',
            prio: 'high',
            score: 78,
            value: `${it.repo || ''}/${it.path || ''}`,
            meta: 'Resultado GitHub Code Search — revisar manualmente',
            url: it.html_url,
          },
          'secrets',
        );
      }
      log(`${gh.items.length} resultados GitHub (total estimado ${gh.total})`, 'warn');
    } else {
      log(gh.note || 'Sem resultados GitHub ou limite atingido', 'info');
    }
  }
  if (modules.includes('pastebin')) {
    log('Pastebin: sem API pública confiável — use os dorks gerados', 'info');
  }
  pipe('secrets', 'done');

  // ── KALI: nmap / searchsploit / ffuf / nuclei ──
  if (kaliMode) {
    pipe('kali', 'active');
    progress(86);
    const cap = await getKaliCapabilities();
    if (cap.kali) {
      // Só roda wpscan se o passivo já indicou WordPress.
      // Evidência vem de findings do tipo "tech" (geradas no probeHttp).
      const wpHosts = new Set();
      for (const f of findings) {
        if (f?.type !== 'tech') continue;
        const v = String(f.value || '');
        if (!/wordpress/i.test(v)) continue;
        const meta = String(f.meta || '');
        const m = meta.match(/Detectado em\s+(.+)\s*$/i);
        if (m?.[1]) wpHosts.add(m[1]);
      }

      const wordpressTargets = [...wpHosts]
        .slice(0, 10)
        .map((h) => {
          const origin = originByHost.get(h)?.origin;
          if (origin) return origin;
          return [`https://${h}/`, `http://${h}/`];
        })
        .flat()
        .filter(Boolean);

      await runKaliAggressiveScan({
        domain,
        subdomainsAlive,
        cap,
        log,
        addFinding,
        wordpressTargets,
        paramUrls: paramUrlsForKali,
      });
    } else {
      log(`Modo Kali pedido mas ambiente não suporta: ${cap.message}`, 'warn');
    }
    pipe('kali', 'done');
  } else {
    emit({ type: 'pipe', name: 'kali', state: 'skip' });
  }

  progress(90);

  // ── PRIORIZAÇÃO V2 + CVE hints + CORRELATION + INTEL ──
  pipe('score', 'active');
  progress(93);
  log('═══ Priorização v2 (composite + HIGH PROBABILITY) ═══', 'section');
  applyPrioritizationV2(findings);
  stats.high = findings.filter((f) => f.prio === 'high').length;
  emit({ type: 'stats', stats: { ...stats } });
  emit({ type: 'findings_rescore', findings });

  const techStrs = findings.filter((f) => f.type === 'tech').map((f) => f.value);
  const cveHints = extractCveHintsFromTechStrings(techStrs);
  if (cveHints.length) {
    log('═══ Versões detectadas → lookup CVE (manual) ═══', 'section');
    for (const h of cveHints) {
      const label = `${h.product}${h.version ? ` ${h.version}` : ''}`;
      log(`🔎 ${label} — NVD: ${h.nvdUrl}`, 'info');
      log(`   OSV: ${h.osvUrl}`, 'info');
    }
  }

  const hpt = topHighProbability(findings, 8);
  if (hpt.length) {
    log(`═══ HIGH PROBABILITY TARGET (${hpt.length}) ═══`, 'section');
    for (const t of hpt) {
      const w = (t.priorityWhy || []).slice(0, 3).join('; ');
      log(`🎯 [${t.compositeScore}] ${t.type}: ${String(t.value).slice(0, 100)}${w ? ` — ${w}` : ''}`, 'warn');
    }
    emit({
      type: 'priority_pass',
      top: hpt.map((f) => ({
        value: f.value,
        type: f.type,
        compositeScore: f.compositeScore,
        attackTier: f.attackTier,
        why: f.priorityWhy || [],
      })),
    });
  }

  progress(96);
  const corr = correlate({
    subdomainsAlive,
    endpoints: findings.filter((f) => f.type === 'endpoint').map((f) => f.value),
    params: paramRows,
  });
  log('═══ Correlação ═══', 'section');
  log(corr.summary, 'info');
  if (corr.riskyParams.length) {
    log(`Parâmetros de risco presentes: ${corr.riskyParams.join(', ')}`, 'warn');
  }

  log('═══ Workflow de testes (checklist) ═══', 'section');
  const checklist = buildExploitChecklist(findings);
  for (const c of checklist) {
    emit({ type: 'intel', line: `☐ CHECKLIST: ${c}` });
  }

  const hints = suggestVectors({ findings, selectedMods: modules });
  for (const h of hints) {
    emit({ type: 'intel', line: h });
  }
  pipe('score', 'done');
  progress(100);

  const modulesForDb = kaliMode ? [...modules, '__kali_scan__'] : modules;
  const saved = await saveRun({
    target: domain,
    exactMatch,
    modules: modulesForDb,
    stats: { ...stats },
    findings,
    correlation: corr,
  });
  let runId = null;
  let intelMerge = null;
  if (saved != null) {
    runId = saved.runId;
    intelMerge = saved.intelMerge;
    log(`Recon gravado — run #${runId} → ${storageLabel()}`, 'success');
    if (intelMerge?.newArtifacts > 0) {
      log(
        `Corpus do alvo: +${intelMerge.newArtifacts} artefacto(s) novo(s) na base; ${intelMerge.alreadyKnown} já existiam; total único para ${domain}: ${intelMerge.totalKnownForTarget}`,
        'success',
      );
    } else if (findings.length > 0 && intelMerge) {
      log(
        `Corpus do alvo: sem linhas novas (todos os ${intelMerge.alreadyKnown} achados deste run já estavam na base). Total único: ${intelMerge.totalKnownForTarget}`,
        'info',
      );
    }
  } else {
    log(`Não foi possível gravar na base (${storageLabel()}) — ver consola do servidor`, 'warn');
  }

  emit({
    type: 'done',
    target: domain,
    findings,
    stats,
    correlation: corr,
    runId,
    intelMerge,
    kaliMode: Boolean(kaliMode),
    storage: storageLabel(),
  });

  const whUrl = (process.env.GHOSTCTF_WEBHOOK_URL || process.env.GHOSTRECON_WEBHOOK_URL)?.trim();
  if (whUrl && runId != null) {
    void postReconWebhook(whUrl, {
      target: domain,
      runId,
      stats,
      intelMerge,
      kaliMode: Boolean(kaliMode),
      modules: modulesForDb,
    });
  }
}

app.post('/api/recon/stream', async (req, res) => {
  res.setHeader('Content-Type', 'application/x-ndjson; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('X-Accel-Buffering', 'no');

  const send = (obj) => {
    res.write(`${JSON.stringify(obj)}\n`);
  };

  if (!allowReconRequest(req)) {
    send({ type: 'error', message: 'Rate limit — aguarde antes de novo recon' });
    res.end();
    return;
  }

  const domainRaw = req.body?.domain;
  const modules = Array.isArray(req.body?.modules) ? req.body.modules : [];
  const exactMatch = Boolean(req.body?.exactMatch);
  const kaliMode = Boolean(req.body?.kaliMode);

  if (!domainRaw || !isValidDomain(normDomain(domainRaw))) {
    send({ type: 'error', message: 'Domínio inválido' });
    res.end();
    return;
  }

  const domain = normDomain(domainRaw);

  try {
    await runPipeline({
      domain,
      exactMatch,
      modules,
      emit: send,
      kaliMode,
    });
  } catch (e) {
    send({ type: 'error', message: e?.message || String(e) });
  }
  res.end();
});

app.post('/api/ghostctf/stream', async (req, res) => {
  res.setHeader('Content-Type', 'application/x-ndjson; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('X-Accel-Buffering', 'no');

  const send = (obj) => {
    res.write(`${JSON.stringify(obj)}\n`);
  };

  if (!allowReconRequest(req)) {
    send({ type: 'error', message: 'Rate limit — aguarde antes de novo run GhostCTF' });
    res.end();
    return;
  }

  const ipRaw = req.body?.ip;
  const platform = req.body?.platform || 'solyd';
  const modules = Array.isArray(req.body?.modules) ? req.body.modules : [];
  const extraHostsRaw = req.body?.extraHosts;
  const extraHosts = Array.isArray(extraHostsRaw)
    ? extraHostsRaw.map((s) => String(s).trim()).filter(Boolean)
    : typeof extraHostsRaw === 'string'
      ? extraHostsRaw.split(/[\n,]+/).map((s) => s.trim()).filter(Boolean)
      : [];
  const udpScan = Boolean(req.body?.udpScan);
  const tcpAllPorts = Boolean(req.body?.tcpAllPorts);
  const hostsOnlyWeb = Boolean(req.body?.hostsOnlyWeb);

  if (!ipRaw || !isValidIpv4(normIp(ipRaw))) {
    send({ type: 'error', message: 'IP inválido (use IPv4)' });
    res.end();
    return;
  }

  const ip = normIp(ipRaw);

  try {
    await runGhostCtfPipeline({
      ip,
      platformId: platform,
      modules,
      extraHosts,
      hostsOnlyWeb,
      udpScan,
      tcpAllPorts,
      emit: send,
      saveRun,
    });
  } catch (e) {
    send({ type: 'error', message: e?.message || String(e) });
  }

  res.end();
});

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'ghostctf' });
});

app.get('/api/capabilities', async (_req, res) => {
  try {
    const cap = await getKaliCapabilities();
    res.json(cap);
  } catch (e) {
    res.status(500).json({ kali: false, message: e.message, tools: {} });
  }
});

function decodeBase64Maybe(s) {
  let x = String(s ?? '').trim();
  if (!x) return null;
  x = x.replace(/-/g, '+').replace(/_/g, '/');
  const mod = x.length % 4;
  if (mod === 2) x += '==';
  else if (mod === 3) x += '=';
  else if (mod === 1) return null;
  try {
    const out = Buffer.from(x, 'base64').toString('utf8');
    return out && out.length >= 1 ? out : null;
  } catch {
    return null;
  }
}

function decodeBase32Maybe(s) {
  let x = String(s ?? '').trim().replace(/=+$/g, '');
  if (!x) return null;
  x = x.toUpperCase();
  if (!/^[A-Z2-7]+$/.test(x)) return null;
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const ch of x) {
    const idx = alphabet.indexOf(ch);
    if (idx < 0) return null;
    bits += idx.toString(2).padStart(5, '0');
  }
  let out = '';
  for (let i = 0; i + 8 <= bits.length; i += 8) {
    out += String.fromCharCode(parseInt(bits.slice(i, i + 8), 2));
  }
  if (!out) return null;
  try {
    return decodeURIComponent(escape(out));
  } catch {
    return out;
  }
}

function extractFlagsByPlatform(text, platformId) {
  const platform = getPlatform(platformId);
  if (!platform) return [];
  const t = String(text ?? '');
  const re = new RegExp(platform.flagRegex.source, platform.flagRegex.flags);
  const out = [];
  let m;
  while ((m = re.exec(t)) !== null) {
    const f = m[0];
    if (platform.validateFlag(f)) out.push(f);
    if (out.length >= 25) break;
  }
  return [...new Set(out)];
}

app.post('/api/ghostctf/decode', async (req, res) => {
  const input = String(req.body?.input ?? '').trim();
  const platformId = String(req.body?.platform || 'solyd').trim().toLowerCase();
  if (!input) {
    res.status(400).json({ ok: false, error: 'input vazio' });
    return;
  }

  const b64 = decodeBase64Maybe(input);
  const b32 = decodeBase32Maybe(input);
  const candidates = [];
  if (b64 != null) candidates.push({ kind: 'base64', decoded: b64 });
  if (b32 != null) candidates.push({ kind: 'base32', decoded: b32 });

  let detected = 'unknown';
  if (b64 != null && b32 == null) detected = 'base64';
  else if (b32 != null && b64 == null) detected = 'base32';
  else if (b64 != null && b32 != null) detected = 'ambiguous';

  const flags = [];
  for (const c of candidates) {
    const hits = extractFlagsByPlatform(c.decoded, platformId);
    for (const h of hits) flags.push({ flag: h, source: c.kind });
  }
  const uniq = [];
  const seen = new Set();
  for (const f of flags) {
    if (seen.has(f.flag)) continue;
    seen.add(f.flag);
    uniq.push(f);
  }

  res.json({
    ok: true,
    detected,
    candidates: candidates.map((c) => ({
      kind: c.kind,
      decoded: c.decoded.slice(0, 4000),
    })),
    flags: uniq,
  });
});

app.post('/api/ghostctf/hash', async (req, res) => {
  const input = String(req.body?.input ?? '');
  if (!input.trim()) {
    res.status(400).json({ ok: false, error: 'input vazio' });
    return;
  }
  const text = input;
  const trimmed = text.trim();
  const lower = trimmed.toLowerCase();

  const md5 = crypto.createHash('md5').update(text, 'utf8').digest('hex');
  const sha1 = crypto.createHash('sha1').update(text, 'utf8').digest('hex');
  const sha256 = crypto.createHash('sha256').update(text, 'utf8').digest('hex');

  let detected = 'texto';
  if (/^[a-f0-9]{32}$/.test(lower)) detected = 'hash-md5';
  else if (/^[a-f0-9]{40}$/.test(lower)) detected = 'hash-sha1';
  else if (/^[a-f0-9]{64}$/.test(lower)) detected = 'hash-sha256';

  res.json({
    ok: true,
    detected,
    inputLength: text.length,
    hashes: { md5, sha1, sha256 },
  });
});

async function crackMd5WithWordlist({ targetHash, wordlistPath, maxLines = 300000 }) {
  return await new Promise((resolve, reject) => {
    const stream = fs.createReadStream(wordlistPath, { encoding: 'utf8' });
    stream.on('error', (e) => reject(e));
    const rl = readline.createInterface({ input: stream, crlfDelay: Infinity });
    let tried = 0;
    let found = null;

    rl.on('line', (line) => {
      if (found) return;
      tried += 1;
      const candidate = String(line ?? '');
      const digest = crypto.createHash('md5').update(candidate, 'utf8').digest('hex');
      if (digest === targetHash) {
        found = candidate;
        rl.close();
      } else if (tried >= maxLines) {
        rl.close();
      }
    });
    rl.on('close', () => resolve({ tried, found }));
  });
}

function runProc(cmd, args, timeoutMs = 90000) {
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

async function hasCommand(cmd) {
  const finder = process.platform === 'win32' ? 'where' : 'which';
  try {
    const r = await runProc(finder, [cmd], 4000);
    return r.code === 0;
  } catch {
    return false;
  }
}

async function crackMd5WithJohn({ targetHash, wordlistPath, maxRunSec = 45 }) {
  const johnOk = await hasCommand('john');
  if (!johnOk) return { ok: false, found: false, reason: 'john_missing' };
  if (!wordlistPath || !fs.existsSync(wordlistPath)) return { ok: false, found: false, reason: 'wordlist_missing' };

  const dir = await mkdtemp(path.join(tmpdir(), 'ghjohn-'));
  const hashFile = path.join(dir, 'hashes.txt');
  const potFile = path.join(dir, 'john.pot');
  try {
    await writeFile(hashFile, `${targetHash}\n`, 'utf8');
    const runArgs = [
      '--format=raw-md5',
      '--wordlist',
      wordlistPath,
      `--pot=${potFile}`,
      `--max-run-time=${Math.max(5, Math.min(180, Number(maxRunSec) || 45))}`,
      hashFile,
    ];
    await runProc('john', runArgs, 120000);

    const showArgs = ['--show', '--format=raw-md5', `--pot=${potFile}`, hashFile];
    const shown = await runProc('john', showArgs, 15000);
    const lines = String(shown.stdout || '')
      .split(/\r?\n/)
      .map((x) => x.trim())
      .filter(Boolean);
    const crackLine = lines.find((x) => x.includes(':') && !/^\d+\s+password hash/i.test(x));
    if (!crackLine) return { ok: true, found: false };

    const parts = crackLine.split(':');
    const plaintext = parts.length >= 2 ? parts[1] : '';
    if (!plaintext) return { ok: true, found: false };
    return { ok: true, found: true, plaintext };
  } catch (e) {
    return { ok: false, found: false, reason: e?.message || String(e) };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

async function crackHashWithJohn({
  hashLine,
  format,
  wordlistPath,
  maxRunSec = 60,
  useRules = false,
  incrementalMode = '',
} = {}) {
  const johnOk = await hasCommand('john');
  if (!johnOk) return { ok: false, found: false, reason: 'john_missing' };
  const hasWordlist = wordlistPath && fs.existsSync(wordlistPath);
  if (!hasWordlist && !incrementalMode) return { ok: false, found: false, reason: 'wordlist_missing' };

  const fmt = String(format || '').trim() || 'raw-md5';
  const dir = await mkdtemp(path.join(tmpdir(), 'ghjohnx-'));
  const hashFile = path.join(dir, 'hashes.txt');
  const potFile = path.join(dir, 'john.pot');
  try {
    await writeFile(hashFile, `${String(hashLine || '').trim()}\n`, 'utf8');
    const runArgs = [`--format=${fmt}`, `--pot=${potFile}`, `--max-run-time=${Math.max(5, Math.min(300, Number(maxRunSec) || 60))}`];
    if (incrementalMode) {
      runArgs.push(`--incremental=${incrementalMode}`);
    } else {
      runArgs.push('--wordlist', wordlistPath);
      if (useRules) runArgs.push('--rules');
    }
    runArgs.push(hashFile);
    const run = await runProc('john', runArgs, 180000);
    const showArgs = ['--show', `--format=${fmt}`, `--pot=${potFile}`, hashFile];
    const shown = await runProc('john', showArgs, 20000);
    const lines = String(shown.stdout || '')
      .split(/\r?\n/)
      .map((x) => x.trim())
      .filter(Boolean);
    const crackLine = lines.find((x) => x.includes(':') && !/^\d+\s+password hash/i.test(x));
    if (!crackLine) return { ok: true, found: false, runCode: run.code };
    const parts = crackLine.split(':');
    const plaintext = parts.length >= 2 ? parts[1] : '';
    if (!plaintext) return { ok: true, found: false, runCode: run.code };
    return { ok: true, found: true, plaintext, runCode: run.code };
  } catch (e) {
    return { ok: false, found: false, reason: e?.message || String(e) };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

app.post('/api/ghostctf/hash-crack', async (req, res) => {
  const inputRaw = String(req.body?.input ?? '').trim().toLowerCase();
  const isMd5 = /^[a-f0-9]{32}$/.test(inputRaw);
  if (!isMd5) {
    res.status(400).json({ ok: false, error: 'informe um hash MD5 (32 hex)' });
    return;
  }

  const customWordlist = String(req.body?.wordlist ?? '').trim();
  const maxLines = Math.max(1000, Math.min(2000000, Number(req.body?.maxLines) || 300000));
  const wordlists = [
    customWordlist || null,
    '/usr/share/wordlists/rockyou.txt',
    '/usr/share/wordlists/dirb/common.txt',
    '/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt',
    '/usr/share/seclists/Passwords/Common-Credentials/500-worst-passwords.txt',
  ].filter(Boolean);

  for (const wl of wordlists) {
    if (!fs.existsSync(wl)) continue;
    try {
      const j = await crackMd5WithJohn({ targetHash: inputRaw, wordlistPath: wl, maxRunSec: 45 });
      if (j.found) {
        res.json({
          ok: true,
          found: true,
          plaintext: j.plaintext,
          tried: null,
          engine: 'john',
          wordlist: wl,
        });
        return;
      }
      const r = await crackMd5WithWordlist({ targetHash: inputRaw, wordlistPath: wl, maxLines });
      if (r.found != null) {
        res.json({
          ok: true,
          found: true,
          plaintext: r.found,
          tried: r.tried,
          engine: 'local-wordlist',
          wordlist: wl,
        });
        return;
      }
    } catch {
      // tenta próxima
    }
  }

  res.json({
    ok: true,
    found: false,
    plaintext: null,
    triedApprox: maxLines,
    message: 'não encontrado nas wordlists disponíveis dentro do limite',
  });
});

app.post('/api/ghostctf/john-crack', async (req, res) => {
  const hashLine = String(req.body?.hash ?? '').trim();
  if (!hashLine) {
    res.status(400).json({ ok: false, error: 'hash vazio' });
    return;
  }
  const format = String(req.body?.format ?? 'raw-md5').trim() || 'raw-md5';
  const customWordlist = String(req.body?.wordlist ?? '').trim();
  const maxRunSec = Math.max(5, Math.min(300, Number(req.body?.maxRunSec) || 60));
  const enableRules = Boolean(req.body?.enableRules ?? true);
  const enableIncremental = Boolean(req.body?.enableIncremental ?? false);
  const incrementalMode = String(req.body?.incrementalMode ?? 'Digits').trim() || 'Digits';

  const wordlists = [
    customWordlist || null,
    '/usr/share/wordlists/rockyou.txt',
    '/usr/share/wordlists/dirb/common.txt',
    '/usr/share/seclists/Passwords/Common-Credentials/10k-most-common.txt',
    '/usr/share/seclists/Passwords/Common-Credentials/500-worst-passwords.txt',
  ].filter(Boolean);

  let triedWordlists = 0;
  let phasesTried = [];
  for (const wl of wordlists) {
    if (!fs.existsSync(wl)) continue;
    triedWordlists += 1;
    // Fase 1: wordlist direta
    let r = await crackHashWithJohn({
      hashLine,
      format,
      wordlistPath: wl,
      maxRunSec,
      useRules: false,
      incrementalMode: '',
    });
    phasesTried.push(`wordlist:${wl}`);
    if (r.found) {
      res.json({
        ok: true,
        found: true,
        engine: 'john',
        plaintext: r.plaintext,
        format,
        wordlist: wl,
        phase: 'wordlist',
      });
      return;
    }
    // Fase 2: wordlist + rules
    if (enableRules) {
      r = await crackHashWithJohn({
        hashLine,
        format,
        wordlistPath: wl,
        maxRunSec,
        useRules: true,
        incrementalMode: '',
      });
      phasesTried.push(`wordlist+rules:${wl}`);
      if (r.found) {
        res.json({
          ok: true,
          found: true,
          engine: 'john',
          plaintext: r.plaintext,
          format,
          wordlist: wl,
          phase: 'wordlist+rules',
        });
        return;
      }
    }
    if (!r.ok && r.reason === 'john_missing') {
      res.status(400).json({ ok: false, error: 'john não encontrado no PATH' });
      return;
    }
  }

  // Fase 3: incremental curto (opcional, sem wordlist)
  if (enableIncremental) {
    phasesTried.push(`incremental:${incrementalMode}`);
    const r = await crackHashWithJohn({
      hashLine,
      format,
      wordlistPath: '',
      maxRunSec: Math.min(maxRunSec, 45),
      useRules: false,
      incrementalMode,
    });
    if (r.found) {
      res.json({
        ok: true,
        found: true,
        engine: 'john',
        plaintext: r.plaintext,
        format,
        wordlist: null,
        phase: `incremental:${incrementalMode}`,
      });
      return;
    }
  }

  res.json({
    ok: true,
    found: false,
    engine: 'john',
    format,
    triedWordlists,
    phasesTried,
    message: 'não encontrado nas wordlists disponíveis',
  });
});

app.get('/api/runs', async (req, res) => {
  const lim = Number(req.query.limit) || 50;
  try {
    const runs = await listRuns(lim);
    res.json({ runs });
  } catch (e) {
    res.status(500).json({ error: e?.message || String(e) });
  }
});

app.get('/api/runs/:id', async (req, res) => {
  const id = Number(req.params.id);
  if (!Number.isFinite(id)) {
    res.status(400).json({ error: 'id inválido' });
    return;
  }
  try {
    const run = await getRunById(id);
    if (!run) {
      res.status(404).json({ error: 'run não encontrado' });
      return;
    }
    res.json(run);
  } catch (e) {
    res.status(500).json({ error: e?.message || String(e) });
  }
});

/** Diff entre dois runs do mesmo alvo (fingerprints como `bounty_intel`). */
app.get('/api/runs/:newerId/diff/:baselineId', async (req, res) => {
  const newerId = Number(req.params.newerId);
  const baselineId = Number(req.params.baselineId);
  if (!Number.isFinite(newerId) || !Number.isFinite(baselineId)) {
    res.status(400).json({ error: 'ids inválidos' });
    return;
  }
  try {
    const result = await compareRuns(baselineId, newerId);
    if (result.error) {
      res.status(result.error === 'run não encontrado' ? 404 : 400).json(result);
      return;
    }
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e?.message || String(e) });
  }
});

/** Corpus deduplicado por alvo (`bounty_intel` — SQLite ou Supabase). */
app.get('/api/intel/:target', async (req, res) => {
  const raw = String(req.params.target || '').trim();
  const isIp = isValidIpv4(raw);
  const t = isIp ? normIp(raw) : raw.toLowerCase();
  if (!t) {
    res.status(400).json({ error: 'target inválido' });
    return;
  }
  if (!isIp && !/^[a-z0-9][a-z0-9.-]*[a-z0-9]$/.test(t)) {
    res.status(400).json({ error: 'target inválido (use domínio ou IPv4)' });
    return;
  }
  try {
    const [totalUnique, items] = await Promise.all([
      intelCountForTarget(t),
      listIntelForTarget(t, 500),
    ]);
    res.json({
      target: t,
      kind: isIp ? 'ip' : 'domain',
      totalUnique,
      items,
    });
  } catch (e) {
    res.status(500).json({ error: e?.message || String(e) });
  }
});

/** Biblioteca global de falhas (independente de alvo/IP). */
app.get('/api/knowledge', async (req, res) => {
  const lim = Number(req.query.limit) || 80;
  try {
    const items = await listKnowledge(lim);
    res.json({ ok: true, items });
  } catch (e) {
    res.status(500).json({ ok: false, error: e?.message || String(e) });
  }
});

app.use(express.static(ROOT, { index: false }));
app.get('/', (_req, res) => {
  res.sendFile(path.join(ROOT, 'index.html'));
});

const PORT = Number(process.env.PORT) || 3847;
const server = createServer(app);
attachShellWebSocket(server);
server.listen(PORT, () => {
  console.log(`GHOSTCTF → http://127.0.0.1:${PORT}`);
});
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      `[GHOSTCTF] Porta ${PORT} em uso. Encerre a instância anterior (ex.: netstat -ano | findstr :${PORT}) ou defina PORT=3850 antes de npm start.`,
    );
  } else {
    console.error('[GHOSTCTF]', err.message);
  }
  process.exit(1);
});
