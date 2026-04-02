import { UA, limits } from '../config.js';

const ROTATING_UAS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15',
  'Mozilla/5.0 (X11; Linux x86_64; rv:124.0) Gecko/20100101 Firefox/124.0',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0',
];

/**
 * Stealth: módulo `stealth_requests` na UI ou GHOSTRECON_STEALTH=1
 */
export function stealthEnabled(modules) {
  if (Array.isArray(modules) && modules.includes('stealth_requests')) return true;
  const v = String(process.env.GHOSTRECON_STEALTH || '').trim().toLowerCase();
  return v === '1' || v === 'true' || v === 'yes';
}

export async function stealthPause(modules) {
  if (!stealthEnabled(modules)) return;
  const lo = Math.max(20, Number(limits.stealthJitterMinMs ?? 60));
  const hi = Math.max(lo, Number(limits.stealthJitterMaxMs ?? 420));
  const ms = lo + Math.random() * (hi - lo);
  await new Promise((r) => setTimeout(r, ms));
}

export function pickStealthUserAgent(modules) {
  if (!stealthEnabled(modules)) return UA;
  return ROTATING_UAS[Math.floor(Math.random() * ROTATING_UAS.length)];
}
