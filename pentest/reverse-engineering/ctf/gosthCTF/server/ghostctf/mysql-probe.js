import net from 'node:net';

export function mysqlPortsFromNmap(nmapRows) {
  const ports = new Set();
  for (const r of nmapRows || []) {
    if (String(r.proto || '').toLowerCase() !== 'tcp') continue;
    const p = Number(r.port);
    if (!Number.isFinite(p)) continue;
    const blob = `${r.name || ''} ${r.product || ''} ${r.extrainfo || ''}`.toLowerCase();
    if (p === 3306 || /\b(mysql|mariadb)\b/.test(blob)) ports.add(p);
  }
  return [...ports].sort((a, b) => a - b);
}

function readCString(buf, start) {
  let i = start;
  while (i < buf.length && buf[i] !== 0x00) i += 1;
  if (i >= buf.length) return { text: '', next: start };
  return {
    text: buf.slice(start, i).toString('latin1'),
    next: i + 1,
  };
}

function parseMysqlHandshakePacket(payload) {
  if (!payload || payload.length < 6) return null;
  const protocolVersion = payload[0];
  if (protocolVersion !== 0x0a) return null;

  const v = readCString(payload, 1);
  const serverVersion = v.text || '';

  let off = v.next;
  if (off + 4 > payload.length) return { protocolVersion, serverVersion };
  const connectionId = payload.readUInt32LE(off);
  off += 4;

  if (off + 8 > payload.length) return { protocolVersion, serverVersion, connectionId };
  off += 8; // auth-plugin-data-part-1
  if (off + 1 > payload.length) return { protocolVersion, serverVersion, connectionId };
  off += 1; // filler

  if (off + 2 > payload.length) return { protocolVersion, serverVersion, connectionId };
  const capLow = payload.readUInt16LE(off);
  off += 2;

  if (off + 1 > payload.length) return { protocolVersion, serverVersion, connectionId, capabilityFlags: capLow };
  const characterSet = payload[off];
  off += 1;

  if (off + 2 > payload.length) return { protocolVersion, serverVersion, connectionId, capabilityFlags: capLow, characterSet };
  const statusFlags = payload.readUInt16LE(off);
  off += 2;

  let capabilityFlags = capLow;
  if (off + 2 <= payload.length) {
    const capHigh = payload.readUInt16LE(off);
    capabilityFlags |= capHigh << 16;
    off += 2;
  }

  return {
    protocolVersion,
    serverVersion,
    connectionId,
    characterSet,
    statusFlags,
    capabilityFlags: capabilityFlags >>> 0,
  };
}

export async function probeMysqlService({ host, port = 3306, timeoutMs = 12000 } = {}) {
  return await new Promise((resolve) => {
    const sock = net.createConnection({ host, port });
    let done = false;
    let buf = Buffer.alloc(0);

    const finish = (out) => {
      if (done) return;
      done = true;
      try {
        sock.destroy();
      } catch {
        /* */
      }
      resolve(out);
    };

    const timer = setTimeout(() => finish({ ok: false, error: 'connect timeout' }), Math.min(timeoutMs, 15000));

    sock.once('connect', () => {
      clearTimeout(timer);
    });

    sock.on('data', (chunk) => {
      buf = Buffer.concat([buf, chunk]);
      if (buf.length < 4) return;
      const len = buf.readUIntLE(0, 3);
      const total = 4 + len;
      if (buf.length < total) return;

      const payload = buf.slice(4, total);
      const hs = parseMysqlHandshakePacket(payload);
      if (!hs) {
        return finish({ ok: false, error: 'payload não reconhecido como handshake MySQL' });
      }
      return finish({ ok: true, ...hs });
    });

    sock.once('error', (e) => finish({ ok: false, error: e?.message || String(e) }));
    sock.once('close', () => {
      if (!done) finish({ ok: false, error: 'socket closed sem handshake' });
    });
  });
}
