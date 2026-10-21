# Feature test plan — `{feature}/test.md`

Every feature gets a **`test.md` file at its root** (next to the feature barrel `{feature}.dart`),
written as prose/checklists **for an AI to execute against** — it is a test PLAN, not test source code.
It records everything that must be verified for that feature's repository, bloc, and UI so a later
session (or a different AI) can write and run the actual tests (`integration_test`, widget tests, an API
script) without re-deriving what "fully tested" means for this feature. When the user asks to test a
feature, read that feature's `test.md` first and drive the work from it. Update it whenever the
feature's endpoints, states, or screens change — a stale plan is worse than none.

## Run this plan ONLY when the user asks (HARD RULE)

Writing/updating `test.md` + `test_uz.md` is part of building a feature. **Executing anything is not.**

After a change the user did not ask you to verify, you run **NOTHING** "to be safe": no
`flutter test` (neither the whole suite nor one file), no `flutter analyze`, no API sweep, no app
launch, no UI driving. Each of those costs the user minutes of waiting and is pure noise when they
only wanted the code changed. Make the edit, say what you changed, stop.

Execute when, and only when, the user explicitly asks — "testla", "test qil", "tekshirib chiq",
"analyze qil", "ishlayaptimi?", or a direct question about whether something works live. The request
sets the scope: a request about one screen means that screen, not the whole repo. One run per
request; no "let me just re-check" repeats after a fix.

Still yours without being asked, because it is part of writing the code: **updating** the tests your
edit invalidates and **updating** the plan files. Leave them unexecuted and name them in one line so
the user can run them when they choose. If a change truly cannot be trusted without a run, offer it
in one sentence and wait for the answer instead of starting it.

## The four required sections (HARD RULE — none may be skipped)

`test.md` has exactly four top-level sections, in this order. A feature isn't done until all four exist
with concrete, feature-specific content — not the placeholders shown here.

### 1. API test

One subsection per repository method/endpoint. For each:
- **Success path** — the exact request (params/body) and what a correct response looks like; assert the
  parsed model matches it.
- **Auth error** — call with a missing/expired/invalid token → assert the exact failure type (e.g.
  `UnAuthorizedResponse`/401) and any message shown.
- **Parameter error** — call with a missing/invalid/wrong-type parameter → assert the backend's error
  shape AND the exact error `message`/`description` text, not just "it fails".
- **Format validation** — every formatted field this feature writes (phone, date, money, etc.): assert
  the backend rejects out-of-format values (wrong phone shape, non-ISO date, letters in a numeric field)
  and record the returned error message. Cover this for both create AND update calls, not only reads.
- **Value correctness — check the NUMBERS, not just the status code (HARD RULE, most-missed step).**
  A 200 with a well-shaped body proves nothing about whether the value is *right*. For every field the
  screen actually SHOWS — a balance, a total, a count, a remaining-days figure, a date range, a status
  badge — assert the value itself, across the WHOLE dataset the endpoint can return, not one lucky
  record. Four checks, each of which has caught a real bug in this repo:
  * **Cross-source agreement.** When the same fact arrives from two endpoints, fetch BOTH and diff them
    per record. (Real example: the clients list sends `balans` while
    `get-balance-transaction` sends `end_balance` — they disagreed for 15 of 18 clients with 1C data,
    so the detail screen and the payment screen printed two different balances for the same person.
    Nothing about either response looked wrong on its own.)
  * **Arithmetic identity.** Any response carrying a start/end/total/turnover set must reconcile:
    `start + income − expense == end`, `sum(pages) == meta.total`, `sum(per-branch counts) == overall
    count`. Compute it in the test; never eyeball it.
  * **Parameters must actually CHANGE the result.** For every filter/range/sort/scope parameter the app
    sends, issue the same request twice with different values and assert the result differs in the way
    it should — and that a value which should exclude everything (a 1990 range, a nonexistent guid)
    really returns nothing. A parameter that is accepted (200, no validation error) but silently
    ignored is worse than a rejected one: the screen then renders a filtered heading over unfiltered
    data. Prove per-record scoping too (three different ids → three different bodies), or the endpoint
    may just be answering from the token owner.
  * **Domain plausibility.** Sanity-check against reality: dates ordered (`start <= end`), no future
    date on a past event, a "remaining days" count matching `until − today`, a status label agreeing
    with the dates beside it, no placeholder text leaking through (`<Объект не найден>`, `null`,
    `01.01.2000`), and no duplicated/self-contradicting records.
  Record every disagreement with the exact numbers and the record it came from — "balance is wrong" is
  not a finding, "client X: list `balans`=3 180, `end_balance`=3 544 240" is.

