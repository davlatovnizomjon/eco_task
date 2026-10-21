import assert from 'node:assert/strict';
import { test } from 'node:test';

import { ApiError } from '../src/api.js';
import { harness } from './helpers.js';

const client = { token: 'tok', userId: 5, name: 'Gulnora', lang: 'uz', lastNotificationId: 0 };

test('login: asks language, then login and password, deletes the password message, links a client', async () => {
  const h = await harness({
    apiImpl: { login: async (u, p) => (u === 'gulnora' && p === 'secret-pass' ? { token: 'T', user: { id: 5, role: 'CLIENT', full_name: 'Gulnora K' } } : Promise.reject(new ApiError(401, 'invalid_credentials', 'bad'))) },
  });
  await h.say('/start');
  assert.match(h.sent().at(-1).text, /Tilni tanlang/);
  await h.press('lang:ru');
  assert.match(h.sent().at(-1).text, /Отправьте логин/);
  await h.say('gulnora');
  await h.say('secret-pass');
  assert.ok(h.calls.some((c) => c.method === 'deleteMessage'), 'password message must be deleted');
  assert.equal(h.store.get(7).token, 'T');
  assert.equal(h.store.get(7).lang, 'ru');
  assert.match(h.sent().at(-1).text, /Здравствуйте, Gulnora K/);
  assert.ok(!JSON.stringify(h.calls).includes('"secret-pass"') || h.calls.filter((c) => c.method === 'sendMessage').every((c) => !String(c.payload.text).includes('secret-pass')));
});

test('login: wrong password restarts at the login question and links nothing', async () => {
  const h = await harness({ users: { 7: { lang: 'uz' } }, apiImpl: { login: async () => Promise.reject(new ApiError(401, 'invalid_credentials', 'bad')) } });
  await h.say('/start');
  await h.say('gulnora');
  await h.say('nope');
  assert.match(h.sent().at(-1).text, /noto‘g‘ri/);
  assert.equal(h.store.get(7).token, undefined);
});

test('login: staff accounts are refused and logged out again', async () => {
  const out = [];
  const h = await harness({
    users: { 7: { lang: 'uz' } },
    apiImpl: { login: async () => ({ token: 'T', user: { id: 1, role: 'OWNER' } }), post: async (_t, path) => out.push(path) },
  });
  await h.say('/start');
  await h.say('jamshid');
  await h.say('whatever');
  assert.match(h.sent().at(-1).text, /faqat mijozlar/);
  assert.equal(h.store.get(7).token, undefined);
  assert.deepEqual(out, ['auth/logout/']);
});

test('request wizard files a request with the typed values', async () => {
  const posts = [];
  const h = await harness({ users: { 7: client }, apiImpl: { post: async (_t, path, body) => (posts.push({ path, body }), { code: 'R-9' }) } });
  await h.say('📝 Yangi so‘rov');
  await h.press('rq:kind:PLANTING');
  await h.say('Plant 20 trees');
  await h.press('rq:skipdetail');
  await h.say('Yunusobod 17');
  await h.press('rq:date:1');
  await h.press('rq:slot:2');
  await h.press('rq:send');
  assert.equal(posts.length, 1);
  assert.equal(posts[0].path, 'requests/');
  assert.deepEqual({ ...posts[0].body, date: 'D' }, { title: 'Plant 20 trees', kind: 'PLANTING', detail: '', address: 'Yunusobod 17', date: 'D', slot: '15:00–18:00' });
  assert.match(posts[0].body.date, /^\d{4}-\d{2}-\d{2}$/);
});

test('request wizard: too-short title is rejected and a menu button cancels the flow', async () => {
  const h = await harness({ users: { 7: client }, apiImpl: { get: async () => ({ results: [] }) } });
  await h.say('📝 Yangi so‘rov');
  await h.press('rq:kind:CARE');
  await h.say('ab');
  assert.match(h.sent().at(-1).text, /Juda qisqa/);
  await h.say('🔔 Xabarlar');
  assert.match(h.sent().at(-1).text, /Yangi xabar yo‘q/);
  await h.say('Plant trees'); // the wizard is over, so plain text is no longer a title
  assert.match(h.sent().at(-1).text, /Menyudan tanlang/);
});

test('an expired token (401) unlinks the chat and asks to sign in again', async () => {
  const h = await harness({ users: { 7: client }, apiImpl: { get: async () => Promise.reject(new ApiError(401, 'x', 'x')) } });
  await h.say('📋 So‘rovlarim');
  assert.match(h.sent().at(-1).text, /Seansingiz tugadi/);
  assert.equal(h.store.get(7).token, undefined);
});

test('chat: text typed while a conversation is open is sent to it with a client_msg_id', async () => {
  const posts = [];
  const cid = '11111111-1111-1111-1111-111111111111';
  const h = await harness({
    users: { 7: client },
    apiImpl: {
      get: async (_t, path) => (path.endsWith('/messages/') ? { results: [], has_more: false } : { id: cid, kind: 'GROUP', title: 'Team', members: [] }),
      post: async (_t, path, body) => (posts.push({ path, body }), {}),
    },
  });
  await h.press(`chat:${cid}`);
  await h.say('Hello team');
  const sentMsg = posts.find((p) => p.path === `conversations/${cid}/messages/`);
  assert.equal(sentMsg.body.body, 'Hello team');
  assert.ok(sentMsg.body.client_msg_id.length > 0 && sentMsg.body.client_msg_id.length <= 64);
});

test('logout forgets the token but keeps the language', async () => {
  const h = await harness({ users: { 7: client } });
  await h.say('🚪 Chiqish');
  assert.deepEqual(h.store.get(7), { lang: 'uz' });
});
