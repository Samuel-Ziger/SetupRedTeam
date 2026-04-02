import { UA } from '../config.js';

/**
 * Busca passiva na API pública do GitHub (rate limit baixo sem token).
 */
export async function githubCodeSearch(domain, token) {
  const q = encodeURIComponent(`${domain} password OR api_key OR secret`);
  const url = `https://api.github.com/search/code?q=${q}&per_page=5`;
  const headers = {
    'User-Agent': UA,
    Accept: 'application/vnd.github+json',
  };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(30000) });
  if (res.status === 403 || res.status === 401) {
    return { ok: false, note: 'GitHub API rate limit ou auth — defina GITHUB_TOKEN' };
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
