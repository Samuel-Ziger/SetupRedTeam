/**
 * Priorização v2: score composto, tier HIGH_PROBABILITY, transparência (motivos).
 * Muta o array `findings` in-place (compositeScore, attackTier, priorityWhy, meta, prio opcional).
 */

const SENSITIVE_PARAM_IN_URL =
  /[?&](token|api_?key|access_token|auth|password|secret|jwt|session|bearer|apikey|id_token|refresh_token)=/i;

function baseMultiplierFromMeta(meta) {
  const m = String(meta || '').toLowerCase();
  let x = 1;
  const reasons = [];
  if (m.includes('github')) {
    x *= 1.38;
    reasons.push('fonte GitHub (leaks/code)');
  }
  if (m.includes('google cse')) {
    x *= 1.18;
    reasons.push('descoberto via Google CSE');
  }
  if (m.includes('nuclei')) {
    x *= 1.32;
    reasons.push('confirmado por Nuclei');
  }
  if (m.includes('exploit-db') || m.includes('searchsploit')) {
    x *= 1.22;
    reasons.push('ligado a Exploit-DB');
  }
  if (m.includes('ffuf')) {
    x *= 1.12;
    reasons.push('path 200 (ffuf)');
  }
  if (m.includes('wayback')) {
    x *= 1.05;
    reasons.push('histórico Wayback');
  }
  if (m.includes('common crawl')) {
    x *= 1.05;
    reasons.push('Common Crawl');
  }
  if (m.includes('robots/sitemap')) {
    x *= 1.08;
    reasons.push('descoberto via robots/sitemap');
  }
  return { x, reasons };
}

function typeMultiplier(f) {
  if (f.type === 'js') return { x: 1.28, r: 'endpoint/caminho extraído de JavaScript' };
  if (f.type === 'secret') return { x: 1.35, r: 'possível secret/credencial' };
  if (f.type === 'exploit') return { x: 1.3, r: 'referência Exploit-DB' };
  if (f.type === 'nuclei') return { x: 1.3, r: 'template Nuclei' };
  if (f.type === 'nmap') return { x: 1.08, r: 'superfície nmap' };
  return { x: 1, r: null };
}

function paramSensitivityBoost(f) {
  if (f.type !== 'param') return { x: 1, r: null };
  const v = String(f.value || '').toLowerCase();
  if (/token|key|auth|jwt|session|password|secret|apikey|bearer|oauth|csrf|admin|role|id=/.test(v)) {
    return { x: 1.35, r: 'parâmetro de controlo / sessão / auth' };
  }
  if (/redirect|url|next|return|dest|callback|path|file/.test(v)) {
    return { x: 1.28, r: 'parâmetro de redirecionamento / ficheiro' };
  }
  return { x: 1, r: null };
}

function endpointUrlBoost(f) {
  if (f.type !== 'endpoint' && f.type !== 'js') return { x: 1, r: null };
  const u = f.url || f.value || '';
  if (SENSITIVE_PARAM_IN_URL.test(u)) {
    return { x: 1.32, r: 'URL com query sensível (token/key/auth…)' };
  }
  if (/\/(api|graphql|admin|internal|debug|actuator|swagger)/i.test(u)) {
    return { x: 1.15, r: 'caminho API/admin/debug' };
  }
  return { x: 1, r: null };
}

/**
 * @param {Array<object>} findings
 */
export function applyPrioritizationV2(findings) {
  for (const f of findings) {
    const why = [];
    let base = Number(f.score);
    if (!Number.isFinite(base)) base = f.prio === 'high' ? 80 : f.prio === 'med' ? 55 : 35;

    const { x: mx, reasons: metaR } = baseMultiplierFromMeta(f.meta);
    why.push(...metaR);

    const tm = typeMultiplier(f);
    let mult = mx * tm.x;
    if (tm.r) why.push(tm.r);

    const pm = paramSensitivityBoost(f);
    mult *= pm.x;
    if (pm.r) why.push(pm.r);

    const em = endpointUrlBoost(f);
    mult *= em.x;
    if (em.r) why.push(em.r);

    let composite = Math.min(100, Math.round(base * mult));

    /** Tier: HIGH_PROBABILITY = prioridade máxima para exploração manual */
    let attackTier = 'STANDARD';
    const strongSignals = why.length;
    if (
      composite >= 92 ||
      (composite >= 85 && strongSignals >= 3) ||
      f.type === 'exploit' ||
      (f.type === 'secret' && composite >= 88) ||
      (f.type === 'js' && composite >= 86) ||
      (metaR.some((s) => s.includes('GitHub')) && composite >= 78)
    ) {
      attackTier = 'HIGH_PROBABILITY';
    } else if (composite >= 72 || strongSignals >= 2) {
      attackTier = 'ELEVATED';
    }

    if (composite >= 93 && f.prio !== 'high') {
      f.prio = 'high';
      why.push('composite ≥93 → prioridade HIGH');
    } else if (composite >= 82 && f.prio === 'low') {
      f.prio = 'med';
      why.push('composite ≥82 → prioridade MED');
    }

    f.compositeScore = composite;
    f.attackTier = attackTier;
    f.priorityWhy = [...new Set(why)].filter(Boolean);

    const whyText = f.priorityWhy.length ? f.priorityWhy.join(' • ') : '';
    const tag = `[COMP ${composite} | ${attackTier}]`;
    if (whyText && !String(f.meta || '').includes('[COMP ')) {
      f.meta = [f.meta, `${tag} ${whyText}`].filter(Boolean).join(' — ');
    } else if (!String(f.meta || '').includes('[COMP ')) {
      f.meta = [f.meta, tag].filter(Boolean).join(' — ');
    }
  }

  return findings;
}

/**
 * Top N alvos para resumo (ordenado por composite).
 */
export function topHighProbability(findings, n = 8) {
  return [...findings]
    .filter((f) => f.attackTier === 'HIGH_PROBABILITY')
    .sort((a, b) => (b.compositeScore || 0) - (a.compositeScore || 0))
    .slice(0, n);
}
