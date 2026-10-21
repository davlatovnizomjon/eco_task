import { chmodSync, existsSync, mkdirSync, readFileSync, renameSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';

/**
 * Linked accounts, persisted as one JSON file written atomically with owner-only permissions.
 * It holds bearer tokens, so treat the file like a secret. For more than a few thousand clients
 * swap this module for a database; the rest of the bot only uses the methods below.
 */
export function createStore(file) {
  let users = {};
  if (existsSync(file)) {
    try {
      users = JSON.parse(readFileSync(file, 'utf8')).users ?? {};
    } catch {
      throw new Error(`Cannot read ${file}: fix or delete it`);
    }
  }

  function save() {
    mkdirSync(dirname(file), { recursive: true });
    const tmp = `${file}.tmp`;
    writeFileSync(tmp, JSON.stringify({ users }, null, 1), { mode: 0o600 });
    renameSync(tmp, file);
    chmodSync(file, 0o600);
  }

  return {
    get: (chatId) => users[chatId],
    all: () => Object.entries(users).map(([chatId, user]) => ({ chatId, ...user })),
    /** Merges [patch] into the record of [chatId] (creating it) and persists. */
    update(chatId, patch) {
      users[chatId] = { ...users[chatId], ...patch };
      save();
      return users[chatId];
    },
    /** Forgets the token and identity of [chatId] but keeps its language choice. */
    unlink(chatId) {
      const lang = users[chatId]?.lang;
      users[chatId] = lang ? { lang } : {};
      save();
    },
  };
}
