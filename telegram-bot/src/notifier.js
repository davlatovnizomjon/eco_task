import { InlineKeyboard } from 'grammy';

import { ApiError } from './api.js';
import { notificationText } from './format.js';
import { DEFAULT_LANG, t } from './i18n.js';

/**
 * Pushes new backend notifications to Telegram. Every [seconds] it asks the API for each linked client's unread
 * notifications, sends the ones it has not sent yet, then marks them read so they are not shown twice. A dead token
 * (401) unlinks the chat; any other failure is skipped until the next tick.
 */
export function startNotifier({ bot, api, store, seconds }) {
  let running = false;

  async function tickOne(user) {
    const lang = user.lang ?? DEFAULT_LANG;
    let page;
    try {
      page = await api.get(user.token, 'notifications/', { unread: 'true', page_size: 30 });
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) {
        store.unlink(user.chatId);
        await bot.api.sendMessage(user.chatId, t(lang, 'sessionExpired'), { reply_markup: { remove_keyboard: true } });
      }
      return;
    }
    const fresh = page.results.filter((n) => n.id > (user.lastNotificationId ?? 0)).reverse();
    for (const n of fresh) {
      const k = n.service_request
        ? new InlineKeyboard().text(t(lang, 'open'), `req:${n.service_request}`)
        : n.conversation
          ? new InlineKeyboard().text(t(lang, 'open'), `chat:${n.conversation}`)
          : undefined;
      await bot.api.sendMessage(user.chatId, notificationText(lang, n), k ? { reply_markup: k } : undefined);
    }
    if (fresh.length) {
      store.update(user.chatId, { lastNotificationId: Math.max(...fresh.map((n) => n.id)) });
      await api.post(user.token, 'notifications/read/', { ids: fresh.map((n) => n.id) }).catch(() => {});
    }
  }

  async function tick() {
    if (running) return;
    running = true;
    try {
      for (const user of store.all().filter((u) => u.token)) {
        await tickOne(user).catch((e) => console.error('notifier:', e.message));
      }
    } finally {
      running = false;
    }
  }

  const timer = setInterval(tick, seconds * 1000);
  return () => clearInterval(timer);
}
