import dns from 'node:dns/promises';

const PROVIDERS = [
  { name: 'GitHub Pages', cname: 'github.io', body: /There isn't a GitHub Pages site here/i },
  { name: 'Heroku', cname: 'herokudns.com', body: /no such app/i },
  { name: 'Amazon S3', cname: 's3-website', body: /The specified bucket does not exist/i },
  { name: 'Azure', cname: 'azurewebsites.net', body: /404 Web Site not found/i },
  { name: 'Fastly', cname: 'fastly.net', body: /Fastly error: unknown domain/i },
  { name: 'CloudFront', cname: 'cloudfront.net', body: /Bad request|ERROR/i },
];

export async function resolveCnameChain(hostname, limit = 5) {
  const chain = [];
  let cur = hostname;
  for (let i = 0; i < limit; i++) {
    try {
      const cn = await dns.resolveCname(cur);
      if (!cn?.length) break;
      chain.push(cn[0]);
      cur = cn[0];
    } catch {
      break;
    }
  }
  return chain;
}

export function matchProviderByCname(chain) {
  const joined = chain.join(' ').toLowerCase();
  for (const p of PROVIDERS) {
    if (joined.includes(p.cname)) return p;
  }
  return null;
}

export function matchProviderBody(p, body) {
  if (!p || !p.body) return false;
  return p.body.test(String(body || ''));
}
