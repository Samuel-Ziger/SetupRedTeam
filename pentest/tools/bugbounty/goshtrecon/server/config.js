export const UA = 'GHOSTRECON/1.0 (+https://example.local; passive OSINT)';

export const limits = {
  waybackCollapseLimit: 3000,
  maxJsFetch: 18,
  probeConcurrency: 6,
  probeTimeoutMs: 12000,
  maxBodySnippet: 65536,
  /** Máx. queries CSE por run (quota grátis ~100/dia) */
  googleCseMaxQueries: 20,
  googleCseDelayMs: 650,
  /** Common Crawl CDX — URLs 200 por índice */
  commonCrawlLimit: 2500,
  commonCrawlCollinfoTimeoutMs: 25000,
  commonCrawlQueryTimeoutMs: 120000,
  /** robots.txt / sitemap.xml */
  surfaceConcurrency: 4,
  robotsFetchTimeoutMs: 12000,
  maxSitemapUrlsPerHost: 400,
  maxSitemapFilesTotal: 12,
  tlsProbeTimeoutMs: 8000,
  /** VirusTotal subdomains (opcional) */
  virustotalSubdomainMax: 200,
  /** DNS enrichment (TXT/MX/DMARC/SPF) */
  dnsEnrichMaxHosts: 18,
  dnsEnrichTimeoutMs: 9000,
  dnsEnrichConcurrency: 6,
  dnsMxMax: 6,
  dnsTxtEnrichMaxHosts: 8,
  dnsTxtInterestingMax: 8,
  /** /.well-known (security.txt / OIDC discovery) */
  wellKnownMaxHosts: 18,
  wellKnownConcurrency: 4,
  wellKnownSecurityTxtTimeoutMs: 8000,
  wellKnownOpenIdTimeoutMs: 9000,
  wellKnownOpenIdMaxEndpoints: 10,
  /** WHOIS (Kali mode) */
  whoisTimeoutMs: 20000,
  whoisSubdomainsMax: 3,
  /** Superfície extraída do HTML (href/forms) por host vivo */
  htmlSurfaceMaxEndpoints: 100,
  /** Shodan (módulo passivo): resolução e IPs consultados */
  shodanResolveMaxHosts: 14,
  shodanMaxIps: 5,
  /** OpenAPI/Swagger — quantas origens HTTPS tentar */
  openapiMaxOrigins: 10,
  /** Stealth (jitter entre pedidos, ms) */
  stealthJitterMinMs: 60,
  stealthJitterMaxMs: 420,
};

/** Rate limit POST /api/recon/stream (por IP). 0 = desativado */
export function reconRateLimitConfig() {
  const max = Number(process.env.GHOSTRECON_RL_MAX || 12);
  const windowMs = Number(process.env.GHOSTRECON_RL_WINDOW_MS || 60000);
  if (!Number.isFinite(max) || max <= 0) return { max: 0, windowMs: 60000 };
  return { max, windowMs: Number.isFinite(windowMs) && windowMs > 0 ? windowMs : 60000 };
}

export const interestingPathRe =
  /\/(api|admin|login|signin|dashboard|internal|debug|dev|test|graphql|swagger|actuator|v1|v2|oauth|callback)(\/|$)/i;

export const sensitiveExtRe = /\.(env|git|bak|old|sql|db|sqlite|pem|key|config|json|ya?ml|log)$/i;
