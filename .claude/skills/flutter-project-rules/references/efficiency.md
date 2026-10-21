# Extraction efficiency — when a widget/function is allowed to exist

The rules that decide whether a chunk of UI may become its own widget, helper function, or
wrapper — and when an existing one must be deleted and inlined. A construct must EARN its keep:
it must either be genuinely reused or produce a real net reduction in code. Read this BEFORE
extracting anything, and apply it to existing helpers you touch.

## Efficiency calculation — REQUIRED before extracting any widget/function (HARD RULE)

Before you turn a chunk of UI into its own named widget/function (or keep an existing one), **do the math
and only extract when it is net-negative on total lines.** Extracting always has a fixed overhead — the
class/function declaration, fields, constructor, `build` signature, the import at each call site — and a
single-use extraction almost never pays that back. `contract_save_bar.dart` was the textbook failure: a
35-line widget whose `build` was ~14 lines, used in **one** place, replacing ~10 inline lines with an
~6-line call — it *added* ~25 lines net and an extra build layer for zero reuse. Don't create those.

Compute it explicitly:

```
overhead   = lines of the widget/function DEFINITION that are pure scaffolding
             (class line + fields + constructor + build signature + closing braces + its imports)
             — typically ~15–22 lines for a widget, ~3–6 for a helper function.
inlineCost = lines the UI occupies when written inline at ONE call site
callCost   = lines the call expression occupies (e.g. `const FooBar(a: 1, b: 2)`)
N          = number of DISTINCT call sites that will actually use it

netSaved   = N * (inlineCost - callCost) - overhead
```

- **Hard floor: ≥ 24 lines of real UI — for standalone widgets AND private helper functions.** If
  the `build`/returned-UI body is under 24 lines, extraction is presumed inefficient — the
  scaffolding (class/function signature + fields + constructor + closing braces + import) outweighs
  the UI. An 8-line `build` (like the old `ContractSectionLabel`) is a clear violation; so is a
  7-line private `Widget _card(children) => CardWidget(...)` helper. Under 24 lines, write the UI
  **inline at the call site** (a private `Widget _section()` helper is NOT an escape under 24
  lines), or — if it's just a recurring style/decoration — make it a **theme token** (see
  `references/theme.md`). The 24-line floor is necessary, not sufficient: still run `netSaved` below.
- **Extract only if `netSaved` is comfortably positive** (rule of thumb: it should save **> ~2×** the
  extracted UI's own size).
- **N = 1 → NEVER extract — not into a widget, not into a private helper.** With one call site
  `N*(inlineCost-callCost)` is tiny and `overhead` dominates → `netSaved` is negative; a
  single-use helper also just hides the UI one hop away. Write it inline in `build`. (Private
  `Widget _section()` helpers exist only for N ≥ 2 AND ≥ 24 UI lines AND ≥ 80% density — see the
  UI-density test below. The only single-use split allowed is `parts/` when `build` > 360 lines.)
- **A single-use "body" / "content" / "assembler" part that only arranges other parts or widgets in a
  `Column`/`ListView` is STILL a banned N = 1 split — inline it into the screen's `build`.** Merely
  *composing* children does NOT earn a `parts/` file: the `parts/` exception fires only when the
  SCREEN'S OWN `build` UI would otherwise exceed 360 lines — count the assembler's OWN lines (the
  `ListView` + its children calls), NOT the combined size of the leaf parts it references. A thin
  `ClientDetailBodyPart` whose whole `build` is
  `ListView(children: [HeaderPart(), Gap(), TariffPart(), Gap(), MenuPart()])` (~15 lines, used once)
  adds a build layer + an import for zero reuse — delete it and put the `ListView` DIRECTLY in the
  screen's `build`. The heavy leaf parts it assembled (Header/Tariff/Menu) stay split, because
  inlining ALL of *them* into the screen WOULD exceed 360 lines — that is what justifies THOSE splits,
  not the assembler.
- **List / grid ITEM widgets: extract the per-row item to `presentation/widgets/` when its built UI
  exceeds 32 lines.** When the UI going on screen is a LIST — a `ListView`/`GridView`(`.builder`/`.count`)
  or a `Column`/`Wrap` of repeated items — you MUST inspect the widget built for ONE item (the
  `itemBuilder` body, or the repeated child). If that item's returned UI is **> 32 lines**, pull it into
  its own widget at `presentation/widgets/{name}_item.dart` (`{Name}Item`) **— the `presentation/widgets/`
  of the SAME (sub-)feature whose screen renders the list, NEVER a parent feature's.** A widget used only
  by a nested sub-feature's screen (e.g. `client_detail`'s menu grid) belongs in that SUB-FEATURE's own
  `client_detail/presentation/widgets/`, NOT the parent `clients/presentation/widgets/`. **Only if a
  SECOND screen in ANOTHER feature uses the same item, move it to `public/widgets/` instead.** A list item
  is inherently multi-instance (N = many at runtime), so this item extraction is exempt from the N = 1 ban. **THEN re-run the efficiency math on
  what REMAINS:** a now-thin, single-use "list section" (the item-data list + the `ListView`/`GridView`
  that just delegates to the extracted item widget) usually no longer earns its OWN `parts/` file — inline
  it into the screen's `build` (per the assembler rule above). If the item's UI is ≤ 32 lines, keep it
  inline in the builder — do not extract.
  > Worked example (a `client_detail_menu_part`): the part was a `GridView.builder` whose
  > `itemBuilder` returned a ~48-line card → extract that card to `presentation/widgets/client_menu_item.dart`
  > (`ClientMenuItem`). What's left (the 8-item data + a `GridView` of `ClientMenuItem`s) is a thin
  > single-use section → the `parts/` file is DELETED and the `GridView` inlined into the detail screen's
  > `build`. Net: one reusable item widget + a few inline lines, instead of a whole part.
