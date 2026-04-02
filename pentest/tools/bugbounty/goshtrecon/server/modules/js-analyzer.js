import { limits } from '../config.js';
import { stealthPause, pickStealthUserAgent } from './request-policy.js';

const PATH_PATTERNS = [
  /["'`](\/api\/[a-zA-Z0-9_\-/.{}]+)["'`]/g,
  /["'`](\/v\d\/[a-zA-Z0-9_\-/.]+)["'`]/g,
  /fetch\(\s*["'`]([^"'`]+)["'`]/g,
  /axios\.[a-z]+\(\s*["'`]([^"'`]+)["'`]/g,
  /endpoint\s*[:=]\s*["'`]([^"'`]+)["'`]/gi,
  /baseURL\s*[:=]\s*["'`]([^"'`]+)["'`]/gi,
];

const INSIGHT_RES = [
  { kind: 'auth_token_ref', re: /(localStorage|sessionStorage)\.(getItem|setItem)\s*\(\s*['"](token|access_token|auth|jwt|refresh)['"]/gi },
  { kind: 'role_admin_hint', re: /\b(isAdmin|is_admin|ROLE_ADMIN|role\s*[:=]\s*['"]admin|userRole\s*[:=])/gi },
  { kind: 'feature_flag', re: /\b(featureFlag|FEATURE_[A-Z0-9_]+|enableFeature|launchDarkly|posthog)/gi },
  { kind: 'api_key_literal', re: /['"](api[_-]?key|apikey|secret[_-]?key)['"]\s*[:=]/gi },
];

function extractJsInsights(text) {
  const insights = [];
  const cap = text.slice(0, 400_000);
  for (const { kind, re } of INSIGHT_RES) {
    re.lastIndex = 0;
    let m;
    let n = 0;
    while ((m = re.exec(cap)) !== null && n < 4) {
      const start = Math.max(0, m.index - 40);
      const slice = cap.slice(start, m.index + Math.min(80, m[0].length + 40)).replace(/\s+/g, ' ').trim();
      if (slice.length > 8) insights.push({ kind, snippet: slice.slice(0, 220) });
      n++;
    }
  }
  return insights;
}

export async function analyzeJsUrl(jsUrl, { modules = [] } = {}) {
  await stealthPause(modules);
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), limits.probeTimeoutMs);
  try {
    const res = await fetch(jsUrl, {
      signal: controller.signal,
      headers: { 'User-Agent': pickStealthUserAgent(modules), Accept: '*/*' },
    });
    if (!res.ok) return { ok: false, status: res.status, endpoints: [], snippet: '', insights: [] };
    const text = await res.text();
    const cap = text.length > 500_000 ? text.slice(0, 500_000) : text;
    const endpoints = new Set();
    for (const re of PATH_PATTERNS) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(cap)) !== null) {
        const p = m[1];
        if (typeof p === 'string' && p.startsWith('/') && p.length < 400) endpoints.add(p.split('?')[0]);
      }
    }
    const insights = extractJsInsights(cap);
    return { ok: true, status: res.status, endpoints: [...endpoints], body: cap, insights };
  } catch (e) {
    return { ok: false, error: e.name === 'AbortError' ? 'timeout' : String(e.message || e), endpoints: [], body: '', insights: [] };
  } finally {
    clearTimeout(t);
  }
}
