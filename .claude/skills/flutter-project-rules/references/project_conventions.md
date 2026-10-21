# Resolved project conventions — the Step-0 record

This file is a **template plus the default answers**. Step 0 of the skill asks you to detect the
project's UI root, theme, shared widgets, localization and formatters; **write the answers down here
once**, then apply them directly on every UI task instead of re-deriving them.

Rules below are written with placeholders — `<ui-root>`, `<theme>`, `<TrKeys>`, `<ScreenShell>` — and
with **example** names in parentheses. Replace every placeholder with the current project's real
name; where the project has no equivalent yet, create one following the shape described here. Never
copy another project's names in: a name only belongs in this file after you have confirmed it exists
in THIS repo.

> Keep this file honest. When a convention below stops matching the code, one of the two is wrong —
> fix it, don't leave both.

## Layout

- **UI root:** `<ui-root>` (e.g. `lib/presentation/`). Feature folders live under
  `<ui-root>/pages/{feature}/` (or `features/`, `screens/` — whatever the project already uses).
- **Feature layout is NESTED under `presentation/`** — non-negotiable. A sub-feature under a feature
  goes to `<ui-root>/pages/{feature}/presentation/screens/{subfeature}/` and is laid out exactly as:
  ```
  {subfeature}/
  ├── bloc/            (bloc.dart, event.dart, state.dart — FIXED names, part/of; see flutter-ui-bloc)
  ├── model/
  ├── repository/
  ├── {subfeature}.dart                 # THE feature barrel — named after the folder (bloc + model + enum + screens + repository)
  ├── test.md                           # the sub-feature's own test plan
  ├── test_uz.md                        # its 1:1 translation — written in the same change
  └── presentation/                     # ALL UI goes here — never at the feature root
      ├── {subfeature}_screen.dart      # main screen, ≤ 360 lines
      ├── screens/{nested}/             # a NESTED sub-feature — same layout, its OWN {nested}.dart barrel
      ├── parts/                        # screen sections when a screen > 360 lines
      ├── widgets/                      # list items, tiles, fields, repeated blocks
      └── dialogs/                      # feature-local dialogs and bottom sheets
  ```
  > Pre-existing folders that put UI at the feature root predate this rule — **do not copy their
  > structure.** Follow the layout above and record the repo's best current example here.
- **A nested screen folder is its OWN feature when it owns state/data.** Any folder under
  `presentation/screens/` that has its own `bloc/` (`cubit/`) and/or `model/` / `repository/` — e.g. a
  detail screen under a list feature — is a self-contained sub-feature: same layout, its own barrel,
  its own `test.md` + `test_uz.md`. Don't treat it as a loose screen of the parent.
- **Barrels: exactly ONE per feature, at that feature's root, named `{feature}.dart`** — the SAME name
  as the feature folder, NOT `{feature}_index.dart` and NOT `index.dart`. It re-exports the feature's
  PUBLIC API: the `bloc` (which itself re-exports its `event`/`state`/`repository`), the `model/`s and
  `enum/`s (exported file-by-file), the `repository`, and the main + secondary `screen`s. A parent
  feature's barrel ALSO re-exports each nested sub-feature's `{nested}.dart` barrel. Outside consumers
  import ONLY the `{feature}.dart` barrel.
  - **Do NOT create per-subfolder barrels.** `presentation/widgets/`, `presentation/parts/`, and
    `model/` never get their own `*_widgets.dart` / `*_parts.dart` / `*_models.dart` aggregator.
    Widgets and parts are feature-INTERNAL implementation details — import them DIRECTLY by relative
    path at their (few, in-feature) call sites; they are not part of the feature's public surface.
    Models/enums are listed individually in `{feature}.dart`, not behind a `model/` barrel.
  - Project-wide aggregators (an assets index, a components index) are the only exception — those are
    shared, app-wide barrels keeping their existing `_index` names, not feature barrels.
- **Test plans:** every feature and sub-feature root carries `test.md` **and** `test_uz.md`, written
  and updated together. See the skill's "Feature test plan" section.

## Theme tokens

- **Every color, text style and decoration goes through the single global theme object `<theme>`**
  (e.g. a global `theme` instance in `<ui-root>/public/theme/`). Record its import path here.
- Record the token names the project actually exposes — colors (`primary`, `background`, `cardColor`,
  `divider`, `red`, `grayText`, …), decorations (`cardDecor`), and text styles (`cardTitle`,
  `cardSubtitle`, `badgeText`, `fieldLabel`, plus the Material `textTheme.*`).
- **Never hardcode hex or `Colors.*` shades** for design values.
- **If a needed token is missing, ADD it to `<theme>`** — never fall back to a second, parallel
  palette. If the repo still has a legacy palette next to the real one, name it here explicitly as
  banned so nobody reintroduces it.
- Repeated **decorations** and **text styles** live on `<theme>` too — write them inline at the call
  site (`Text(s, style: <theme>.cardSubtitle)`; size differs → `.copyWith(fontSize: …)`); never wrap a
  recurring style in a one-purpose widget.

## Shared building blocks

- **Sizing:** the project's responsive system (e.g. `flutter_screenutil` — `.w .h .r .sp` on every
  dimension). Record which, and where it is exported from.
- **Icons:** the project's icon constants rendered the project's way (e.g. `AppIcons.*` SVGs via
  `SvgPicture.asset`).
