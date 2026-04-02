import test from 'node:test';
import assert from 'node:assert/strict';
import { resolveReconProfile } from '../modules/runtime-profile.js';

test('resolveReconProfile aplica fallback para standard', () => {
  assert.equal(resolveReconProfile('foo').name, 'standard');
  assert.equal(resolveReconProfile('').name, 'standard');
});

test('resolveReconProfile aceita quick/deep', () => {
  assert.equal(resolveReconProfile('quick').maxHostsToProbe > 0, true);
  assert.equal(resolveReconProfile('deep').includeCliArchives, true);
});
