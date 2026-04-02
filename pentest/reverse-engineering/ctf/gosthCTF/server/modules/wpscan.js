import { readFile, writeFile, mkdtemp, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { spawn } from 'node:child_process';

function runProc(cmd, args, timeoutMs) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const out = [];
    const err = [];
    let killed = false;

    const t = setTimeout(() => {
      killed = true;
      try {
        child.kill('SIGKILL');
      } catch {
        /* ignore */
      }
      reject(new Error(`${cmd} timeout (${timeoutMs}ms)`));
    }, timeoutMs);

    child.stdout.on('data', (d) => out.push(d));
    child.stderr.on('data', (d) => err.push(d));
    child.on('error', (e) => {
      clearTimeout(t);
      reject(e);
    });
    child.on('close', (code) => {
      clearTimeout(t);
      if (killed) return;
      resolve({
        code,
        stdout: Buffer.concat(out).toString('utf8'),
        stderr: Buffer.concat(err).toString('utf8'),
      });
    });
  });
}

function safeConfidence(n) {
  const x = Number(n);
  return Number.isFinite(x) ? x : null;
}

function prioScoreFromVersionConfidence({ hasVersion, confidence }) {
  const c = safeConfidence(confidence);
  if (!hasVersion) return { prio: 'low', score: 40 };
  if (c != null && c >= 80) return { prio: 'med', score: 80 };
  return { prio: 'med', score: 70 };
}

function extractMainThemeFindings(targetUrl, wps) {
  const out = [];
  const mt = wps?.main_theme;
  if (!mt?.slug) return out;

  const location = mt.location || null;
  const version = mt?.version?.number || null;
  const confidence = mt?.version?.confidence ?? null;

  const { prio, score } = prioScoreFromVersionConfidence({ hasVersion: Boolean(version), confidence });
  out.push({
    type: 'wpscan',
    prio,
    score,
    value: version ? `Main theme: ${mt.slug} v${version}` : `Main theme: ${mt.slug}`,
    meta: `found_by=${mt?.version?.found_by || mt?.found_by || 'unknown'}; confidence=${confidence ?? '—'}`,
    url: location || targetUrl,
  });

  return out;
}

function extractPluginsFindings(targetUrl, wps) {
  const out = [];
  const plugins = wps?.plugins;
  if (!plugins || typeof plugins !== 'object') return out;

  for (const [slug, p] of Object.entries(plugins)) {
    if (slug === '*') continue; // placeholder entry
    if (!p || typeof p !== 'object') continue;

    const location = p.location || null;
    const version = p?.version?.number || null;
    const confidence = p?.version?.confidence ?? p?.confidence ?? null;

    const { prio, score } = prioScoreFromVersionConfidence({ hasVersion: Boolean(version), confidence });
    out.push({
      type: 'wpscan',
      prio,
      score,
      value: version ? `Plugin: ${slug} v${version}` : `Plugin: ${slug}`,
      meta: `found_by=${p?.version?.found_by || p?.found_by || 'unknown'}; confidence=${confidence ?? '—'}`,
      url: location || targetUrl,
    });
  }

  return out;
}

function extractCoreVersionFindings(targetUrl, wps) {
  const out = [];
  const v = wps?.version;
  if (!v || typeof v !== 'object') return out;

  const number = v?.number;
  if (!number) return out;

  const confidence = v?.confidence ?? null;
  const { prio, score } = prioScoreFromVersionConfidence({ hasVersion: true, confidence });
  out.push({
    type: 'wpscan',
    prio,
    score,
    value: `WordPress version: ${number}`,
    meta: `found_by=${v?.found_by || 'unknown'}; confidence=${confidence ?? '—'}`,
    url: targetUrl,
  });
  return out;
}

export function extractWpscanFindings({ targetUrl, wpscanJson }) {
  if (!wpscanJson || typeof wpscanJson !== 'object') return [];
  const out = [
    ...extractCoreVersionFindings(targetUrl, wpscanJson),
    ...extractMainThemeFindings(targetUrl, wpscanJson),
    ...extractPluginsFindings(targetUrl, wpscanJson),
  ];

  // limit to avoid UI flood (still shows "what it found")
  const maxFindings = 60;
  return out.slice(0, maxFindings);
}

/**
 * Rodar wpscan e retornar JSON parseado.
 * @returns {Promise<{ json: any|null, error?: string, stderr?: string }>}
 */
export async function runWpscanJson({ targetUrl, detectionMode, timeoutMs, log }) {
  const dir = await mkdtemp(join(tmpdir(), 'ghwp-'));
  const outJson = join(dir, 'wpscan.json');

  const mode = detectionMode || 'mixed';
  const timeout = Number(timeoutMs) > 0 ? Number(timeoutMs) : 240000;

  try {
    const args = [
      '--url',
      targetUrl,
      '--detection-mode',
      mode,
      '--format',
      'json',
      '-o',
      outJson,
      '--random-user-agent',
      '--no-banner',
      '--force',
    ];

    const label = `wpscan ${mode} ${targetUrl}`;
    if (typeof log === 'function') log(`Executando ${label}...`, 'info');

    const proc = await runProc('wpscan', args, timeout);
    if (proc.code !== 0) {
      if (typeof log === 'function') log(`${label} terminou com código ${proc.code}`, 'warn');
    }

    const raw = await readFile(outJson, 'utf8');
    try {
      const json = JSON.parse(raw);
      return { json };
    } catch (e) {
      return { json: null, error: `JSON parse error: ${e.message}`, stderr: proc.stderr || '' };
    }
  } catch (e) {
    return { json: null, error: String(e?.message || e), stderr: '' };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

