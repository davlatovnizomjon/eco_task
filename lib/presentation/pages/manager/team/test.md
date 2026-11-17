# Team: employees, clients, rating (manager) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `TeamRepository.getUsers` — GET `users?role=staff|client`

- [ ] Success: both directories → 200 with paged `AppUser` rows with `activeCount`; the parsed model matches the payload.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: a manager's staff list contains workers only (the backend hides owners and managers from assistants); clients are the same for everyone; `activeCount` equals open tasks (staff) or open requests (clients).
- [ ] Parameter error: `q` filters by name, phone and team; an unmatched `q` returns an empty page → the backend `detail` text is shown verbatim in the shared dialog.
- [ ] Paging: opening the list issues exactly ONE request for page 1 (`pageSize` = the repository constant); the next page is requested only when scrolling near the end; pull-to-refresh reloads page 1 and resets the list.
- [ ] Cached-first: reopening the screen shows the cached data immediately (no loading flicker), then the fresh data replaces it; a failed refresh keeps the cache and shows the error dialog.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Employees (from the dashboard card): search, role sheet (Hammasi / Rahbar / Menejer / Oddiy ishchi), Hammasi / Vazifali / Vazifasiz switch, “+” opens the invite form, tap a row opens the profile. Clients: search, Hammasi / Faol so‘rov / So‘rovsiz switch, “+” opens the client form. Rating: period switch, tap a row opens the profile.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Employee rows show the avatar, name, role and “N vazifa” / “Bo‘sh”; client rows show the address and “N so‘rov” / “So‘rov yo‘q”; the filter button turns green while a role is chosen.
- [ ] Boards 1.21–1.21f and 1.24–1.24e: the team list has a search field and two underline tabs (Hammasi / Xodimlar); each row shows the avatar, name, phone and the task count with “vazifa” under it; the clients list has the tabs Hammasi / Jismoniy shaxs / Tashkilot and rows with phone and “N so‘rov” (or “So‘rov yo‘q”); every tab has its own empty state (tile, title, hint).

## 4. Logical/Business Test

- [ ] Role and switch filters apply to the loaded page locally; the search goes to the server (debounced); creating an account refreshes the list on return.
