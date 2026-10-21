# Data screens, long text, destructive actions & other style rules

## Pull-to-refresh on every data screen (HARD RULE)

Every screen (or tab body) whose content is fetched from a repository/network MUST support
swipe-to-refresh that re-triggers the load:

- Wrap the screen's scrollable in the project's refresh control (e.g. a themed `RefreshIndicator`)
  and re-fire the screen's load event in `onRefresh`, completing when the reload finishes.
- Give the scrollable `AlwaysScrollableScrollPhysics`, and keep the EMPTY state scrollable too
  (e.g. the empty view inside a `ListView`), so the gesture works even when content doesn't fill
  the viewport.
- Pushed detail screens that fetch their own model get the same treatment.

## Long text is clamped + expandable — never unbounded (HARD RULE)

Free/user text (descriptions, comments, notes) must never render unbounded:

- **In a list/grid item:** clamp to 1–2 lines per the design (3–5 on web/desktop) with ellipsis;
  the full text belongs to the detail/expanded surface (or make the item itself expandable when the
  design wants it readable in place).
- **In a screen body:** when the text can exceed ~80 words, render it through the shared
  expandable-text widget in `public/`: a collapsed preview (~4–6 lines) with an animated
  "read more" / "collapse" toggle; cap even the expanded view with a sane `maxLines` (e.g. ~40)
  so one field can never swallow the screen. Short text renders as a plain `Text`.
- **EVERY multi-line content text declares an explicit `maxLines` + overflow** (ellipsis/fade) —
  descriptions, info/explainer paragraphs, empty-state subtitles, dialog messages. "It's short
  today" is not an excuse: translations and real data grow (the 2×-length test), and a `Text`
  without `maxLines` is unbounded by definition. Only true single-word/number labels may skip it.
- **Fixed-width single-line labels must never overflow the row** — tab-bar labels, chips,
  segmented controls, buttons, stat cells: give the label a bounded parent (`Flexible`/`Expanded`)
  and either `maxLines: 1` + ellipsis or `FittedBox(fit: BoxFit.scaleDown)` (preferred where
  truncation would hide the meaning, e.g. equal-width tabs). A `Row` that renders a translated
  label at its natural size WILL overflow in some locale — that's a layout bug, not a copy bug.

## Free text never renders on a list card — the card gets a details dialog instead (HARD RULE)

A `description` / `note` / `comment` / free-form `reason` — any field a human TYPED rather than
picked — must NOT appear as a row on a list/grid card at all. Cards carry short, scannable FACTS
(status, name, dates, amounts, who, where). A free-text row is unbounded by nature, so it either
pushes the real facts below the fold or is clipped to a useless fragment, and it makes sibling
cards ragged heights for zero informational gain. Clamping it to 2 lines does NOT make it
acceptable on a card — the rule is that it is not there.

Where the free text goes instead:

- the item already has an **expandable in-place surface** (the card itself expands) or its own
  **detail SCREEN** → the full text lives there, through the expandable-text treatment above;
- **neither exists** → you MUST add a **full-details dialog for that item in the same change**.
  The card becomes tappable and opens the project's shared dialog, which lists EVERY field of the
  record — including the free text. Shipping a card that hides a description with no way to read
  it is an incomplete feature, not a design choice.

Rules for that dialog:

- It is feature-local → `presentation/dialogs/{item}_info_dialog.dart`, opened through the
  project's dialog helper (never a raw `showDialog`/`showModalBottomSheet`).
- It repeats the card's fields in the SAME order with the SAME labels, then adds the ones the card
  omits — the free text LAST, since it is the tallest and least scannable.
- The free text inside the dialog still declares `maxLines` + overflow and the dialog body scrolls;
  a long note must never push the close button off-screen.
- Empty free text → the row is omitted entirely, never an empty dangling label.
- The card keeps a visible affordance that it opens (chevron, ripple, or a "batafsil" hint). A
  tappable card with no affordance is a dead control.

## Destructive actions ALWAYS confirm first (HARD RULE)

Any action that ends, removes, or backs out of something the user has — cancelling a
subscription / tariff / membership / order / booking / session, leaving or unsubscribing,
stopping or pausing a service, deleting an item / record / account, logging out — MUST show the
project's shared warning/confirmation dialog BEFORE executing:

- The dialog names the consequence in one sentence ("your seat is released and given to someone
  else", "this cannot be undone"); the destructive choice is the primary button, the harmless
  back/dismiss is the secondary one.
- Only the explicit confirm runs the action; dismissing/backing out does nothing.
- Any follow-up input the flow needs (a cancellation reason, feedback) is asked AFTER the
  confirm — the input form is not a substitute for the warning.
- Use the shared dialog component + launcher (never a raw `AlertDialog`). A red/destructive-looking
  button is NOT a substitute for the confirm step.

## Other style rules

First detect how the project already does each of these, then match it — don't impose a tool the
project doesn't use.

- **Sizing:** inspect how the project sizes UI (a responsive system or direct values) and follow
  that same approach before writing any raw value.
- **Strings:** inspect how the project handles user-facing text (a localization layer or direct
  strings) and follow that same approach before hardcoding any text. In this project that means the
  `easy_localization` + `TrWords` constant rule (HARD RULE — see `project_conventions.md`): reference
  keys as `TrWords.x.tr()`, never as a raw `'x.y'.tr()` string literal.
- **Taps:** inspect the project's existing tap-feedback for interactive widgets and apply it
  consistently.
- **Units in input titles (HARD RULE):** every input/field whose value carries a unit or
  measurable dimension MUST state that unit in parentheses inside its title/label — e.g.
  `Duration (min)`, `Length (m)`, `Count (pcs)`, `Volume (l)`, `Weight (kg)`, `Price (UZS)`.
  The unit belongs in the TITLE (put it in the localized label string), not only inside the
  value text — so the field stays unambiguous and readable even when the value area is narrow.
- **Bottom safe-area inset on scrollables (HARD RULE):** any scrollable whose last item can
  reach the screen bottom MUST add the system inset to its BOTTOM padding —
  `MediaQuery.of(context).viewPadding.bottom` (or `.padding.bottom`) — on top of the design's
  base padding, so the final item is never hidden behind the Android gesture/navigation bar.
  Put the inset in the scroll view's own `padding` (e.g.
  `EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom)`), not a
  trailing `SizedBox` spacer. Exceptions: if a **pinned bottom bar or FAB** already covers that
  zone, the inset belongs on THAT widget (or the scroll's bottom padding = bar height + inset) —
  never double it; and a plain `SafeArea(bottom: true)` around the scroll is enough only when
  nothing is pinned below it. When a bottom bar is conditionally shown, the scroll's bottom
  padding must switch to include the inset in the state where the bar is absent.
