---
name: flutter-project-rules
description: >-
  The project-wide Flutter code rules — they apply to EVERY file in the project, not only UI.
  Use whenever creating/modifying anything in lib/: a screen, page, widget, dialog, list/grid item,
  model, enum, repository or bloc. Covers: comments on every declaration, in English
  (references/comments.md); where each piece of UI lives (shared widgets in public/, screen-local
  widgets/dialogs/parts under presentation/) so nothing is duplicated and screens stay small;
  when extracting a widget actually pays off (references/efficiency.md — efficiency math, no
  alias/passthrough wrappers, UI-density test); centralized theme tokens (references/theme.md);
  sibling uniformity in size, design and motion (references/uniformity.md); data-screen rules —
  pull-to-refresh, clamped/expandable text, destructive-action confirmation, safe-area insets
  (references/data_screens.md); form validation / error display (references/info_edit.md); and the
  `test.md` + `test_uz.md` test-plan pair every feature keeps at its root.
---

# Flutter Project Rules — correctness, readability & reuse

A blocking convention for **the whole project**. It is NOT merely a file-structure guide — it is
the set of rules for writing project code **correctly**, so that any file is understandable at a
glance and easy to read, review and verify. The goal: **every declaration explained by a comment,
no duplicated UI code, small screens, a single source of truth for shared widgets, all design
tokens routed through a central theme, and UI behaviour (validation, feedback, motion) expressed
the same way everywhere.**

State management (bloc ⇄ repository wiring for every page, dialog and widget) lives in the
companion **`flutter-ui-bloc`** skill.

## References — read the one that matches your task (HARD RULES live there too)

| File | Read it when… |
|------|---------------|
| `references/comments.md` | Writing or editing ANY file — the comment rules: English only, a comment on EVERY class/enum/value/method/field/variable, kept as short as possible (1–2 lines) |
| `references/efficiency.md` | BEFORE extracting/keeping ANY widget or helper function — the efficiency calculation, the 24-line floor, N=1 ban, no-alias/passthrough rule, factory-variant rule, UI-density test |
| `references/theme.md` | Touching any color / text style / decoration — centralized theme tokens, repeated style/decoration → theme token, `CardWidget` surfaces |
| `references/uniformity.md` | Laying out siblings in a Row/Column/list — matching size, design language and motion |
| `references/data_screens.md` | A screen that loads data or shows long text — pull-to-refresh, clamped/expandable text, destructive-action confirms, units in titles, safe-area insets |
| `references/info_edit.md` | A screen where the user ENTERS information — required-field validation, first-error dialog + red fields, per-field clearing |
| `references/project_conventions.md` | Recording (or reading) the CURRENT project's resolved Step-0 names — the template every project fills in once, then applies directly |

## Comments — on every declaration, in English (HARD RULE)

Comments are project-wide, not UI-only: **every class, enum (and every enum value), constructor,
method, function, field, getter, top-level constant and variable carries a comment** — private
members included. A class/function comment states what it does and how it is used; a variable
comment states what it holds and what it is used for. Comments are written in **English only** and
kept **as short as possible — 1–2 lines is the target**; there is no hard cap, but a longer comment
must earn its length. Restating the identifier, narrating past bugs, section dividers and
commented-out code stay banned.

Full rules, the per-declaration table, examples and the sweep checklist → **`references/comments.md`**.
Read it before commenting any file.

## Step 0 — Adapt to the project (do this first)

1. **Read project docs if present** (optional, improves accuracy): look for `CLAUDE.md`, a `rules/`,
   `docs/`, `.planning/`, or design-system markdown. If found, read them to learn project-specific
   tokens, paths, and naming. If absent, rely entirely on the conventions in this skill.
2. **Detect the UI root** — the folder that holds screens. Common roots: `lib/ui/`,
   `lib/presentation/`, `lib/features/`, `lib/screens/`. Use whatever the project already uses; call
   it `<ui-root>` below. If extending existing code, match the base path of the file you're in.
3. **Detect the shared theme** — find a central theme object (e.g. a global `theme` instance and a
   `colors` palette). If none exists, you will create one (see `references/theme.md`).

## Folder map

