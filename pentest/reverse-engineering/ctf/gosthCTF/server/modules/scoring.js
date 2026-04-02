export function scoreEndpointPath(pathname) {
  const p = pathname || '';
  if (/\.(env|git|sql|bak|backup|old|db|log|pem|key)$/i.test(p)) return { score: 98, prio: 'high' };
  if (/(admin|phpmyadmin|actuator|debug|swagger|internal|\.git|\/v1\/|\/v2\/|graphql)/i.test(p)) return { score: 88, prio: 'high' };
  if (/(api\/v\d|export|reset|oauth|webhook|upload|download)/i.test(p)) return { score: 78, prio: 'med' };
  if (/(login|dashboard|portal|signin|oauth|callback)/i.test(p)) return { score: 62, prio: 'med' };
  return { score: 34, prio: 'low' };
}

export function scoreParamName(name) {
  const critical = [
    'redirect',
    'url',
    'file',
    'path',
    'callback',
    'next',
    'return_url',
    'dest',
    'target',
    'continue',
    'goto',
  ];
  const high = [
    'token',
    'access_token',
    'id_token',
    'refresh_token',
    'api_key',
    'apikey',
    'key',
    'secret',
    'password',
    'auth',
    'authorization',
    'jwt',
    'session',
    'admin',
    'role',
    'id',
    'user_id',
    'uid',
    'email',
    'query',
    'q',
    'search',
  ];
  const n = String(name).toLowerCase();
  if (critical.includes(n)) return { score: 94, prio: 'high' };
  if (high.includes(n)) return { score: 82, prio: 'high' };
  return { score: 40, prio: 'low' };
}

export function buildFinding(type, value, extra = {}) {
  return { type, value, ...extra };
}
