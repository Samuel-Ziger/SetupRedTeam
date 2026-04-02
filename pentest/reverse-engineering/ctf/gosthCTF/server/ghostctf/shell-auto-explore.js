const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * Comandos extra com base no output acumulado (stdout+stderr) desde o início do enum.
 * Só corre após alguns passos fixos para não explodir ruído.
 * @param {number} stepIndex Índice (0-based) do passo fixo que acabou de terminar.
 * @param {string} buf Buffer acumulado.
 */
export function getReactiveFollowups(stepIndex, buf) {
  const b = String(buf || '');
  const out = [];
  const idxOk = [3, 4, 6, 8, 9];
  if (!idxOk.includes(stepIndex)) return out;

  if (stepIndex === 3) {
    if (/\b(flag|proof|secret|\.txt)\b/i.test(b)) {
      out.push({
        label: '↳ Heurística: ficheiros txt/flag no cwd',
        cmd:
          'for f in *.txt .flag* .flag flag.txt proof.txt user.txt 2>/dev/null; do ' +
          '[ -f "$f" ] && echo "=== $f ===" && cat "$f" 2>/dev/null; done; ls -la . 2>/dev/null\n',
        wait: 2800,
      });
    }
  }

  if (stepIndex === 4) {
    if (/\/var\/www|\/html\b|nginx|apache|httpd/i.test(b)) {
      out.push({
        label: '↳ Heurística: aprofundar web root',
        cmd:
          'ls -la /var/www/html 2>/dev/null; ls -la /var/www 2>/dev/null; ' +
          'find /var/www -maxdepth 4 -type f 2>/dev/null | head -50\n',
        wait: 3200,
      });
    }
    if (/\/home\/[a-zA-Z0-9._-]+/i.test(b)) {
      out.push({
        label: '↳ Heurística: listar /home/*',
        cmd: 'for d in /home/*; do [ -d "$d" ] && echo "=== $d ===" && ls -la "$d" 2>/dev/null; done 2>/dev/null | head -150\n',
        wait: 2800,
      });
    }
  }

  if (stepIndex === 6) {
    if (/root:\$[0-9$./a-z]+/i.test(b) || /^root:\$/m.test(b)) {
      out.push({
        label: '↳ Heurística: hash root em shadow',
        cmd: 'grep -E "^root:" /etc/shadow 2>/dev/null; grep -E "^[^:]+:" /etc/passwd 2>/dev/null | head -15\n',
        wait: 1800,
      });
    }
  }

  if (stepIndex === 8) {
    const seen = new Set();
    const paths = [];
    const re = /(\/[^\s"'`]+flag[^\s"'`]*)/gi;
    let m;
    while ((m = re.exec(b)) !== null) {
      const p = m[1].replace(/:$/, '');
      if (p.length > 1 && p.length < 400 && !seen.has(p)) {
        seen.add(p);
        paths.push(p);
      }
      if (paths.length >= 12) break;
    }
    if (paths.length) {
      const parts = paths.map((p) => `echo "=== ${p} ==="; cat "${p}" 2>/dev/null;`);
      out.push({
        label: '↳ Heurística: cat paths com "flag" (do find/output)',
        cmd: `${parts.join(' ')}\n`,
        wait: 4500,
      });
    }
  }

  if (stepIndex === 9 && /Solyd\{/.test(b)) {
    out.push({
      label: '↳ Heurística: texto Solyd{ já apareceu no buffer',
      cmd: 'echo "[ghostctf] possível flag no output acima — rever scroll"\n',
      wait: 500,
    });
  }

  return out;
}

/**
 * Sequência curta de enumeração pós-shell para CTF (bash/sh).
 * Pausas fixas + heurísticas reativas no output acumulado.
 */
export async function runCtfShellAutoExplore({ write, send, isAborted, getBuffer = () => '' }) {
  const steps = [
    {
      label: 'Estabilizar: script (PTY)',
      cmd: 'script -qc /bin/bash /dev/null\n',
      wait: 2800,
    },
    {
      label: 'Estabilizar: TERM=xterm',
      cmd: 'export TERM=xterm\n',
      wait: 900,
    },
    {
      label: 'Estabilizar: python3 pty.spawn(bash)',
      cmd: 'python3 -c \'import pty; pty.spawn("/bin/bash")\'\n',
      wait: 3500,
    },
    {
      label: 'Raiz: pwd + ls -la',
      cmd: 'cd / 2>/dev/null; pwd; ls -la\n',
      wait: 2200,
    },
    {
      label: 'Dirs comuns: /home, /root, /var/www',
      cmd: 'ls -la /home 2>/dev/null; echo "---"; ls -la /root 2>/dev/null; echo "---"; ls -la /var/www 2>/dev/null\n',
      wait: 2400,
    },
    {
      label: 'Ficheiros flag / user / proof (cat se legível)',
      cmd:
        'for p in /flag /flag.txt /root/flag.txt ./flag.txt .flag.txt flag.txt user.txt proof.txt; do ' +
        'test -r "$p" 2>/dev/null && echo "=== $p ===" && cat "$p" 2>/dev/null && echo; done\n',
      wait: 2600,
    },
    {
      label: 'passwd + shadow (head)',
      cmd:
        'head -60 /etc/passwd 2>/dev/null; echo "--- shadow ---"; head -3 /etc/shadow 2>/dev/null || echo "(shadow: sem permissão ou não existe)"\n',
      wait: 2200,
    },
    {
      label: 'id / whoami / uname',
      cmd: 'id; whoami; uname -a 2>/dev/null\n',
      wait: 1800,
    },
    {
      label: 'Procura rápida *flag* (até depth 4)',
      cmd: 'find / -maxdepth 4 -iname "*flag*" 2>/dev/null | head -35\n',
      wait: 3500,
    },
    {
      label: 'Grep padrão Solyd{ no cwd (se existir)',
      cmd: 'grep -r "Solyd{" . 2>/dev/null | head -25\n',
      wait: 2800,
    },
  ];

  send({
    type: 'autoExplore',
    phase: 'start',
    message: 'Início: PTY + enum fixo + heurísticas no output (reactivo)',
    total: steps.length,
  });

  for (let i = 0; i < steps.length; i++) {
    if (isAborted()) {
      send({ type: 'autoExplore', phase: 'aborted', message: 'Cancelado.' });
      return;
    }
    const s = steps[i];
    send({
      type: 'autoExplore',
      phase: 'step',
      index: i + 1,
      total: steps.length,
      label: s.label,
    });
    try {
      write(s.cmd);
    } catch (e) {
      send({ type: 'autoExplore', phase: 'error', message: e?.message || String(e) });
      return;
    }
    await sleep(s.wait);

    const buf = typeof getBuffer === 'function' ? getBuffer() : '';
    const extras = getReactiveFollowups(i, buf);
    for (const ex of extras) {
      if (isAborted()) {
        send({ type: 'autoExplore', phase: 'aborted', message: 'Cancelado.' });
        return;
      }
      send({
        type: 'autoExplore',
        phase: 'reactive',
        index: i + 1,
        total: steps.length,
        label: ex.label,
      });
      try {
        write(ex.cmd);
      } catch (e) {
        send({ type: 'autoExplore', phase: 'error', message: e?.message || String(e) });
        return;
      }
      await sleep(ex.wait ?? 2200);
    }
  }

  if (!isAborted()) {
    send({ type: 'autoExplore', phase: 'done', message: 'Sequência automática concluída. Rever saída acima.' });
  }
}
