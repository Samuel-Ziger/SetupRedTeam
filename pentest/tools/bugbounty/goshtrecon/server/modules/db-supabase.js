import { createClient } from '@supabase/supabase-js';
import { fingerprintFinding, findingsForRunsTable, norm } from './db-common.js';

let client = null;

function getSupabase() {
  if (client) return client;
  const url = process.env.SUPABASE_URL?.trim();
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() ||
    process.env.SUPABASE_ANON_KEY?.trim() ||
    process.env.SUPABASE_KEY?.trim() ||
    process.env.SUPABASE_PUBLISHABLE_KEY?.trim();
  if (!url || !key) {
    throw new Error('SUPABASE_URL e chave (anon, publishable ou service_role) são obrigatórios');
  }
  client = createClient(url, key);
  return client;
}

function parseJsonField(v) {
  if (v == null) return v;
  if (typeof v === 'object') return v;
  try {
    return JSON.parse(String(v));
  } catch {
    return v;
  }
}

function mergeIntelRow(cur, f, runId, now) {
  cur.last_seen = now;
  cur.last_run_id = runId;
  const ns = f.score ?? null;
  if (ns != null && (cur.score == null || ns > cur.score)) {
    cur.score = ns;
    cur.prio = f.prio ?? null;
  }
  if (f.meta) cur.meta = f.meta;
  if (f.url) cur.url = f.url;
}

function newPendingIntelRow(t, fp, f, runId, now) {
  return {
    target: t,
    fp,
    type: f.type ?? null,
    prio: f.prio ?? null,
    score: f.score ?? null,
    value: f.value ?? '',
    meta: f.meta ?? null,
    url: f.url ?? null,
    first_seen: now,
    last_seen: now,
    last_run_id: runId,
  };
}

export async function mergeIntelForTarget(target, runId, findings) {
  try {
    const sb = getSupabase();
    const t = norm(target);
    const now = new Date().toISOString();
    let newArtifacts = 0;
    let alreadyKnown = 0;

    const fps = [...new Set(findings.map((f) => fingerprintFinding(t, f)))];
    const fromDb = new Map();
    if (fps.length) {
      const chunk = 200;
      for (let i = 0; i < fps.length; i += chunk) {
        const slice = fps.slice(i, i + chunk);
        const { data: rows, error } = await sb
          .from('bounty_intel')
          .select('id,fp,score,prio,meta,url')
          .eq('target', t)
          .in('fp', slice);
        if (error) throw error;
        for (const r of rows || []) fromDb.set(r.fp, { ...r });
      }
    }

    const pending = new Map();
    const touchedDb = new Set();

    for (const f of findings) {
      const fp = fingerprintFinding(t, f);
      if (fromDb.has(fp)) {
        alreadyKnown++;
        mergeIntelRow(fromDb.get(fp), f, runId, now);
        touchedDb.add(fp);
      } else if (pending.has(fp)) {
        alreadyKnown++;
        mergeIntelRow(pending.get(fp), f, runId, now);
      } else {
        newArtifacts++;
        pending.set(fp, newPendingIntelRow(t, fp, f, runId, now));
      }
    }

    if (pending.size) {
      const toInsert = [...pending.values()];
      const batch = 400;
      for (let i = 0; i < toInsert.length; i += batch) {
        const { error } = await sb.from('bounty_intel').insert(toInsert.slice(i, i + batch));
        if (error) throw error;
      }
    }

    for (const fp of touchedDb) {
      const cur = fromDb.get(fp);
      const { id, ...rest } = cur;
      const patch = {
        last_seen: rest.last_seen,
        last_run_id: rest.last_run_id,
        score: rest.score,
        prio: rest.prio,
        meta: rest.meta,
        url: rest.url,
      };
      const { error } = await sb.from('bounty_intel').update(patch).eq('id', id);
      if (error) throw error;
    }

    const { count, error: cErr } = await sb
      .from('bounty_intel')
      .select('*', { count: 'exact', head: true })
      .eq('target', t);
    if (cErr) throw cErr;

    return { newArtifacts, alreadyKnown, totalKnownForTarget: count ?? 0 };
  } catch (e) {
    console.error('[GHOSTRECON DB intel]', e.message);
    return { newArtifacts: 0, alreadyKnown: 0, totalKnownForTarget: 0, error: e.message };
  }
}

