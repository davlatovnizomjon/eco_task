/** Reads and validates the environment once; everything else imports the frozen result. */

function required(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Missing environment variable ${name} (see .env.example)`);
  return value;
}

export function loadConfig(env = process.env) {
  const get = (name, fallback) => env[name]?.trim() || fallback;
  const poll = Number(get('POLL_SECONDS', '15'));
  if (!Number.isFinite(poll) || poll < 3) throw new Error('POLL_SECONDS must be a number >= 3');
  return Object.freeze({
    botToken: env.BOT_TOKEN?.trim() || required('BOT_TOKEN'),
    apiBaseUrl: get('API_BASE_URL', 'http://localhost:8000/api/v1').replace(/\/+$/, ''),
    dataFile: get('DATA_FILE', './data/store.json'),
    pollSeconds: poll,
  });
}
