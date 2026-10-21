---
name: navigation-map
description: Keeps navigation discoverable — every new or changed screen is registered in the project's router(s) and written into the navigation map document in the SAME change. Use whenever a screen is created, renamed, moved or removed, when a route is added, or when asked "which screens exist / where does this screen live". Also holds the hard rule that on web every screen must have its own URL path.
---

# Navigation map & router registration

A screen that exists but is not routable, or is routable but not written down, is invisible work: the
next session re-creates it, links to it break, and nobody can answer "what screens does this app
have?" without reading every file.

This skill guarantees two things after **every** task that touches screens:

1. every screen is reachable through the project's router, and
2. the navigation map document lists it.

## Step 0 — Map this onto the project

Detect and record the project's real names; use them for the rest of the task:

- **Router file(s)** — where routes are declared. A project may have one (`app_router.dart`) or one
  per platform/target (e.g. a mobile router and a web router). Note all of them.
- **Routing package** — `go_router`, `auto_route`, plain `Navigator`, … Match what exists.
- **Navigation map document** — the markdown file listing every navigable screen (e.g.
  `NAVIGATION_MAP.md` next to the routers). **If it doesn't exist, create it** in the format below.
- **Which target a screen belongs to** — if the project splits mobile/web/desktop UI, a new screen is
  registered in that target's router, not all of them.

## The hard rules

### 1. A new screen is not done until it is routed

Any newly created screen is added to the matching router in the same change. No "I'll wire it up
later" — an unrouted screen is dead code.

### 2. The navigation map is updated in the same change

Whenever a screen is **added, renamed, moved or removed**, or its path changes, update the navigation
map document. It must list **all** navigable screens of the project. A map that lags the code is worse
than no map, because it is trusted and wrong.

### 3. On web, every screen must have its own URL (HARD RULE)

> On web, every screen navigation MUST be visible in the browser address bar.

Each route gets its own `path` (`/dashboard`, `/drivers`, `/settings`) so a user can deep-link
straight to it, reload without losing the screen, and use browser back/forward.

**Correct:**
```dart
GoRoute(
  path: '/items',
  builder: (context, state) => const ItemsScreen(),
),
```

**Wrong (navigation with no URL):**
```dart
// Don't push anonymous routes on web — the address bar never changes
Navigator.push(context, MaterialPageRoute(...));
```

Parameters belong in the path or query string (`/items/:id`, `/items?status=active`), not only in
`extra` — a URL that can't be typed by hand is not a URL. On mobile-only screens `Navigator.push` is
fine; this rule is about the web target.

### 4. Route names/paths are derived from the feature, not the widget

A route path names the domain section (`/items`, `/items/:id`), matching the feature folder. It never
carries widget-type suffixes (`/items_screen`, `/items_page`).

## Navigation map format

```markdown
# Navigation map — <app name>

Mobile screens (<mobile ui root>/)
 ├─ OnboardingScreen [Path: '/'] (onboarding/presentation/onboarding_screen.dart)
 ├─ LoginScreen [Path: '/login'] (auth/presentation/login_screen.dart)
 ...
 └─ Drawer (side-menu destinations)
     ├─ WalletScreen [Path: '/wallet'] (wallet/presentation/wallet_screen.dart)
 ...

Web screens (<web ui root>/)
 ├─ DashboardScreen [Path: '/dashboard'] (dashboard/presentation/dashboard_screen.dart)
 ...
```

Each row carries three facts: the **class name**, the **route path**, and the **file path** — that is
what makes the map usable without opening the code.

## Adding a new screen — the order

1. Create the feature folder in the correct UI root for its target, following the layout rules in the
   UI skill (`presentation/`, `bloc/`, `repository/`, the `{feature}.dart` barrel, the `test.md` +
   translation pair).
2. Build the screen widget.
3. Register the route in the matching router file — on web with its own URL path.
4. Add the row to the navigation map document.
5. Run the project's analyzer (e.g. `dart analyze` / `flutter analyze`) and confirm it is clean.

## Definition of done (checklist)

- [ ] Every screen created/renamed/moved/removed in this task is reflected in the matching router file
- [ ] The navigation map document was updated in the SAME change — class name, route path, file path
- [ ] On web, every route has its own address-bar URL; parameters are in the path/query, not only in `extra`
- [ ] Route paths name the domain, with no `_screen`/`_page`/`_view` suffix
- [ ] The analyzer runs clean
