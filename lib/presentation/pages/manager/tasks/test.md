# Tasks (boss task list) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks`

- [ ] Success: `page=1&pageSize=20&sort=due` → 200 with a paged list `{items, page, lastPage, total}`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: an unknown `status` value is ignored by the backend, never crashes the app → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: every filter really changes the result: `status=prog` → only `prog`; `late=1` → only overdue; `who=boris` → only tasks involving Boris; `due=today` → only today's; `q=ECO-142` → that task; an impossible filter returns an empty page.
- [ ] Values: `sort=due` ascending by deadline, `sort=priority` high → low, `sort=created` newest id first.
- [ ] Values: a manager's list contains only tasks of their team; an admin's list contains all.
- [ ] Paging: opening the list issues exactly ONE request for page 1 (`pageSize` = the repository constant); the next page is requested only when scrolling near the end; pull-to-refresh reloads page 1 and resets the list.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Search (debounced), quick chips, the filter sheet (status, deadline, overdue, assignee, sort), clear and apply; each changes the list through ONE new request.
- [ ] Fast typing in the search box shows only the result of the last query (stale responses are dropped).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in Settings repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] Loading shows the shimmer placeholder cards (no spinner); an empty result shows the empty view; a failed first load shows the retry view and the retry button reloads.
- [ ] Pull-to-refresh works on a full list, a short list and the empty/error view (always-scrollable); the indicator completes when the network call finishes, not on the cached emit.
- [ ] The last row clears the system gesture bar (bottom inset is part of the scroll padding).
- [ ] The filter badge shows the number of active filters; chips highlight the matching query; tapping a card opens the task details.

## 4. Logical/Business Test

- [ ] Creating or editing a task makes the list reflect it on return (cache invalidated).
- [ ] A task past its deadline and still open is shown as overdue in the list, the chip row and the filter result consistently.
