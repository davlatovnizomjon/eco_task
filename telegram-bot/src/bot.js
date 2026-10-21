import { Bot, InlineKeyboard, Keyboard } from 'grammy';

import { ApiError } from './api.js';
import { addDays, isoDate, messageLine, notificationText, personName, requestCard, when } from './format.js';
import { allLangs, DEFAULT_LANG, LANGS, t } from './i18n.js';

/** Time windows offered by the request wizard (same as the mobile app used to). */
export const SLOTS = ['09:00–12:00', '12:00–15:00', '15:00–18:00', '18:00–20:00'];
const KINDS = ['DELIVERY', 'PLANTING', 'CARE'];
const MENU = ['menuNew', 'menuRequests', 'menuChats', 'menuNotifs', 'menuLang', 'menuLogout'];

/**
 * Builds the grammY bot. Conversation state (a half-filled request, "I am typing into chat X") lives in memory in
 * [flows] and is lost on restart, which only costs a client re-pressing a button; linked accounts live in [store].
 */
export function createBot({ config, api, store }) {
  const bot = new Bot(config.botToken);
  /** chatId -> {name, ...} current multi-step flow. */
  const flows = new Map();

  const lang = (ctx) => store.get(ctx.chat.id)?.lang ?? DEFAULT_LANG;
  const account = (ctx) => store.get(ctx.chat.id);
  const linked = (ctx) => Boolean(account(ctx)?.token);

  const menuKeyboard = (l) => {
    const k = new Keyboard();
    MENU.forEach((key, i) => {
      k.text(t(l, key));
      if (i % 2 === 1) k.row();
    });
    return k.resized().persistent();
  };

  const cancelKeyboard = (l) => new InlineKeyboard().text(t(l, 'cancel'), 'x:cancel');

  /** Runs [fn]; turns API failures into a readable message and drops dead sessions. */
  async function guarded(ctx, fn) {
    const l = lang(ctx);
    try {
      return await fn();
    } catch (e) {
      if (!(e instanceof ApiError)) throw e;
      if (e.status === 401) {
        store.unlink(ctx.chat.id);
        flows.delete(ctx.chat.id);
        await ctx.reply(t(l, 'sessionExpired'), { reply_markup: { remove_keyboard: true } });
      } else if (e.status === 0 || e.status >= 500) {
        await ctx.reply(t(l, 'serverDown'));
      } else {
        await ctx.reply(t(l, 'error', { detail: e.detail || e.code || e.status }));
      }
      return undefined;
    }
  }

  const token = (ctx) => account(ctx).token;
  const meId = (ctx) => account(ctx).userId;

  // ─── start, language, login ───────────────────────────────────────────────

  async function askLanguage(ctx) {
    const k = new InlineKeyboard();
    for (const [code, name] of Object.entries(LANGS)) k.text(name, `lang:${code}`).row();
    await ctx.reply(t(lang(ctx), 'pickLang'), { reply_markup: k });
  }

  async function beginLogin(ctx) {
    flows.set(ctx.chat.id, { name: 'login', step: 'username' });
    await ctx.reply(`${t(lang(ctx), 'welcome')}\n\n${t(lang(ctx), 'askLogin')}`, {
      reply_markup: { remove_keyboard: true },
    });
  }

  bot.command('start', async (ctx) => {
    flows.delete(ctx.chat.id);
    if (linked(ctx)) return ctx.reply(t(lang(ctx), 'menu'), { reply_markup: menuKeyboard(lang(ctx)) });
    if (!account(ctx)?.lang) return askLanguage(ctx);
    return beginLogin(ctx);
  });

  bot.callbackQuery(/^lang:(.+)$/, async (ctx) => {
    const code = ctx.match[1];
    if (!(code in LANGS)) return ctx.answerCallbackQuery();
    store.update(ctx.chat.id, { lang: code });
    await ctx.answerCallbackQuery();
    await ctx.deleteMessage().catch(() => {});
    if (linked(ctx)) return ctx.reply(t(code, 'menu'), { reply_markup: menuKeyboard(code) });
    return beginLogin(ctx);
  });

  async function handleLogin(ctx, flow) {
    const l = lang(ctx);
    const text = ctx.message.text.trim();
    if (flow.step === 'username') {
      flows.set(ctx.chat.id, { name: 'login', step: 'password', username: text });
      return ctx.reply(t(l, 'askPassword'));
    }
    await ctx.deleteMessage().catch(() => {}); // never leave the password in the chat
    flows.delete(ctx.chat.id);
    try {
      const { token: bearer, user } = await api.login(flow.username, ctx.message.text);
      if (user.role !== 'CLIENT') {
        await api.post(bearer, 'auth/logout/').catch(() => {});
        return ctx.reply(t(l, 'notClient'));
      }
      store.update(ctx.chat.id, {
        token: bearer,
        userId: user.id,
        name: personName(user),
        lastNotificationId: 0,
      });
      return ctx.reply(t(l, 'loggedIn', { name: personName(user) }), { reply_markup: menuKeyboard(l) });
    } catch (e) {
      if (!(e instanceof ApiError)) throw e;
      if (e.status === 401 || e.status === 400) {
        flows.set(ctx.chat.id, { name: 'login', step: 'username' });
        return ctx.reply(`${t(l, 'loginFailed')}\n\n${t(l, 'askLogin')}`);
      }
      if (e.status === 429) return ctx.reply(t(l, 'error', { detail: e.detail }));
      return ctx.reply(t(l, 'serverDown'));
    }
  }

  // ─── menu buttons ─────────────────────────────────────────────────────────

  const isButton = (ctx, key) => allLangs(key).includes(ctx.message.text);

  async function logout(ctx) {
    const l = lang(ctx);
    await api.post(token(ctx), 'auth/logout/').catch(() => {});
    store.unlink(ctx.chat.id);
    flows.delete(ctx.chat.id);
    return ctx.reply(t(l, 'loggedOut'), { reply_markup: { remove_keyboard: true } });
  }

  // ─── new request wizard ───────────────────────────────────────────────────

  function startRequest(ctx) {
    const l = lang(ctx);
    flows.set(ctx.chat.id, { name: 'request', step: 'kind', draft: {} });
    const k = new InlineKeyboard();
    for (const kind of KINDS) k.text(t(l, `kind${kind}`), `rq:kind:${kind}`).row();
    k.text(t(l, 'cancel'), 'x:cancel');
    return ctx.reply(t(l, 'kindPrompt'), { reply_markup: k });
  }

  const flowOf = (ctx, name) => {
    const f = flows.get(ctx.chat.id);
    return f?.name === name ? f : undefined;
  };

  bot.callbackQuery('x:cancel', async (ctx) => {
    flows.delete(ctx.chat.id);
    await ctx.answerCallbackQuery();
    await ctx.editMessageText(t(lang(ctx), 'cancelled')).catch(() => {});
  });

  bot.callbackQuery(/^rq:kind:(\w+)$/, async (ctx) => {
    const f = flowOf(ctx, 'request');
    await ctx.answerCallbackQuery();
    if (!f || !KINDS.includes(ctx.match[1])) return;
    f.draft.kind = ctx.match[1];
    f.step = 'title';
    await ctx.editMessageText(t(lang(ctx), 'askTitle'), { reply_markup: cancelKeyboard(lang(ctx)) });
  });

  bot.callbackQuery('rq:skipdetail', async (ctx) => {
    const f = flowOf(ctx, 'request');
    await ctx.answerCallbackQuery();
    if (!f) return;
    f.draft.detail = '';
    f.step = 'address';
    await ctx.editMessageText(t(lang(ctx), 'askAddress'), { reply_markup: cancelKeyboard(lang(ctx)) });
  });

  function dateKeyboard(l) {
    return new InlineKeyboard()
      .text(t(l, 'today'), 'rq:date:0')
      .text(t(l, 'tomorrow'), 'rq:date:1')
      .text(t(l, 'dayAfter'), 'rq:date:2')
      .row()
      .text(t(l, 'skip'), 'rq:date:none')
      .row()
      .text(t(l, 'cancel'), 'x:cancel');
  }

  bot.callbackQuery(/^rq:date:(\d|none)$/, async (ctx) => {
    const f = flowOf(ctx, 'request');
    await ctx.answerCallbackQuery();
    if (!f) return;
    const l = lang(ctx);
    f.draft.date = ctx.match[1] === 'none' ? null : isoDate(addDays(Number(ctx.match[1])));
    if (!f.draft.date) {
      f.draft.slot = '';
      return showSummary(ctx, f);
    }
    f.step = 'slot';
    const k = new InlineKeyboard();
    SLOTS.forEach((s, i) => {
      k.text(s, `rq:slot:${i}`);
      if (i % 2 === 1) k.row();
    });
    k.row().text(t(l, 'skip'), 'rq:slot:none').row().text(t(l, 'cancel'), 'x:cancel');
    await ctx.editMessageText(t(l, 'askSlot'), { reply_markup: k });
  });

  bot.callbackQuery(/^rq:slot:(\d|none)$/, async (ctx) => {
    const f = flowOf(ctx, 'request');
    await ctx.answerCallbackQuery();
    if (!f) return;
    f.draft.slot = ctx.match[1] === 'none' ? '' : (SLOTS[Number(ctx.match[1])] ?? '');
    return showSummary(ctx, f);
  });

  async function showSummary(ctx, f) {
    const l = lang(ctx);
    f.step = 'confirm';
    const d = f.draft;
    const text = t(l, 'summary', {
      kind: t(l, `kind${d.kind}`),
      title: d.title,
      address: d.address,
      when: when(l, d.date, d.slot),
    });
    const k = new InlineKeyboard().text(t(l, 'send'), 'rq:send').row().text(t(l, 'cancel'), 'x:cancel');
    await ctx.editMessageText(text, { reply_markup: k }).catch(() => ctx.reply(text, { reply_markup: k }));
  }

  bot.callbackQuery('rq:send', async (ctx) => {
    const f = flowOf(ctx, 'request');
    await ctx.answerCallbackQuery();
    if (!f || f.step !== 'confirm') return;
    flows.delete(ctx.chat.id);
    const d = f.draft;
    await guarded(ctx, async () => {
      const created = await api.post(token(ctx), 'requests/', {
        title: d.title,
        kind: d.kind,
        detail: d.detail,
        address: d.address,
        ...(d.date ? { date: d.date, slot: d.slot } : {}),
      });
      await ctx.editMessageText(t(lang(ctx), 'sent', { code: created.code })).catch(() => {});
    });
  });

  async function handleRequestText(ctx, f) {
    const l = lang(ctx);
    const text = ctx.message.text.trim();
    if (f.step === 'title') {
      if (text.length < 3) return ctx.reply(t(l, 'tooShort'));
      f.draft.title = text.slice(0, 200);
      f.step = 'detail';
      return ctx.reply(t(l, 'askDetail'), {
        reply_markup: new InlineKeyboard().text(t(l, 'skip'), 'rq:skipdetail').row().text(t(l, 'cancel'), 'x:cancel'),
      });
    }
    if (f.step === 'detail') {
      f.draft.detail = text.slice(0, 5000);
      f.step = 'address';
      return ctx.reply(t(l, 'askAddress'), { reply_markup: cancelKeyboard(l) });
    }
    if (f.step === 'address') {
      if (text.length < 3) return ctx.reply(t(l, 'tooShort'));
      f.draft.address = text.slice(0, 300);
      f.step = 'date';
      return ctx.reply(t(l, 'askDate'), { reply_markup: dateKeyboard(l) });
    }
    return ctx.reply(t(l, 'unknownText'));
  }

  // ─── my requests ──────────────────────────────────────────────────────────

  async function listRequests(ctx) {
    const l = lang(ctx);
    await guarded(ctx, async () => {
      const page = await api.get(token(ctx), 'requests/', { page_size: 10 });
      if (!page.results.length) return ctx.reply(t(l, 'noRequests'));
      const k = new InlineKeyboard();
      for (const r of page.results) k.text(`${r.code} · ${r.title}`.slice(0, 60), `req:${r.id}`).row();
      return ctx.reply(t(l, 'requestsTitle'), { reply_markup: k });
    });
  }

  async function showRequest(ctx, id) {
    const l = lang(ctx);
    await guarded(ctx, async () => {
      const [r, messages] = await Promise.all([
        api.get(token(ctx), `requests/${id}/`),
        api.get(token(ctx), `requests/${id}/messages/`),
      ]);
      const tail = messages.slice(-5).map((m) => messageLine(l, m, meId(ctx)));
      const text = [requestCard(l, r), tail.length ? `\n${t(l, 'messages')}\n${tail.join('\n')}` : ''].join('');
      const k = r.status === 'DONE' ? undefined : new InlineKeyboard().text(t(l, 'writeMessage'), `reqmsg:${id}`);
      await ctx.reply(text, k ? { reply_markup: k } : undefined);
    });
  }

  bot.callbackQuery(/^req:(\d+)$/, async (ctx) => {
    await ctx.answerCallbackQuery();
    if (linked(ctx)) await showRequest(ctx, ctx.match[1]);
  });

  bot.callbackQuery(/^reqmsg:(\d+)$/, async (ctx) => {
    await ctx.answerCallbackQuery();
    if (!linked(ctx)) return;
    flows.set(ctx.chat.id, { name: 'reqmsg', id: ctx.match[1] });
    await ctx.reply(t(lang(ctx), 'askMessage'), { reply_markup: cancelKeyboard(lang(ctx)) });
  });

  async function handleRequestMessage(ctx, f) {
    flows.delete(ctx.chat.id);
    await guarded(ctx, async () => {
      await api.post(token(ctx), `requests/${f.id}/messages/`, { body: ctx.message.text.trim().slice(0, 2000) });
      await ctx.reply(t(lang(ctx), 'messageSent'));
    });
  }

  // ─── chats ────────────────────────────────────────────────────────────────

  const chatName = (c, ctx) =>
    c.kind === 'DIRECT'
      ? personName(c.members.find((m) => String(m.id) !== String(meId(ctx)))) || c.title
      : c.title || t(lang(ctx), 'menuChats');

  async function listChats(ctx) {
    const l = lang(ctx);
    await guarded(ctx, async () => {
      const chats = await api.get(token(ctx), 'conversations/');
      const k = new InlineKeyboard();
      for (const c of chats.slice(0, 15)) {
        k.text(`${c.unread_count ? `(${c.unread_count}) ` : ''}${chatName(c, ctx)}`.slice(0, 60), `chat:${c.id}`).row();
      }
      k.text(t(l, 'newChat'), 'chatnew');
      return ctx.reply(chats.length ? t(l, 'chatsTitle') : t(l, 'noChats'), { reply_markup: k });
    });
  }

  async function openChat(ctx, id) {
    const l = lang(ctx);
    await guarded(ctx, async () => {
      const [chat, history] = await Promise.all([
        api.get(token(ctx), `conversations/${id}/`),
        api.get(token(ctx), `conversations/${id}/messages/`, { limit: 5 }),
      ]);
      flows.set(ctx.chat.id, { name: 'chat', id });
      const lines = history.results.slice().reverse().map((m) => messageLine(l, m, meId(ctx)));
      await ctx.reply(
        [t(l, 'chatOpened', { name: chatName(chat, ctx) }), lines.length ? `\n${lines.join('\n')}` : `\n${t(l, 'noMessages')}`].join(''),
      );
      const newest = history.results[0]?.id;
      if (newest) await api.post(token(ctx), `conversations/${id}/read/`, { message_id: newest }).catch(() => {});
    });
  }

  bot.callbackQuery(/^chat:([0-9a-f-]{36})$/, async (ctx) => {
    await ctx.answerCallbackQuery();
    if (linked(ctx)) await openChat(ctx, ctx.match[1]);
  });

  bot.callbackQuery('chatnew', async (ctx) => {
    await ctx.answerCallbackQuery();
    if (!linked(ctx)) return;
    const l = lang(ctx);
    await guarded(ctx, async () => {
      const people = await api.get(token(ctx), 'conversations/contacts/');
      if (!people.length) return ctx.reply(t(l, 'noContacts'));
      const k = new InlineKeyboard();
      for (const p of people.slice(0, 20)) k.text(personName(p), `chatwith:${p.id}`).row();
      return ctx.reply(t(l, 'contactsTitle'), { reply_markup: k });
    });
  });

  bot.callbackQuery(/^chatwith:(\d+)$/, async (ctx) => {
    await ctx.answerCallbackQuery();
    if (!linked(ctx)) return;
    await guarded(ctx, async () => {
      const chat = await api.post(token(ctx), 'conversations/', { kind: 'DIRECT', user: Number(ctx.match[1]) });
      await openChat(ctx, chat.id);
    });
  });

  let clientSeq = 0;
  async function handleChatText(ctx, f) {
    await guarded(ctx, async () => {
      await api.post(token(ctx), `conversations/${f.id}/messages/`, {
        body: ctx.message.text.trim().slice(0, 4000),
        client_msg_id: `tg-${ctx.chat.id}-${ctx.message.message_id}-${clientSeq++}`.slice(0, 64),
      });
    });
  }

  // ─── notifications ────────────────────────────────────────────────────────

  async function showUnread(ctx) {
    const l = lang(ctx);
    await guarded(ctx, async () => {
      const page = await api.get(token(ctx), 'notifications/', { unread: 'true', page_size: 20 });
      if (!page.results.length) return ctx.reply(t(l, 'noNotifs'));
      await ctx.reply(t(l, 'notifsTitle'));
      for (const n of page.results.slice().reverse()) await ctx.reply(notificationText(l, n), { reply_markup: openButton(l, n) });
      await api.post(token(ctx), 'notifications/read/', { ids: page.results.map((n) => n.id) });
    });
  }

  /** "Open" button for a notification that points at a request or a chat. */
  function openButton(l, n) {
    if (n.service_request) return new InlineKeyboard().text(t(l, 'open'), `req:${n.service_request}`);
    if (n.conversation) return new InlineKeyboard().text(t(l, 'open'), `chat:${n.conversation}`);
    return undefined;
  }

  // ─── text router ──────────────────────────────────────────────────────────

  bot.on('message:text', async (ctx) => {
    const l = lang(ctx);
    const flow = flows.get(ctx.chat.id);
    if (flow?.name === 'login') return handleLogin(ctx, flow);
    if (!linked(ctx)) return ctx.reply(t(l, 'welcome') + '\n/start');

    // A menu button always wins over a running flow and ends it.
    const button = MENU.find((key) => isButton(ctx, key));
    if (button) {
      flows.delete(ctx.chat.id);
      switch (button) {
        case 'menuNew': return startRequest(ctx);
        case 'menuRequests': return listRequests(ctx);
        case 'menuChats': return listChats(ctx);
        case 'menuNotifs': return showUnread(ctx);
        case 'menuLang': return askLanguage(ctx);
        case 'menuLogout': return logout(ctx);
      }
    }
    if (flow?.name === 'request') return handleRequestText(ctx, flow);
    if (flow?.name === 'reqmsg') return handleRequestMessage(ctx, flow);
    if (flow?.name === 'chat') return handleChatText(ctx, flow);
    return ctx.reply(t(l, 'unknownText'), { reply_markup: menuKeyboard(l) });
  });

  bot.catch((err) => console.error('bot error:', err.error?.message ?? err.message));

  return { bot, flows, notificationText };
}
