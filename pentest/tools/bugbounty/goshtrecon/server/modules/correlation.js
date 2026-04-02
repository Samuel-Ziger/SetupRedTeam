/**
 * Correlaciona hosts, endpoints e parâmetros para reduzir ruído.
 */
export function correlate({ subdomainsAlive, endpoints, params }) {
  const hostHits = new Map();
  for (const e of endpoints) {
    try {
      const h = new URL(e).hostname;
      hostHits.set(h, (hostHits.get(h) || 0) + 1);
    } catch {
      /* skip */
    }
  }
  const topHosts = [...hostHits.entries()].sort((a, b) => b[1] - a[1]).slice(0, 8);

  const paramSet = new Set(params.map((p) => p.name));
  const riskyParams = ['redirect', 'url', 'file', 'path', 'callback', 'token', 'id', 'admin'].filter((p) =>
    paramSet.has(p),
  );

  return {
    summary: `Hosts com mais endpoints: ${topHosts.map(([h, c]) => `${h}(${c})`).join(', ') || 'n/d'}`,
    riskyParams,
    subsWithEndpoints: subdomainsAlive.filter((s) => (hostHits.get(s) || 0) > 0),
  };
}
