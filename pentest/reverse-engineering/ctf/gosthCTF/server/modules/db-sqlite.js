import Database from 'better-sqlite3';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { findingsForRunsTable, fingerprintFinding, knowledgeKeyFromFinding } from './db-common.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, '..', '..');
const DATA_DIR = path.join(ROOT, 'data');
const DEFAULT_DB = path.join(DATA_DIR, 'bugbounty.db');

let dbInstance = null;

export function getDb() {
  if (dbInstance) return dbInstance;
  const dbPath = process.env.GHOSTCTF_DB ?? process.env.GHOSTRECON_DB ?? DEFAULT_DB;
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  dbInstance = new Database(dbPath);
  dbInstance.pragma('journal_mode = WAL');
  dbInstance.exec(`
    CREATE TABLE IF NOT EXISTS runs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      target TEXT NOT NULL,
      exact_match INTEGER NOT NULL DEFAULT 0,
      modules_json TEXT NOT NULL,
      stats_json TEXT NOT NULL,
      correlation_json TEXT,
      created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS findings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      run_id INTEGER NOT NULL,
      type TEXT,
      prio TEXT,
      score INTEGER,
      value TEXT,
      meta TEXT,
      url TEXT,
      FOREIGN KEY (run_id) REFERENCES runs(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_findings_run ON findings(run_id);

    CREATE TABLE IF NOT EXISTS bounty_intel (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      target TEXT NOT NULL,
      fp TEXT NOT NULL,
      type TEXT,
      prio TEXT,
      score INTEGER,
      value TEXT,
      meta TEXT,
      url TEXT,
      first_seen TEXT NOT NULL,
      last_seen TEXT NOT NULL,
      last_run_id INTEGER,
      UNIQUE(target, fp)
    );
    CREATE INDEX IF NOT EXISTS idx_intel_target ON bounty_intel(target);

    CREATE TABLE IF NOT EXISTS ctf_knowledge (
      k TEXT PRIMARY KEY,
      type TEXT,
      sample TEXT,
      count INTEGER NOT NULL DEFAULT 0,
      first_seen TEXT NOT NULL,
      last_seen TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_knowledge_type ON ctf_knowledge(type);
  `);
  return dbInstance;
}

function mergeKnowledge(findings) {
  const d = getDb();
  const now = new Date().toISOString();
  const sel = d.prepare('SELECT k, count FROM ctf_knowledge WHERE k = ?');
  const ins = d.prepare(
    `INSERT INTO ctf_knowledge (k, type, sample, count, first_seen, last_seen)
     VALUES (@k, @type, @sample, @count, @first, @last)`,
  );
  const upd = d.prepare(
    `UPDATE ctf_knowledge SET
       count = count + @inc,
       last_seen = @last,
       sample = COALESCE(NULLIF(@sample, ''), sample)
     WHERE k = @k`,
  );

  const seen = new Set();
  for (const f of findings || []) {
    if (!f) continue;
    // ignora ruído óbvio
    if (f.type === 'domain' || f.type === 'subdomain') continue;
    const key = knowledgeKeyFromFinding(f);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    const type = String(f.type || '').trim().toLowerCase();
    const sample = String(f.value || '').slice(0, 280);
    const cur = sel.get(key);
    if (cur) {
      upd.run({ k: key, inc: 1, last: now, sample });
    } else {
      ins.run({ k: key, type, sample, count: 1, first: now, last: now });
    }
  }
}

export function mergeIntelForTarget(target, runId, findings) {
  try {
    const d = getDb();
    const now = new Date().toISOString();
    let newArtifacts = 0;
    let alreadyKnown = 0;

    const sel = d.prepare('SELECT id FROM bounty_intel WHERE target = ? AND fp = ?');
    const ins = d.prepare(
      `INSERT INTO bounty_intel (target, fp, type, prio, score, value, meta, url, first_seen, last_seen, last_run_id)
       VALUES (@target, @fp, @type, @prio, @score, @value, @meta, @url, @first, @last, @run)`,
    );
    const upd = d.prepare(
      `UPDATE bounty_intel SET
         last_seen = @last,
         last_run_id = @run,
         score = CASE WHEN @score > score OR score IS NULL THEN @score ELSE score END,
         prio = CASE WHEN @score > COALESCE(score, 0) THEN @prio ELSE prio END,
         meta = COALESCE(NULLIF(@meta, ''), meta),
         url = COALESCE(NULLIF(@url, ''), url)
       WHERE target = @target AND fp = @fp`,
    );

    const tx = d.transaction((rows) => {
      for (const f of rows) {
        const fp = fingerprintFinding(target, f);
        if (sel.get(target, fp)) {
          upd.run({
            target,
            fp,
            last: now,
            run: runId,
            score: f.score ?? null,
            prio: f.prio ?? null,
            meta: f.meta ?? '',
            url: f.url ?? '',
          });
          alreadyKnown++;
        } else {
          ins.run({
            target,
            fp,
            type: f.type ?? null,
            prio: f.prio ?? null,
            score: f.score ?? null,
            value: f.value ?? '',
            meta: f.meta ?? null,
            url: f.url ?? null,
            first: now,
            last: now,
            run: runId,
          });
          newArtifacts++;
        }
      }
    });
    tx(findings);

    const row = d.prepare('SELECT COUNT(*) AS c FROM bounty_intel WHERE target = ?').get(target);
    const totalKnownForTarget = row?.c ?? 0;

    return { newArtifacts, alreadyKnown, totalKnownForTarget };
  } catch (e) {
    console.error('[GHOSTCTF DB intel]', e.message);
    return { newArtifacts: 0, alreadyKnown: 0, totalKnownForTarget: 0, error: e.message };
  }
}

