# Team directory (boss) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.getUsers` — GET `users?role=staff|client`

- [ ] Success: both directories → 200 with paged `AppUser` rows with `activeCount`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: a manager's staff list contains only their team; clients are the same for everyone; `activeCount` equals open tasks (staff) or open requests (clients).
- [ ] Parameter error: `q` filters by name, phone and team; an unmatched `q` returns an empty page → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Paging: opening the list issues exactly ONE request for page 1 (`pageSize` = the repository constant); the next page is requested only when scrolling near the end; pull-to-refresh reloads page 1 and resets the list.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Switch staff/clients, search, open an employee, open the account form from the top button.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Loading shows the shimmer placeholder cards (no spinner); an empty result shows the empty view; a failed first load shows the retry view and the retry button reloads.
- [ ] Pull-to-refresh works on a full list, a short list and the empty/error view (always-scrollable); the indicator completes when the network call finishes, not on the cached emit.
- [ ] The last row clears the system gesture bar (bottom inset is part of the scroll padding).
- [ ] Staff are grouped by team with the lead's name; managers carry the role chip; clients show district and request count; the clients help line is visible.

## 4. Logical/Business Test

- [ ] Creating an account makes it appear in the directory on return (cache invalidated).
