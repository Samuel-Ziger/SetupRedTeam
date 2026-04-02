import dns from 'node:dns/promises';

export async function resolves(host) {
  try {
    const r4 = await dns.resolve4(host).catch(() => []);
    if (r4.length) return { ok: true, records: r4.map((a) => `A:${a}`) };
  } catch {
    /* continue */
  }
  try {
    const r6 = await dns.resolve6(host).catch(() => []);
    if (r6.length) return { ok: true, records: r6.map((a) => `AAAA:${a}`) };
  } catch {
    /* continue */
  }
  return { ok: false, records: [] };
}
