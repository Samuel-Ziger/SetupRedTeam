import * as sqlite from './db-sqlite.js';
import * as supabase from './db-supabase.js';
import * as pg from './db-pg.js';

export { fingerprintFinding, norm } from './db-common.js';

/** Conexão direta Postgres (recomendado no Node; IPv4 → Session Pooler no dashboard). */
function useDatabaseUrl() {
  return Boolean(process.env.DATABASE_URL?.trim());
}

function useSupabaseApi() {
  if (useDatabaseUrl()) return false;
  const url = process.env.SUPABASE_URL?.trim();
  const key =
    process.env.SUPABASE_SERVICE_ROLE_KEY?.trim() ||
    process.env.SUPABASE_ANON_KEY?.trim() ||
    process.env.SUPABASE_KEY?.trim() ||
    process.env.SUPABASE_PUBLISHABLE_KEY?.trim();
  return Boolean(url && key);
}

export function isUsingSupabase() {
  return useDatabaseUrl() || useSupabaseApi();
}

export function storageLabel() {
  if (useDatabaseUrl()) return 'Supabase Postgres (DATABASE_URL)';
  if (useSupabaseApi()) return 'Supabase (API REST)';
  return 'SQLite (data/bugbounty.db)';
}

/** @returns {Promise<{ runId: number, intelMerge: object } | null>} */
export async function saveRun(payload) {
  if (useDatabaseUrl()) return pg.saveRun(payload);
  if (useSupabaseApi()) return supabase.saveRun(payload);
  return sqlite.saveRun(payload);
}

export async function listRuns(limit) {
  if (useDatabaseUrl()) return pg.listRuns(limit);
  if (useSupabaseApi()) return supabase.listRuns(limit);
  return sqlite.listRuns(limit);
}

export async function getRunById(id) {
  if (useDatabaseUrl()) return pg.getRunById(id);
  if (useSupabaseApi()) return supabase.getRunById(id);
  return sqlite.getRunById(id);
}

export async function listIntelForTarget(target, limit) {
  if (useDatabaseUrl()) return pg.listIntelForTarget(target, limit);
  if (useSupabaseApi()) return supabase.listIntelForTarget(target, limit);
  return sqlite.listIntelForTarget(target, limit);
}

export async function intelCountForTarget(target) {
  if (useDatabaseUrl()) return pg.intelCountForTarget(target);
  if (useSupabaseApi()) return supabase.intelCountForTarget(target);
  return sqlite.intelCountForTarget(target);
}

export async function listKnowledge(limit) {
  // Por enquanto: apenas SQLite (padrão). Em Supabase/PG voltamos vazio.
  if (useDatabaseUrl()) return [];
  if (useSupabaseApi()) return [];
  return sqlite.listKnowledge(limit);
}