- **The only thing that overrides a negative `netSaved` is genuine cross-screen reuse** (the widget
  belongs in `public/` and will be used by other features) **or** the widget **adds real behaviour/state**
  (then it's not a pure extraction — see the no-alias rule). Visual taste / "it feels cleaner" does NOT
  override the math.

**This is the same principle as the no-alias rule below** — both forbid creating a named construct that
doesn't earn its keep. The no-alias rule kills constructs that add *no behaviour*; the efficiency
calculation kills constructs that add *no net code savings*. A construct must pass **both** to exist.

**When you find an existing widget/function that fails this (single-use, thin, no behaviour) — delete it
and inline it at its call site as part of your change, then optimize/format the result.** Leaving it is
not neutral: it is standing duplication that costs every reader an extra file to open.

## NO alias / passthrough wrappers (HARD RULE — applies to classes AND functions)

**Never create a new widget, class, or function whose body just forwards to an existing one under a
different name.** A wrapper that adds no real behaviour — it only renames, re-defaults, or relabels an
existing widget/function — is a duplicate. It bloats the tree with an extra build layer, hides the real
component from readers, fragments the API into two names for one thing, and tanks efficiency. This is
exactly as forbidden for **functions** (a `myShowSheet(...)` that just calls `showBottomDialog(...)`) as
for **widgets**.

A construct is a banned passthrough when **all** of these hold — delete it and call the real thing
directly at every call site:
- its `build`/body is essentially a single `return ExistingThing(...)` (or a thin forward), and
- it introduces **no new state, layout, branching, or composition** of its own, and
- every parameter it takes maps 1:1 onto the thing it forwards to.

> Concrete example of the violation (do NOT do this): a `ContractPickerTile` whose entire `build` is
> `return TileWidget.dropdown(title:…, isSelected:…, onTap:…, onClear:…, leftIcon: SvgPicture.asset(icon,…))`.
> That is just `TileWidget.dropdown` wearing a feature-specific name. Use `TileWidget.dropdown`
> directly at the call sites and pass the `leftIcon` inline; do not keep the alias.

**Allowed (these are NOT passthroughs):**
- A **named constructor / factory variant ON the real widget itself** that bakes in a preset
  (e.g. `Btn.unActive`, `TileWidget.dropdown`, `InputBox.search`). The variant lives on the same
  class and is the *canonical* way to get that preset — it does not create a second, differently-named
  type. Prefer this over a wrapper whenever you need a "preset" of an existing widget.
- A widget/function that **genuinely composes or adds behaviour**: owns state, arranges multiple
  children, adds branching/validation, or wires events — i.e. it does something the wrapped thing
  doesn't. (Caveat: "arranges multiple children" only means it is not a *passthrough* — it does NOT
  exempt a single-use assembler from the N = 1 efficiency ban above. A `Column`/`ListView` of a few
  child widgets used in ONE place is still inlined into the caller's `build`.)

Decision rule when you catch yourself about to wrap: if the goal is "the same widget with some values
pre-filled", add a **named constructor/factory on the original** (or just pass the values at the call
site). Only create a brand-new named type/function when it adds behaviour the original lacks.

## Shared-widget presets live in FACTORY VARIANTS — never in local wrapper helpers (HARD RULE)

Recurring rows/tiles/fields go through the `public/` shared widget **directly at every call site** —
including static label+value info rows (`TileWidget.grayTitle`). One canonical widget per UI pattern
is the efficiency goal: a single place defines the look, every screen renders it identically, and a
change propagates everywhere from one file.

