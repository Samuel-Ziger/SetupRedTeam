import fs from 'fs';
import path from 'path';
import { DATA_DIR, resolveLocalProjectDbDir, sanitizePathSegment } from './db-sqlite.js';

/** Prompt idêntico para Gemini e Claude (system + instrução sobre o JSON). */
export const AI_SYSTEM_PROMPT = `És analista de segurança (bug bounty / pentest defensivo). Recebes UM objeto JSON exportado do framework GHOSTRECON (recon passivo, OSINT, heurísticas).

Regras obrigatórias:
- Baseia-te APENAS no conteúdo do JSON. Não inventes CVEs, versões exactas, URLs que não apareçam, nem explorações "confirmadas" se o dado for só heurística ou passivo.
- Indica claramente quando algo for hipótese ou requer verificação manual.
- Não descrevas passos de exploit automatizado; foca em priorização, verificação e documentação.

Formato de resposta (OBRIGATÓRIO):
Responde APENAS com um único objeto JSON válido (sem texto antes ou depois, sem blocos markdown), com exactamente estas chaves:
- "relatorio": string em Markdown — síntese executiva, superfície de ataque inferida, agrupamento por tipo de achado, notas de risco.
- "proximos_passos": string em Markdown — lista priorizada de próximas acções manuais (verificação, reprodução segura, escopo).

Idioma: português (Portugal ou Brasil, consistente).`;

const MAX_PAYLOAD_CHARS = 900_000;

function shrinkPayload(obj) {
  let o = JSON.parse(JSON.stringify(obj));
  if (!Array.isArray(o.findings)) o.findings = [];
  let s = JSON.stringify(o);
  while (s.length > MAX_PAYLOAD_CHARS && o.findings.length > 50) {
    const cut = Math.max(50, Math.floor(o.findings.length * 0.85));
    o.findings = o.findings.slice(0, cut);
    o._truncated = { note: 'findings cortados para caber no limite da API', kept: o.findings.length };
    s = JSON.stringify(o);
  }
  if (s.length > MAX_PAYLOAD_CHARS) {
    o.findings = (o.findings || []).slice(0, 100);
    o._truncated = { note: 'truncagem agressiva', kept: o.findings.length };
    s = JSON.stringify(o);
  }
  return { payload: o, json: s };
}

function buildUserContent(jsonString) {
  return `${AI_SYSTEM_PROMPT}

---

Segue o JSON completo do pipeline GHOSTRECON (é o único contexto). Depois da análise, responde só com o objeto JSON com "relatorio" e "proximos_passos".

JSON:
${jsonString}`;
}

function extractJsonObject(text) {
  if (!text || typeof text !== 'string') throw new Error('Resposta vazia');
  let s = text.trim();
  const fence = s.match(/```(?:json)?\s*([\s\S]*?)```/i);
  if (fence) s = fence[1].trim();
  const start = s.indexOf('{');
  const end = s.lastIndexOf('}');
  if (start === -1 || end <= start) throw new Error('JSON não encontrado na resposta');
  s = s.slice(start, end + 1);
  return JSON.parse(s);
}

export async function callGemini(userText, apiKey, model) {
  const u = new URL(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
  );
  u.searchParams.set('key', apiKey);
  const res = await fetch(u.toString(), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: userText }] }],
      generationConfig: {
        temperature: 0.25,
        maxOutputTokens: 8192,
      },
    }),
    signal: AbortSignal.timeout(180000),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = data?.error?.message || JSON.stringify(data).slice(0, 300);
    throw new Error(`Gemini HTTP ${res.status}: ${msg}`);
  }
  const parts = data?.candidates?.[0]?.content?.parts;
  const t = Array.isArray(parts) ? parts.map((p) => p.text || '').join('') : '';
  if (!t) throw new Error('Gemini sem texto na resposta');
  return t;
}

export async function callClaude(userText, apiKey, model) {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: 16384,
      system: AI_SYSTEM_PROMPT,
      messages: [{ role: 'user', content: userText }],
    }),
    signal: AbortSignal.timeout(180000),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = data?.error?.message || JSON.stringify(data).slice(0, 300);
    throw new Error(`Claude HTTP ${res.status}: ${msg}`);
  }
  const blocks = data?.content;
  const t = Array.isArray(blocks) ? blocks.map((b) => (b.type === 'text' ? b.text : '')).join('') : '';
  if (!t) throw new Error('Claude sem texto na resposta');
  return t;
}

