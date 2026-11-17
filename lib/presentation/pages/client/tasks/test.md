# Tasks (client list) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks`

- [ ] Success: `page=1&pageSize=20&sort=due` → 200 with a paged list `{items, page, lastPage, total}`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Parameter error: an unknown `status` value is ignored by the backend, never crashes the app → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Values: every filter really changes the result: `status=prog` → only `prog`; `late=1` → only overdue; `who=boris,malika` → tasks involving either; `due=today|week|month` → that window; `due=range&from=…&to=…` → deadlines inside the range (inclusive); `q=ECO-142` → that task; an impossible filter returns an empty page.
- [ ] Values: `sort=due` ascending by deadline, `sort=priority` high → low, `sort=created` newest id first.
- [ ] Values: a manager's list contains only tasks of their team; an client's list contains all.
- [ ] Paging: opening the list issues exactly ONE request for page 1 (`pageSize` = the repository constant); the next page is requested only when scrolling near the end; pull-to-refresh reloads page 1 and resets the list.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Search (debounced) and the six status tabs (Hammasi / Yangi / Jarayonda / Kechikkan / Bajarilgan / Bajarilmagan); each changes the list through ONE new request and the tab strip scrolls sideways.
- [ ] Filter sheet: pick a status, a deadline window (Bugun / Shu hafta / Shu oy) or “Sanani tanlash” → the range sheet → the chip shows `20-okt — 26-okt` with an “x”; open the assignee row → the staff loads once, search narrows it, checks toggle, “Tanlash” returns “N ta”; “Tozalash” resets the draft; “Natijani ko‘rsatish” applies it with ONE request.
- [ ] The old archive screen is gone (calendar, expenses and archive are not in the design); closed tasks are reached through the list tabs.
- [ ] Fast typing in the search box shows only the result of the last query (stale responses are dropped).
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] The list is flat (boards 2.1–2.1e): each row shows a status circle, the title, the first line of the description, a clock with `22-okt, 16:00` and the tinted status pill, the assignees' avatars at the right (three, then “+N”) and a chevron; an overdue open task shows an amber alarm circle and “N kun kechikdi” with no pill.
- [ ] The header has only the “+” action; the filter button shows a red dot on its corner while a deadline or assignee filter is active.
- [ ] Empty states per tab (boards 2.1f–2.1k): the tile icon and tone, title and hint match the tab.
- [ ] Filter sheets (boards 2.2–2.2e): selected chips are green; the two bottom buttons are 52 px high in a 1 : 1.6 split.
- [ ] Loading shows shimmer placeholders; an empty result shows the empty view; a failed first load shows the retry view; pull-to-refresh works on all three; the last row clears the floating tab bar.

## 4. Logical/Business Test

- [ ] Creating or editing a task makes the list reflect it on return (cache invalidated).
- [ ] A task past its deadline and still open is shown as overdue consistently in the list, the “Kechikkan” tab and the filter result.
- [ ] The status chosen in the filter sheet and the selected tab stay in sync (both edit the same query).
- [ ] A range picked end-first is stored start-first; a single tapped day is a one-day range.
- [ ] Done and failed tasks appear under their own tabs and in “Hammasi”; closed tasks stay reachable through the tabs.
