import dns from 'node:dns/promises';
import { limits } from '../config.js';

function uniq(arr) {
  return [...new Set(arr)];
}

function joinTxtRecord(txtParts) {
  // node:dns/promises.resolveTxt returns: Array<Array<string>>
  // Each inner array is one TXT record split into parts.
  if (!Array.isArray(txtParts)) return '';
  return txtParts.join('');
}

function extractSpfFromTxt(txts) {
  for (const t of txts) {
    const s = joinTxtRecord(t).trim();
    if (/^v=spf1\s/i.test(s)) return s;
  }
  return null;
}

function extractDmarcFromTxt(txts) {
  for (const t of txts) {
    const s = joinTxtRecord(t).trim();
    if (/^v=DMARC1\s/i.test(s)) return s;
  }
  return null;
}

function extractInterestingTxtTokens(txts) {
  // Pequeno filtro para reduzir ruído: tokens comuns de verificação/validação.
  // Mantém o módulo "fonte" útil sem despejar dezenas de TXT irrelevantes.
  const patterns = [
    /google-site-verification=/i,
    /facebook-domain-verification=/i,
    /atlassian-domain-verification=/i,
    /yandex-verification=/i,
    /microsoft-verification=/i,
    /apple-domain-verification=/i,
    /shopify-verification=/i,
    /stripe-verification=/i,
  ];

  const out = [];
  for (const t of txts) {
    const s = joinTxtRecord(t).trim();
    if (!s) continue;
    if (patterns.some((re) => re.test(s))) out.push(s);
    if (out.length >= limits.dnsTxtInterestingMax) break;
  }
  return uniq(out);
}

async function withTimeout(promiseFactory, timeoutMs) {
  // resolveTxt/resolveMx não aceitam AbortSignal nativamente.
  // Usamos "Promise.race" para evitar hangs.
  return await Promise.race([
    promiseFactory(),
    new Promise((_, reject) =>
      setTimeout(() => reject(new Error('timeout')), Math.max(1, timeoutMs || 8000)),
    ),
  ]);
}

async function resolveMxSafe(hostname, timeoutMs) {
  try {
    const mx = await withTimeout(() => dns.resolveMx(hostname), timeoutMs);
    if (!Array.isArray(mx) || mx.length === 0) return [];
    return mx
      .map((x) => ({ exchange: String(x.exchange || '').toLowerCase(), priority: x.priority }))
      .filter((x) => x.exchange);
  } catch {
    return [];
  }
}

async function resolveTxtSafe(hostname, timeoutMs) {
  try {
    const txt = await withTimeout(() => dns.resolveTxt(hostname), timeoutMs);
    if (!Array.isArray(txt) || txt.length === 0) return [];
    return txt;
  } catch {
    return [];
  }
}

async function mapPool(items, concurrency, fn) {
  const results = [];
  let i = 0;
  async function worker() {
    while (i < items.length) {
      const idx = i++;
      results[idx] = await fn(items[idx], idx);
    }
  }
  const workers = Array.from({ length: Math.max(1, Math.min(concurrency || 1, items.length)) }, () => worker());
  await Promise.all(workers);
  return results;
}

/**
 * Enriquecimento passivo via DNS (MX/TXT) e extração de SPF/DMARC.
 * @returns {Promise<{ findings: Array<{type:string, prio:string, score:number, value:string, meta?:string, url?:string}> }>}
 */
export async function fetchDnsEnrichment(rootDomain, aliveHosts = [], opts = {}) {
  const maxHosts = Number(opts.maxHosts ?? limits.dnsEnrichMaxHosts ?? 20);
  const timeoutMs = Number(opts.timeoutMs ?? limits.dnsEnrichTimeoutMs ?? 8000);
  const concurrency = Number(opts.concurrency ?? limits.dnsEnrichConcurrency ?? 6);

  const targets = uniq([rootDomain, ...(Array.isArray(aliveHosts) ? aliveHosts : [])]).slice(0, maxHosts);

  const findings = [];

  // SPF/DMARC são tipicamente no domínio raiz; buscamos uma vez para reduzir ruído.
  const [mxRoot, txtRoot] = await Promise.all([resolveMxSafe(rootDomain, timeoutMs), resolveTxtSafe(rootDomain, timeoutMs)]);
  if (mxRoot.length) {
    const topMx = mxRoot.slice(0, limits.dnsMxMax);
    for (const m of topMx) {
      findings.push({
        type: 'dns',
        prio: 'low',
        score: 22,
        value: `${m.exchange} (prio ${m.priority ?? '?'})`,
        meta: `MX @ ${rootDomain}`,
        url: null,
      });
    }
  }

  const spf = extractSpfFromTxt(txtRoot);
  if (spf) {
    findings.push({
      type: 'dns',
      prio: 'low',
      score: 30,
      value: `SPF: ${spf}`,
      meta: `TXT SPF @ ${rootDomain}`,
    });
  }

  const dmarcHost = `_dmarc.${rootDomain}`;
  const dmarcTxt = await resolveTxtSafe(dmarcHost, timeoutMs);
  const dmarc = extractDmarcFromTxt(dmarcTxt);
  if (dmarc) {
    findings.push({
      type: 'dns',
      prio: 'low',
      score: 30,
      value: `DMARC: ${dmarc}`,
      meta: `TXT DMARC @ ${dmarcHost}`,
    });
  }

  // TXT "interessantes" em alvos vivos (e o próprio domínio).
  // Pequeno filtro para não virar spam.
  const txtInterestingHosts = targets.slice(0, Math.max(1, Math.min(targets.length, limits.dnsTxtEnrichMaxHosts)));
  const txtPerHost = await mapPool(
    txtInterestingHosts,
    concurrency,
    async (h) => ({
      host: h,
      txts: await resolveTxtSafe(h, timeoutMs),
    }),
  );
  for (const { host: h, txts } of txtPerHost) {
    const tokens = extractInterestingTxtTokens(txts);
    for (const t of tokens.slice(0, limits.dnsTxtInterestingMax)) {
      findings.push({
        type: 'dns',
        prio: 'low',
        score: 20,
        value: t,
        meta: `TXT verificação @ ${h}`,
      });
    }
  }

  return { findings };
}

