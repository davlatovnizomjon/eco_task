---
name: style-governor
description: >-
  Governs WHERE every code-style / convention / structure / naming / formatting decision lives and
  keeps the codebase and the conventions in sync. Invoke whenever the user asks to change a coding
  style, convention, structure, naming, formatting, lint, or design rule ("always do X", "stop doing
  Y", "from now on", "rename", "move", "use Z instead"), OR whenever you notice code that conflicts
  with the skills/rules. Routes each change to its correct home — a shared skill, a project rule, or a
  marked exception — asks the user when the directive is missing/ambiguous/conflicting, and auto-fixes
  code or rules so they always agree (except in exception-marked paths). ALSO runs automatically on
  EVERY task that creates or modifies code — INCLUDING code ported/copied in from another project:
  before the task is reported done, every touched folder is swept for conformance with ALL
  skills/rules and violations are fixed (layout, feature/file/class names, bloc structure, barrels,
  shared widgets) — a modified folder must contain zero unmarked non-conforming code. Compiling
  cleanly is NOT conforming.
---

# style-governor — convention router & consistency enforcer

This skill makes one guarantee: **the code and the written conventions are always consistent.** Every
style/convention/structure decision has exactly one correct home, and when a decision changes, either
the convention is updated and the code is brought to match, or the code is corrected to the existing
convention — never left to drift.

It does **not** invent taste. It routes a decision to where it belongs and enforces it. When the
decision itself is unclear, it **asks the user** instead of guessing.

## Precedence (where conventions live, highest first)

```
<skills dir>/*            ← portable conventions (apply to other projects too)
                            (the project's skills folder: `skills/` or `.claude/skills/`)
CLAUDE.md                 ← the project's overriding instructions
.rules/*                  ← the project's detailed rules
.rules/exceptions.md      ← registry of paths intentionally exempt from a rule
```

These are the **expected standard files** — assume they exist and use them by name. A skill always wins
over `CLAUDE.md`, which wins over `.rules/`. If a given project does **not** have one of them yet,
**create it following this convention** (the missing skills dir, `CLAUDE.md`, `.rules/`, or
`.rules/exceptions.md`) instead of inventing a different layout — then route the change into the
freshly-created file.

> A project may add its own maintenance rules on TOP of this (e.g. "keep a translated copy of each
> skill"). Such rules are **project-specific** and live in `CLAUDE.md`/`.rules/`, not here — follow them
> only where they are written; never assume them in another project.

## The routing decision (run this on every style/convention request)

### Step 1 — Locate the existing convention

Search, in precedence order, for an existing rule covering the request: the shared skills under
the skills directory (incl. their `references/`), then `CLAUDE.md`, then `.rules/*`. Note every place it
is (or isn't) already specified.

### Step 2 — If unclear, ASK (do not guess)

Ask the user **before** changing anything when ANY of these holds:
- the directive is **not covered** by any skill/rule, and its intent is ambiguous;
- it **conflicts** with an existing higher-precedence rule (e.g. user asks for something a skill forbids);
- you **cannot tell whether it is portable or project-only** (Step 3);
- it would weaken a HARD RULE or a security/formatting guarantee.

Ask the smallest question that unblocks routing — e.g. "Is this a one-off for this screen, a
project-wide rule, or a convention for all your projects?" Never silently pick.

### Step 3 — Classify the change and route it

| The change is… | Home | Action |
|---|---|---|
| **Portable** — would apply to other projects too (state patterns, widget/structure conventions, enum usage, naming, file layout, formatting) | the relevant **shared skill** | Edit the matching skill in the skills directory. Large detail → a `references/*.md`. (If the project's own rules require translated skill copies, update those too — that's a project rule, not part of this skill.) |
| **Project-specific** — only meaningful in THIS project (encryption helpers, API endpoints/links, brand colors, this app's auth/passcode/business flows) | a **project rule** | Add/update a rule in `.rules/` (or `CLAUDE.md` if it's an overriding instruction) and apply it. |
| **Unique one-off** — an intentional divergence in ONE file/folder, used nowhere else and NOT meant to spread (a legacy screen kept as-is, a vendor file, generated code) | an **exception** | Register it (below). Do NOT touch skills/rules; do NOT propagate. |

When portable, the change goes to the skill **even if** only one file uses it today — the skill is the
source of truth, not the current call sites. When project-only, it goes to `.rules/`, never into a
shared skill (that would leak this project's specifics into other projects).

### Step 4 — Enforce consistency (auto-fix, then report)

After the convention is settled, make the whole codebase agree with it:
- **Sweep the repo** for code that now conflicts with the (new/updated) convention.
- **Auto-fix** it — change the code to match the convention, OR (if the user's intent was to keep the
  code and relax the rule) change the rule — so the two agree.
- **Skip exception-marked paths** (registry + inline marker, below).
- **Report** a short summary: what convention changed, where it now lives, which files were fixed, and
  any exceptions honored.

If a conflict genuinely cannot be auto-resolved (it needs a product decision), surface it explicitly
rather than leaving silent drift.

## Continuous conformance — every code change (HARD RULE)

The governor is NOT only for explicit style/convention requests. **Every task that creates or
modifies code ends with a conformance pass over every folder it touched — before the task is
reported done:**

1. **List the touched folders** — the folders containing every file created or edited in this task.
2. **Re-check them against ALL conventions** in precedence order (the shared skills incl. their
   `references/`, then `CLAUDE.md`, then `.rules/*`) — every file in the touched folder, not just the
   files you edited. HARD RULEs first (they are the most common silent misses), then structure,
   naming, and design rules.
3. **Fix every violation found** — or, if the divergence is intentional, register it as an exception
   (registry row + inline marker, below). A touched folder must contain **zero** unmarked
   non-conforming code when the task is reported done.
4. **State the result in the final report** — what the pass found and fixed, or that it was clean.

A violation you noticed but left unfixed and unreported is a governor failure — silence counts as
drift. If a fix is too large to do inline (it needs its own task), say so explicitly and list it as
known debt instead of staying quiet.

### IMPORTED / COPIED-IN code is held to the SAME standard (HARD RULE)

Code that arrives from **another project** — ported, copied, vendored, pasted by the user, or
generated from a reference implementation — is **new code in THIS repo** the moment it lands. The
conformance pass above applies to **every file of it**, not just the lines you edited to make it
compile. "It came from elsewhere and already worked" is NOT a reason to keep the source project's
layout, file names, class names, or bloc structure.

Getting an import to resolve and `analyze` to pass is **only step one**. Before the task is done,
run the pass over the imported tree and rewrite it into this repo's conventions:

- **Folder layout** — remap the source project's structure onto the folder map of the UI/feature
  skills (its `components/`, `views/`, `page_parts/` etc. become this repo's `widgets/`, `parts/`,
  `screens/`, `dialogs/`). Do NOT keep a foreign folder name just because the files came that way.
- **Feature & sub-feature names** — see the naming rule below.
- **Bloc/state-management shape** — file names, `part`/`part of` structure, state shape, error model
  and repository wiring all follow THIS repo's state-management skill, not the source's.
- **Barrels** — the imported feature and every sub-feature inside it get this repo's barrel form.
- **Shared widgets** — the source's shared widgets (app bar, buttons, sheets, empty/error views,
  pickers, progress bars) are replaced by this repo's equivalents; port a widget into `public/` only
  when nothing here fits.
- **Naming of screens/parts/widgets/dialogs** — apply this repo's naming rules to every class and
  file, including ones you never opened.
- **Test plans** — the imported feature and each of its sub-features get this repo's test-plan pair
  (`test.md` + its translation) at their root.
- **Dead branches** — features of the source app that do not apply here (a payment/unlock flow in a
  staff app, an export that needs an endpoint we don't have) are removed, and their removal is
  **stated in the report**, not silently dropped.

> The 2026-07 failure this rule exists for: a `health_page` feature was ported from a client app into
> a staff app. It compiled, analyzed clean and its tests passed — but it kept the source's
> `components/`, `views/`, `page_parts/` folders, `{feature}_bloc.dart` / `{feature}_event.dart` /
> `{feature}_state.dart` bloc files with no `part of`, a made-up `health_page_feature.dart` barrel,
> `*Page` class names, and no sub-feature barrels. None of that was reported. Compiling is not
> conforming — **run the pass on imported code before calling the task done.**

### Feature names describe the DOMAIN, not the widget type (HARD RULE)

A feature/sub-feature folder is named for **what the section is about**, not for what kind of Flutter
object sits in it. Strip `_page`, `_screen`, `_view`, `_widget`, `_form`, `_tab` from folder names —
those suffixes belong on the FILE/CLASS inside, never on the feature.

```
health/                      NOT health_page/        → barrel health.dart,  presentation/health_screen.dart  → HealthScreen
metrics/                     NOT metrics_page/       → barrel metrics.dart, presentation/metrics_screen.dart → MetricsScreen
health_detail/                                       → barrel health_detail.dart, presentation/health_detail_screen.dart
```

Consequences that follow from the name (all of them, together):

- The barrel is `{feature}.dart` — **exactly the folder name**. If that name looks "taken" by a file
  inside the feature, the FILE is misnamed (it needs its `_screen`/`_part`/`_dialog` suffix); never
  invent `{feature}_feature.dart`, `{feature}_index.dart`, `index.dart` or any other workaround.
- The entry screen is `presentation/{feature}_screen.dart` → `class {Feature}Screen`.
- Section files are `presentation/parts/{feature}_{section}_part.dart` → `class {Feature}{Section}Part`
  — a screen section is a *part*, not a "page"/"view".
- No class in a feature keeps a `Page` suffix: a pushed route is `…Screen`, a screen section is
  `…Part`, a bottom sheet/modal is `…Dialog`.

When a name is inherited from another project and breaks this, **rename it as part of the import** —
folder, barrel, files and classes together.

## Exceptions — registry + inline marker (both required)

A path is exempt from a rule only when BOTH exist:

1. **Registry row** in the exceptions registry (`.rules/exceptions.md`):

   ```
   | Path | Exempt from | Reason | Date |
   |------|-------------|--------|------|
   | path/to/legacy_screen | <skill-or-rule>:<short-name> | Legacy, frozen until redesign | YYYY-MM-DD |
   ```

2. **Inline marker** at the top of the exempt file (or the folder's barrel), in the file's comment
   syntax (`//` for Dart, `#` otherwise):

   ```dart
   // style-governor:exempt <skill-or-rule>:<short-name> — legacy, frozen until redesign
   ```

The Step-4 sweep **skips** any path that has both. A registry row without a marker (or vice-versa) is
NOT a valid exception — the governor will still enforce the rule there and flag the mismatch.

`<skill-or-rule>:<short-name>` identifies the convention, e.g. `ui-structure:screen-shell`,
`feature-wiring:bloc-file-names`, `design-system:theme-colors`.

## Worked examples

- **"Use Riverpod instead of Bloc."** Portable architecture decision → rewrite the state-management
  convention in the relevant feature-wiring skill: replace the Bloc/event/state structure with the
  Riverpod provider/notifier structure (file layout, naming, the state/error model).
  Then sweep the codebase and migrate every feature to the new pattern. Report files touched.
- **"Card numbers must be encrypted before saving."** Project-specific security behaviour → add a rule
  in `.rules/` (and note it in `CLAUDE.md`'s Security section if overriding), implement the helper, and
  sweep for raw card persistence. Does NOT go into a shared skill.
- **"Leave this one legacy screen on its hand-rolled layout."** Intentional one-off → add the registry
  row + the inline marker; the layout rule is enforced everywhere else but skips this file.
- **"Stop splitting widgets under N lines."** If this already IS a rule (a skill's efficiency rule), no
  change is needed — confirm it's covered and point the user at the existing rule.

## Anti-patterns (do NOT do these)

- **Guessing the route** when portability or intent is unclear — ASK (Step 2).
- **Applying a portable change only in code** (call sites) and not updating the owning skill — the next
  feature will re-introduce the old style.
- **Putting a project-only rule into a shared skill** — it leaks into other projects. (Maintenance
  habits like "keep a translated copy of every skill" are project rules → they live in `CLAUDE.md`/
  `.rules/`, never baked into a portable skill.)
- **Marking an exception with only a registry row or only an inline marker** — both are required.
- **Leaving the repo inconsistent** after a convention change — the sweep + auto-fix is mandatory.
- **Finishing a code task without the touched-folder conformance pass** — writing code and skipping
  the sweep is how drift enters; the pass is part of "done", not an optional extra.
- **Treating ported/copied-in code as "not my code"** — stopping at "it compiles and the tests pass"
  and leaving the source project's folders, file names, class names and bloc shape in place.
- **Naming a feature folder after a widget type** (`health_page/`, `profile_screen/`) and then
  inventing a barrel name (`health_page_feature.dart`) because `{feature}.dart` "was taken".

## Definition of done (checklist)

- [ ] The requested convention is located in the skills/instructions/rules (or its absence noted)
- [ ] Missing/ambiguous/conflicting/uncertain-scope → the user was asked before any change
- [ ] The change landed in its correct home: portable → shared skill (+ `references/` for large detail);
      project-only → `.rules/` (or `CLAUDE.md`); one-off → exception registry + inline marker
- [ ] Any missing standard file (the skills dir, `CLAUDE.md`, `.rules/`, `.rules/exceptions.md`) was created per this convention before routing into it
- [ ] Project-only maintenance rules (e.g. translated skill copies) were honored only as written in `CLAUDE.md`/`.rules/`, not assumed
- [ ] The repo was swept and brought into agreement (code or rule changed); exception-marked paths skipped
- [ ] Code-change tasks: every touched folder passed the conformance pass — checked against ALL skills/rules, violations fixed or exception-registered, result stated in the report
- [ ] IMPORTED/copied-in code (from another project, vendored, pasted): the WHOLE imported tree was rewritten to this repo's conventions — folder layout, feature/sub-feature names, file + class names, bloc file structure, barrels, shared widgets, the `test.md` + translation pair — not merely made to compile; dropped source features were named in the report
- [ ] No feature/sub-feature folder carries a widget-type suffix (`_page`/`_screen`/`_view`/`_widget`/`_form`/`_tab`); the barrel is exactly `{feature}.dart` (no `_feature`/`_index` workaround) and no class inside keeps a `Page` suffix
- [ ] A short report lists: the convention, its new home, files fixed, exceptions honored
