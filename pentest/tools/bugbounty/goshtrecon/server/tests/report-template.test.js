import test from 'node:test';
import assert from 'node:assert/strict';
import { buildReportTemplates } from '../modules/report-template.js';

test('gera template para finding verificado', () => {
  const templates = buildReportTemplates(
    [
      {
        type: 'xss',
        value: 'Verify XSS CONFIRMED @ /search ?q=',
        verification: {
          classification: 'confirmed',
          evidence: {
            url: 'https://example.com/search?q=payload',
            method: 'GET',
            status: 200,
            requestSnippet: '/search?q=payload',
            responseSnippet: '...payload...',
            source: 'verify-xss',
            timestamp: '2026-01-01T00:00:00.000Z',
          },
        },
      },
    ],
    'example.com',
  );
  assert.equal(templates.length, 1);
  assert.match(templates[0].title, /XSS/i);
  assert.match(templates[0].suggestedFix, /encoding|CSP/i);
});
