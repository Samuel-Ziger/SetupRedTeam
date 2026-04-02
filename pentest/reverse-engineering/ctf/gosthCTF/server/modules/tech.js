import { enrichTechWithVersions } from './tech-versions.js';

/**
 * Detecção heurística de stack (headers + snippet HTML/JS) + versões em banner/meta.
 */
export function detectTech(headers, bodySnippet) {
  const list = [];
  const add = (label) => {
    const x = String(label || '').trim();
    if (!x) return;
    if (!list.includes(x)) list.push(x);
  };
  const server = headers.get('server');
  if (server) add(`Server: ${server}`);
  const xp = headers.get('x-powered-by');
  if (xp) add(`X-Powered-By: ${xp}`);
  const cf = headers.get('cf-ray');
  if (cf) add('Cloudflare (CF-Ray presente)');
  const xAsp = headers.get('x-aspnet-version');
  if (xAsp) add(`ASP.NET/${xAsp} (header)`);
  const xAspMvc = headers.get('x-aspnetmvc-version');
  if (xAspMvc) add(`ASP.NET MVC/${xAspMvc} (header)`);
  const xDrupalCache = headers.get('x-drupal-cache');
  if (xDrupalCache) add('Drupal (header)');
  const xGenerator = headers.get('x-generator');
  if (xGenerator) add(`Generator header: ${xGenerator}`);

  const html = String(bodySnippet == null ? '' : bodySnippet);
  const lower = html.slice(0, 60000).toLowerCase();
  const hints = [
    ['wp-content', 'WordPress'],
    ['/wp-includes/', 'WordPress'],
    ['wp-json', 'WordPress REST'],
    ['woocommerce', 'WooCommerce'],
    ['drupal-settings-json', 'Drupal'],
    ['sites/all/', 'Drupal (hint)'],
    ['/skin/frontend/', 'Magento (hint)'],
    ['shopify', 'Shopify (hint)'],
    ['cdn.shopify.com', 'Shopify'],
    ['react', 'React (hint)'],
    ['__next', 'Next.js (hint)'],
    ['_next/static', 'Next.js'],
    ['nuxt', 'Nuxt (hint)'],
    ['angular', 'Angular (hint)'],
    ['vue', 'Vue.js (hint)'],
    ['svelte', 'Svelte (hint)'],
    ['laravel', 'Laravel (hint)'],
    ['csrf-token', 'Laravel (hint)'],
    ['django', 'Django (hint)'],
    ['ruby on rails', 'Ruby on Rails (hint)'],
    ['spring', 'Spring (hint)'],
    ['/static/js/main.', 'Create React App (hint)'],
    ['/assets/index-', 'Vite build (hint)'],
  ];
  for (const [needle, label] of hints) {
    if (lower.includes(needle)) add(label);
  }

  // Leve estilo "Wappalyzer-like": fingerprint por <script src> com versão.
  const scriptVersionPatterns = [
    [/jquery[.-](\d+\.\d+(?:\.\d+)?)(?:\.min)?\.js/i, 'jQuery'],
    [/bootstrap(?:[.-](\d+\.\d+(?:\.\d+)?))?(?:\.min)?\.js/i, 'Bootstrap JS'],
    [/bootstrap[.-](\d+\.\d+(?:\.\d+)?)(?:\.min)?\.css/i, 'Bootstrap CSS'],
    [/vue(?:\.runtime)?(?:[.-](\d+\.\d+(?:\.\d+)?))?(?:\.prod)?(?:\.min)?\.js/i, 'Vue.js'],
    [/react(?:[.-](\d+\.\d+(?:\.\d+)?))?(?:\.production)?(?:\.min)?\.js/i, 'React'],
    [/angular(?:[.-](\d+\.\d+(?:\.\d+)?))?(?:\.min)?\.js/i, 'AngularJS'],
    [/lodash(?:[.-](\d+\.\d+(?:\.\d+)?))?(?:\.min)?\.js/i, 'Lodash'],
    [/moment(?:[.-](\d+\.\d+(?:\.\d+)?))?(?:\.min)?\.js/i, 'Moment.js'],
    [/font-?awesome(?:[.-](\d+\.\d+(?:\.\d+)?))?(?:\.min)?\.(?:css|js)/i, 'Font Awesome'],
  ];
  for (const [re, label] of scriptVersionPatterns) {
    const m = html.match(re);
    if (!m) continue;
    if (m[1]) add(`${label}/${m[1]} (asset)`);
    else add(`${label} (asset)`);
  }

  // Meta generator (fallback rápido se enrich não extrair versão)
  const gen = html.match(/<meta[^>]+name=["']generator["'][^>]+content=["']([^"']+)["']/i);
  if (gen?.[1]) add(`Generator: ${gen[1]}`);

  const base = [...new Set(list)];
  return enrichTechWithVersions(headers, html.slice(0, 90000), base);
}
