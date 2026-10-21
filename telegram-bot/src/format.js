import { t } from './i18n.js';

/** Display name of a backend brief user. */
export function personName(user) {
  return (user?.full_name || user?.username || '').trim();
}

/** `yyyy-mm-dd` of [date] in local time (what the API's DateField expects). */
export function isoDate(date) {
  const pad = (n) => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

/** The date `days` from [from] (default: now). */
export function addDays(days, from = new Date()) {
  const d = new Date(from);
  d.setDate(d.getDate() + days);
  return d;
}

/** "2026-11-02, 09:00–12:00" or the localized "date to be agreed". */
export function when(lang, date, slot) {
  if (!date) return t(lang, 'dateUnknown');
  return slot ? `${date}, ${slot}` : date;
}

/** Card text of one request. */
export function requestCard(lang, r) {
  return t(lang, 'requestCard', {
    code: r.code,
    kind: t(lang, `kind${r.kind}`),
    title: r.title,
    address: r.address,
    when: when(lang, r.date, r.slot),
    assignee: r.assignee ? personName(r.assignee) : t(lang, 'noAssignee'),
    status: t(lang, `status${r.status}`),
  });
}

/** One chat/request message line: "Name: text". */
export function messageLine(lang, message, meId) {
  const author = message.author ?? message.sender;
  const who = author && String(author.id) === String(meId) ? t(lang, 'me') : personName(author);
  return `${who}: ${message.body}`;
}

/** Backend English status labels used inside notification titles -> status keys. */
const STATUS_LABELS = { Accepted: 'ACCEPTED', Planned: 'PLANNED', 'In Progress': 'IN_PROGRESS', Done: 'DONE' };

/** Localized text of one backend notification (the API sends English sentences, never message bodies). */
export function notificationText(lang, n) {
  if (n.kind === 'request.status') {
    const match = /^(R-\d+): (.+)$/.exec(n.title);
    const status = match && STATUS_LABELS[match[2]];
    if (status) return t(lang, 'notifStatus', { code: match[1], status: t(lang, `status${status}`) });
  }
  if (n.kind === 'request.message') {
    const code = /(R-\d+)/.exec(n.title)?.[1];
    if (code) return t(lang, 'notifRequestMessage', { code });
  }
  if (n.kind === 'chat.message') return t(lang, 'notifChat', { title: n.title });
  return t(lang, 'notifOther', { title: n.title });
}