```
lib/<ui-root>/public/               # APP-WIDE shared UI (used in many places)
├── widgets/                        # buttons, dropdowns, inputs, chips, cards, ...
├── dialogs/                        # common dialogs
└── theme/                          # shared theme + color palette (create if missing)

lib/<ui-root>/pages/{role}/         # (when the app has per-role UIs) ONLY shared `auth/` + one folder per role; the role folder
                                    # holds main/ (shell), <role>_routes.dart and its own copy of every feature it uses,
                                    # laid out as {feature} below (roles never import each other)
lib/<ui-root>/pages/{feature}/      # (or features/{feature}/, screens/{feature}/)
├── bloc/ | cubit/ | controller/    # state management
├── model/
├── repository/
├── {feature}.dart                  # THE feature barrel — named after the feature folder (see below)
├── test.md                         # the feature's test PLAN (see below) — REQUIRED
├── test_uz.md                      # its translation — REQUIRED, always written in the same change
└── presentation/
    ├── {feature}_screen.dart       # the screen itself — keep it SMALL
    ├── parts/                      # screen split into sections (when screen > 360 lines)
    ├── widgets/                    # screen-local reusable widgets (list/grid items, repeats)
    ├── dialogs/                    # screen-LOCAL dialogs (used only by this feature)
    └── screens/{sub_feature}/      # a self-contained SUB-FEATURE — SAME layout as a feature
        ├── bloc/ | cubit/          #   (its own state management)
        ├── model/ | repository/    #   (only if it owns them; else it reuses the parent's)
        ├── {sub_feature}.dart      #   its OWN barrel
        ├── test.md                 #   its OWN test plan …
        ├── test_uz.md              #   … and its translation
        └── presentation/           #   ALL of its UI lives here too — NEVER at the sub-feature root
            ├── {sub_feature}_screen.dart
            ├── parts/
            └── widgets/ | dialogs/
```

**What counts as a feature (or sub-feature).** Any folder that owns its **own state management**
(`bloc/` / `cubit/` / `controller/`) and/or its **own `model/` / `repository/`** alongside a
screen is a self-contained feature — INCLUDING nested ones like a detail/form screen under
`presentation/screens/`. Example: `clients/presentation/screens/client_detail/` has its own `bloc/`
and screen → it is a sub-feature, so it follows the SAME layout (its screen + `parts/` go under its
OWN `presentation/`, never at the sub-feature root) and gets its OWN barrel just like the parent.

**Barrels — exactly ONE per feature, at that feature's root, named `{feature}.dart`** (the same name
as the feature folder — NOT `{feature}_index.dart`, NOT `index.dart`). E.g. `clients/clients.dart`,
`client_detail/client_detail.dart`. It re-exports that feature's public API — `bloc` (which
re-exports its event/state/repository), `model/`s + `enum/`s (file-by-file), `repository`, and the
main + secondary `screen`s — and outside code imports only it. A parent feature's barrel also
re-exports each sub-feature's barrel.
**Never create per-subfolder barrels:** `presentation/widgets/`, `presentation/parts/`, and `model/`
get NO `*_widgets.dart` / `*_parts.dart` / `*_models.dart` aggregator. Widgets and parts are
feature-internal — import them DIRECTLY by relative path where used.
(App-wide aggregators such as an assets or components index keep their existing `_index` names —
those are shared aggregators, not feature barrels.)

## Feature test plan — `test.md` + `test_uz.md` at the feature root (HARD RULE)

Every feature AND sub-feature keeps a test PLAN at its root, next to its barrel — as a **pair**:

```
{feature}/test.md      # source of truth
{feature}/test_uz.md   # its translation — 1:1 mirror
```

It is prose/checklists for an AI to execute against (a test PLAN, not test source code) with four
sections in order: **1. API test, 2. Mobile/Web integration test, 3. UI test, 4. Logical/business
test**. Full structure and a copyable template live in the state-management skill
(`flutter-ui-bloc/references/test.md`).

What this skill adds on top, because it is UI work that most often breaks the plan:

- **Creating a screen creates/updates the plan.** A new screen, a new navigation path, a new dialog
  or a new empty/error state is a change to section 3 (UI test) and usually section 2 — write it in
  the same change, never "later".
- **The pair is atomic.** Never write or update `test.md` without writing/updating `test_uz.md` in
  the same change. A `test.md` with no `test_uz.md` beside it is an incomplete feature.
- **`test_uz.md` mirrors `test.md` 1:1** — same headings, same order, same checklist items, same
  `[ ]` / `[x]` states. A translation, not a summary: nothing dropped, added or reordered. Keep code
  identifiers, class/method names, file paths, endpoints, HTTP verbs, JSON keys and error-type names
  untranslated; translate only prose, headings and notes.
- **A pushed sub-screen that owns its own state gets its OWN pair**, at the sub-feature root — it is
  not covered by the parent's plan.
- A stale plan is worse than none: if you changed a screen and left the plan untouched, the feature
  is not done.

## Decision procedure — extract ONLY when it pays off (do not over-split)

Splitting is justified by **reuse** or by a **real reduction in code size** — never by taste.
Default to leaving UI inline in `build()`. Run these steps in order:

1. **Reused across screens?** If a widget is (or will be) used in more than one screen, make it a
   shared component in `public/widgets/` (or `public/dialogs/`) and use it everywhere. If a fitting
   one doesn't exist yet, CREATE it in `public/` — never inline a one-off copy.
