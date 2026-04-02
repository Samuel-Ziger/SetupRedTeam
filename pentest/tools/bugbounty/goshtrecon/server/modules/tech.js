import { enrichTechWithVersions } from './tech-versions.js';

/**
 * Detecção heurística de stack (headers + snippet HTML/JS) + versões em banner/meta.
 */
export function detectTech(headers, bodySnippet) {
  const list = [];
  const server = headers.get('server');
  if (server) list.push(`Server: ${server}`);
  const xp = headers.get('x-powered-by');
  if (xp) list.push(`X-Powered-By: ${xp}`);
  const cf = headers.get('cf-ray');
  if (cf) list.push('Cloudflare (CF-Ray presente)');

  const lower = bodySnippet.slice(0, 12000).toLowerCase();
  const hints = [
    ['wp-content', 'WordPress'],
    ['react', 'React (hint)'],
    ['__next', 'Next.js (hint)'],
    ['nuxt', 'Nuxt (hint)'],
    ['angular', 'Angular (hint)'],
    ['laravel', 'Laravel (hint)'],
    ['django', 'Django (hint)'],
    ['rails', 'Ruby on Rails (hint)'],
    ['spring', 'Spring (hint)'],
    ['/wp-includes/', 'WordPress'],
  ];
  for (const [needle, label] of hints) {
    if (lower.includes(needle) && !list.some((l) => l.includes(label.split(' ')[0]))) list.push(label);
  }

  const base = [...new Set(list)];
  return enrichTechWithVersions(headers, bodySnippet.slice(0, 50000), base);
}
