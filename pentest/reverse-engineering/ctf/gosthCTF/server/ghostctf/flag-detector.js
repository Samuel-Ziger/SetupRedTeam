import { getPlatform } from './platforms.js';

function safeToString(v) {
  return v == null ? '' : String(v);
}

export function extractRawFlagsByPlatform(text, platformId) {
  const platform = getPlatform(platformId);
  if (!platform) return [];
  const t = safeToString(text);
  const re = new RegExp(platform.flagRegex.source, platform.flagRegex.flags);
  const out = [];
  let m;
  while ((m = re.exec(t)) !== null) {
    const flag = m[0];
    if (platform.validateFlag(flag)) out.push(flag);
    if (out.length >= 25) break;
  }
  return [...new Set(out)];
}

function decodeBase64Maybe(s) {
  // Aceita base64 normal e base64url.
  let x = safeToString(s).trim();
  if (!x) return null;
  x = x.replace(/-/g, '+').replace(/_/g, '/');

  // padding (base64 exige múltiplos de 4)
  const mod = x.length % 4;
  if (mod === 2) x += '==';
  else if (mod === 3) x += '=';
  else if (mod === 1) return null;

  try {
    const buf = Buffer.from(x, 'base64');
    // filtro anti-lixo: precisamos que a string decodificada pareça texto.
    const decoded = buf.toString('utf8');
    if (!decoded || decoded.length < 4) return null;
    return decoded;
  } catch {
    return null;
  }
}

function decodeBase32Maybe(s) {
  // Implementação simples (base32 RFC4648, alfabet: A-Z2-7).
  // Retorna string utf-8 se possível, senão null.
  let x = safeToString(s).trim().replace(/=+$/g, '');
  if (!x) return null;
  x = x.toUpperCase();
  if (!/^[A-Z2-7]+$/.test(x)) return null;

  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  for (const ch of x) {
    const idx = alphabet.indexOf(ch);
    if (idx < 0) return null;
    bits += idx.toString(2).padStart(5, '0');
  }

  let out = '';
  for (let i = 0; i + 8 <= bits.length; i += 8) {
    const byte = bits.slice(i, i + 8);
    out += String.fromCharCode(parseInt(byte, 2));
  }

  if (!out || out.length < 4) return null;
  try {
    // tenta re-interpretar como UTF-8 (já é string JS; melhor esforço)
    return decodeURIComponent(escape(out));
  } catch {
    return out;
  }
}

function findBase64LikeStrings(text, limit = 30) {
  const t = safeToString(text);
  // Heurística: base64 com tamanho mínimo e caracteres típicos.
  const re = /(?:[A-Za-z0-9+/_]{16,}={0,2})/g;
  const out = [];
  let m;
  while ((m = re.exec(t)) !== null) {
    const s = m[0];
    // evita capturar aleatório muito curto
    if (s.length < 16) continue;
    out.push(s);
    if (out.length >= limit) break;
  }
  return out;
}

function findBase32LikeStrings(text, limit = 30) {
  const t = safeToString(text);
  const re = /(?:[A-Z2-7]{16,}={0,6})/g;
  const out = [];
  let m;
  while ((m = re.exec(t)) !== null) {
    const s = m[0];
    if (s.length < 16) continue;
    out.push(s);
    if (out.length >= limit) break;
  }
  return out;
}

export function detectFlagsWithDecoding({ rawText, platformId }) {
  const direct = extractRawFlagsByPlatform(rawText, platformId);
  const decodedFlags = [];

  // Base64 decode (muito comum no seu histórico Solyd)
  const base64s = findBase64LikeStrings(rawText, 40);
  for (const s of base64s) {
    const decoded = decodeBase64Maybe(s);
    if (!decoded) continue;
    const hits = extractRawFlagsByPlatform(decoded, platformId);
    for (const h of hits) {
      decodedFlags.push({
        flag: h,
        evidence: 'base64',
        decodedFrom: s,
      });
    }
  }

  // Base32 decode (caso apareça em challenges)
  const base32s = findBase32LikeStrings(rawText, 40);
  for (const s of base32s) {
    const decoded = decodeBase32Maybe(s);
    if (!decoded) continue;
    const hits = extractRawFlagsByPlatform(decoded, platformId);
    for (const h of hits) {
      decodedFlags.push({
        flag: h,
        evidence: 'base32',
        decodedFrom: s,
      });
    }
  }

  const seen = new Set();
  const all = [];
  for (const f of direct) {
    if (seen.has(f)) continue;
    seen.add(f);
    all.push({ flag: f, evidence: 'direct' });
  }
  for (const x of decodedFlags) {
    if (seen.has(x.flag)) continue;
    seen.add(x.flag);
    all.push(x);
  }
  return all.slice(0, 25);
}