2. **Duplicated within THIS screen?** Extract a chunk into `presentation/widgets/` **only if it
   passes the efficiency calculation in `references/efficiency.md`** (it removes real duplication
   and the net line count drops). This test also governs **list/grid items**, with one concrete
   threshold: when the on-screen UI is a LIST (`ListView`/`GridView`/repeated `Column`), inspect the
   per-item widget the builder returns — if that item's UI is **> 32 lines**, extract it to
   `presentation/widgets/{name}_item.dart` (→ `public/widgets/` if a second screen uses it), THEN
   re-run the efficiency math on what remains (the thin list section usually inlines into the screen).
   If the item is ≤ 32 lines, leave it inline. (Size alone never forces extraction otherwise.)
   **A screen-local widget always lands in the `presentation/widgets/` of the SAME (sub-)feature whose
   screen uses it — a nested sub-feature's widget goes in the SUB-FEATURE's own `presentation/widgets/`
   (e.g. `client_detail/presentation/widgets/`), never a parent feature's `presentation/widgets/`.**
   Move to `public/widgets/` only when a screen in ANOTHER feature reuses it (Step 1).
3. **Parts (`presentation/parts/`) — only when `build` is genuinely huge.** Do NOT split a screen
   into `parts/` unless the UI code inside `build` exceeds **360 lines**. Under that, keep all
   sections inline in `build` (or as small private `Widget _section()` methods at most — which must
   themselves pass the UI-density test in `references/efficiency.md`).
4. **Dialogs** — app-wide → `public/dialogs/`; feature-local → `presentation/dialogs/`. Extract a
   dialog into its own widget **only if its UI (the widget tree inside `build`) is more than 20
   lines**; a short dialog body stays inline at its call site.

If none apply, the UI stays inline in `build()`.

**Every extraction decision — including keeping an existing widget/helper you touch — must pass
`references/efficiency.md` (efficiency math + no-alias rule + UI-density test).** Single-use, thin,
or passthrough constructs get deleted and inlined as part of your change.

## Reuse before you create

Before writing a new shared widget, **search `lib/<ui-root>/public/` first** and reuse what exists.
Typical shared building blocks a mature project has (create them in `public/` if missing and you need
them more than once):
- A primary/secondary button (e.g. `Btn`, `Btn.unActive`)
- A general dialog + dialog icon (e.g. `PublicDialog`, `DialogIcon`)
- Dialog launchers / helpers (e.g. `showCenterDialog`, `showBottomDialog`)
- Inputs, dropdowns, empty/loading/error states

Only add a new public widget when nothing fits. And when a public widget fits, call it **directly**
at every call site — never through a local wrapper helper (see the factory-variant rule in
`references/efficiency.md`).

## Naming

- Screen: `{feature}_screen.dart` → `class {Feature}Screen`
- Screen part: `{feature}_{section}_part.dart` → `class {Feature}{Section}Part`
- Local widget: `{name}_item.dart` / `{name}_widget.dart` → `class {Name}Item`
- Local dialog: `{name}_dialog.dart` → `class {Name}Dialog`
- Shared widget: descriptive, no feature prefix (e.g. `app_dropdown.dart` → `AppDropdown`)

## Worked example

Building a "Projects" screen with a header, a filter dropdown, and a list of project cards:

1. **Filter dropdown** — generic, reusable app-wide → `public/widgets/app_dropdown.dart`
   (`AppDropdown`). Reuse everywhere.
2. **Project card** — list item, repeated per row, passes the efficiency math →
   `.../projects/presentation/widgets/project_card.dart` (`ProjectCard`).
3. **"Delete project?" confirm dialog** — only used here →
   `.../projects/presentation/dialogs/delete_project_dialog.dart`. (If reused across features, move
   it to `public/dialogs/` instead.)
4. Screen grows past 360 lines → split header + body into `.../presentation/parts/` and let
   `projects_screen.dart` just compose them.

Result — `projects_screen.dart`:
```dart
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.background,           // centralized theme token
      appBar: AppBar(title: Text(Tr.projects.tr())),
      body: SafeArea(
        child: Column(
          children: const [
            ProjectsHeaderPart(),                   // parts/
            Expanded(child: ProjectsBodyPart()),    // parts/ → uses ProjectCard from widgets/
          ],
        ),
      ),
    );
  }
}
```

## Definition of done (checklist)

