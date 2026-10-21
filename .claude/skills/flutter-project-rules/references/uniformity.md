# Sibling uniformity — siblings match in SIZE, DESIGN and MOTION by default (HARD RULE)

Widgets laid out together along a main axis (a `Row`/`Column`, or a scrollable list of items) are
read as **one group**, so by default they must be uniform in **three** ways — cross-axis size, visual
design, and animation — unless the user asks otherwise or the design clearly shows otherwise.

## 1. Cross-axis SIZE

They should match on the **cross axis** — the one perpendicular to how the widgets are arranged:

- **Row** (main axis horizontal) → children share the same **height**. **Prefer content-driven
  equality over a hardcoded number:** wrap the row in `IntrinsicHeight` + `CrossAxisAlignment.stretch`
  so every child grows to the tallest sibling's *natural* height (let the content-rich item set the
  height via its own text + padding; the others — icon buttons, etc. — stretch to match). Do **not**
  declare a shared size variable/constant and pass it to every child to force equality — that is a
  magic number divorced from the content. A taller child must never leave a sibling shorter. Two
  cards/buttons side by side must not differ in height.
- **Column** (main axis vertical) → children share the same **width** (usually full width via
  `CrossAxisAlignment.stretch`, or one explicit equal width).
- **Horizontally scrollable** (`ListView`/`Row` scrolling sideways) → every item shares the same
  **height**.
- **Vertically scrollable** (`ListView`/`Column` scrolling down) → every item shares the same
  **width**.

Rule of thumb: the dimension **along** the scroll/main axis may vary per item; the dimension
**across** it must be uniform. Equal-sized tiles read as one control group; mismatched ones look
broken.

**How to VERIFY equality (do this, don't eyeball a number):** when an item is a `Column`/`Row` of
several widgets, its cross-axis extent is the **sum of its children's extents plus their spacing and
padding** — add them up and compare against the sibling's. (e.g. a tile = `vertical padding` +
`text line height` must equal the neighbour's total.) If you can't make the sums match by reasoning,
let the framework do it: `IntrinsicHeight`/`IntrinsicWidth` + `stretch` guarantees equality without
any literal.

**When the design or the user explicitly wants different cross-axis sizes** (a 2/3 + 1/3 split, a
hero item, intentionally staggered tiles), follow that — uniformity is the default, not a
straitjacket. When a layout plausibly needs non-uniform cross-axis sizes and it isn't obvious from
the design, **ASK** which sizing is wanted (e.g. match a shared component's size vs. size by the
row) instead of guessing.

> Size violation caught 2026-06 (`activity_table_screen._FilterBar`): a left filter icon button at
> `padding: EdgeInsets.all(8.r)` (~44.r tall) sat in the same Row as `_FilterDropdown`s fixed at
> `height: 48.h` — visibly mismatched heights. The **wrong** fix (also rejected) was to declare a
> shared height variable and pass it to every child — a magic number unrelated to the content. The
> **right** fix: `IntrinsicHeight` + `CrossAxisAlignment.stretch` on the row; the dropdown sets its
> height from its own text + vertical padding, and the icon button stretches to match — no literal
> height anywhere.

## 2. DESIGN (visual treatment)

Siblings in the same row/list must share the **same design language** — the same surface
(background/decoration via the same `theme.cardDecor`/`CardWidget`/border token), the same corner
radius, the same padding rhythm, and — critically — the **same way they express STATE**. If one item
shows its active/selected state as a colored **border**, every sibling must show active/selected the
**same way** (a border too) — never a colored **fill** on one and a border on another. Route the
shared decoration through one place (a `theme.*` token, a shared `CardWidget`, or a single local
`BoxDecoration _xDecor(bool active)` helper used by every item) so the look — and the active state —
is defined once and applied identically.

> Design violation caught 2026-06 (same `_FilterBar`): the filter icon button signalled "active"
> with a `theme.primary` 15% background **fill**, while the dropdown cards signalled "selected" with a
> `theme.primary` **border** — two different state languages in one row. Fix: one shared surface
> (`theme.cardColor` + a `Border.all` that turns `theme.primary` when active) used by the icon button
> AND the dropdowns, so every item looks and reacts identically.

## 3. MOTION (animation)

If row/list items animate (tap bounce, selection scale, color/elevation transition, entrance
stagger), **every sibling uses the SAME animation** — same trigger, curve, duration, and magnitude.
Don't bounce one tile on tap and leave its neighbour static, or fade one in over 200ms and another
over 500ms. Define the motion once (a shared wrapper/helper or shared duration/curve tokens) and
apply it to all of them. Differing motion between siblings is as broken as differing size or design.
