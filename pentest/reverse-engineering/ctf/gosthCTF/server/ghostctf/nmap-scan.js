import fs from 'fs';
import { readFile, mkdtemp, rm } from 'fs/promises';
import { join } from 'path';
import { tmpdir } from 'os';
import { spawn } from 'node:child_process';
import { parseNmapXml } from '../modules/kali-scan.js';

function safeIps(ip) {
  const t = String(ip || '').trim();
  if (!t) return [];
  return [t];
}

function whichCmd(cmd) {
  return new Promise((resolve) => {
    const finder = process.platform === 'win32' ? 'where' : 'which';
    const p = spawn(finder, [cmd], { stdio: ['ignore', 'pipe', 'pipe'] });
    p.on('error', () => resolve(false));
    p.on('close', (c) => resolve(c === 0));
  });
}

async function ensureNmap() {
  return await whichCmd('nmap');
}

function buildNmapArgs({ ip, tcpAllPorts, udpScan }) {
  // Importante: nmap com UDP é caro; usamos top-ports quando tcpAllPorts está OFF.
  // Sem -T3/-T4 explícito: usa template por defeito do nmap (menos agressivo, menos risco de falsos negativos).
  const common = ['-sV', '-Pn', '--reason', '--open', '--max-retries', '1'];

  // Port selection
  let portArgs = [];
  if (tcpAllPorts) {
    portArgs = ['-p-'];
  } else {
    // padrão mais conservador (rápido o suficiente pra MVP)
    portArgs = ['--top-ports', '500'];
  }

  const protoArgs = [];
  if (udpScan) protoArgs.push('-sU');

  // nmapXML
  return [...common, ...protoArgs, ...portArgs, ip];
}

async function runNmapToXml({ ip, tcpAllPorts, udpScan, timeoutMs = 660000 }) {
  const ready = await ensureNmap();
  if (!ready) {
    throw new Error('nmap não encontrado no PATH (ou não suportado no ambiente).');
  }

  const dir = await mkdtemp(join(tmpdir(), 'ghnmap-'));
  const xmlPath = join(dir, 'nmap.xml');
  const args = [...buildNmapArgs({ ip, tcpAllPorts, udpScan }), '-oX', xmlPath];

  // Observação: o nmap aceita args fora de ordem, mas mantemos terminal.
  const proc = await new Promise((resolve, reject) => {
    const child = spawn('nmap', args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const chunks = [];
    const errChunks = [];
    let killed = false;
    const t = setTimeout(() => {
      killed = true;
      try {
        child.kill('SIGKILL');
      } catch {
        // ignore
      }
      reject(new Error(`nmap timeout (${timeoutMs}ms)`));
    }, timeoutMs);
    child.stdout.on('data', (d) => chunks.push(d));
    child.stderr.on('data', (d) => errChunks.push(d));
    child.on('error', (e) => {
      clearTimeout(t);
      reject(e);
    });
    child.on('close', (code) => {
      clearTimeout(t);
      if (killed) return;
      if (code !== 0) {
        // ainda assim pode ter gerado xml; tentamos ler depois
      }
      resolve({ code, stdout: Buffer.concat(chunks).toString('utf8'), stderr: Buffer.concat(errChunks).toString('utf8') });
    });
  });

  try {
    const xml = await readFile(xmlPath, 'utf8');
    return xml;
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

export async function scanIpPorts({ ip, tcpAllPorts = false, udpScan = false, log }) {
  const ips = safeIps(ip);
  if (!ips.length) throw new Error('IP vazio.');
  const target = ips[0];

  if (typeof log === 'function') {
    log(`nmap scan IP: ${target} (tcpAllPorts=${tcpAllPorts}, udpScan=${udpScan})`, 'info');
  }

  const xml = await runNmapToXml({ ip: target, tcpAllPorts, udpScan });
  const rows = parseNmapXml(xml);

  // Normaliza: port e proto vêm como string; vamos manter string.
  return rows;
}

