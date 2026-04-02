/**
 * Notificação opcional pós-recon (Slack/Discord/custom).
 */
export async function postReconWebhook(webhookUrl, payload) {
  const u = String(webhookUrl || '').trim();
  if (!u) return;
  try {
    await fetch(u, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        source: 'ghostrecon',
        ...payload,
      }),
      signal: AbortSignal.timeout(15000),
    });
  } catch (e) {
    console.warn('[GHOSTRECON webhook]', e?.message || e);
  }
}
