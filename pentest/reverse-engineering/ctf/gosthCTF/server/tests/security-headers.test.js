import test from 'node:test';
import assert from 'node:assert/strict';
import { analyzeSecurityHeaders } from '../modules/security-headers.js';

test('HTTPS sem HSTS gera achado', () => {
  const snap = {
    strictTransportSecurity: '',
    contentSecurityPolicy: 'default-src self',
    xFrameOptions: 'DENY',
    xContentTypeOptions: 'nosniff',
    referrerPolicy: 'no-referrer',
    permissionsPolicy: '',
    crossOriginOpenerPolicy: '',
    crossOriginEmbedderPolicy: '',
    server: 'nginx',
    setCookieSample: [],
  };
  const issues = analyzeSecurityHeaders('https://exemplo.com/', snap);
  assert.ok(issues.some((i) => i.text.includes('HSTS')));
});

test('HTTP não exige HSTS', () => {
  const snap = {
    strictTransportSecurity: '',
    contentSecurityPolicy: '',
    xFrameOptions: '',
    xContentTypeOptions: '',
    referrerPolicy: '',
    permissionsPolicy: '',
    crossOriginOpenerPolicy: '',
    crossOriginEmbedderPolicy: '',
    server: '',
    setCookieSample: [],
  };
  const issues = analyzeSecurityHeaders('http://exemplo.com/', snap);
  assert.ok(!issues.some((i) => i.text.includes('HSTS')));
});
