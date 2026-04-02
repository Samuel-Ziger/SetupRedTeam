import { curlWebSingle } from './web-curl-single.js';

function unique(arr) {
  return [...new Set((arr || []).filter(Boolean))];
}

function collectWordpressOrigins(webResponses) {
  const out = [];
  for (const r of webResponses || []) {
    const techBlob = (r?.tech || []).join(' ').toLowerCase();
    const body = String(r?.bodyText || '').toLowerCase();
    const looksWp = techBlob.includes('wordpress') || body.includes('wp-content') || body.includes('/wp-includes/') || body.includes('/wp-json');
    if (!looksWp) continue;
    try {
      const u = new URL(String(r.url));
      out.push(`${u.protocol}//${u.host}`);
    } catch {
      // ignore
    }
  }
  return unique(out).slice(0, 8);
}

function extractPluginHints(body) {
  const out = [];
  const re = /\/wp-content\/plugins\/([a-z0-9._-]+)\//gi;
  let m;
  while ((m = re.exec(String(body || ''))) !== null) {
    const p = String(m[1] || '').trim();
    if (!p) continue;
    if (!out.includes(p)) out.push(p);
    if (out.length >= 20) break;
  }
  return out;
}

function extractThemeHints(body) {
  const out = [];
  const re = /\/wp-content\/themes\/([a-z0-9._-]+)\//gi;
  let m;
  while ((m = re.exec(String(body || ''))) !== null) {
    const t = String(m[1] || '').trim();
    if (!t) continue;
    if (!out.includes(t)) out.push(t);
    if (out.length >= 10) break;
  }
  return out;
}

function parseWpVersion(body) {
  const b = String(body || '');
  const m1 = b.match(/<meta[^>]+name=["']generator["'][^>]+content=["']WordPress\s+([0-9][^"']*)["']/i);
  if (m1?.[1]) return String(m1[1]).trim();
  return '';
}

function parseWpUsersFromJson(body) {
  const out = [];
  try {
    const j = JSON.parse(String(body || ''));
    if (!Array.isArray(j)) return out;
    for (const u of j) {
      const name = String(u?.slug || u?.name || '').trim();
      if (!name) continue;
      if (!out.includes(name)) out.push(name);
      if (out.length >= 20) break;
    }
  } catch {
    // ignore
  }
  return out;
}

function pluginCveHints(pluginName) {
  const p = String(pluginName || '').toLowerCase();
  const map = {
    'simply-poll': 'known CTF plugin target (historical SQLi vectors)',
    revslider: 'historical critical vulns in old versions',
    elementor: 'check vulnerable addon ecosystem',
    woocommerce: 'review addon/plugin CVEs by version',
    'wp-file-manager': 'historical RCE campaign surface',
  };
  for (const [k, v] of Object.entries(map)) {
    if (p === k || p.includes(k)) return v;
  }
  return '';
}

export async function runWordpressFocusProbe(webResponses, { log, timeoutMs = 12000 } = {}) {
  const logger = typeof log === 'function' ? log : () => {};
  const origins = collectWordpressOrigins(webResponses);
  const findings = [];
  let fetched = 0;
  const users = [];
  const plugins = new Set();
  const themes = new Set();
  const wpTargets = [];
  let wpVersion = '';
  let xmlrpcEnabled = false;
  const seen = new Set((webResponses || []).map((r) => String(r?.url || '')).filter(Boolean));

  for (const origin of origins) {
    const base = String(origin).replace(/\/$/, '');
    const paths = ['/wp-login.php', '/xmlrpc.php', '/wp-json/wp/v2/users', '/readme.html'];
    for (const p of paths) {
      const u = `${base}${p}`;
      if (seen.has(u)) continue;
      try {
        logger(`[wp-focus] GET ${u}`, 'info');
        const r = await curlWebSingle({ url: u, timeoutMs, maxBodyBytes: 180000 });
        seen.add(u);
        r.__via = 'wp-focus';
        webResponses.push(r);
        fetched += 1;
        wpTargets.push(base);
        const st = Number(r.status) || 0;
        if (st >= 200 && st < 500) {
          findings.push({
            url: u,
            status: st,
            value: `WordPress endpoint ${p} (HTTP ${st})`,
            meta: 'wp-focus',
          });
        }
        if (p === '/readme.html' && st === 200) {
          const m = String(r.bodyText || '').match(/\bversion\s+([0-9]+\.[0-9]+(?:\.[0-9]+)?)\b/i);
          if (m?.[1]) {
            if (!wpVersion) wpVersion = String(m[1]).trim();
            findings.push({
              url: u,
              status: st,
              value: `WordPress version hint ${m[1]}`,
              meta: 'readme version',
            });
          }
        }
        if (p === '/xmlrpc.php' && st === 405) {
          xmlrpcEnabled = true;
          findings.push({
            url: u,
            status: st,
            value: 'XML-RPC endpoint exposto (405 expected)',
            meta: 'xmlrpc enabled signal',
          });
        }
        if (p === '/wp-json/wp/v2/users' && st >= 200 && st < 300) {
          for (const uName of parseWpUsersFromJson(r.bodyText || '')) {
            if (!users.includes(uName)) users.push(uName);
          }
        }
        if (!wpVersion) {
          const v = parseWpVersion(r.bodyText || '');
          if (v) wpVersion = v;
        }
      } catch {
        // ignore
      }
    }
  }

  // Plugin hints from all pages after focus requests.
  const pluginSet = new Set();
  for (const r of webResponses || []) {
    for (const p of extractPluginHints(r?.bodyText || '')) pluginSet.add(p);
    for (const t of extractThemeHints(r?.bodyText || '')) themes.add(t);
    if (!wpVersion) {
      const v = parseWpVersion(r?.bodyText || '');
      if (v) wpVersion = v;
    }
  }
  for (const p of [...pluginSet].slice(0, 15)) {
    plugins.add(p);
    findings.push({
      url: null,
      status: 0,
      value: `Plugin detectado: ${p}`,
      meta: 'wp-content/plugins path hint',
    });
    const hint = pluginCveHints(p);
    if (hint) {
      findings.push({
        url: null,
        status: 0,
        value: `Plugin CVE hint: ${p}`,
        meta: hint,
      });
    }
  }
  for (const t of [...themes].slice(0, 10)) {
    findings.push({
      url: null,
      status: 0,
      value: `Theme detectado: ${t}`,
      meta: 'wp-content/themes path hint',
    });
  }
  if (wpVersion) {
    findings.push({
      url: null,
      status: 0,
      value: `WordPress versão provável: ${wpVersion}`,
      meta: 'generator/assets/readme',
    });
  }
  for (const u of users.slice(0, 20)) {
    findings.push({
      url: null,
      status: 0,
      value: `WP user enum: ${u}`,
      meta: '/wp-json/wp/v2/users',
    });
  }

  return {
    originsTested: origins.length,
    fetched,
    findings,
    users: users.slice(0, 20),
    plugins: [...plugins].slice(0, 20),
    themes: [...themes].slice(0, 12),
    wpVersion,
    xmlrpcEnabled,
    wpTargets: unique(wpTargets).slice(0, 8),
  };
}

