import crypto from 'crypto';
import { stealthPause, pickStealthUserAgent } from './request-policy.js';

const XSS_PARAM_RE = /^(q|query|search|s|keyword|term|message|comment|title|name)$/i;
const SQLI_PARAM_RE = /^(id|ids|user|user_id|uid|account|order|order_id|page|sort|filter|where)$/i;
const REDIRECT_PARAM_RE = /^(redirect|url|next|return|return_url|dest|target|goto|callback)$/i;
const IDOR_PARAM_RE = /^(id|user_id|uid|account|order_id|profile_id|invoice_id)$/i;
const LFI_PARAM_RE = /^(file|path|page|template|include|inc|doc|document|folder|dir|download|view|cat)$/i;
const SQL_ERROR_RE =
  /(sql syntax|mysql_fetch|ora-\d+|sqlite error|sqlstate|postgresql|unclosed quotation|syntax error at or near)/i;
const LFI_UNIX_RE = /(root:x:0:0:|daemon:x:|bin:x:|nobody:x:|\/bin\/bash|\/usr\/sbin\/nologin)/i;
const LFI_WIN_RE = /(\[extensions\]|\[fonts\]|\[mci extensions\]|for 16-bit app support)/i;

function nowIso() {
  return new Date().toISOString();
}

function buildHeaders(auth = {}, modules = []) {
  const h = {
    'User-Agent': pickStealthUserAgent(modules),
    Accept: 'text/html,application/xhtml+xml,application/json,*/*;q=0.8',
  };
  const extra = auth?.headers && typeof auth.headers === 'object' ? auth.headers : {};
  for (const [k, v] of Object.entries(extra)) {
    if (!k || v == null) continue;
    h[String(k)] = String(v);
  }
  if (auth?.cookie) h.Cookie = String(auth.cookie);
  return h;
}

async function fetchText(url, { auth, timeoutMs = 12000, modules = [] } = {}) {
  await stealthPause(modules);
  const res = await fetch(url, {
    method: 'GET',
    redirect: 'manual',
    signal: AbortSignal.timeout(timeoutMs),
    headers: buildHeaders(auth, modules),
  });
  const text = await res.text().catch(() => '');
  return { status: res.status, headers: res.headers, text: text.slice(0, 160000), location: res.headers.get('location') || '' };
}

function sampleSnippet(text, needle, radius = 90) {
  const s = String(text || '');
  if (!needle) return s.slice(0, 180);
  const i = s.toLowerCase().indexOf(String(needle).toLowerCase());
  if (i < 0) return s.slice(0, 180);
  const st = Math.max(0, i - radius);
  const en = Math.min(s.length, i + String(needle).length + radius);
  return s.slice(st, en).replace(/\s+/g, ' ').trim();
}

function evidenceHash(evidence) {
  const raw = JSON.stringify({
    source: evidence?.source || '',
    url: evidence?.url || '',
    method: evidence?.method || '',
    status: evidence?.status || 0,
    requestSnippet: evidence?.requestSnippet || '',
    responseSnippet: evidence?.responseSnippet || '',
  });
  return crypto.createHash('sha256').update(raw).digest('hex');
}

function pushVerificationFinding(out, kind, classification, score, value, meta, evidence) {
  out.push({
    type: kind,
    prio: classification === 'confirmed' ? 'high' : classification === 'probable' ? 'med' : 'low',
    score,
    value,
    meta,
    verification: {
      classification,
      evidence: { ...evidence, evidenceHash: evidenceHash(evidence) },
      verifiedAt: nowIso(),
    },
    url: evidence?.url || null,
  });
}