export function saveRun({ target, exactMatch, modules, stats, findings, correlation }) {
  try {
    const d = getDb();
    const now = new Date().toISOString();
    const insRun = d.prepare(
      `INSERT INTO runs (target, exact_match, modules_json, stats_json, correlation_json, created_at)
       VALUES (@target, @exact, @modules, @stats, @corr, @created)`,
    );
    const insFinding = d.prepare(
      `INSERT INTO findings (run_id, type, prio, score, value, meta, url)
       VALUES (@run_id, @type, @prio, @score, @value, @meta, @url)`,
    );

    const runResult = insRun.run({
      target,
      exact: exactMatch ? 1 : 0,
      modules: JSON.stringify(modules),
      stats: JSON.stringify(stats),
      corr: correlation ? JSON.stringify(correlation) : null,
      created: now,
    });
    const runId = Number(runResult.lastInsertRowid);

    const insertAll = d.transaction((rows) => {
      for (const f of rows) {
        insFinding.run({
          run_id: runId,
          type: f.type,
          prio: f.prio,
          score: f.score ?? null,
          value: f.value,
          meta: f.meta ?? null,
          url: f.url ?? null,
        });
      }
    });
    insertAll(findingsForRunsTable(target, findings));

    const intelMerge = mergeIntelForTarget(target, runId, findings);
    // biblioteca global (independente do IP)
    try {
      mergeKnowledge(findings);
    } catch (e) {
      console.error('[GHOSTCTF DB knowledge]', e.message);
    }

    return { runId, intelMerge };
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return null;
  }
}

export function listKnowledge(limit = 80) {
  try {
    const d = getDb();
    const lim = Math.min(500, Math.max(1, Number(limit) || 80));
    return d
      .prepare(
        `SELECT k, type, sample, count, first_seen, last_seen
         FROM ctf_knowledge
         ORDER BY count DESC, last_seen DESC
         LIMIT ?`,
      )
      .all(lim);
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return [];
  }
}

export function listRuns(limit = 50) {
  try {
    const d = getDb();
    const rows = d
      .prepare(`SELECT id, target, created_at, stats_json FROM runs ORDER BY id DESC LIMIT ?`)
      .all(Math.min(200, Math.max(1, limit)));
    return rows.map((r) => ({
      id: r.id,
      target: r.target,
      created_at: r.created_at,
      stats: JSON.parse(r.stats_json),
    }));
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return [];
  }
}

export function getRunById(id) {
  try {
    const d = getDb();
    const run = d.prepare(`SELECT * FROM runs WHERE id = ?`).get(id);
    if (!run) return null;
    const findings = d
      .prepare(`SELECT type, prio, score, value, meta, url FROM findings WHERE run_id = ? ORDER BY id`)
      .all(id);
    return {
      id: run.id,
      target: run.target,
      exact_match: Boolean(run.exact_match),
      modules: JSON.parse(run.modules_json),
      stats: JSON.parse(run.stats_json),
      correlation: run.correlation_json ? JSON.parse(run.correlation_json) : null,
      created_at: run.created_at,
      findings,
    };
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return null;
  }
}

export function listIntelForTarget(target, limit = 500) {
  try {
    const d = getDb();
    const t = String(target).trim().toLowerCase();
    return d
      .prepare(
        `SELECT type, prio, score, value, meta, url, first_seen, last_seen, last_run_id
         FROM bounty_intel WHERE target = ? ORDER BY last_seen DESC LIMIT ?`,
      )
      .all(t, Math.min(2000, Math.max(1, limit)));
  } catch (e) {
    console.error('[GHOSTCTF DB]', e.message);
    return [];
  }
}

export function intelCountForTarget(target) {
  try {
    const d = getDb();
    const t = String(target).trim().toLowerCase();
    const r = d.prepare('SELECT COUNT(*) AS c FROM bounty_intel WHERE target = ?').get(t);
    return r?.c ?? 0;
  } catch {
    return 0;
  }
}
