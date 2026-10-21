import { createBot } from '../src/bot.js';

/** Builds a bot whose Telegram calls are recorded instead of sent, over a fake API and an in-memory store. */
export async function harness({ apiImpl = {}, users = {} } = {}) {
  const data = structuredClone(users);
  const store = {
    get: (id) => data[id],
    all: () => Object.entries(data).map(([chatId, u]) => ({ chatId, ...u })),
    update: (id, patch) => (data[id] = { ...data[id], ...patch }),
    unlink: (id) => (data[id] = data[id]?.lang ? { lang: data[id].lang } : {}),
  };
  const calls = [];
  const api = {
    login: async () => {
      throw new Error('login not stubbed');
    },
    get: async () => {
      throw new Error('get not stubbed');
    },
    post: async () => ({}),
    ...apiImpl,
  };
  const { bot } = createBot({ config: { botToken: '1:test' }, api, store });
  bot.botInfo = { id: 1, is_bot: true, first_name: 'bot', username: 'bot', can_join_groups: true, can_read_all_group_messages: false, supports_inline_queries: false, can_connect_to_business: false, has_main_web_app: false };
  let messageId = 100;
  bot.api.config.use(async (_prev, method, payload) => {
    calls.push({ method, payload });
    return { ok: true, result: method === 'sendMessage' ? { message_id: ++messageId, chat: { id: payload.chat_id }, date: 0, text: payload.text } : true };
  });
  let updateId = 0;
  const chat = { id: 7, type: 'private', first_name: 'C' };
  const from = { id: 7, is_bot: false, first_name: 'C' };
  return {
    store,
    calls,
    sent: () => calls.filter((c) => c.method === 'sendMessage').map((c) => c.payload),
    say: (text) =>
      bot.handleUpdate({ update_id: ++updateId, message: { message_id: ++messageId, date: 0, chat, from, text, ...(text.startsWith('/') ? { entities: [{ type: 'bot_command', offset: 0, length: text.split(' ')[0].length }] } : {}) } }),
    press: (data) =>
      bot.handleUpdate({
        update_id: ++updateId,
        callback_query: { id: String(updateId), from, chat_instance: 'x', data, message: { message_id: 55, date: 0, chat, text: 'old' } },
      }),
  };
}
