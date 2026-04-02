import test from 'node:test';
import assert from 'node:assert/strict';
import { dedupeBySemanticFamily } from '../modules/semantic-dedupe.js';

test('dedupe semântico colapsa endpoints da mesma família', () => {
  const input = [
    { type: 'endpoint', value: 'https://a.example.com/api/user?id=1', score: 50, prio: 'med' },
    { type: 'endpoint', value: 'https://b.example.com/api/user?id=2', score: 70, prio: 'high' },
    { type: 'endpoint', value: 'https://c.example.com/api/user?ID=3', score: 65, prio: 'med' },
  ];
  const out = dedupeBySemanticFamily(input);
  assert.equal(out.findings.length, 1);
  assert.equal(out.merged, 2);
  assert.equal(out.findings[0].prio, 'high');
});
