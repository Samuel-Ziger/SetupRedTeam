import './load-env.js';
import express from 'express';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { randomBytes } from 'crypto';
import { fetchCrtShSubdomains } from './modules/subdomains.js';
import { resolves } from './modules/dns.js';
import { probeHttp, mapPool } from './modules/probe.js';
import { analyzeSecurityHeaders } from './modules/security-headers.js';
import { peekTlsCertificate } from './modules/tls-cert.js';
import { crawlRobotsAndSitemapsForOrigin } from './modules/robots-sitemap.js';
import {
  parseOutOfScopeEnv,
  hostInReconScope,
  urlInReconScope,
  parseOutOfScopeClientInput,
  mergeOutOfScopeLists,
} from './modules/scope.js';
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
import { runEvidenceVerification, runMicroExploitVariants } from './modules/verify.js';
import { harvestOpenApiFromOrigins, tryGraphqlMinimalProbe } from './modules/openapi-harvest.js';
import { dedupeBySemanticFamily } from './modules/semantic-dedupe.js';
import { buildReportTemplates } from './modules/report-template.js';
import { discoverAssetHints, detectTakeoverCandidates } from './modules/asset-discovery.js';
import { resolveReconProfile } from './modules/runtime-profile.js';
import { fetchArchiveToolUrls } from './modules/archive-tools.js';
import { wafw00fFingerprint } from './modules/waf-fingerprint.js';
import { discoverParamsActive } from './modules/param-discovery.js';
import { resolveCnameChain, matchProviderByCname, matchProviderBody } from './modules/takeover.js';
import { crawlWithKatana } from './modules/js-crawler.js';
import { validateSecretFindings } from './modules/secret-validation.js';
import { limits, reconRateLimitConfig } from './config.js';
import {
  saveRun,
  listRuns,
  getRunById,
  listIntelForTarget,
  intelCountForTarget,
  storageLabel,
  fingerprintFinding,
} from './modules/db.js';
import { collectUniqueIpv4, shodanHostSummary } from './modules/ip-intel.js';
import { googleCseSearch } from './modules/google-cse.js';
import { getKaliCapabilities, runKaliAggressiveScan } from './modules/kali-scan.js';
import { runDualAiReports, aiKeysConfigured } from './modules/ai-dual-report.js';
import { enumerateSubdomainsWithSubfinder, enumerateSubdomainsWithAmass } from './modules/kali-subdomain-tools.js';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const reconRlHits = new Map();
const csrfTokens = new Map();
const CSRF_TTL_MS = 2 * 60 * 60 * 1000;

const PORT = Number(process.env.PORT) || 3847;
const HOST = String(process.env.HOST || '127.0.0.1').trim();
const allowedOrigins = new Set([`http://127.0.0.1:${PORT}`, `http://localhost:${PORT}`]);

function clientIp(req) {
  return String(
    req.headers['x-forwarded-for']?.split(',')[0]?.trim() || req.socket?.remoteAddress || '_',
  );
}

function cleanupExpiredCsrfTokens(now = Date.now()) {
  for (const [token, entry] of csrfTokens.entries()) {
    if (!entry?.expiresAt || entry.expiresAt <= now) csrfTokens.delete(token);
  }
}

function issueCsrfToken(req) {
  cleanupExpiredCsrfTokens();
  const token = randomBytes(24).toString('hex');
  csrfTokens.set(token, { ip: clientIp(req), expiresAt: Date.now() + CSRF_TTL_MS });
  return token;
}

function validateCsrfToken(req) {
  cleanupExpiredCsrfTokens();
  const token = String(req.headers['x-csrf-token'] || '').trim();
  if (!token) return false;
  const entry = csrfTokens.get(token);
  if (!entry) return false;
  if (entry.ip !== clientIp(req)) return false;
  if (entry.expiresAt <= Date.now()) {
    csrfTokens.delete(token);
    return false;
  }
  return true;
}

function allowReconRequest(req) {
  const { max, windowMs } = reconRateLimitConfig();
  if (max <= 0) return true;
  const ip = clientIp(req);
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
  const origin = String(req.headers.origin || '').trim();
  const hasOrigin = Boolean(origin);
  const originAllowed = hasOrigin ? allowedOrigins.has(origin) : true;

  if (hasOrigin && originAllowed) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-CSRF-Token');
  if (req.method === 'OPTIONS') {
    if (!originAllowed) {
      res.sendStatus(403);
      return;
    }
    res.sendStatus(204);
    return;
  }
  if (!originAllowed) {
    res.status(403).json({ error: 'origin não permitido' });
    return;
  }
  next();
});

app.use(express.json({ limit: '5mb' }));