export async function saveRun({ target, exactMatch, modules, stats, findings, correlation }) {
  try {
    const sb = getSupabase();
    const t = norm(target);
    const { data: runRow, error: runErr } = await sb
      .from('runs')
      .insert({
        target: t,
        exact_match: Boolean(exactMatch),
        modules_json: modules,
        stats_json: stats,
        correlation_json: correlation ?? null,
      })
      .select('id')
      .single();
    if (runErr) throw runErr;
    const runId = Number(runRow.id);

    const rows = findingsForRunsTable(t, findings).map((f) => ({
      run_id: runId,
      type: f.type,
      prio: f.prio,
      score: f.score ?? null,
      value: f.value,
      meta: f.meta ?? null,
      url: f.url ?? null,
    }));

    const batch = 500;
    for (let i = 0; i < rows.length; i += batch) {
      const { error: fErr } = await sb.from('findings').insert(rows.slice(i, i + batch));
      if (fErr) throw fErr;
    }

    const intelMerge = await mergeIntelForTarget(t, runId, findings);

    return { runId, intelMerge };
  } catch (e) {
    console.error('[GHOSTRECON DB]', e.message);
    return null;
  }
}

export async function listRuns(limit = 50) {
  try {
    const sb = getSupabase();
    const lim = Math.min(200, Math.max(1, limit));
    const { data, error } = await sb
      .from('runs')
      .select('id, target, created_at, stats_json')
      .order('id', { ascending: false })
      .limit(lim);
    if (error) throw error;
    return (data || []).map((r) => ({
      id: r.id,
      target: r.target,
      created_at: r.created_at,
      stats: parseJsonField(r.stats_json),
    }));
  } catch (e) {
    console.error('[GHOSTRECON DB]', e.message);
    return [];
  }
}

export async function getRunById(id) {
  try {
    const sb = getSupabase();
    const { data: run, error: rErr } = await sb.from('runs').select('*').eq('id', id).maybeSingle();
    if (rErr) throw rErr;
    if (!run) return null;
    const { data: findings, error: fErr } = await sb
      .from('findings')
      .select('type, prio, score, value, meta, url')
      .eq('run_id', id)
      .order('id', { ascending: true });
    if (fErr) throw fErr;
    return {
      id: run.id,
      target: run.target,
      exact_match: Boolean(run.exact_match),
      modules: parseJsonField(run.modules_json),
      stats: parseJsonField(run.stats_json),
      correlation: run.correlation_json != null ? parseJsonField(run.correlation_json) : null,
      created_at: run.created_at,
      findings: findings || [],
    };
  } catch (e) {
    console.error('[GHOSTRECON DB]', e.message);
    return null;
  }
}

export async function listIntelForTarget(target, limit = 500) {
  try {
    const sb = getSupabase();
    const t = String(target).trim().toLowerCase();
    const lim = Math.min(2000, Math.max(1, limit));
    const { data, error } = await sb
      .from('bounty_intel')
      .select('type, prio, score, value, meta, url, first_seen, last_seen, last_run_id')
      .eq('target', t)
      .order('last_seen', { ascending: false })
      .limit(lim);
    if (error) throw error;
    return data || [];
  } catch (e) {
    console.error('[GHOSTRECON DB]', e.message);
    return [];
  }
}

export async function intelCountForTarget(target) {
  try {
    const sb = getSupabase();
    const t = String(target).trim().toLowerCase();
    const { count, error } = await sb
      .from('bounty_intel')
      .select('*', { count: 'exact', head: true })
      .eq('target', t);
    if (error) throw error;
    return count ?? 0;
  } catch {
    return 0;
  }
}
