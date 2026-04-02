/**
 * Postgres direto via DATABASE_URL (conexão Supabase “Direct” ou Session Pooler).
 * Alinhado ao guia Node.js do dashboard Supabase.
 */
import postgres from 'postgres';
import { fingerprintFinding, findingsForRunsTable, norm } from './db-common.js';

let sqlInstance = null;

export function getSql() {
  if (sqlInstance) return sqlInstance;
  const url = process.env.DATABASE_URL?.trim();
  if (!url) {
    throw new Error('DATABASE_URL em falta');
  }
  const isSupabaseHost = /supabase\.co/i.test(url);
  sqlInstance = postgres(url, {
    ssl: isSupabaseHost ? 'require' : undefined,
    max: 10,
  });
  return sqlInstance;
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
    const sql = getSql();
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
        const rows = await sql`
          select id, fp, score, prio, meta, url
          from bounty_intel
          where target = ${t} and fp in ${sql(slice)}
        `;
        for (const r of rows) fromDb.set(r.fp, { ...r });
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
        await sql`insert into bounty_intel ${sql(toInsert.slice(i, i + batch))}`;
      }
    }

    for (const fp of touchedDb) {
      const cur = fromDb.get(fp);
      await sql`
        update bounty_intel set
          last_seen = ${cur.last_seen},
          last_run_id = ${cur.last_run_id},
          score = ${cur.score},
          prio = ${cur.prio},
          meta = ${cur.meta},
          url = ${cur.url}
        where id = ${cur.id}
      `;
    }

    const countRows = await sql`
      select count(*)::int as c from bounty_intel where target = ${t}
    `;
    const totalKnownForTarget = countRows[0]?.c ?? 0;

    return { newArtifacts, alreadyKnown, totalKnownForTarget };
  } catch (e) {
    console.error('[GHOSTCTF DB intel]', e.message);
    return { newArtifacts: 0, alreadyKnown: 0, totalKnownForTarget: 0, error: e.message };
  }
}

export async function saveRun({ target, exactMatch, modules, stats, findings, correlation }) {
  try {
    const sql = getSql();
    const t = norm(target);
    const corr = correlation == null ? null : sql.json(correlation);

    const [runRow] = await sql`
      insert into runs (target, exact_match, modules_json, stats_json, correlation_json)
      values (
        ${t},
        ${Boolean(exactMatch)},
        ${sql.json(modules)},
        ${sql.json(stats)},
        ${corr}
      )
      returning id
    `;
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

    for (let i = 0; i < rows.length; i += 500) {
      const chunk = rows.slice(i, i + 500);
      if (chunk.length) await sql`insert into findings ${sql(chunk)}`;
    }

    const intelMerge = await mergeIntelForTarget(t, runId, findings);

    return { runId, intelMerge };
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return null;
  }
}

export async function listRuns(limit = 50) {
  try {
    const sql = getSql();
    const lim = Math.min(200, Math.max(1, limit));
    const rows = await sql`
      select id, target, created_at, stats_json
      from runs
      order by id desc
      limit ${lim}
    `;
    return rows.map((r) => ({
      id: r.id,
      target: r.target,
      created_at: r.created_at,
      stats: parseJsonField(r.stats_json),
    }));
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return [];
  }
}

export async function getRunById(id) {
  try {
    const sql = getSql();
    const runs = await sql`select * from runs where id = ${id} limit 1`;
    const run = runs[0];
    if (!run) return null;
    const findings = await sql`
      select type, prio, score, value, meta, url
      from findings
      where run_id = ${id}
      order by id asc
    `;
    return {
      id: run.id,
      target: run.target,
      exact_match: Boolean(run.exact_match),
      modules: parseJsonField(run.modules_json),
      stats: parseJsonField(run.stats_json),
      correlation: run.correlation_json != null ? parseJsonField(run.correlation_json) : null,
      created_at: run.created_at,
      findings,
    };
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return null;
  }
}

export async function listIntelForTarget(target, limit = 500) {
  try {
    const sql = getSql();
    const t = String(target).trim().toLowerCase();
    const lim = Math.min(2000, Math.max(1, limit));
    return await sql`
      select type, prio, score, value, meta, url, first_seen, last_seen, last_run_id
      from bounty_intel
      where target = ${t}
      order by last_seen desc
      limit ${lim}
    `;
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return [];
  }
}

export async function intelCountForTarget(target) {
  try {
    const sql = getSql();
    const t = String(target).trim().toLowerCase();
    const rows = await sql`
      select count(*)::int as c from bounty_intel where target = ${t}
    `;
    return rows[0]?.c ?? 0;
  } catch {
    return 0;
  }
}
