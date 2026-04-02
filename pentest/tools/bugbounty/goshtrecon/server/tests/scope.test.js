import { describe, it } from 'node:test';
import assert from 'node:assert';
import {
  normalizeOutOfScopeToken,
  parseOutOfScopeClientInput,
  mergeOutOfScopeLists,
  hostInReconScope,
} from '../modules/scope.js';

describe('scope / fora de escopo', () => {
  it('normaliza URL para hostname', () => {
    assert.strictEqual(normalizeOutOfScopeToken('https://cdn.a.com/x'), 'cdn.a.com');
    assert.strictEqual(normalizeOutOfScopeToken('http://b.com:8080/'), 'b.com');
  });

  it('mantém wildcard *.', () => {
    assert.strictEqual(normalizeOutOfScopeToken('*.x.y.com'), '*.x.y.com');
  });

  it('parse textarea multilinha e vírgulas', () => {
    const r = parseOutOfScopeClientInput('a.com\nhttps://b.com/c, *.staging.z.com');
    assert.deepStrictEqual(r, ['a.com', 'b.com', '*.staging.z.com']);
  });

  it('merge deduplica', () => {
    assert.deepStrictEqual(mergeOutOfScopeLists(['a.com'], ['a.com', 'b.com']), ['a.com', 'b.com']);
  });

  it('hostInReconScope exclui lista UI', () => {
    assert.strictEqual(hostInReconScope('ok.target.com', 'target.com', ['bad.target.com']), true);
    assert.strictEqual(hostInReconScope('bad.target.com', 'target.com', ['bad.target.com']), false);
  });
});
