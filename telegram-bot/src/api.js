/** Thin client for the Eco Tasks REST API. Errors carry the backend's `{error: {code, message}}` envelope. */

export class ApiError extends Error {
  constructor(status, code, detail) {
    super(detail || code || `HTTP ${status}`);
    this.status = status;
    this.code = code;
    this.detail = detail;
  }
}

/** First readable sentence of an `error.message` (a string, a list, or a field -> messages map). */
export function detailText(detail) {
  if (typeof detail === 'string') return detail;
  if (Array.isArray(detail)) return detail.length ? detailText(detail[0]) : '';
  if (detail && typeof detail === 'object') {
    const first = Object.entries(detail)[0];
    return first ? `${first[0]}: ${detailText(first[1])}` : '';
  }
  return '';
}

export function createApi(baseUrl, fetchImpl = fetch) {
  async function call(token, method, path, { query, body } = {}) {
    const url = new URL(`${baseUrl}/${path.replace(/^\/+/, '')}`);
    for (const [key, value] of Object.entries(query ?? {})) {
      if (value !== undefined && value !== null && value !== '') url.searchParams.set(key, String(value));
    }
    let response;
    try {
      response = await fetchImpl(url, {
        method,
        headers: {
          Accept: 'application/json',
          ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: body === undefined ? undefined : JSON.stringify(body),
        signal: AbortSignal.timeout(20_000),
      });
    } catch {
      throw new ApiError(0, 'network', 'The server is unreachable.');
    }
    if (response.status === 204) return null;
    const data = await response.json().catch(() => null);
    if (!response.ok) {
      throw new ApiError(response.status, data?.error?.code, detailText(data?.error?.message));
    }
    return data;
  }

  return {
    call,
    login: (username, password) => call(null, 'POST', 'auth/login/', { body: { username, password } }),
    get: (token, path, query) => call(token, 'GET', path, { query }),
    post: (token, path, body) => call(token, 'POST', path, { body: body ?? {} }),
  };
}