- [ ] Comments (`references/comments.md`): EVERY class, enum + every enum value, constructor, method/function (private included), field, getter, top-level constant and local variable in every file you created or touched has a comment; class/function comments state what it does and how it is used, variable comments state what it holds and what it is for; all in English and as short as possible (1–2 lines typical); no restatement, no history narration, no dividers, no commented-out code, nothing stale
- [ ] Every feature AND sub-feature (a nested folder owning its own `bloc/`/`model/`/`repository/`, e.g. a `screens/{detail}/`) has EXACTLY ONE barrel — `{feature}.dart`, named after the feature folder (NOT `_index.dart`), at that feature's root, exporting bloc + model + enum + repository + screens; the parent barrel re-exports each sub-feature barrel. `widgets/`, `parts/`, `model/` get NO barrel — imported directly by relative path
- [ ] NOT over-split: a chunk is extracted to `presentation/widgets/` only when it's reused or the extraction saves >~2× its size (same test for list/grid items) — otherwise left inline
- [ ] `references/efficiency.md` applied to EVERY extraction (created or touched): efficiency math (`netSaved` positive, `build` ≥ 24 lines, N ≥ 2), no alias/passthrough wrappers (presets go on the real widget as factory variants), shared widgets called DIRECTLY at every call site (no private `_row`/`_tile` wrappers), UI-density test passed for every private `Widget _x()` helper — failures deleted + inlined
- [ ] Recurring visual values are THEME TOKENS, not widgets (`references/theme.md`): a repeated `TextStyle` → `theme.titleStyle`/`textTheme.*` inline; a repeated `BoxDecoration`/color/radius → a `theme.*` token; card/panel surfaces via the shared `CardWidget`; all design values via central `theme.*`/`colors.*` (created in `public/theme/` if absent)
- [ ] No `parts/` split unless the `build` UI exceeds 360 lines; a dialog is its own widget only if its `build` UI is > 20 lines
- [ ] Reused-across-screens widgets live in `public/{widgets,dialogs}` and are imported, not re-implemented (create in `public/` if missing); inputs/buttons/dropdowns use the project's shared components
- [ ] Dialogs & sheets go through the project's dialog helpers; confirm/error dialogs use the shared dialog — no raw `showDialog`/`AlertDialog`/`showModalBottomSheet`; dialogs routed: app-wide → `public/dialogs/`, feature-local → `presentation/dialogs/`
- [ ] Sibling uniformity (`references/uniformity.md`): row/column/list siblings match in cross-axis size (IntrinsicHeight/stretch, no magic numbers), design language (same surface + same state expression), and motion (same animation trigger/curve/duration)
- [ ] Every destructive action (cancel/stop/leave/delete/logout/unsubscribe) shows the shared confirmation dialog first; follow-up input (e.g. reason) comes after the confirm (`references/data_screens.md`)
- [ ] Every data-loading screen (incl. pushed details) has swipe-to-refresh: themed refresh control, `AlwaysScrollableScrollPhysics`, a scrollable EMPTY state, `onRefresh` re-fires the load (`references/data_screens.md`)
- [ ] NO free-text field (`description`/`note`/`comment`/free-form `reason`) is rendered on a list/grid card at all; if the item has neither an expandable in-place surface nor a detail screen, a feature-local full-details dialog was added IN THIS CHANGE (all fields, free text last, scrollable body) and the card carries a visible tap affordance (`references/data_screens.md`)
- [ ] No unbounded free text: list items clamp with ellipsis; long body text goes through the shared expandable-text widget; EVERY multi-line content text has explicit `maxLines` + overflow; fixed-width single-line labels sit in a bounded parent with ellipsis or `FittedBox(scaleDown)` — nothing overflows at 2× text length (`references/data_screens.md`)
- [ ] Scrollables clear the system nav bar: bottom padding includes `MediaQuery.viewPadding.bottom` (or a pinned bottom bar/FAB carries the inset, never doubled) (`references/data_screens.md`)
- [ ] Sizes via the project's responsive system; strings via its localization — HARD RULE: every key referenced through the project's key-constant class (e.g. `TrKeys.x.tr()`), NEVER a raw string-literal key (`'x.y'.tr()`); new keys added to that class + every translation JSON the project ships, first (`references/project_conventions.md`); every input title carrying a unit states it in parentheses (`Duration (min)`, `Price (sum)`, …)
- [ ] HARD RULE: every money/phone/date is formatted via the project's formatters — both on input and on display; raw `num`/phone/ISO-date is never shown, and separators are stripped before hitting the API
- [ ] Every feature AND sub-feature you created or whose UI you changed has BOTH `test.md` and `test_uz.md` at its root, updated in THIS change: the four sections present (API, mobile/web integration, UI, logical/business), new screens/navigation paths/dialogs/empty states written into the UI section, and `test_uz.md` a 1:1 mirror (same headings, order, items, `[ ]`/`[x]` states) with identifiers/paths/endpoints left untranslated
- [ ] Data-entry/form screens follow `references/info_edit.md`: nothing red before the first submit; on a failed submit the FIRST invalid field's message shows in the shared error dialog while ALL invalid fields turn the theme error color; each field's error clears the moment it is fixed
