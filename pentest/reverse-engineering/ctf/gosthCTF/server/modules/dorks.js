/**
 * Templates de Google Dorks — apenas geração de URLs de busca (sem scraping).
 * Para adicionar categoria: inclua chave em DORK_TEMPLATES com array de funções (domain) => string.
 */
export const DORK_TEMPLATES = {
  directory: [
    (d) => `site:${d} intitle:"index of"`,
    (d) => `site:${d} intitle:"index of /" "parent directory"`,
    (d) => `site:${d} intitle:"index of" inurl:backup`,
  ],
  documents: [
    // PDFs e documentos de escritório (uso geral)
    (d) => `site:${d} (filetype:pdf OR filetype:doc OR filetype:docx OR filetype:odt OR filetype:xls OR filetype:xlsx OR filetype:ods OR filetype:csv OR filetype:ppt OR filetype:pptx OR filetype:odp)`,
    // PDFs com termos comuns de vazamento
    (d) => `site:${d} filetype:pdf ("confidential" OR "internal use" OR "do not distribute" OR "for internal")`,
    // Word/ODT com termos comuns
    (d) => `site:${d} (filetype:doc OR filetype:docx OR filetype:odt) ("confidential" OR "internal" OR "contract" OR "nda")`,
    // Planilhas/CSV com contexto de documento interno
    (d) => `site:${d} (filetype:xls OR filetype:xlsx OR filetype:ods OR filetype:csv) ("internal" OR "report" OR "pricing" OR "budget")`,
    // Apresentações
    (d) => `site:${d} (filetype:ppt OR filetype:pptx OR filetype:odp) ("presentation" OR "slide" OR "deck" OR "overview")`,
  ],
  config: [
    (d) => `site:${d} ext:xml OR ext:conf OR ext:cnf OR ext:config`,
    (d) => `site:${d} inurl:".env" OR inurl:".config"`,
    (d) => `site:${d} ext:ini "password" OR "db_pass"`,
    (d) => `site:${d} ext:yaml OR ext:yml`,
  ],
  database: [
    (d) => `site:${d} ext:sql OR ext:db OR ext:sqlite`,
    (d) => `site:${d} ext:sql "INSERT INTO" OR "CREATE TABLE"`,
    (d) => `site:${d} filetype:mdb`,
  ],
  logs: [
    (d) => `site:${d} ext:log OR inurl:"/logs/"`,
    (d) => `site:${d} inurl:error_log OR inurl:access_log`,
  ],
  backup: [
    (d) => `site:${d} ext:bak OR ext:old OR ext:backup OR ext:orig`,
    (d) => `site:${d} inurl:backup OR inurl:bkp OR inurl:old`,
    (d) => `site:${d} ext:zip OR ext:tar OR ext:gz "backup"`,
  ],
  login: [
    (d) => `site:${d} inurl:login OR inurl:admin OR inurl:signin`,
    (d) => `site:${d} inurl:wp-admin OR inurl:wp-login`,
    (d) => `site:${d} intitle:"admin panel" OR intitle:"control panel"`,
    (d) => `site:${d} inurl:dashboard inurl:admin`,
  ],
  sqlerrors: [
    (d) => `site:${d} "sql syntax" OR "mysql_fetch" OR "ORA-01756"`,
    (d) => `site:${d} intext:"Warning: mysql" OR intext:"MySQL Error"`,
    (d) => `site:${d} "Microsoft OLE DB Provider for SQL Server"`,
  ],
  phperrors: [
    (d) => `site:${d} intext:"Fatal error" intext:"PHP"`,
    (d) => `site:${d} "Warning: include" OR "Warning: require"`,
  ],
  phpinfo: [
    (d) => `site:${d} inurl:phpinfo.php OR intitle:"phpinfo()"`,
    (d) => `site:${d} inurl:info.php intitle:"PHP Version"`,
  ],
  github: [
    (d) => `"${d}" site:github.com password OR apikey OR token OR secret`,
    (d) => `"${d}" site:github.com .env OR .config OR credentials`,
  ],
  pastebin: [
    (d) => `"${d}" site:pastebin.com password OR api_key`,
    (d) => `"${d}" site:pastebin.com leaked OR dump`,
  ],
  passwords: [
    (d) => `site:${d} intext:"password" filetype:txt OR filetype:log`,
    (d) => `"${d}" "admin" "password" site:pastebin.com OR site:github.com`,
  ],
  sensitive: [
    (d) => `site:${d} inurl:api/v1 OR inurl:api/v2 OR inurl:/api/`,
    (d) => `site:${d} inurl:.git OR inurl:.svn OR inurl:.htpasswd`,
    (d) => `site:${d} ext:json "api_key" OR "access_token" OR "client_secret"`,
  ],
  subdomains: [],
  wayback: [],
  /** Descoberta via Google Custom Search API (chaves em env), não gera query própria */
  google_cse: [],
  common_crawl: [],
  robots_sitemap: [],
  rdap: [],
  security_headers: [],
  virustotal: [],
};

const HIGH_DORK = new Set([
  'sqlerrors',
  'config',
  'backup',
  'phpinfo',
  'database',
  'passwords',
  'sensitive',
  'github',
  'pastebin',
]);

export function buildDorks(domainStr, selectedMods) {
  const out = [];
  for (const mod of selectedMods) {
    const tpls = DORK_TEMPLATES[mod];
    if (!tpls?.length) continue;
    for (const fn of tpls) {
      const query = fn(domainStr);
      out.push({
        mod,
        query,
        googleUrl: `https://www.google.com/search?q=${encodeURIComponent(query)}`,
        prio: HIGH_DORK.has(mod) ? 'high' : 'med',
      });
    }
  }
  return out;
}
