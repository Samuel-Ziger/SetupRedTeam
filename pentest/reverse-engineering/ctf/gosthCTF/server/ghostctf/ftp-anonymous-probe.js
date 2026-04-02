import net from 'node:net';

/**
 * Portas FTP prováveis a partir do XML do nmap (21 ou serviço com nome "ftp").
 */
export function ftpPortsFromNmap(nmapRows) {
  const ports = new Set();
  for (const r of nmapRows || []) {
    if (String(r.proto || 'tcp').toLowerCase() !== 'tcp') continue;
    const p = Number(r.port);
    if (!Number.isFinite(p)) continue;
    const blob = `${r.name || ''} ${r.product || ''} ${r.extrainfo || ''}`.toLowerCase();
    if (p === 21 || /\bftp\b/.test(blob)) ports.add(p);
  }
  return [...ports].sort((a, b) => a - b);
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Consome uma mensagem FTP completa do buffer (inclui continuações 220- ... 220 ).
 * @returns {{ code: number, lastLine: string, consumed: number } | null}
 */
function tryConsumeFtpMessage(buf) {
  if (!buf || !buf.length) return null;
  const firstCrlf = buf.indexOf('\r\n');
  if (firstCrlf < 0) return null;
  const line0 = buf.slice(0, firstCrlf);
  const m = line0.match(/^(\d{3})([- ])/) ;
  if (!m) return null;
  const code = m[1];
  const sep = m[2];
  if (sep === ' ') {
    return { code: Number(code), lastLine: line0, consumed: firstCrlf + 2 };
  }
  let pos = firstCrlf + 2;
  while (pos <= buf.length) {
    const next = buf.indexOf('\r\n', pos);
    if (next < 0) return null;
    const line = buf.slice(pos, next);
    pos = next + 2;
    if (line.startsWith(`${code} `)) {
      return { code: Number(code), lastLine: line, consumed: pos };
    }
  }
  return null;
}

async function nextFtpMessage(bufRef, sock, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const parsed = tryConsumeFtpMessage(bufRef.buf);
    if (parsed) {
      bufRef.buf = bufRef.buf.slice(parsed.consumed);
      return parsed;
    }
    if (sock.destroyed) throw new Error('socket closed');
    await delay(20);
  }
  throw new Error('resposta FTP timeout');
}

function sendCmd(sock, line) {
  sock.write(`${line}\r\n`, 'latin1');
}

function parsePasvEndpoint(line) {
  const m = String(line || '').match(/\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)/);
  if (!m) return null;
  const host = `${m[1]}.${m[2]}.${m[3]}.${m[4]}`;
  const p1 = Number(m[5]);
  const p2 = Number(m[6]);
  if (!Number.isFinite(p1) || !Number.isFinite(p2)) return null;
  return { host, port: p1 * 256 + p2 };
}

async function fetchFtpListPasv({ host, ctrlSock, ctrlBufRef, timeoutMs }) {
  sendCmd(ctrlSock, 'PASV');
  const pasv = await nextFtpMessage(ctrlBufRef, ctrlSock, timeoutMs);
  if (pasv.code !== 227) return { ok: false, reason: `PASV ${pasv.code}` };
  const ep = parsePasvEndpoint(pasv.lastLine);
  if (!ep) return { ok: false, reason: 'PASV sem endpoint' };

  const dataHost = ep.host === '0.0.0.0' ? host : ep.host;
  const dataSock = net.createConnection({ host: dataHost, port: ep.port });
  let dataBuf = '';
  await new Promise((resolve, reject) => {
    const t = setTimeout(() => {
      try {
        dataSock.destroy();
      } catch {
        /* */
      }
      reject(new Error('data connect timeout'));
    }, Math.min(timeoutMs, 10000));
    dataSock.once('connect', () => {
      clearTimeout(t);
      resolve();
    });
    dataSock.once('error', (e) => {
      clearTimeout(t);
      reject(e);
    });
  });

  dataSock.on('data', (chunk) => {
    dataBuf += chunk.toString('latin1');
  });

  sendCmd(ctrlSock, 'LIST -la');
  const pre = await nextFtpMessage(ctrlBufRef, ctrlSock, timeoutMs);
  if (![125, 150].includes(pre.code)) {
    try {
      dataSock.destroy();
    } catch {
      /* */
    }
    return { ok: false, reason: `LIST ${pre.code}` };
  }

  await new Promise((resolve) => {
    const t = setTimeout(() => {
      try {
        dataSock.destroy();
      } catch {
        /* */
      }
      resolve();
    }, Math.min(timeoutMs, 10000));
    dataSock.once('close', () => {
      clearTimeout(t);
      resolve();
    });
    dataSock.once('error', () => {
      clearTimeout(t);
      resolve();
    });
  });

  const post = await nextFtpMessage(ctrlBufRef, ctrlSock, timeoutMs);
  if (![226, 250].includes(post.code)) return { ok: false, reason: `LIST fim ${post.code}` };

  const lines = dataBuf
    .split(/\r?\n/)
    .map((x) => String(x || '').trim())
    .filter(Boolean)
    .slice(0, 10);

  return { ok: true, lines };
}

/**
 * Tenta USER anonymous + PASS anonymous@ (RFC 1630 estilo).
 * @returns {Promise<{ anonymousOk: boolean, code?: number, lastLine?: string, stages: string[], error?: string, listPreview?: string[] }>}
 */
