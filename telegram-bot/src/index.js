import { createApi } from './api.js';
import { createBot } from './bot.js';
import { loadConfig } from './config.js';
import { startNotifier } from './notifier.js';
import { createStore } from './store.js';

const config = loadConfig();
const api = createApi(config.apiBaseUrl);
const store = createStore(config.dataFile);
const { bot } = createBot({ config, api, store });

const stopNotifier = startNotifier({ bot, api, store, seconds: config.pollSeconds });

async function shutdown() {
  stopNotifier();
  await bot.stop();
  process.exit(0);
}
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);

await bot.api.setMyCommands([{ command: 'start', description: 'Start / Boshlash / Начать' }]);
console.log('Eco Tasks bot is running');
await bot.start();
