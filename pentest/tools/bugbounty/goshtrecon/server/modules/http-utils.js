export async function fetchWithBackoff(url, options = {}, cfg = {}) {
  const retries = Math.max(0, Number(cfg.retries ?? 2));
  const baseDelayMs = Math.max(100, Number(cfg.baseDelayMs ?? 450));
  let lastErr = null;
  for (let i = 0; i <= retries; i++) {
    try {
      const res = await fetch(url, options);
      if (res.status === 429 || (res.status >= 500 && i < retries)) {
        await new Promise((r) => setTimeout(r, baseDelayMs * (i + 1)));
        continue;
      }
      return res;
    } catch (e) {
      lastErr = e;
      if (i < retries) {
        await new Promise((r) => setTimeout(r, baseDelayMs * (i + 1)));
      }
    }
  }
  throw lastErr || new Error('fetchWithBackoff failed');
}
