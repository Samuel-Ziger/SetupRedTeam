import { UA } from '../config.js';

/**
 * Busca passiva na API pública do GitHub (rate limit baixo sem token).
 */
function trimToken(raw) {
  if (raw == null || typeof raw !== 'string') return '';
  let t = raw.trim();
  if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
    t = t.slice(1, -1).trim();
  }
  return t;
}

export async function githubCodeSearch(domain, token) {
  const q = encodeURIComponent(`${domain} password OR api_key OR secret`);
  const url = `https://api.github.com/search/code?q=${q}&per_page=5`;
  const tok = trimToken(token);
  const headers = {
    'User-Agent': UA,
    Accept: 'application/vnd.github+json',
  };
  if (tok) headers.Authorization = `Bearer ${tok}`;
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(30000) });
  if (res.status === 403 || res.status === 401) {
    let detail = '';
    try {
      const errBody = await res.clone().json();
      if (errBody?.message) detail = ` — ${String(errBody.message).slice(0, 200)}`;
    } catch {
      /* ignore */
    }
    const hint = tok
      ? 'Token rejeitado (expirado/revogado ou fine-grained sem permissões) ou rate limit.'
      : 'Sem GITHUB_TOKEN no processo (reinicia o servidor depois de editar .env) ou rate limit por IP.';
    return { ok: false, note: `GitHub API ${res.status}: ${hint}${detail}` };
  }
  if (!res.ok) return { ok: false, note: `HTTP ${res.status}` };
  const data = await res.json();
  const items = data.items || [];
  return {
    ok: true,
    total: data.total_count ?? items.length,
    items: items.map((it) => ({
      repo: it.repository?.full_name,
      path: it.path,
      html_url: it.html_url,
    })),
  };
}