- **NEVER wrap a shared widget in a private `Widget _row()` / `_tile()` / `_field()` helper inside a
  screen/part/feature.** Even when the helper adds small conveniences (a `null → '---'` fallback, a
  conditional style), it is an alias layer: it hides the real widget from the reader, forks the API
  into a local dialect, and adds an indirection every reader must open. This is the function-form of
  the no-alias rule above, and the `netSaved` math is NOT an escape hatch for it — a local wrapper
  around a `public/` widget is banned regardless of line counts. Call the factory variant directly:
  > The 2026-06 violation (do NOT repeat): `contract_info_part.dart` had a private
  > `_row(label, value, {icon, highlight})` whose whole body was `return TileWidget.grayTitle(...)`.
  > Banned. Correct form: `TileWidget.grayTitle(icon: …, title: …, subtitle: …)` written directly at
  > each of the 16 row call sites.
- **Recurring preset args belong INSIDE the factory variant — not repeated at call sites, not in a
  local wrapper.** If every call site would repeat the same icon styling / padding / decoration,
  move that preset into the named factory on the shared widget (e.g. `TileWidget.grayTitle` takes
  `IconData? icon` and applies the standard gray 18.sp leading icon itself, and defaults to its
  flat-row padding) — the factory on the real widget is the canonical preset location (see
  "Allowed" in the no-alias rule). This keeps call sites down to the per-row facts:
  `TileWidget.grayTitle(icon: Icons.apartment_rounded, title: TrKeys.branch.tr(), subtitle: _fmtText(v))`.
- **Pure VALUE formatting is separate from widgets:** `null/empty → '---'`, date/number/money
  formatting live in small `static String _fmtX(...)` helpers in the file or in the project's
  formatters folder — value helpers are fine and encouraged; WIDGET-returning wrappers around
  a shared widget are not.
- Scope note: the efficiency calculation above governs extracting NEW custom UI (raw
  `Row`/`Column`/`Container` compositions — a private `Widget _section()` of raw UI is allowed
  only per the UI-density test below: ≥ 24 UI lines AND ≥ 80% density). Wrapping an EXISTING
  shared widget is governed by this rule + the no-alias rule: always banned.

## UI-density test — ≥ 2 call sites, ≥ 24 UI lines AND ≥ 80% density for ANY widget-returning helper (HARD RULE)

A private `Widget _x(...)` helper function is allowed only when **ALL THREE** hold:

1. **It has ≥ 2 call sites.** A helper used in ONE place is ALWAYS inefficient — regardless of its
   size or density: it occupies extra lines (signature + braces + the call) and hides the UI one
   hop away from where it renders. Inline it at its single call site.
   > Worked examples (`contract_info_part.dart`): `_statusBadge` — a ~93%-dense, 26-line-UI
   > builder, but used ONCE → inlined into `build`; same for the single-use `_expandableCard`
   > (its `final shape` local simply moved into `build`). The ONLY sanctioned single-use split is
   > the `parts/` file split when a screen's `build` UI exceeds 360 lines.
2. **Its returned UI widget tree is ≥ 24 lines.** A few-lines function returning a single widget is
   pure waste — write that widget inline at the call site instead.
   > Worked example (the `_card` violation): a 7-line
   > `Widget _card(List<Widget> children) => CardWidget(width: …, padding: …, child: Column(children))`
   > — banned. The fix: delete it and write `CardWidget(…)` directly at each call site.
3. **uiDensity ≥ 80%**, measured explicitly:

```
uiDensity = lines of the returned UI widget tree
          ÷ TOTAL lines of the function (signature + params + logic + comments + blank lines)
```

- A dense block of real UI passes — e.g. a raw `Row`/`Column` tree of ~27 lines inside a 29-line
  function = ~93%, efficient.
- **Failing either condition → the helper is BANNED — delete it and inline.** The function is
  mostly scaffolding (parameter re-declarations, branching, doc comments) per line of UI.
  > Worked example (the `_row` violation): the returned UI was ~8 lines while the whole function
  > was 20 lines (6-line signature, doc comment, a conditional-style ternary) → 8/20 = **40% →
  > inefficient**. The fix: delete the helper and write `TileWidget.grayTitle(...)` directly at
  > every call site.
- A helper that forwards to ONE shared widget almost always fails both conditions — its "UI" is a
  single call expression and everything else is signature/logic. That is exactly why shared-widget
  wrappers are banned outright by the rule above; this test is the measurable form of it.
- **Logic lines count as scaffolding, NOT as UI** — a ternary computing a style, a `null → '---'`
  fallback, a date format. Move value logic into `static String _fmtX()` helpers and style/icon
  presets into the shared widget's factory variant, then re-measure: if what remains is a bare
  forward, inline it.
- Apply the test to EXISTING helpers you touch too: failing → inline/replace as part of the
  change.
