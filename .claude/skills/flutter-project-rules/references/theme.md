# Centralized theme (design tokens)

**All design values go through one shared theme — never hardcode colors, text styles, or decorations
in widgets.** Reference tokens like:
- `theme.primary`, `theme.cardColor`, `theme.line`, `theme.red`, ... — colors
- `theme.textStyle` and a typed text-theme (`titleLarge`, `bodyMedium`, ...) — typography
- `theme.cardDecor` and similar — reusable `BoxDecoration`s
- a `colors` palette object for the raw color set

Rules:
- Never use `Colors.grey`, raw hex, or inline `TextStyle(...)`/`BoxDecoration(...)` for design values.
- Reuse decorations (`theme.cardDecor`) instead of rebuilding the same `BoxDecoration` per widget.
- **Repeated text styles live on the theme, not inline AND not in a wrapper widget (HARD RULE).** The
  moment a `TextStyle(...)` (section label, card title, price, hint, …) is used in more than one place,
  it is a theme token — add it once (`theme.titleStyle`, `theme.textStyle`, the Material
  `textTheme.*`, …) and write `Text(s, style: theme.titleStyle)` at the call site. A recurring text
  style is **NEVER** a reason to create a widget: a `SectionLabel(text)` whose whole job is to apply a
  `TextStyle` is a failed extraction (its inline form `Text(s, style: theme.titleStyle)` is as short as
  the call `SectionLabel(s)`, so it saves nothing — see `references/efficiency.md`). Put the style on
  the theme and inline the `Text`; do not wrap it in a widget.
- **Repeated decorations live on the theme, not inline (HARD RULE).** The moment a `BoxDecoration`
  (card surface, elevated card, footer/bottom-bar shadow, …) appears in more than one place, it is a
  theme token — add it once (`theme.cardDecor`, `theme.cardDecorElevated`, `theme.cardShadow`,
  `theme.bottomBarShadow`, …) and reference it everywhere. Do NOT re-type
  `BoxDecoration(color: …white, borderRadius: …, boxShadow: […])` per widget — that is duplication.
  > General principle: **a recurring *visual value* (text style, color, decoration, radius, padding
  > preset) is a THEME TOKEN, not a widget.** Reach for the theme first; only build a widget when there
  > is real *structure/behaviour* to extract (and it passes the efficiency calculation).
- **Card/panel surfaces go through the shared `CardWidget`** (`public/widgets/card_widget.dart`),
  never a hand-rolled `Container(decoration: BoxDecoration(color: white, borderRadius: …))`.
  `CardWidget` takes its **default decoration from the theme** (`theme.cardDecor`) and stays flexible:
  `decoration` (full override), `radius`, `color`, `shadow`, `height`, `padding`, `onTap` — all
  optional overrides. A footer bar is `CardWidget(radius: 0, shadow: theme.bottomBarShadow, …)`; a flat
  panel is just `CardWidget(child: …)`. (`ExpansionTile`-based collapsible cards use `shape`, not a
  wrapping `Container`, so they stay as-is.)
- **If the project has no shared theme, create one at `lib/<ui-root>/public/theme/`** — e.g.
  `public/theme/app_theme.dart` exposing a global `theme` instance plus a `colors` palette
  (`public/theme/colors.dart`) — and route every token through it. Then use those tokens everywhere.