/** Conteúdo user só com o JSON (system já leva as regras no Claude). */
function buildClaudeUserPayloadJsonOnly(jsonString) {
  return `Analisa o seguinte JSON do GHOSTRECON. Responde APENAS com o objeto JSON pedido (chaves "relatorio" e "proximos_passos", valores Markdown).

JSON:
${jsonString}`;
}

function resolveOutputDir(projectName, targetDomain) {
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const scoped = resolveLocalProjectDbDir(projectName, targetDomain);
  if (scoped) return path.join(scoped, 'ia', stamp);
  const safe = sanitizePathSegment(targetDomain, 'alvo');
  return path.join(DATA_DIR, 'ai_reports', safe, stamp);
}

/**
 * @param {object} payload — export completo do pipeline (UI)
 * @returns {{ outputDir: string, gemini: object, claude: object, pipelineJsonPath: string }}
 */
export async function runDualAiReports(payload, { projectName, targetDomain } = {}) {
  const geminiKey = process.env.GEMINI_API_KEY?.trim() || process.env.GOOGLE_AI_API_KEY?.trim();
  const claudeKey = process.env.ANTHROPIC_API_KEY?.trim();
  const geminiModel = process.env.GHOSTRECON_GEMINI_MODEL?.trim() || 'gemini-2.0-flash';
  const claudeModel = process.env.GHOSTRECON_CLAUDE_MODEL?.trim() || 'claude-3-5-sonnet-20241022';

  const { payload: p, json: jsonStr } = shrinkPayload(payload);
  const outputDir = resolveOutputDir(projectName, targetDomain);
  fs.mkdirSync(outputDir, { recursive: true });
  const pipelineJsonPath = path.join(outputDir, 'pipeline_snapshot.json');
  fs.writeFileSync(pipelineJsonPath, JSON.stringify(p, null, 2), 'utf8');

  const userBlockGemini = buildUserContent(jsonStr);
  const userBlockClaude = buildClaudeUserPayloadJsonOnly(jsonStr);

  const result = {
    outputDir,
    pipelineJsonPath,
    gemini: { ok: false, error: null, relatorioPath: null, proximosPath: null },
    claude: { ok: false, error: null, relatorioPath: null, proximosPath: null },
  };

  const writePair = (prefix, parsed) => {
    const rel = String(parsed?.relatorio ?? '');
    const prox = String(parsed?.proximos_passos ?? '');
    const rp = path.join(outputDir, `${prefix}_relatorio.md`);
    const pp = path.join(outputDir, `${prefix}_proximos_passos.md`);
    fs.writeFileSync(rp, rel, 'utf8');
    fs.writeFileSync(pp, prox, 'utf8');
    return { relatorioPath: rp, proximosPath: pp };
  };

  if (geminiKey) {
    try {
      const raw = await callGemini(userBlockGemini, geminiKey, geminiModel);
      fs.writeFileSync(path.join(outputDir, 'gemini_raw.txt'), raw, 'utf8');
      const parsed = extractJsonObject(raw);
      const paths = writePair('gemini', parsed);
      result.gemini = { ok: true, ...paths };
    } catch (e) {
      result.gemini = { ok: false, error: e.message, relatorioPath: null, proximosPath: null };
    }
  } else {
    result.gemini = { ok: false, error: 'GEMINI_API_KEY ou GOOGLE_AI_API_KEY não definido', relatorioPath: null, proximosPath: null };
  }

  if (claudeKey) {
    try {
      const raw = await callClaude(userBlockClaude, claudeKey, claudeModel);
      fs.writeFileSync(path.join(outputDir, 'claude_raw.txt'), raw, 'utf8');
      const parsed = extractJsonObject(raw);
      const paths = writePair('claude', parsed);
      result.claude = { ok: true, ...paths };
    } catch (e) {
      result.claude = { ok: false, error: e.message, relatorioPath: null, proximosPath: null };
    }
  } else {
    result.claude = { ok: false, error: 'ANTHROPIC_API_KEY não definido', relatorioPath: null, proximosPath: null };
  }

  return result;
}

export function aiKeysConfigured() {
  const g = Boolean(process.env.GEMINI_API_KEY?.trim() || process.env.GOOGLE_AI_API_KEY?.trim());
  const c = Boolean(process.env.ANTHROPIC_API_KEY?.trim());
  return { gemini: g, claude: c, any: g || c, both: g && c };
}