- **Shared widgets live in `<ui-root>/public/` — REUSE them, never re-implement, and CREATE a new one
  there if nothing fits (do not inline a one-off instead).** Search `public/` first. Record the real
  inventory here, e.g.:
  - `public/widgets/`: the primary/secondary button (+ its inactive variant), the text field (+ its
    search variant), the dropdown field, the universal tile (card / dropdown / flat label→value info
    row — the ONLY way to render static info rows, called DIRECTLY at each call site, never via a
    local `_row` wrapper), the card/panel surface, the dialog icon, the screen shell + app bar.
    Use these for buttons / inputs / dropdowns / tiles / cards — do NOT hand-roll a `TextField`, a
    `Container` button, a `DropdownButton`, or a `Container(decoration: BoxDecoration(...))` card in a
    feature.
  - `public/dialogs/`: the standard titled dialog (active/unActive buttons) and the shared pickers.
  - Any older shared-components folder: list what is still current and mark what is LEGACY, so new or
    touched screens migrate off it.
  - A generic widget you build for a feature that could serve others → put it in `public/`, not in the
    feature's `widgets/`.
- **Every screen wraps its content in the shared screen shell `<ScreenShell>` — never a hand-rolled
  `Scaffold` + `AppBar` in feature code (HARD RULE).** The shell composes focus-dismissal + `Scaffold`
  + the shared app bar (centered title, back arrow, actions with a trailing gap), killing the
  duplicated boilerplate on every pushed screen.
  - Params to record: `title` (required), `child` (required), `actions`, `showBack: false` for
    root/tab screens, `resizeToAvoidBottomInset`.
  - `padding` — body padding with a project default. Pass `EdgeInsets.zero` when the child is a scroll
    view carrying its own padding (so content scrolls edge-to-edge).
  - `bottomBar` — the footer save-button bar, rendered as `Scaffold.bottomNavigationBar` (a card
    surface with the project's bottom-bar shadow wrapping `SafeArea(top: false, child: <button>)`).
    Do NOT build a `Stack` + `Positioned` footer inside the body.
  - Back behaviour: the default back button should call `Navigator.maybePop`, so a screen's `PopScope`
    (exit-confirm dialog, returning a result on pop) keeps working WITHOUT passing `onBack`; pass
    `onBack` only for fully custom handling. Use the app bar standalone only when a custom `Scaffold`
    is unavoidable.

## Dialogs & bottom sheets

- **They go through the project's dialog helpers — never raw `showDialog` / `showModalBottomSheet` /
  `AlertDialog` in feature code.** Record the helper names and their file (e.g. a
  `showCenterDialog(widget, context)` and a `showBottomDialog(widget, context, {title})` that render
  the drag handle, optional title, padding and safe area for you).
- Confirm / info / error dialogs → build the shared dialog widget (set its inactive/active button
  texts and callbacks; it pops itself) and show it via the centered helper. Do not write a bespoke
  `AlertDialog`.
- API/validation failures are shown via the single failure presenter (see `flutter-ui-bloc`),
  which itself wraps the shared dialog — do not build your own error dialog.
- **File location (HARD RULE):** a dialog/bottom-sheet content widget lives in a `dialogs/` folder,
  never in `widgets/`. A **bottom sheet is a dialog** — anything opened via the bottom/centered
  helpers or `showModalBottomSheet` counts. Feature-local ones go under the feature's
  `presentation/dialogs/`; app-wide ones under `<ui-root>/public/dialogs/`. Reusable non-dialog UI
  still goes in `widgets/`.

## Strings (HARD RULE) — keys go through a constant, NEVER a raw string literal

Every user-facing string is localized, and the translation key is **always** referenced through the
project's key-constant class `<TrKeys>` (record its class name and file). Write
`<TrKeys>.clientsTitle.tr()`; **never** `'clients.title'.tr()`. This applies everywhere a key is used:
widgets, enum `title`/label getters, repository return messages, dialogs — no exceptions.

- Before referencing a new key, FIRST add it to `<TrKeys>` (a `static const` whose name is the
  camelCase of the dotted key, e.g. `clients.no_transactions_desc` → `clientsNoTransactionsDesc`) and
  add the key to **every** translation JSON the project ships (record the list, e.g.
  `assets/translations/{uz,ru,en}.json`). Then reference only the constant.
- `.tr()` still runs on the constant (`<TrKeys>.clientsAge.tr(args: [...])`), so `args`/`namedArgs`
  work unchanged.
- Import just the key-constant file, not the whole constants barrel — pulling the barrel in only for a
  key re-exports icons etc. and causes `ambiguous_import`.
- Record which language the app's user-facing copy is written in.

## Formatted values are MANDATORY (HARD RULE) — never show a raw number/phone/date

Every money/amount, phone, and date — whether **typed into an input** or **rendered as text** — MUST go
through the project's formatters folder (record its path, e.g. `lib/utils/formatters/`). Never display
a bare `num`, a raw local-format phone, or an ISO date.

- **Money / sum / price:** display with thousand separators via the project's price formatter/
  extension. For **text inputs**, attach the thousands-separator input formatter +
  `FilteringTextInputFormatter.digitsOnly`, and strip separators (or parse digits only) before sending
  to the API. Edit-prefill must also be pre-formatted.
- **Phone:** display via the phone formatter's display function and input via its input formatter;
  send the raw (unformatted) value to the API.
- **Date / time:** format via the project's date formatter or `intl`'s `DateFormat` — never show the
  raw API string.
- If a fitting formatter doesn't exist, ADD it in the formatters folder and reuse it — do not inline
  ad-hoc formatting at the call site.
