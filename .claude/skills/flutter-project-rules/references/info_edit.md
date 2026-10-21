# Data-entry (info edit / create form) screens — validation & error display

Rules for ANY screen where the user enters or edits information (a create/edit form, a profile
editor, a checkout form, ...). The goal: the user always sees **where** the error is and **what**
the first problem is, in the app's own error design — never a silently ignored tap, never a wall
of dialogs.

## Required-field validation on submit (HARD RULE)

1. **Nothing turns red before the first submit attempt.** While the user is still filling the
   form, fields stay in their normal design. Validation feedback appears only after the
   submit/save button is pressed (a `showErrors`-style flag flips in state on the first failed
   submit and stays on).

2. **On submit, validate EVERY required field at once** — do not stop at the first failure.
   The result of a failed submit is:
   - **The FIRST invalid field's error message (in visual/form order) is shown in the app's
     shared error dialog** (the same dialog used for API errors — e.g. a typed
     `MessageErrorResponse` routed through the shared `showScreenResponse`-style helper). One
     dialog only — never one dialog per field.
   - **Every invalid field is SIMULTANEOUSLY marked in the app's error color** (the shared
     `theme` error token — e.g. `theme.red`): text inputs show the shared input's built-in error
     state (red outline + error text under the field); tap/picker fields and selection cards get
     the SAME red outline style. All siblings express the error the same way (see the sibling
     uniformity rule in SKILL.md).
   - The submit is blocked — no request is sent while any required field is invalid.

3. **Errors clear per field, immediately.** As soon as the user fixes a field (types a
   character, picks a value), THAT field's red mark and error text disappear — without waiting
   for the next submit. Other still-invalid fields stay red. (Compute each field's error as
   `showErrors && <field is invalid>` so this falls out naturally.)

4. **The error message for each field is short and field-specific** ("Enter the name",
   "Pick a date", "Enter the description") and localized like all other copy. The dialog shows
   the FIRST field's message; the inline text under an input repeats that field's own message.

5. **Where validation lives:** required-field checks run in the state layer (bloc/cubit) on the
   submit event — the UI only renders `showErrors` + per-field invalid flags. Server-side /
   business validation errors (from the repository/API) keep going through the shared error
   dialog as usual.

## Field design in the error state

- Use the SAME error visual everywhere: the shared input's error border color/width is the
  canonical style — tap fields, picker cards, and chip/selection cards reuse it (a
  `Border.all(color: theme.red)` on their existing decoration), never a different color or a
  filled red background.
- A field whose value can never be empty by construction (a counter with a minimum, a
  pre-selected enum chip row, a time that always has a value) is NOT a required-field check —
  do not add dead validation for it.

## Worked example (create form)

Form order: name → category → date → description (uz) → description (ru); all required.
User taps Save with everything empty:

- Dialog: "Enter the name" (the FIRST invalid field, via the shared error dialog).
- Simultaneously: name, category and date fields get the red outline; both description inputs
  get the red outline + "Enter the description" under them.
- User picks a name → the name field's red clears instantly; the rest stay red.
- Next Save tap: dialog now shows "Pick a category" (the new first invalid field), and so on
  until the form passes and the request is sent.
