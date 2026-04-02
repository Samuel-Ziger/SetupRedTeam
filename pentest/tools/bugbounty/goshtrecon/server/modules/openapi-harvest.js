import { limits } from '../config.js';
import { urlInReconScope } from './scope.js';
import { stealthPause, pickStealthUserAgent } from './request-policy.js';

const SPEC_PATHS = [
  '/openapi.json',
  '/swagger.json',
  '/v2/api-docs',
  '/v3/api-docs',
  '/api-docs/swagger.json',
  '/swagger/v1/swagger.json',
];

function collectParamsFromOpenApi3(doc) {
  const names = new Set();
  const paths = doc?.paths && typeof doc.paths === 'object' ? doc.paths : {};
  for (const [, methods] of Object.entries(paths)) {
    if (!methods || typeof methods !== 'object') continue;
    for (const def of Object.values(methods)) {
      if (!def || typeof def !== 'object') continue;
      const params = def.parameters;
      if (!Array.isArray(params)) continue;
      for (const p of params) {
        const n = p?.name;
        if (typeof n === 'string' && n.length < 120) names.add(n);
      }
    }
  }
  return [...names];
}

function collectParamsFromSwagger2(doc) {
  const names = new Set();
  const paths = doc?.paths && typeof doc.paths === 'object' ? doc.paths : {};
  for (const [, methods] of Object.entries(paths)) {
    if (!methods || typeof methods !== 'object') continue;
    for (const def of Object.values(methods)) {
      if (!def || typeof def !== 'object') continue;
      const params = def.parameters;
      if (!Array.isArray(params)) continue;
      for (const p of params) {
        const n = p?.name;
        if (typeof n === 'string' && n.length < 120) names.add(n);
      }
    }
  }
  return [...names];
}

/**
 * @returns {{ type:'endpoint'|'param', value, meta, url?, prio, score }[]}
 */
export async function harvestOpenApiFromOrigins(origins, domain, outOfScopeList, modules, log) {
  const out = [];
  const cap = Math.max(1, Number(limits.openapiMaxOrigins ?? 10));
  const list = [...new Set(origins.map((o) => String(o).replace(/\/$/, '')))].slice(0, cap);
  const ua = pickStealthUserAgent(modules);
  const timeoutMs = Math.min(14000, limits.probeTimeoutMs || 12000);

  for (const base of list) {
    for (const sp of SPEC_PATHS) {
      await stealthPause(modules);
      let u;
      try {
        u = new URL(sp, base + '/');
      } catch {
        continue;
      }
      if (!urlInReconScope(u.href, domain, outOfScopeList)) continue;
      try {
        const res = await fetch(u.href, {
          method: 'GET',
          redirect: 'follow',
          signal: AbortSignal.timeout(timeoutMs),
          headers: {
            Accept: 'application/json,*/*;q=0.8',
            'User-Agent': ua,
          },
        });
        if (!res.ok) continue;
        const ct = (res.headers.get('content-type') || '').toLowerCase();
        if (!ct.includes('json') && !ct.includes('text')) continue;
        const text = await res.text();
        if (text.length > 2_000_000) continue;
        let doc;
        try {
          doc = JSON.parse(text);
        } catch {
          continue;
        }
        const isOas3 = doc.openapi && String(doc.openapi).startsWith('3');
        const paramNames = isOas3 ? collectParamsFromOpenApi3(doc) : collectParamsFromSwagger2(doc);
        if (!paramNames.length && !doc.paths) continue;

        out.push({
          type: 'endpoint',
          prio: 'med',
          score: 64,
          value: u.href,
          meta: `OpenAPI/Swagger leak • ${isOas3 ? 'OAS3' : 'Swagger2'} • params=${paramNames.length}`,
          url: u.href,
        });
        for (const name of paramNames.slice(0, 40)) {
          out.push({
            type: 'param',
            prio: 'med',
            score: 66,
            value: `?${name}=`,
            meta: `openapi_spec • source=${u.pathname}`,
            url: u.href,
          });
        }
        if (typeof log === 'function') {
          log(`OpenAPI: ${u.href} → ${paramNames.length} parâmetro(s) em spec`, 'success');
        }
        break;
      } catch {
        /* next path */
      }
    }
  }

  return out;
}

const GQL_INTRO = JSON.stringify({
  query: 'query IntrospectionQuery { __schema { queryType { name } } }',
});

/**
 * Um POST de introspecção mínima em /graphql (só se já existir pista no corpus).
 */
export async function tryGraphqlMinimalProbe(graphqlUrls, domain, outOfScopeList, modules, log) {
  const ua = pickStealthUserAgent(modules);
  const timeoutMs = Math.min(12000, limits.probeTimeoutMs || 12000);
  const seen = new Set();
  for (const raw of graphqlUrls.slice(0, 4)) {
    let u;
    try {
      u = new URL(raw);
    } catch {
      continue;
    }
    if (!urlInReconScope(u.href, domain, outOfScopeList)) continue;
    const key = u.origin + u.pathname;
    if (seen.has(key)) continue;
    seen.add(key);
    await stealthPause(modules);
    try {
      const res = await fetch(u.href, {
        method: 'POST',
        redirect: 'manual',
        signal: AbortSignal.timeout(timeoutMs),
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'User-Agent': ua,
        },
        body: GQL_INTRO,
      });
      const text = await res.text();
      let j;
      try {
        j = JSON.parse(text);
      } catch {
        continue;
      }
      if (j?.data?.__schema?.queryType?.name || j?.errors?.length) {
        if (typeof log === 'function') {
          log(`GraphQL: resposta a introspecção mínima @ ${u.href} (analisar manualmente)`, j.errors ? 'warn' : 'success');
        }
        return [
          {
            type: 'intel',
            prio: j.errors ? 'med' : 'high',
            score: j.errors ? 62 : 74,
            value: `GraphQL introspection reachable @ ${u.pathname}`,
            meta: `graphql_probe • status=${res.status} • errors=${j.errors ? 'yes' : 'no'}`,
            url: u.href,
          },
        ];
      }
    } catch {
      /* ignore */
    }
  }
  return [];
}
