import { getRunById } from './db.js';
import { fingerprintFinding, norm } from './db-common.js';

/**
 * Compara dois runs do mesmo alvo por fingerprint (igual ao corpus `bounty_intel`).
 * `removed` = achados no baseline cuja fingerprint não aparece no run mais recente.
 */
export async function compareRuns(baselineId, newerId) {
  const [a, b] = await Promise.all([getRunById(baselineId), getRunById(newerId)]);
  if (!a || !b) return { error: 'run não encontrado' };
  const ta = norm(a.target);
  const tb = norm(b.target);
  if (ta !== tb) {
    return {
      error: 'alvos diferentes',
      baselineTarget: a.target,
      newerTarget: b.target,
    };
  }

  const fp = (f) => fingerprintFinding(ta, f);
  const baseFps = new Set(a.findings.map(fp));
  const newerFps = new Set(b.findings.map(fp));

  const added = b.findings.filter((f) => !baseFps.has(fp(f)));
  const removed = a.findings.filter((f) => !newerFps.has(fp(f)));

  return {
    target: ta,
    baselineId: a.id,
    newerId: b.id,
    baselineCreatedAt: a.created_at,
    newerCreatedAt: b.created_at,
    addedCount: added.length,
    removedCount: removed.length,
    added,
    removed,
  };
}
