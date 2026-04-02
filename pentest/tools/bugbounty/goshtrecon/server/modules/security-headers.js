/**
 * Achados de configuração de cabeçalhos (orientação a hardening / superfície).
 * Não substitui auditoria manual.
 */

function cookieFlagsIssues(lines) {
  const issues = [];
  for (const line of lines || []) {
    const l = String(line).toLowerCase();
    if (!l.trim()) continue;
    if (!l.includes('httponly')) issues.push('Set-Cookie sem HttpOnly (amostra)');
    if (!l.includes('secure') && !l.includes('__host-') && !l.includes('__secure-'))
      issues.push('Set-Cookie sem Secure em contexto HTTPS (amostra)');
    break;
  }
  return issues;
}

/**
 * @param {string} pageUrl URL final após redirects
 * @param {object} snap resultado de snapshotSecurityHeaders()
 * @returns {{ text: string, prio: string, score: number }[]}
 */
export function analyzeSecurityHeaders(pageUrl, snap) {
  if (!snap) return [];
  const out = [];
  const isHttps = String(pageUrl).toLowerCase().startsWith('https:');

  if (isHttps && !snap.strictTransportSecurity) {
    out.push({
      text: 'Sem Strict-Transport-Security (HSTS)',
      prio: 'med',
      score: 48,
    });
  }
  if (!snap.contentSecurityPolicy) {
    out.push({
      text: 'Sem Content-Security-Policy',
      prio: 'low',
      score: 32,
    });
  }
  if (!snap.xFrameOptions && !/frame-ancestors/i.test(snap.contentSecurityPolicy || '')) {
    out.push({
      text: 'Sem X-Frame-Options / frame-ancestors em CSP (clickjacking)',
      prio: 'low',
      score: 35,
    });
  }
  if (!snap.xContentTypeOptions) {
    out.push({
      text: 'Sem X-Content-Type-Options: nosniff',
      prio: 'low',
      score: 30,
    });
  }
  if (!snap.referrerPolicy) {
    out.push({
      text: 'Sem Referrer-Policy explícita',
      prio: 'low',
      score: 26,
    });
  }

  for (const msg of cookieFlagsIssues(snap.setCookieSample)) {
    out.push({ text: msg, prio: 'med', score: 44 });
  }

  return out;
}