export async function runEvidenceVerification({ findings, auth, log, maxEndpoints = 36, modules = [] }) {
  const out = [];
  const endpointUrls = [...new Set(
    (findings || [])
      .filter((f) => f?.type === 'endpoint' && typeof f.value === 'string' && /^https?:\/\//i.test(f.value))
      .map((f) => f.value),
  )].slice(0, Math.max(1, maxEndpoints));

  if (!endpointUrls.length) return out;
  if (typeof log === 'function') log(`Verify: analisando ${endpointUrls.length} endpoint(s)`, 'info');

  for (const raw of endpointUrls) {
    let u;
    try {
      u = new URL(raw);
    } catch {
      continue;
    }
    const params = [...u.searchParams.keys()].slice(0, 8);
    if (!params.length) continue;

    for (const p of params) {
      const param = String(p || '').toLowerCase();

      if (XSS_PARAM_RE.test(param)) {
        const marker = `ghxss_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`;
        const payload = `"'><${marker}>`;
        const x = new URL(u.href);
        x.searchParams.set(p, payload);
        try {
          const r = await fetchText(x.href, { auth, modules });
          const reflectedRaw = r.text.includes(payload);
          const reflectedMarker = r.text.includes(marker);
          const escaped = r.text.includes('&lt;') && r.text.includes(marker);
          const classification = reflectedRaw && !escaped ? 'confirmed' : reflectedMarker ? 'probable' : 'noisy';
          const score = classification === 'confirmed' ? 96 : classification === 'probable' ? 76 : 36;
          pushVerificationFinding(
            out,
            'xss',
            classification,
            score,
            `Verify XSS ${classification.toUpperCase()} @ ${x.pathname} ?${p}=`,
            `verify=xss • param=${p} • reflected=${reflectedMarker ? 'yes' : 'no'} • escaped=${escaped ? 'yes' : 'no'} • confidence=${classification}`,
            {
              source: 'verify-xss',
              url: x.href,
              method: 'GET',
              status: r.status,
              requestSnippet: `${x.pathname}?${p}=${payload}`,
              responseSnippet: sampleSnippet(r.text, marker),
              timestamp: nowIso(),
            },
          );
        } catch {
          /* ignore */
        }
      }

      if (SQLI_PARAM_RE.test(param)) {
        const b = new URL(u.href);
        const t = new URL(u.href);
        b.searchParams.set(p, '1');
        t.searchParams.set(p, "1'");
        try {
          const [rb, rt] = await Promise.all([
            fetchText(b.href, { auth, modules }),
            fetchText(t.href, { auth, modules }),
          ]);
          const errBase = SQL_ERROR_RE.test(rb.text);
          const errTest = SQL_ERROR_RE.test(rt.text);
          const statusDiff = rb.status !== rt.status;
          const classification = errTest && !errBase ? 'confirmed' : statusDiff ? 'probable' : 'noisy';
          const score = classification === 'confirmed' ? 95 : classification === 'probable' ? 72 : 34;
          pushVerificationFinding(
            out,
            'sqli',
            classification,
            score,
            `Verify SQLi ${classification.toUpperCase()} @ ${t.pathname} ?${p}=`,
            `verify=sqli • param=${p} • sql_error=${errTest ? 'yes' : 'no'} • status_diff=${statusDiff ? 'yes' : 'no'} • confidence=${classification}`,
            {
              source: 'verify-sqli',
              url: t.href,
              method: 'GET',
              status: rt.status,
              requestSnippet: `${t.pathname}?${p}=1'`,
              responseSnippet: sampleSnippet(rt.text, 'sql'),
              timestamp: nowIso(),
            },
          );
        } catch {
          /* ignore */
        }
      }

      if (REDIRECT_PARAM_RE.test(param)) {
        const x = new URL(u.href);
        x.searchParams.set(p, 'https://example.org/');
        try {
          const r = await fetchText(x.href, { auth, modules });
          const loc = String(r.location || '');
          const confirmed = /^https?:\/\/example\.org\/?/i.test(loc);
          const probable = !confirmed && /example\.org/i.test(r.text);
          const classification = confirmed ? 'confirmed' : probable ? 'probable' : 'noisy';
          const score = classification === 'confirmed' ? 94 : classification === 'probable' ? 70 : 30;
          pushVerificationFinding(
            out,
            'open_redirect',
            classification,
            score,
            `Verify Open Redirect ${classification.toUpperCase()} @ ${x.pathname} ?${p}=`,
            `verify=open_redirect • param=${p} • location=${loc ? 'present' : 'none'} • confidence=${classification}`,
            {
              source: 'verify-open-redirect',
              url: x.href,
              method: 'GET',
              status: r.status,
              requestSnippet: `${x.pathname}?${p}=https://example.org/`,
              responseSnippet: loc || sampleSnippet(r.text, 'example.org'),
              timestamp: nowIso(),
            },
          );
        } catch {
          /* ignore */
        }
      }

      if (IDOR_PARAM_RE.test(param)) {
        const b = new URL(u.href);
        const t = new URL(u.href);
        b.searchParams.set(p, '1');
        t.searchParams.set(p, '2');
        try {
          const [rb, rt] = await Promise.all([
            fetchText(b.href, { auth, modules }),
            fetchText(t.href, { auth, modules }),
          ]);
          const sameStatus = rb.status === rt.status;
          const bodyChanged = rb.text.slice(0, 4000) !== rt.text.slice(0, 4000);
          const maybeUnauthorized = [401, 403].includes(rt.status);
          const classification = sameStatus && bodyChanged && !maybeUnauthorized ? 'probable' : 'noisy';
          const score = classification === 'probable' ? 68 : 28;
          pushVerificationFinding(
            out,
            'idor',
            classification,
            score,
            `Verify IDOR ${classification.toUpperCase()} @ ${t.pathname} ?${p}=`,
            `verify=idor • param=${p} • status_base=${rb.status} status_test=${rt.status} • body_changed=${bodyChanged ? 'yes' : 'no'} • confidence=${classification}`,
            {
              source: 'verify-idor',
              url: t.href,
              method: 'GET',
              status: rt.status,
              requestSnippet: `${t.pathname}?${p}=2`,
              responseSnippet: sampleSnippet(rt.text, ''),
              timestamp: nowIso(),
            },
          );
        } catch {
          /* ignore */
        }
      }

      if (LFI_PARAM_RE.test(param)) {
        const payloads = [
          '../../../../../../../etc/passwd',
          '..%2f..%2f..%2f..%2f..%2fetc%2fpasswd',
          '..%252f..%252f..%252f..%252fetc%252fpasswd',
          '..\\..\\..\\..\\..\\windows\\win.ini',
        ];
        for (const payload of payloads) {
          const x = new URL(u.href);
          x.searchParams.set(p, payload);
          try {
            const r = await fetchText(x.href, { auth, modules });
            const unixHit = LFI_UNIX_RE.test(r.text);
            const winHit = LFI_WIN_RE.test(r.text);
            const hasTraversalError = /(failed to open stream|no such file|permission denied|include\(\)|fopen\()/i.test(
              r.text,
            );
            const classification = unixHit || winHit ? 'confirmed' : hasTraversalError ? 'probable' : 'noisy';
            const score = classification === 'confirmed' ? 97 : classification === 'probable' ? 70 : 30;
            const marker = unixHit ? 'etc/passwd signature' : winHit ? 'win.ini signature' : 'error-pattern';
            pushVerificationFinding(
              out,
              'lfi',
              classification,
              score,
              `Verify LFI ${classification.toUpperCase()} @ ${x.pathname} ?${p}=`,
              `verify=lfi • param=${p} • payload=${payload.slice(0, 40)} • marker=${marker} • confidence=${classification}`,
              {
                source: 'verify-lfi',
                url: x.href,
                method: 'GET',
                status: r.status,
                requestSnippet: `${x.pathname}?${p}=${payload}`,
                responseSnippet: sampleSnippet(r.text, unixHit ? 'root:x:' : winHit ? '[extensions]' : 'failed'),
                timestamp: nowIso(),
              },
            );
            if (classification === 'confirmed') break;
          } catch {
            /* ignore */
          }
        }
      }
    }
  }

  return out;
}

/**
 * Segunda ronda leve: variantes de payload em XSS classificados como probable (micro-exploit).
 */
export async function runMicroExploitVariants({ findings, auth, log, modules = [], maxTests = 14 }) {
  const out = [];
  const tried = new Set();
  let count = 0;
  for (const f of findings) {
    if (f.type !== 'xss') continue;
    if (f.verification?.classification !== 'probable') continue;
    const urlStr = f.verification?.evidence?.url || f.url;
    if (!urlStr || typeof urlStr !== 'string') continue;
    if (tried.has(urlStr)) continue;
    tried.add(urlStr);
    if (count >= maxTests) break;
    let u;
    try {
      u = new URL(urlStr);
    } catch {
      continue;
    }
    const params = [...u.searchParams.keys()];
    if (!params.length) continue;
    const p = params[0];
    const payload = String.raw`"><svg/onload=alert(1)>`;
    const x = new URL(u.href);
    x.searchParams.set(p, payload);
    try {
      const r = await fetchText(x.href, { auth, modules });
      const raw = r.text.includes(payload);
      const loose = /onload\s*=\s*alert/i.test(r.text) && /<svg/i.test(r.text);
      const classification = raw ? 'confirmed' : loose ? 'probable' : 'noisy';
      const score = classification === 'confirmed' ? 97 : classification === 'probable' ? 82 : 32;
      pushVerificationFinding(
        out,
        'xss',
        classification,
        score,
        `Micro-exploit XSS ${classification.toUpperCase()} @ ${x.pathname} ?${p}= (variante svg)`,
        `verify=micro_xss • param=${p} • variant=svg_onload • confidence=${classification}`,
        {
          source: 'micro-exploit-xss',
          url: x.href,
          method: 'GET',
          status: r.status,
          requestSnippet: `${x.pathname}?${p}=…`,
          responseSnippet: sampleSnippet(r.text, 'svg'),
          timestamp: nowIso(),
        },
      );
      count++;
    } catch {
      /* ignore */
    }
  }
  if (out.length && typeof log === 'function') {
    log(`Micro-exploit: ${out.length} teste(s) de variante XSS após verify`, 'info');
  }
  return out;
}
