import tls from 'tls';

/**
 * Certificado TLS do servidor (rejectUnauthorized: false — só recon, não valida cadeia).
 * @param {string} hostname
 * @param {number} port
 * @param {number} timeoutMs
 */
export function peekTlsCertificate(hostname, port = 443, timeoutMs = 8000) {
  return new Promise((resolve) => {
    const socket = tls.connect({
      host: hostname,
      port,
      servername: hostname,
      rejectUnauthorized: false,
    });

    const finish = (payload) => {
      try {
        socket.destroy();
      } catch {
        /* ignore */
      }
      resolve(payload);
    };

    const timer = setTimeout(() => finish({ ok: false, error: 'timeout' }), timeoutMs);

    socket.once('secureConnect', () => {
      clearTimeout(timer);
      try {
        const cert = socket.getPeerCertificate(true);
        if (!cert || Object.keys(cert).length === 0) {
          finish({ ok: false, error: 'sem certificado' });
          return;
        }
        const san = cert.subjectaltname || '';
        const daysLeft = cert.valid_to ? (new Date(cert.valid_to) - Date.now()) / 86400000 : null;
        finish({
          ok: true,
          subject: cert.subject?.CN || cert.subject?.O || JSON.stringify(cert.subject || {}),
          issuer: cert.issuer?.O || cert.issuer?.CN || '',
          validFrom: cert.valid_from,
          validTo: cert.valid_to,
          daysLeft: daysLeft != null && Number.isFinite(daysLeft) ? Math.round(daysLeft * 10) / 10 : null,
          subjectAltName: san.length > 500 ? `${san.slice(0, 500)}…` : san,
        });
      } catch (e) {
        finish({ ok: false, error: e?.message || String(e) });
      }
    });

    socket.once('error', (e) => {
      clearTimeout(timer);
      finish({ ok: false, error: e?.message || String(e) });
    });
  });
}
