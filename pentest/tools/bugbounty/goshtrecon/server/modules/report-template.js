function classifyFix(type) {
  switch (type) {
    case 'xss':
      return 'Aplicar encoding contextual (HTML/attr/JS), sanitização server-side e CSP estrita.';
    case 'sqli':
      return 'Usar queries parametrizadas/prepared statements e validação estrita de tipos.';
    case 'open_redirect':
      return 'Implementar allowlist de destinos e bloquear URLs absolutas externas.';
    case 'idor':
      return 'Aplicar autorização por objeto (ownership/ACL) em toda leitura/escrita por ID.';
    case 'lfi':
      return 'Bloquear path traversal, usar allowlist de ficheiros e resolver path canónico no servidor.';
    default:
      return 'Validar input, reforçar autorização e registrar evidência de tentativa.';
  }
}

export function buildReportTemplates(findings = [], target = '') {
  const out = [];
  const candidates = findings
    .filter((f) => ['xss', 'sqli', 'open_redirect', 'idor', 'lfi'].includes(String(f.type)))
    .filter((f) => ['confirmed', 'probable'].includes(String(f?.verification?.classification || '')))
    .slice(0, 24);

  for (const f of candidates) {
    const c = f.verification.classification;
    const evidence = f.verification?.evidence || {};
    const title = `[${c.toUpperCase()}] ${String(f.type).toUpperCase()} em ${target || 'alvo'} (${String(f.value || '').slice(0, 70)})`;
    const impact =
      f.type === 'xss'
        ? 'Possível execução de JavaScript no contexto da sessão do utilizador.'
        : f.type === 'sqli'
          ? 'Possível extração/alteração de dados sensíveis no backend.'
          : f.type === 'open_redirect'
            ? 'Possível phishing/cadeia de ataque via redirecionamento controlado.'
          : f.type === 'lfi'
            ? 'Possível leitura de ficheiros locais sensíveis no servidor.'
            : 'Possível acesso indevido a objetos de outros utilizadores.';
    const steps = [
      `Aceder: ${evidence.url || f.url || '(URL não informada)'}`,
      `Executar requisição: ${evidence.method || 'GET'} com payload de teste.`,
      'Comparar resposta e validar comportamento reproduzível.',
    ];
    const poc = evidence.requestSnippet || String(f.value || '');
    const ev = [
      `Status: ${evidence.status ?? 'n/a'}`,
      `Confidence: ${f?.verification?.confidenceScore ?? 'n/a'}`,
      `Evidence-Hash: ${evidence.evidenceHash || 'n/a'}`,
      `Snippet: ${String(evidence.responseSnippet || '').slice(0, 220)}`,
      `Source: ${evidence.source || 'verify'}`,
      `Timestamp: ${evidence.timestamp || f.verification.verifiedAt || ''}`,
    ].join(' | ');
    out.push({
      type: 'report_template',
      vulnType: f.type,
      classification: c,
      title,
      impact,
      stepsToReproduce: steps,
      poc,
      evidence: ev,
      suggestedFix: classifyFix(f.type),
      findingRef: String(f.value || '').slice(0, 160),
    });
  }
  return out;
}