function isValidDomain(d) {
  return /^[a-zA-Z0-9][a-zA-Z0-9-.]+\.[a-zA-Z]{2,}$/.test(d);
}

function normDomain(d) {
  return d.trim().toLowerCase().replace(/^https?:\/\//, '').split('/')[0];
}

function aiAutoReportsServerAllowed() {
  const v = String(process.env.GHOSTRECON_AI_AUTO ?? '1').trim().toLowerCase();
  return v !== '0' && v !== 'false' && v !== 'no';
}

/** Mesmo formato que `buildPipelineExportPayload()` na UI — para `runDualAiReports`. */
/** Lê os .md de próximos passos gerados pela IA e envia para o terminal NDJSON (decisão antes do próximo alvo na fila). */
function emitIaProximosPassosToLog(aiOut, log) {
  if (!aiOut || typeof log !== 'function') return;
  const parts = [];
  if (aiOut.gemini?.ok && aiOut.gemini.proximosPath) {
    parts.push({ label: 'Gemini — próximos passos', path: aiOut.gemini.proximosPath });
  }
  if (aiOut.claude?.ok && aiOut.claude.proximosPath) {
    parts.push({ label: 'Claude — próximos passos', path: aiOut.claude.proximosPath });
  }
  if (!parts.length) return;
  log('═══ DECISÃO / PRÓXIMOS PASSOS (IA) ═══', 'section');
  for (const { label, path: fpath } of parts) {
    log(`── ${label} ──`, 'section');
    try {
      const text = fs.readFileSync(fpath, 'utf8');
      for (const line of text.split('\n')) {
        const t = line.replace(/\r$/, '');
        if (t.trim() === '') log(' ', 'info');
        else if (t.length > 2400) log(`${t.slice(0, 2400)}…`, 'info');
        else log(t, 'info');
      }
    } catch (e) {
      log(`Não foi possível ler ${fpath}: ${e.message}`, 'warn');
    }
  }
  log('═══ Fim decisão IA — pode seguir para o próximo alvo ═══', 'section');
}

function buildPipelineExportPayloadForAi({
  target,
  projectName,
  stats,
  findings,
  correlation,
  reportTemplates,
  runId,
  storage,
  intelMerge,
  kaliMode,
  modules,
}) {
  const findingsExport = findings.map((f) => ({
    type: f.type,
    priority: f.prio,
    score: f.score || 0,
    value: f.value,
    meta: f.meta || '',
    url: f.url || '',
    fingerprint: f.fingerprint || '',
    compositeScore: f.compositeScore,
    attackTier: f.attackTier,
    priorityWhy: f.priorityWhy,
  }));
  return {
    schemaVersion: 1,
    source: 'ghostrecon-server-pipeline',
    exportedAt: new Date().toISOString(),
    projectName: projectName || undefined,
    target,
    stats: { ...stats },
    findings: findingsExport,
    correlation,
    reportTemplates,
    runId,
    storage,
    intelMerge,
    kaliMode,
    modules,
  };
}

async function runPipeline(ctx) {
  const {
    domain,
    exactMatch,
    modules,
    emit,
    kaliMode = false,
    auth = null,
    profile = 'standard',
    outOfScope: outOfScopeClientRaw = null,
    projectName: projectNameRaw = '',
    autoAiReports = false,
  } = ctx;
  const runtimeProfile = resolveReconProfile(profile);
  const domainStr = exactMatch ? `"${domain}"` : domain;
  const findings = [];
  const stats = { subs: 0, endpoints: 0, params: 0, secrets: 0, dorks: 0, high: 0 };

  const addFinding = (f, statKey) => {
    try {
      f.fingerprint = fingerprintFinding(domain, f);
    } catch {
      /* ignore */
    }
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
  let tlsSanHosts = [];

  log(`Alvo: ${domain} | Módulos: ${modules.join(', ')} | Perfil: ${runtimeProfile.name}`, 'info');
  log(exactMatch ? 'Modo: exact match (aspas nos dorks)' : 'Modo: broad match', 'info');
  const outOfScopeFromEnv = parseOutOfScopeEnv(process.env.GHOSTRECON_OUT_OF_SCOPE);
  let outOfScopeList = [...outOfScopeFromEnv];
  if (modules.includes('out_of_scope') && outOfScopeClientRaw != null && outOfScopeClientRaw !== '') {
    const fromUi = parseOutOfScopeClientInput(outOfScopeClientRaw);
    outOfScopeList = mergeOutOfScopeLists(outOfScopeFromEnv, fromUi);
  }
  if (outOfScopeList.length) {
    log(`Fora de escopo (${outOfScopeList.length} regra(s)): ${outOfScopeList.join(', ')}`, 'info');
  }

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
  /** Hostnames normalizados devolvidos pelo subfinder (para meta `tool=subfinder` na UI). */
  const subfinderHostsNorm = new Set();
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
          for (const h of extra) {
            const hn = String(h).trim().toLowerCase();
            if (hn) subfinderHostsNorm.add(hn);
          }
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
        const hn = String(host).trim().toLowerCase();
        const viaSubfinder = subfinderHostsNorm.has(hn);
        addFinding(
          {
            type: 'subdomain',
            prio,
            score,
            value: host,
            meta: `DNS: ${r.records.join(', ')}${viaSubfinder ? ' · tool=subfinder' : ''}`,
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
  ].slice(0, runtimeProfile.maxHostsToProbe);
  const urlsToProbe = [];
  for (const h of hostsToProbe) {
    urlsToProbe.push(`https://${h}/`, `http://${h}/`);
  }
  log(`HTTP probing em ${hostsToProbe.length} hosts (GET, timeout ${limits.probeTimeoutMs}ms)...`, 'info');

  const probeResults = await mapPool(urlsToProbe, limits.probeConcurrency, async (u) => {
    const r = await probeHttp(u, { auth, modules });
    return { u, r };
  });

  const seenTech = new Set();
  for (const { r } of probeResults) {
    if (!r.ok) continue;
    const host = new URL(r.url).hostname;
    if (r.status > 0 && r.status < 500) {
      log(`ALIVE ${r.url} → ${r.status} ${r.title ? `"${r.title.slice(0, 60)}"` : ''}`, 'success');
      // WAFW00F (fase 2 – opcional, melhor em quick<= off; standard/deep só se ferramenta existir)
      if (modules.includes('wafw00f') || runtimeProfile.name !== 'quick') {
        try {
          const wf = await wafw00fFingerprint(host);
          if (wf?.waf) {
            addFinding({
              type: 'intel',
              prio: 'low',
              score: 30,
              value: `WAF detected: ${wf.waf} @ ${host}`,
              meta: `waf=${wf.waf} • tool=wafw00f`,
              url: r.url,
            });
          }
        } catch {}
      }
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
        if (String(t).toLowerCase().includes('cloudflare')) {
          addFinding({
            type: 'intel',
            prio: 'low',
            score: 28,
            value: `WAF hint @ ${host}`,
            meta: 'waf=cloudflare',
            url: r.url,
          });
        }
      }
    }
  }

  {
    let surfaceN = 0;
    const cap = limits.htmlSurfaceMaxEndpoints;
    for (const { r } of probeResults) {
      if (!r.ok || !r.surface) continue;
      if (surfaceN >= cap) break;
      let pageHost = '';
      try {
        pageHost = new URL(r.url).hostname;
      } catch {
        continue;
      }
      const merged = [...(r.surface.links || []), ...(r.surface.formActions || [])];
      for (const link of merged) {
        if (surfaceN >= cap) break;
        let u;
        try {
          u = new URL(link);
        } catch {
          continue;
        }
        if (!hostInReconScope(u.hostname, domain, outOfScopeList)) continue;
        const href = u.href;
        if (seenEp.has(href)) continue;
        seenEp.add(href);
        const { score, prio } = scoreEndpointPath(u.pathname);
        addFinding(
          {
            type: 'endpoint',
            prio,
            score: Math.max(score, 42),
            value: href,
            meta: `HTML surface • ${pageHost}`,
            url: href,
          },
          'endpoints',
        );
        surfaceN++;
      }
    }
    if (surfaceN) log(`Superfície HTML: +${surfaceN} URL(s) (href/forms)`, 'info');
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
    if (!hostInReconScope(u.hostname, domain, outOfScopeList)) continue;
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
          if (cert.subjectAltName) {
            const sanHosts = String(cert.subjectAltName)
              .split(',')
              .map((x) => x.replace(/DNS:/gi, '').trim().toLowerCase().replace(/^\*\./, ''))
              .filter((x) => /^[a-z0-9][a-z0-9.-]+\.[a-z]{2,}$/i.test(x))
              .slice(0, 30);
            tlsSanHosts = [...new Set([...tlsSanHosts, ...sanHosts])];
          }
        }
      });
    }
    if (modules.includes('robots_sitemap')) {
      const bases = [...originByHost.values()].map((v) => v.origin);
      log(`robots.txt / sitemap (${bases.length} origem(ns))...`, 'info');
      await mapPool(bases, limits.surfaceConcurrency, async (baseOrigin) => {
        const crawl = await crawlRobotsAndSitemapsForOrigin(baseOrigin, domain, outOfScopeList);
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

  if (modules.includes('shodan')) {
    const sk = process.env.SHODAN_API_KEY?.trim();
    if (!sk) {
      log('Shodan: define SHODAN_API_KEY para lookup passivo (api.shodan.io)', 'warn');
    } else {
      log('Shodan: resolução IPv4 + host lookup (passivo)...', 'info');
      try {
        const ips = await collectUniqueIpv4(
          hostsToProbe,
          limits.shodanResolveMaxHosts,
          limits.shodanMaxIps,
        );
        for (const ip of ips) {
          const s = await shodanHostSummary(ip, sk);
          if (!s.ok) {
            log(`Shodan ${ip}: ${s.note}`, 'warn');
            continue;
          }
          const portStr = s.ports?.length ? s.ports.join(', ') : '—';
          const hn = s.hostnames?.length ? s.hostnames.join(', ') : '—';
          const vn = s.vulns?.length ? s.vulns.join(', ') : '';
          addFinding(
            {
              type: 'intel',
              prio: s.vulns?.length ? 'high' : 'med',
              score: s.vulns?.length ? 74 : 50,
              value: `Shodan host ${ip}`,
              meta: [
                s.org && `org: ${s.org}`,
                `ports: ${portStr}`,
                `hostnames: ${hn}`,
                vn && `cve/tags: ${vn}`,
              ]
                .filter(Boolean)
                .join(' · '),
              url: `https://www.shodan.io/host/${ip}`,
            },
            null,
          );
        }
      } catch (e) {
        log(`Shodan: ${e.message}`, 'warn');
      }
    }
  }

  if (modules.includes('openapi_specs')) {
    log('OpenAPI/Swagger: a procurar specs em paths comuns…', 'info');
    try {
      const bases = [...originByHost.values()].map((v) => v.origin);
      const specRows = await harvestOpenApiFromOrigins(bases, domain, outOfScopeList, modules, log);
      for (const row of specRows) {
        addFinding(row, row.type === 'param' ? 'params' : row.type === 'endpoint' ? 'endpoints' : null);
      }
    } catch (e) {
      log(`OpenAPI harvest: ${e.message}`, 'warn');
    }
  }

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

  let archiveCliUrls = [];
  if (runtimeProfile.includeCliArchives || modules.includes('gau') || modules.includes('waybackurls')) {
    try {
      archiveCliUrls = await fetchArchiveToolUrls(domain, log);
    } catch (e) {
      log(`Archive CLI: ${e.message}`, 'warn');
    }
  }

  let urlCorpus = [...new Set([...waybackUrls, ...ccUrls, ...archiveCliUrls])];
  if (runtimeProfile.name === 'deep') {
    const seeds = [`https://${domain}/`, `http://${domain}/`];
    for (const seed of seeds) {
      try {
        const k = await crawlWithKatana(seed, { depth: 3 });
        if (k.ok && k.urls.length) {
          let added = 0;
          for (const u of k.urls.slice(0, 300)) {
            if (!urlInReconScope(u, domain, outOfScopeList)) continue;
            if (!urlCorpus.includes(u)) {
              urlCorpus.push(u);
              added++;
            }
          }
          log(`Katana: +${added} URL(s) no escopo via crawl JS (${k.urls.length} brutas)`, 'info');
        }
      } catch (e) {
        log(`Katana: ${e.message}`, 'warn');
      }
    }
  }
  urlCorpus = urlCorpus.filter((u) => urlInReconScope(u, domain, outOfScopeList));

  if (modules.includes('graphql_probe')) {
    const gqlUrls = [...new Set(urlCorpus.filter((u) => /graphql/i.test(u)))].slice(0, 10);
    if (!gqlUrls.length) {
      log(
        'GraphQL: módulo activo mas nenhuma URL com "graphql" no corpus — liga Wayback/Common Crawl ou outras fontes de URLs.',
        'info',
      );
    } else {
      try {
        const gqlFindings = await tryGraphqlMinimalProbe(gqlUrls, domain, outOfScopeList, modules, log);
        for (const gf of gqlFindings) addFinding(gf, null);
      } catch (e) {
        log(`GraphQL probe: ${e.message}`, 'warn');
      }
    }
  }

  const waybackSet = new Set(waybackUrls);
  const ccSet = new Set(ccUrls);
  const interesting = filterInterestingUrls(urlCorpus);
  log(`${interesting.length} URLs marcadas como interessantes (filtro heurístico)`, 'info');

  // URLs com query string (bons alvos para templates de XSS/SQLi no modo Kali)
  const paramUrlsForKali = [...new Set(urlCorpus.filter((u) => /\?.+=/i.test(u)))].slice(0, 40);

  for (const rawUrl of interesting.slice(0, runtimeProfile.maxInterestingUrls)) {
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
          meta: 'Heurístico (passivo) — priorizar testes de reflexão/encoding • confidence=heuristic',
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
          meta: 'Heurístico (passivo) — priorizar filtros/IDs/ordenação • confidence=heuristic',
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
    const a = await analyzeJsUrl(jsUrl, { modules });
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
    for (const ins of a.insights || []) {
      addFinding(
        {
          type: 'intel',
          prio: ins.kind === 'role_admin_hint' ? 'high' : 'med',
          score: ins.kind === 'role_admin_hint' ? 72 : 58,
          value: `JS insight (${ins.kind}): ${ins.snippet.slice(0, 160)}`,
          meta: `js_context • kind=${ins.kind} • confidence=heuristic`,
          url: jsUrl,
        },
        null,
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
  const techHintsForDorks = findings.filter((f) => f.type === 'tech').map((f) => f.value);
  const dorks = buildDorks(domainStr, modules, techHintsForDorks);
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
            if (!urlInReconScope(it.link, domain, outOfScopeList)) continue;
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
  // Validação live/dead de achados de secret (fase 3)
  try {
    const sv = await validateSecretFindings(findings, log);
    for (const row of sv) {
      addFinding({
        type: 'secret_validation',
        prio: row.status === 'live' ? 'high' : row.status === 'probable' ? 'med' : 'low',
        score: row.status === 'live' ? 86 : row.status === 'probable' ? 62 : 24,
        value: `Secret ${row.status.toUpperCase()} • ${row.ref}`,
        meta: `reason=${row.reason}`,
      });
    }
    if (sv.length) log(`Secret validation: ${sv.length} item(ns)`, 'info');
  } catch (e) {
    log(`Secret validation: ${e.message}`, 'warn');
  }
  pipe('secrets', 'done');

  // ── VERIFY (evidence-guided) ─────────────────
  pipe('verify', 'active');
  progress(84);
  try {
    const verified = await runEvidenceVerification({
      findings,
      auth,
      log,
      maxEndpoints: runtimeProfile.maxVerifyEndpoints,
      modules,
    });
    for (const vf of verified) addFinding(vf, null);
    if (verified.length) log(`Verify: ${verified.length} resultado(s) xss/sqli/open_redirect/idor/lfi`, 'success');
  } catch (e) {
    log(`Verify: ${e.message}`, 'warn');
  }
  if (modules.includes('micro_exploit')) {
    try {
      const micro = await runMicroExploitVariants({ findings, auth, log, modules, maxTests: 16 });
      for (const mf of micro) addFinding(mf, null);
    } catch (e) {
      log(`Micro-exploit: ${e.message}`, 'warn');
    }
  }
  // Param discovery ativo (fase 2): tentar em endpoints sem query
  try {
    const candidates = findings
      .filter((f) => f.type === 'endpoint' && typeof f.value === 'string' && /^https?:\/\//i.test(f.value))
      .filter((f) => !/\?/.test(String(f.value)))
      .slice(0, Math.max(6, Math.round(runtimeProfile.maxVerifyEndpoints / 3)));
    for (const ep of candidates) {
      const r = await discoverParamsActive(ep.value, { timeoutMs: 70000 });
      const ps = [...new Set(r.params || [])].slice(0, 20);
      for (const p of ps) {
        addFinding(
          {
            type: 'param',
            prio: 'med',
            score: 62,
            value: `?${p}=`,
            meta: `active_discovery • tool=${r.tool || 'n/a'}`,
            url: `${ep.value}${ep.value.includes('?') ? '&' : '?'}${p}=X`,
          },
          'params',
        );
      }
      if (ps.length) log(`Param discovery: ${ps.length} em ${ep.value}`, 'info');
    }
  } catch (e) {
    log(`Param discovery: ${e.message}`, 'warn');
  }
  pipe('verify', 'done');

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

      let xssSignals = false;
      let sqliSignals = false;
      const xssParamRe = /[?&](q|query|search|s|keyword|term|message|comment|title|name)=/i;
      const sqliParamRe =
        /[?&](id|ids|user|user_id|uid|account|order|order_id|page|sort|filter|where)=/i;
      for (const u of paramUrlsForKali) {
        if (xssParamRe.test(u)) xssSignals = true;
        if (sqliParamRe.test(u)) sqliSignals = true;
        if (xssSignals && sqliSignals) break;
      }
      for (const f of findings) {
        if (f.type !== 'intel') continue;
        const v = String(f.value || '');
        if (/XSS candidate param/i.test(v)) xssSignals = true;
        if (/SQLi candidate param/i.test(v)) sqliSignals = true;
      }
      if (!xssSignals && !sqliSignals) {
        log(
          'Scan agressivo XSS/SQLi: sem sinais (URLs com parâmetros típicos nem candidatos intel) — nuclei tags xss/sqli e dalfox em skip',
          'info',
        );
      } else {
        log(
          `Scan agressivo: sinais XSS=${xssSignals ? 'sim' : 'não'} SQLi=${sqliSignals ? 'sim' : 'não'}`,
          'info',
        );
      }

      await runKaliAggressiveScan({
        domain,
        subdomainsAlive,
        cap,
        log,
        addFinding,
        wordpressTargets,
        paramUrls: paramUrlsForKali,
        xssSignals,
        sqliSignals,
      });
    } else {
      log(`Modo Kali pedido mas ambiente não suporta: ${cap.message}`, 'warn');
    }
    pipe('kali', 'done');
  } else {
    emit({ type: 'pipe', name: 'kali', state: 'skip' });
  }

  progress(90);

  // ── ASSET DISCOVERY (passivo complementar) ──
  pipe('assets', 'active');
  try {
    const assets = await discoverAssetHints(domain, subdomainsAlive, tlsSanHosts);
    for (const a of assets) addFinding(a, null);
    const tk = detectTakeoverCandidates(findings);
    for (const t of tk) addFinding(t, null);
    // Takeover avançado (fase 2): CNAME + corpo
    const aliveHosts = [...new Set(findings.filter((f) => f.type === 'subdomain').map((f) => f.value))].slice(0, 20);
    for (const h of aliveHosts) {
      try {
        const chain = await resolveCnameChain(h, 4);
        const prov = matchProviderByCname(chain);
        if (!prov) continue;
        let body = '';
        try {
          const res = await fetch(`https://${h}/`, { redirect: 'follow', signal: AbortSignal.timeout(9000) });
          body = await res.text();
        } catch {}
        const match = matchProviderBody(prov, body);
        addFinding(
          {
            type: 'takeover',
            prio: match ? 'high' : 'med',
            score: match ? 82 : 60,
            value: `Takeover ${match ? 'CONFIRMED' : 'candidate'}: ${h} → ${prov.name}`,
            meta: `cname_chain=${chain.join(' > ').slice(0, 160)} • body_match=${match ? 'yes' : 'no'}`,
            url: `https://${h}/`,
          },
          null,
        );
      } catch {}
    }
    if (assets.length || tk.length) {
      log(`Asset discovery: +${assets.length} hints, takeover candidates: ${tk.length}`, 'info');
    }
  } catch (e) {
    log(`Asset discovery: ${e.message}`, 'warn');
  }
  pipe('assets', 'done');

  // ── PRIORIZAÇÃO V2 + CVE hints + CORRELATION + INTEL ──
  pipe('score', 'active');
  progress(93);
  log('═══ Priorização v2 (composite + HIGH PROBABILITY) ═══', 'section');
  applyPrioritizationV2(findings);
  for (const f of findings) {
    if (f.type === 'endpoint' && f.url && /\?.+=/i.test(f.url)) {
      f.meta = [f.meta, 'status_consistent=true'].filter(Boolean).join(' • ');
    }
    if (f.type === 'endpoint' && /\/(admin|dashboard|account|profile|settings|billing)(\/|$)/i.test(String(f.value || ''))) {
      f.meta = [f.meta, 'auth=required'].filter(Boolean).join(' • ');
    }
  }
  const techStrs = findings.filter((f) => f.type === 'tech').map((f) => f.value);
  const cveHints = extractCveHintsFromTechStrings(techStrs);
  for (const f of findings) {
    if (cveHints.length && f.type === 'tech') {
      f.meta = [f.meta, 'cve_hint=true'].filter(Boolean).join(' • ');
    }
  }
  applyPrioritizationV2(findings);

  const semantic = dedupeBySemanticFamily(findings);
  if (semantic.merged > 0) {
    findings.length = 0;
    findings.push(...semantic.findings);
    log(`Dedupe semântico: ${semantic.merged} achado(s) colapsado(s) por família`, 'info');
  }
  stats.high = findings.filter((f) => f.prio === 'high').length;
  emit({ type: 'stats', stats: { ...stats } });
  emit({ type: 'findings_rescore', findings });

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
  const reportTemplates = buildReportTemplates(findings, domain);
  for (const tpl of reportTemplates) {
    emit({ type: 'report_template', template: tpl });
    emit({ type: 'intel', line: `REPORT: ${tpl.title}` });
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
    localProjectName: String(projectNameRaw || '').trim(),
  });
  let runId = null;
  let intelMerge = null;
  if (saved != null) {
    runId = saved.runId;
    intelMerge = saved.intelMerge;
    log(`Recon gravado — run #${runId} → ${storageLabel()}`, 'success');
    const sqlitePath = saved.localMirrorPath || saved.dbPath;
    if (sqlitePath) {
      log(`SQLite no disco: ${sqlitePath}`, 'success');
    }
    if (saved.remoteSaveFailed) {
      log('Aviso: gravação na cloud falhou — este run ficou no SQLite local acima.', 'warn');
    }
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
    try {
      const runs = await listRuns(120);
      const nt = domain.trim().toLowerCase();
      const prev = runs.find((r) => String(r.target).trim().toLowerCase() === nt && r.id < runId);
      if (prev) {
        const diff = await compareRuns(prev.id, runId);
        if (!diff.error) {
          const hotAdded = diff.added.filter((x) => {
            const t = String(x.type || '').toLowerCase();
            const v = String(x.value || '').toLowerCase();
            return ['xss', 'sqli', 'open_redirect', 'idor', 'lfi', 'secret', 'exploit', 'nuclei', 'takeover'].includes(t)
              || /\/(admin|api|graphql|internal|debug)|token|key|secret/.test(v);
          });
          if (hotAdded.length) {
            emit({
              type: 'delta_hot',
              baselineRunId: prev.id,
              newerRunId: runId,
              hotAddedCount: hotAdded.length,
              sample: hotAdded.slice(0, 12).map((x) => ({
                type: x.type,
                prio: x.prio,
                value: String(x.value || '').slice(0, 180),
              })),
            });
            log(`Delta hot: ${hotAdded.length} novidade(s) crítica(s) vs run #${prev.id}`, 'warn');
          }
        }
      }
    } catch {
      /* ignore delta hot */
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
    reportTemplates,
    localSqlitePath: saved?.localMirrorPath || saved?.dbPath || null,
  });

  if (autoAiReports && aiAutoReportsServerAllowed() && aiKeysConfigured().any) {
    emit({ type: 'ai_report', phase: 'start', target: domain });
    log('IA: recon concluído — a gerar relatórios (Gemini e/ou Claude) com o JSON deste run…', 'info');
    const pn = String(projectNameRaw || '').trim();
    const aiPayload = buildPipelineExportPayloadForAi({
      target: domain,
      projectName: pn,
      stats,
      findings,
      correlation: corr,
      reportTemplates,
      runId,
      storage: storageLabel(),
      intelMerge,
      kaliMode: Boolean(kaliMode),
      modules: modulesForDb,
    });
    try {
      const aiOut = await runDualAiReports(aiPayload, { projectName: pn, targetDomain: domain });
      emit({
        type: 'ai_report',
        phase: 'done',
        target: domain,
        outputDir: aiOut.outputDir,
        pipelineJsonPath: aiOut.pipelineJsonPath,
        gemini: { ok: Boolean(aiOut.gemini?.ok), error: aiOut.gemini?.error || null },
        claude: { ok: Boolean(aiOut.claude?.ok), error: aiOut.claude?.error || null },
      });
      if (aiOut.gemini?.ok) log('IA Gemini ✓ relatório + próximos passos gravados.', 'success');
      else if (aiKeysConfigured().gemini) log(`IA Gemini ✗ ${aiOut.gemini?.error || 'falhou'}`, 'warn');
      if (aiOut.claude?.ok) log('IA Claude ✓ relatório + próximos passos gravados.', 'success');
      else if (aiKeysConfigured().claude) log(`IA Claude ✗ ${aiOut.claude?.error || 'falhou'}`, 'warn');
      emitIaProximosPassosToLog(aiOut, log);
    } catch (e) {
      emit({
        type: 'ai_report',
        phase: 'error',
        target: domain,
        message: e?.message || String(e),
      });
      log(`IA: ${e?.message || e}`, 'error');
    }
  }

  const whUrl = process.env.GHOSTRECON_WEBHOOK_URL?.trim();
  if (whUrl && runId != null) {
    const findingsByType = {};
    for (const f of findings) {
      const t = f?.type || 'unknown';
      findingsByType[t] = (findingsByType[t] || 0) + 1;
    }
    let runDiffSummary = null;
    try {
      const runs = await listRuns(120);
      const nt = domain.trim().toLowerCase();
      const prev = runs.find((r) => String(r.target).trim().toLowerCase() === nt && r.id < runId);
      if (prev) {
        const diff = await compareRuns(prev.id, runId);
        if (!diff.error) {
          runDiffSummary = {
            baselineId: diff.baselineId,
            newerId: diff.newerId,
            baselineCreatedAt: diff.baselineCreatedAt,
            newerCreatedAt: diff.newerCreatedAt,
            addedCount: diff.addedCount,
            removedCount: diff.removedCount,
            addedSample: diff.added.slice(0, 10).map((x) => ({
              type: x.type,
              prio: x.prio,
              value: String(x.value ?? '').slice(0, 240),
            })),
            removedSample: diff.removed.slice(0, 10).map((x) => ({
              type: x.type,
              prio: x.prio,
              value: String(x.value ?? '').slice(0, 240),
            })),
          };
        }
      }
    } catch (e) {
      console.warn('[GHOSTRECON webhook diff]', e?.message || e);
    }
    void postReconWebhook(whUrl, {
      target: domain,
      runId,
      stats,
      intelMerge,
      kaliMode: Boolean(kaliMode),
      modules: modulesForDb,
      highCount: findings.filter((f) => f.prio === 'high').length,
      findingsByType,
      runDiffSummary,
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

  if (!validateCsrfToken(req)) {
    send({ type: 'error', message: 'CSRF token inválido/ausente' });
    res.end();
    return;
  }

  if (!allowReconRequest(req)) {
    send({ type: 'error', message: 'Rate limit — aguarde antes de novo recon' });
    res.end();
    return;
  }

  const domainRaw = req.body?.domain;
  const modules = Array.isArray(req.body?.modules) ? req.body.modules : [];
  const exactMatch = Boolean(req.body?.exactMatch);
  const kaliMode = Boolean(req.body?.kaliMode);
  const profile = String(req.body?.profile || 'standard')
    .trim()
    .toLowerCase();
  const auth =
    req.body?.auth && typeof req.body.auth === 'object'
      ? {
          headers: req.body.auth.headers && typeof req.body.auth.headers === 'object' ? req.body.auth.headers : {},
          cookie: req.body.auth.cookie ? String(req.body.auth.cookie) : '',
        }
      : null;

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
      auth,
      profile,
      outOfScope: req.body?.outOfScope,
      projectName: req.body?.projectName,
      autoAiReports: Boolean(req.body?.autoAiReports),
    });
  } catch (e) {
    send({ type: 'error', message: e?.message || String(e) });
  }
  res.end();
});

app.get('/api/csrf-token', (req, res) => {
  const token = issueCsrfToken(req);
  res.setHeader('Cache-Control', 'no-store');
  res.json({ token, expiresInMs: CSRF_TTL_MS });
});

app.get('/api/health', (_req, res) => {
  res.json({ ok: true, service: 'ghostrecon' });
});

app.get('/api/capabilities', async (_req, res) => {
  try {
    const cap = await getKaliCapabilities();
    res.json({ ...cap, ai: aiKeysConfigured() });
  } catch (e) {
    res.status(500).json({ kali: false, message: e.message, tools: {}, ai: aiKeysConfigured() });
  }
});

app.post('/api/ai-reports', async (req, res) => {
  if (!validateCsrfToken(req)) {
    res.status(403).json({ ok: false, error: 'CSRF token inválido ou ausente' });
    return;
  }
  const payload = req.body?.payload;
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    res.status(400).json({ ok: false, error: 'Corpo inválido: falta object "payload" (export JSON do pipeline).' });
    return;
  }
  const projectName = String(req.body?.projectName ?? payload.projectName ?? '').trim();
  const targetDomain = String(req.body?.targetDomain ?? payload.target ?? '').trim();
  if (!targetDomain) {
    res.status(400).json({ ok: false, error: 'Define Target ($) ou inclui "target" no payload.' });
    return;
  }
  try {
    const out = await runDualAiReports(payload, { projectName, targetDomain });
    res.json({ ok: true, ...out });
  } catch (e) {
    res.status(500).json({ ok: false, error: e?.message || String(e) });
  }
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
  const t = String(req.params.target || '')
    .trim()
    .toLowerCase();
  if (!t || !/^[a-z0-9][a-z0-9.-]*[a-z0-9]$/.test(t)) {
    res.status(400).json({ error: 'domínio inválido' });
    return;
  }
  try {
    const [totalUnique, items] = await Promise.all([
      intelCountForTarget(t),
      listIntelForTarget(t, 500),
    ]);
    res.json({
      target: t,
      totalUnique,
      items,
    });
  } catch (e) {
    res.status(500).json({ error: e?.message || String(e) });
  }
});

app.use(express.static(ROOT, { index: false }));
app.get('/', (_req, res) => {
  res.sendFile(path.join(ROOT, 'index.html'));
});

const server = app.listen(PORT, HOST, () => {
  console.log(`GHOSTRECON → http://${HOST}:${PORT}`);
});
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(
      `[GHOSTRECON] Porta ${PORT} em uso. Encerre a instância anterior (ex.: netstat -ano | findstr :${PORT}) ou defina PORT=3850 antes de npm start.`,
    );
  } else {
    console.error('[GHOSTRECON]', err.message);
  }
  process.exit(1);
});
