# Worker UI (bottom tab bar) — Test Plan

A plan for an AI to execute against; nothing here is run unless the user asks.

## 1. API Test

- [ ] No endpoints of its own: the sections reuse the repositories of their features; see their plans.
- [ ] Auth error: an expired token on any section → 401 → the session is cleared and the router returns to sign-in.

## 2. Mobile/Web Integration Test

- [ ] Sign in as `jamshid` (worker): the floating bottom bar shows Asosiy, Vazifa, Chat (round green slot), Hisobot and Profil.
- [ ] Run on a real or emulated Android/iOS device with `AppConfig.useMockData = true` and again against the live API.

## 3. UI Test

- [ ] The bar floats 12 px from the sides and above the system gesture area; the selected tab has a tinted pill (the chat slot a larger tinted circle).
- [ ] The chat slot shows the unread counter as a red badge; the other tabs show their label.
- [ ] No overflow or clipping at a small phone width (320 px) and a tablet width (768 px); the five items stay equally wide.
- [ ] Light and dark themes both read correctly; Uzbek Latin, Uzbek Cyrillic and Russian render without missing keys.

## 4. Logical/Business Test

- [ ] Section state is kept when switching tabs (`IndexedStack`); every other screen opens above the shell with a Back chevron.
- [ ] Any screen can switch the selected tab through `homeTab` (0 home, 1 tasks, 2 chat, 3 reports, 4 profile).
- [ ] Signing out from the profile asks for confirmation, clears the session and resets the selected tab to home.