### 2. Mobile/Web integration test

The full vertical for this feature — model parsing → repository call → real/mocked HTTP response → bloc
state transitions → UI render — exercised together with **zero unhandled errors** at any layer. Record:
- Which flows must be driven end-to-end (list load, create, edit, delete, pagination, filters — whatever
  this feature actually has).
- That the run happens on a **real or emulated Android/iOS device** (or a real browser for a web target)
  — not only `flutter test` in isolation. Note any required test account/data setup.

### 3. UI test

- **Overflow/clipping** — check at least a small-phone width and a tablet/large width; note any text or
  row/column prone to `RenderFlex` overflow (long names, long numbers, long localized strings).
- **Design conformance** — spacing, color, and component usage matching the design (link the Figma/
  `UI-SPEC` for this feature if one exists).
- **Navigation** — every entry/exit route for this feature (push/pop, deep links, back-stack behavior)
  goes where intended.
- **Animations** — any transition/loading animation this feature has runs without jank or dropped
  frames.

### 4. Logical/business test

Domain-logic bugs that pass every type check but are still wrong. For each scenario, name where the fix
belongs and how it's verified:
- **Flutter-side logical error** (an impossible input the UI should block/validate — a nonexistent date,
  an invalid age, a negative quantity) → reproduce by **running the app** and driving the exact input.
- **Backend-side logical error** (double-booking/over-selling one item to multiple buyers, a time
  conflict — one person joining two overlapping sessions, or creating two overlapping bookings) →
  reproduce with an **API test** (concurrent/conflicting requests) and assert the backend rejects it
  with the correct error, never a silent double-write.

## Template

```markdown
# {Feature} — Test Plan

## 1. API Test
### {method/endpoint} — {HTTP verb} {path}
- [ ] Success: request → expected result
- [ ] Auth error: no/expired token → expected failure + message
- [ ] Param error: {field} missing/invalid → expected message
- [ ] Format: {phone/date/...} wrong format rejected → expected message
- [ ] Values: {field} cross-checked against {other endpoint} for ALL records — expected {N}/{N} agree
- [ ] Identity: {start + income − expense == end / sum(pages) == total} holds for every record
- [ ] {param} really changes the result: {value A} → {n}, {value B} → {m}, {impossible value} → 0
- [ ] Plausibility: dates ordered, counts match the calendar, no placeholder/duplicate rows
(repeat per endpoint, including create/update)

## 2. Mobile/Web Integration Test
- [ ] {flow, e.g. "list loads and paginates"} — model → repository → bloc → UI, no errors
- [ ] {flow, e.g. "create item"} — same, including cache/optimistic update
- [ ] Run on real/emulated device (Android/iOS) or browser: {which}

## 3. UI Test
- [ ] No overflow/clipping at {sizes}
- [ ] Matches design: {spacing/colors/components}
- [ ] Navigation: {routes} behave correctly
- [ ] Animations: {which} run without jank

## 4. Logical/Business Test
- [ ] {scenario} — flutter-side, reproduced by running the app: {steps}
- [ ] {scenario} — backend-side, reproduced via API test: {steps}
```

## The Uzbek pair — `test_uz.md` (HARD RULE)

Every `test.md` ships with an Uzbek translation beside it:

```
[feature_name]/test.md      # English — the source of truth
[feature_name]/test_uz.md   # Uzbek translation of the same file
```

Never write or update `test.md` without writing/updating `test_uz.md` in the same change. The
translation mirrors the original **1:1** — same headings, same order, same checklist items, same
`[ ]`/`[x]` states. It is a translation, not a summary; nothing may be dropped, added, or reordered.
Leave untranslated: code identifiers, class/method names, file paths, endpoints, HTTP verbs, JSON keys,
error-type names, and quoted UI strings that are already Uzbek. Only prose, headings, and explanatory
notes are translated (Uzbek Latin).

## Keeping it current

Update `test.md` **and `test_uz.md`** in the same change that touches the feature's endpoints, states, or screens. When the
user later asks to test the feature — and only then, see the rule at the top — use this file as the
source of truth: write/run the API checks (§1, values included), drive the full vertical on a
device/browser (§2), verify layout/navigation/animation (§3), and chase the logical scenarios (§4)
through whichever side (app run or API) they belong to.

A live snapshot goes stale fast. Keep a dated status table at the end of the plan (endpoint → what it
actually returned → the measured numbers) and **re-measure it on every test run instead of trusting the
last one** — a backend that worked last week can return an empty dataset today, and a defect recorded
as open can already be fixed. Mark each recorded defect as fixed/still-open with the date it was last
re-checked.
