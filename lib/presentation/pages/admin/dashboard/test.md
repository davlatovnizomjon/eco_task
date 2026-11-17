# Dashboard (admin home)

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

### `ReportsRepository.getDashboard` — GET `dashboard`

- [ ] Success: the request as admin → 200 with counts, `dueToday` and `team`; the parsed model matches the payload.
- [ ] Values: `pendingNew` + `pendingClient` equal the number of not yet started tasks, split by whether a client created them.
- [ ] Auth error: missing/expired token → 401 → `UnAuthorizedResponse`; the session is cleared and the router returns to sign-in.
- [ ] Values: `dueToday` is sorted by deadline and contains only open tasks due today or earlier.
- [ ] Companion calls of the same load: `GET reports?period=week` (weekly card), `GET tasks?who=<me>&status=new,prog` (my tasks stack), `GET users` for staff and for clients (head counts, `total`); one failing call keeps the cached summary and shows the error dialog.
- [ ] Cached-first: reopening the screen shows the cached summary immediately (no loading flicker), then the fresh data replaces it.
- [ ] Mock/live parity: the same calls pass against `MockDioClient` and the live API (`AppConfig.useMockData`), with identical models and error shapes.

## 2. Mobile/Web Integration Test

- [ ] Open the dashboard, pull to refresh, tap the avatar (opens the profile tab), the bell (opens notifications), the employees and clients cards, the weekly card (opens the reports tab), the “Rating” link, the “All” link, both “Tasdiq kutmoqda” rows (open the tasks tab) and every “+” of an empty block (opens the new-task form); each lands on the right screen.
- [ ] On a new company, the three first-step rows open the staff form, the client form and the new-task form.
- [ ] Swipe vertically on the “my tasks” stack: the front card changes and the dots on the right follow; tapping a card opens its details.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; switching the theme in the profile repaints this screen without losing its state.
- [ ] Uzbek Latin, Uzbek Cyrillic and Russian all render without missing keys or layout breaks.
- [ ] The design matches the `Eco Tasks — mobile app` board of this screen 1:1 (sizes, colors, radii, icons) in light and dark themes.
- [ ] Skeleton shimmer while the first load runs.
- [ ] Empty blocks (board 1.5): no own tasks → “Sizda vazifa yo‘q” card with a “+”; a week without tasks → gray ring, `0` and the hint, no chevron; nobody completed a task → “Hali reyting yo‘q” card and no “Reyting” link; nothing due today → “Bugunga vazifa yo‘q” card with a “+” and no “Hammasi” link.
- [ ] New company (board 1.4): no staff but the admin, no clients, no tasks → greeting “Xush kelibsiz,”, the centred “Hali hech narsa yo‘q” block and the three “Ishni boshlang” rows.
- [ ] Weekly card: the donut arcs follow done / in progress / overdue / failed in that order and the legend numbers match them.
- [ ] “Tasdiq kutmoqda” is drawn only when at least one of its two counters is above zero; a zero counter hides its red badge.
- [ ] The bell badge follows the unread counter; the bottom tab bar does not cover the last row (bottom inset is part of the scroll padding).

## 4. Logical/Business Test

- [ ] After creating or closing a task elsewhere, returning to the dashboard shows updated numbers (cache invalidated).
- [ ] The best employee is the one with the most completed tasks this week and has at least one; the ring shows done / total as a percent; overdue tasks show an amber alarm marker and “N kun kech”, the rest show their time.
