import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';

import { ApiError, createApi, detailText } from '../src/api.js';
import { loadConfig } from '../src/config.js';
import { addDays, isoDate, notificationText, requestCard } from '../src/format.js';
import { t, TEXT_TABLES } from '../src/i18n.js';
import { createStore } from '../src/store.js';

test('every language defines exactly the same keys and placeholders', () => {
  const base = TEXT_TABLES.uz;
  for (const [lang, table] of Object.entries(TEXT_TABLES)) {
    assert.deepEqual(Object.keys(table).sort(), Object.keys(base).sort(), `${lang} keys`);
    for (const key of Object.keys(base)) {
      const ph = (s) => [...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1]).sort().join();
      assert.equal(ph(table[key]), ph(base[key]), `${lang}.${key} placeholders`);
    }
  }
});

test('t falls back to the default language and fills placeholders', () => {
  assert.equal(t('xx', 'sent', { code: 'R-1' }), 'So‘rov yuborildi: R-1');
});

test('config requires the bot token and a sane poll interval', () => {
  assert.throws(() => loadConfig({}), /BOT_TOKEN/);
  assert.throws(() => loadConfig({ BOT_TOKEN: 'x', POLL_SECONDS: '1' }), /POLL_SECONDS/);
  assert.equal(loadConfig({ BOT_TOKEN: 'x', API_BASE_URL: 'http://a/api/v1/' }).apiBaseUrl, 'http://a/api/v1');
});

test('api: sends the bearer token, parses the error envelope, maps network failures', async () => {
  let seen;
  const ok = createApi('http://h/api/v1', async (url, init) => ((seen = { url: String(url), init }), new Response('{"a":1}', { status: 200 })));
  assert.deepEqual(await ok.get('tok', 'requests/', { page_size: 10, q: '' }), { a: 1 });
  assert.equal(seen.url, 'http://h/api/v1/requests/?page_size=10');
  assert.equal(seen.init.headers.Authorization, 'Bearer tok');

  const bad = createApi('http://h', async () => new Response('{"error":{"code":"forbidden","detail":{"title":["Required."]}}}', { status: 400 }));
  await assert.rejects(bad.post('t', 'x/'), (e) => e instanceof ApiError && e.code === 'forbidden' && e.detail === 'title: Required.');

  const down = createApi('http://h', async () => Promise.reject(new TypeError('fetch failed')));
  await assert.rejects(down.get('t', 'x/'), (e) => e.status === 0);
  assert.equal(detailText(['one', 'two']), 'one');
});

test('store persists atomically with owner-only permissions and unlink keeps the language', () => {
  const file = join(mkdtempSync(join(tmpdir(), 'bot-')), 'nested', 'store.json');
  const a = createStore(file);
  a.update('1', { token: 'T', lang: 'ru' });
  assert.equal(statSync(file).mode & 0o777, 0o600);
  assert.equal(createStore(file).get('1').token, 'T');
  a.unlink('1');
  assert.deepEqual(JSON.parse(readFileSync(file, 'utf8')).users['1'], { lang: 'ru' });
});

test('format helpers', () => {
  assert.equal(isoDate(new Date(2026, 0, 5)), '2026-01-05');
  assert.equal(isoDate(addDays(1, new Date(2026, 0, 31))), '2026-02-01');
  const r = { code: 'R-3', kind: 'CARE', title: 'Prune', address: 'Here', date: null, slot: '', status: 'PLANNED', assignee: null };
  assert.match(requestCard('uz', r), /R-3 · 🍃 Parvarish[\s\S]*sana kelishiladi[\s\S]*tayinlanmagan[\s\S]*Rejalashtirildi/);
  assert.match(notificationText('ru', { kind: 'request.status', title: 'R-3: In Progress' }), /R-3: статус — Выполняется/);
  assert.match(notificationText('uz', { kind: 'request.message', title: 'New message on R-3' }), /R-3 bo‘yicha/);
  assert.match(notificationText('uz', { kind: 'task.status', title: 'Foo: OPEN -> REVIEW' }), /Foo/);
});
