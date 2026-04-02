const PARAM_RE = /[?&]([a-zA-Z_][a-zA-Z0-9_]{0,64})=/g;

export function extractParamsFromUrls(urls) {
  // name -> { count, sampleUrl }
  const map = new Map();
  for (const raw of urls) {
    let u;
    try {
      u = new URL(raw);
    } catch {
      continue;
    }
    u.searchParams.forEach((_, k) => {
      if (!map.has(k)) map.set(k, { count: 0, sampleUrl: raw });
      const cur = map.get(k);
      cur.count += 1;
      // keep first sampleUrl
    });
    let m;
    const s = u.search;
    while ((m = PARAM_RE.exec(s)) !== null) {
      const k = m[1];
      if (!map.has(k)) map.set(k, { count: 0, sampleUrl: raw });
      const cur = map.get(k);
      cur.count += 1;
    }
  }
  return [...map.entries()]
    .sort((a, b) => b[1].count - a[1].count)
    .map(([name, v]) => ({ name, count: v.count, sampleUrl: v.sampleUrl }));
}
