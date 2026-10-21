# Admin UI (left menu) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

- [ ] No endpoints of its own: the sections reuse the repositories of their features (`pages/dashboard`, `pages/tasks`, `pages/chat`, `pages/calendar`, `pages/reports`, `pages/team`, `pages/expenses`); see their plans.
- [ ] Auth error: an expired token on any section → 401 → the session is cleared and the router returns to sign-in.

## 2. Mobile/Web Integration Test

- [ ] Sign in as `jamshid` (owner): the left menu shows Home, Tasks, Chat, Calendar, Reports, Team, Expenses, Profile.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] The menu button on every section's app bar opens the left drawer; its header shows the account avatar, name and role; the selected section is highlighted.
- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); long names and translated strings truncate with an ellipsis.
- [ ] Light and dark themes both read correctly; Uzbek Latin, Uzbek Cyrillic and Russian render without missing keys.
- [ ] Unread badges on the menu entries follow the repositories' counters.

## 4. Logical/Business Test

- [ ] Section state is kept when switching sections (`IndexedStack`); pushed entries (menu items with a route) open as screens with a Back button.
- [ ] The profile section shows the account card, settings and sign-out; signing out asks for confirmation, clears the session and resets the selected section.