export async function probeFtpAnonymous({ host, port = 21, timeoutMs = 12000 } = {}) {
  const stages = [];
  const bufRef = { buf: '' };

  return new Promise((resolve) => {
    const sock = net.createConnection({ host, port });

    const finish = (out) => {
      try {
        if (!sock.destroyed) {
          try {
            sendCmd(sock, 'QUIT');
          } catch {
            /* */
          }
        }
        sock.destroy();
      } catch {
        /* */
      }
      resolve(out);
    };

    let finished = false;
    const done = (out) => {
      if (finished) return;
      finished = true;
      finish(out);
    };

    const connTimer = setTimeout(() => {
      try {
        sock.destroy();
      } catch {
        /* */
      }
      done({ anonymousOk: false, stages, error: 'connect timeout', summary: 'timeout' });
    }, Math.min(timeoutMs, 15000));

    sock.once('connect', async () => {
      clearTimeout(connTimer);
      try {
        sock.on('data', (chunk) => {
          bufRef.buf += chunk.toString('latin1');
        });

        const banner = await nextFtpMessage(bufRef, sock, timeoutMs);
        stages.push(`banner ${banner.code}`);
        if (banner.code !== 220) {
          return done({
            anonymousOk: false,
            stages,
            code: banner.code,
            summary: `banner inesperado (${banner.code})`,
          });
        }

        sendCmd(sock, 'USER anonymous');
        const userRep = await nextFtpMessage(bufRef, sock, timeoutMs);
        stages.push(`USER ${userRep.code}`);
        if (userRep.code === 230) {
          return done({ anonymousOk: true, stages, code: 230, lastLine: userRep.lastLine, summary: '230 sem PASS' });
        }
        if (userRep.code !== 331 && userRep.code !== 332) {
          return done({
            anonymousOk: false,
            stages,
            code: userRep.code,
            summary: `USER recusado (${userRep.code})`,
          });
        }

        sendCmd(sock, 'PASS anonymous@');
        const passRep = await nextFtpMessage(bufRef, sock, timeoutMs);
        stages.push(`PASS ${passRep.code}`);
        if (passRep.code === 230) {
          let listPreview = [];
          try {
            const list = await fetchFtpListPasv({ host, ctrlSock: sock, ctrlBufRef: bufRef, timeoutMs: Math.min(timeoutMs, 10000) });
            if (list.ok && Array.isArray(list.lines)) {
              listPreview = list.lines;
              stages.push(`LIST ok (${list.lines.length})`);
            } else if (list.reason) {
              stages.push(`LIST skip (${list.reason})`);
            }
          } catch (e) {
            stages.push(`LIST erro (${e?.message || String(e)})`);
          }
          return done({
            anonymousOk: true,
            stages,
            code: 230,
            lastLine: passRep.lastLine,
            summary: '230 Login successful',
            listPreview,
          });
        }
        return done({
          anonymousOk: false,
          stages,
          code: passRep.code,
          lastLine: passRep.lastLine,
          summary: `anonymous negado (${passRep.code})`,
        });
      } catch (e) {
        done({
          anonymousOk: false,
          stages,
          error: e?.message || String(e),
          summary: e?.message || 'erro',
        });
      }
    });

    sock.once('error', (e) => {
      clearTimeout(connTimer);
      done({ anonymousOk: false, stages, error: e?.message || String(e), summary: 'erro de rede' });
    });
  });
}

export async function probeFtpCredentials({
  host,
  port = 21,
  username,
  password,
  timeoutMs = 12000,
} = {}) {
  const user = String(username || '').trim();
  const pass = String(password || '');
  if (!user) return { ok: false, summary: 'username vazio' };
  const stages = [];
  const bufRef = { buf: '' };

  return new Promise((resolve) => {
    const sock = net.createConnection({ host, port });
    let doneFlag = false;
    const done = (out) => {
      if (doneFlag) return;
      doneFlag = true;
      try {
        if (!sock.destroyed) {
          try {
            sendCmd(sock, 'QUIT');
          } catch {
            /* */
          }
          sock.destroy();
        }
      } catch {
        /* */
      }
      resolve(out);
    };

    const timer = setTimeout(() => {
      try {
        sock.destroy();
      } catch {
        /* */
      }
      done({ ok: false, summary: 'timeout', stages });
    }, Math.min(timeoutMs, 15000));

    sock.once('connect', async () => {
      clearTimeout(timer);
      try {
        sock.on('data', (chunk) => {
          bufRef.buf += chunk.toString('latin1');
        });
        const banner = await nextFtpMessage(bufRef, sock, timeoutMs);
        stages.push(`banner ${banner.code}`);
        if (banner.code !== 220) return done({ ok: false, summary: `banner ${banner.code}`, stages });
        sendCmd(sock, `USER ${user}`);
        const userRep = await nextFtpMessage(bufRef, sock, timeoutMs);
        stages.push(`USER ${userRep.code}`);
        if (userRep.code === 230) return done({ ok: true, summary: '230 sem PASS', stages });
        if (userRep.code !== 331 && userRep.code !== 332) return done({ ok: false, summary: `USER ${userRep.code}`, stages });
        sendCmd(sock, `PASS ${pass}`);
        const passRep = await nextFtpMessage(bufRef, sock, timeoutMs);
        stages.push(`PASS ${passRep.code}`);
        if (passRep.code === 230) return done({ ok: true, summary: '230 Login successful', stages });
        return done({ ok: false, summary: `PASS ${passRep.code}`, stages });
      } catch (e) {
        done({ ok: false, summary: e?.message || String(e), stages });
      }
    });

    sock.once('error', (e) => {
      clearTimeout(timer);
      done({ ok: false, summary: e?.message || String(e), stages });
    });
  });
}
