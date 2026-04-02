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
  if (f.type === 'lfi') return { x: 1.28, r: 'teste LFI/traversal' };
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

function exploitabilityBoost(f) {
  let x = 1;
  const r = [];
  const m = String(f.meta || '').toLowerCase();
  const v = String(f.value || '').toLowerCase();
  if (f?.verification?.classification === 'confirmed') {
    x *= 1.35;
    r.push('verify=confirmed');
  } else if (f?.verification?.classification === 'probable') {
    x *= 1.18;
    r.push('verify=probable');
  }
  if (/auth=required|401|403/.test(m)) {
    x *= 1.14;
    r.push('endpoint autenticado');
  }
  if (/waf=/.test(m)) {
    x *= 0.92;
    r.push('waf presente');
  }
  if (/status_consistent=true|stable_status=true/.test(m)) {
    x *= 1.12;
    r.push('status consistente');
  }
  if (/reflected=yes/.test(m)) {
    x *= 1.2;
    r.push('parâmetro refletido');
  }
  if (/cve_hint=true|cve\/tags|cve:/.test(m) || /cve-\d{4}-\d+/i.test(v)) {
    x *= 1.16;
    r.push('sinal de CVE');
  }
  const conf = Number(f?.verification?.confidenceScore);
  if (Number.isFinite(conf)) {
    if (conf >= 85) {
      x *= 1.18;
      r.push('confidence alta');
    } else if (conf >= 65) {
      x *= 1.08;
      r.push('confidence média');
    }
  }
  return { x, reasons: r };
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

    const ex = exploitabilityBoost(f);
    mult *= ex.x;
    why.push(...ex.reasons);

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

    let bountyProbability = Math.min(100, Math.max(0, Math.round(composite)));
    if (attackTier === 'HIGH_PROBABILITY') {
      bountyProbability = Math.min(100, Math.round(bountyProbability * 1.08));
    } else if (attackTier === 'ELEVATED') {
      bountyProbability = Math.min(100, Math.round(bountyProbability * 1.03));
    }
    f.bountyProbability = bountyProbability;

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
    if (f.verification) {
      let c = f.verification.classification === 'confirmed' ? 88 : f.verification.classification === 'probable' ? 68 : 35;
      if (String(f.meta || '').toLowerCase().includes('reflected=yes')) c += 6;
      if (String(f.meta || '').toLowerCase().includes('waf=')) c -= 5;
      f.verification.confidenceScore = Math.max(1, Math.min(99, Math.round(c)));
    }

    const whyText = f.priorityWhy.length ? f.priorityWhy.join(' • ') : '';
    const tag = `[COMP ${composite} | ${attackTier}]`;
    if (whyText && !String(f.meta || '').includes('[COMP ')) {
      f.meta = [f.meta, `${tag} ${whyText}`].filter(Boolean).join(' — ');
    } else if (!String(f.meta || '').includes('[COMP ')) {
      f.meta = [f.meta, tag].filter(Boolean).join(' — ');
    }
    const metaClean = String(f.meta || '')
      .replace(/\s*—\s*bounty_prob=\d+\/100/g, '')
      .trim();
    f.meta = [metaClean, `bounty_prob=${f.bountyProbability}/100`].filter(Boolean).join(' — ');
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
