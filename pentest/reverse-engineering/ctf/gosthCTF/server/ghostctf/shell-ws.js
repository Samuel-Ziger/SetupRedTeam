import { spawn } from 'node:child_process';
import { WebSocketServer } from 'ws';
import { runCtfShellAutoExplore } from './shell-auto-explore.js';

/** Se `1`, aceita WebSocket shell de qualquer IP (ex.: UI atrás de ngrok). Risco: expõe injeção de comandos no teu nc. */
const SHELL_WS_ANY = process.env.GHOSTCTF_SHELL_WS_ANY === '1';

function isLocalhostSocket(req) {
  const a = String(req.socket?.remoteAddress || '');
  return (
    a === '127.0.0.1' ||
    a === '::1' ||
    a === '::ffff:127.0.0.1' ||
    a.endsWith('127.0.0.1')
  );
}

function allowShellUpgrade(req) {
  if (SHELL_WS_ANY) return true;
  return isLocalhostSocket(req);
}

if (SHELL_WS_ANY) {
  console.warn(
    '[GHOSTCTF] GHOSTCTF_SHELL_WS_ANY=1 — WebSocket /shell-ws aceita ligações não-locais (UI via ngrok, etc.). Usa só em ambiente confiável.',
  );
}

/**
 * WebSocket em /api/ghostctf/shell-ws — por defeito só localhost; com GHOSTCTF_SHELL_WS_ANY=1 aceita outras origens.
 * Mensagens JSON: { type:'start', port:number } | { type:'stdin', data:string } | { type:'stop' }
 * | { type:'autoExplore' } | { type:'autoExploreAbort' }
 * Respostas: { type:'started', port, cmd } | { type:'stdout'|'stderr', data } | { type:'exit', code } | { type:'error', message }
 *
 * Corre `nc -nlvp <port>` no host onde o Node está (o teu Kali). Quando a reverse shell
 * liga, o stdin/stdout deste processo passa a ser a shell remota.
 */
export function attachShellWebSocket(httpServer) {
  const wss = new WebSocketServer({ noServer: true });

  httpServer.on('upgrade', (request, socket, head) => {
    const url = String(request.url || '').split('?')[0];
    if (!url.startsWith('/api/ghostctf/shell-ws')) return;
    if (!allowShellUpgrade(request)) {
      socket.destroy();
      return;
    }
    wss.handleUpgrade(request, socket, head, (ws) => {
      handleShellConnection(ws);
    });
  });
}

function handleShellConnection(ws) {
  /** @type {import('node:child_process').ChildProcess | null} */
  let child = null;
  /** @type {{ running: boolean, aborted: boolean }} */
  let exploreState = { running: false, aborted: false };
  /** Acumulado durante enum automático para heurísticas (stdout+stderr do nc). */
  let exploreStdoutBuf = '';
  const EXPLORE_BUF_MAX = 480_000;

  const send = (obj) => {
    if (ws.readyState === 1) {
      try {
        ws.send(JSON.stringify(obj));
      } catch {
        /* ignore */
      }
    }
  };

  const cleanup = () => {
    exploreState.aborted = true;
    if (child) {
      try {
        child.kill('SIGTERM');
      } catch {
        /* ignore */
      }
      child = null;
    }
  };

  const pushExploreBuf = (chunk) => {
    if (!exploreState.running) return;
    exploreStdoutBuf += chunk;
    if (exploreStdoutBuf.length > EXPLORE_BUF_MAX) {
      exploreStdoutBuf = exploreStdoutBuf.slice(-EXPLORE_BUF_MAX);
    }
  };

  const attachStreams = (c) => {
    c.stdout?.on('data', (d) => {
      const text = d.toString('utf8');
      pushExploreBuf(text);
      send({ type: 'stdout', data: text });
    });
    c.stderr?.on('data', (d) => {
      const text = d.toString('utf8');
      pushExploreBuf(text);
      send({ type: 'stderr', data: text });
    });
    c.on('close', (code, signal) => {
      send({ type: 'exit', code: code ?? -1, signal: signal || null });
      child = null;
    });
  };

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return;
    }
    if (msg.type === 'start') {
      if (child) {
        send({ type: 'error', message: 'Já existe um listener ativo. Clica em Parar primeiro.' });
        return;
      }
      const port = Number(msg.port);
      if (!Number.isInteger(port) || port < 1 || port > 65535) {
        send({ type: 'error', message: 'Porta inválida (1–65535).' });
        return;
      }
      const args = ['-nlvp', String(port)];
      const c = spawn('nc', args, { stdio: ['pipe', 'pipe', 'pipe'] });
      let settled = false;
      const finish = (bin, proc) => {
        if (settled) return;
        settled = true;
        child = proc;
        attachStreams(proc);
        send({ type: 'started', port, cmd: `${bin} ${args.join(' ')}` });
      };
      c.once('error', (err) => {
        if (settled) return;
        if (err && err.code === 'ENOENT') {
          const c2 = spawn('ncat', args, { stdio: ['pipe', 'pipe', 'pipe'] });
          c2.once('error', (e2) => {
            if (settled) return;
            settled = true;
            send({
              type: 'error',
              message:
                e2?.code === 'ENOENT'
                  ? 'Comando nc/ncat não encontrado no PATH (instala netcat).'
                  : e2?.message || String(e2),
            });
          });
          c2.once('spawn', () => finish('ncat', c2));
        } else {
          settled = true;
          send({ type: 'error', message: err?.message || String(err) });
        }
      });
      c.once('spawn', () => finish('nc', c));
    } else if (msg.type === 'stdin') {
      if (!child?.stdin) {
        send({ type: 'error', message: 'Sem processo ativo. Inicia o listener primeiro.' });
        return;
      }
      const data = typeof msg.data === 'string' ? msg.data : '';
      try {
        child.stdin.write(data);
      } catch (e) {
        send({ type: 'error', message: e?.message || String(e) });
      }
    } else if (msg.type === 'stop') {
      exploreState.aborted = true;
      cleanup();
      send({ type: 'stopped' });
    } else if (msg.type === 'autoExplore') {
      if (!child?.stdin) {
        send({ type: 'error', message: 'Sem listener nc ativo. Inicia o nc primeiro.' });
        return;
      }
      if (exploreState.running) {
        send({ type: 'error', message: 'Exploração automática já a correr.' });
        return;
      }
      exploreState.running = true;
      exploreState.aborted = false;
      exploreStdoutBuf = '';
      runCtfShellAutoExplore({
        write: (s) => {
          if (!child?.stdin) throw new Error('Processo nc terminou.');
          child.stdin.write(s);
        },
        send,
        isAborted: () => exploreState.aborted,
        getBuffer: () => exploreStdoutBuf,
      }).catch((e) => {
        send({ type: 'autoExplore', phase: 'error', message: e?.message || String(e) });
      }).finally(() => {
        exploreState.running = false;
      });
    } else if (msg.type === 'autoExploreAbort') {
      exploreState.aborted = true;
    }
  });

  ws.on('close', cleanup);
  ws.on('error', cleanup);
}
