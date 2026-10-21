# Comments — English, on EVERY declaration, as short as possible

Comments are part of the code, not decoration. Someone reading this project must be able to open any
file and learn, from the comments alone, **what each thing is, what it is for, and how it is used** —
without reverse-engineering the body.

So the rule here is coverage plus brevity: **every declaration carries a comment**, and that comment
is **as short as it can be while still answering the question — 1–2 lines is the target**. There is
no hard cap; a member that genuinely needs more gets more, but length must be earned.

## Rule 1 — English only (HARD RULE)

Every comment and doc comment is written in **English**. No Uzbek, no Russian, no mixed language,
regardless of the language the task was requested in or the language of the UI strings.

```dart
// ✅ Loads the first page of clients and the branch list.
// ❌ Birinchi sahifani va filial ro'yxatini yuklaydi.
```

Untranslated inside a comment: identifiers, class/method names, file paths, endpoints, HTTP verbs,
JSON keys, and quoted UI strings that are already Uzbek/Russian.

The only place non-English prose is allowed is `test_uz.md`, which is a translation artifact, not code.

## Rule 2 — Comment EVERY declaration (HARD RULE)

Each of these gets its own comment. Not one comment for a group — one per declaration:

| Declaration | Comment |
|---|---|
| `class` / `mixin` / `extension` / `typedef` | `///` — what it represents, what it is responsible for, how it is meant to be used |
| `enum` | `///` on the enum, **plus `///` on every value** — what that value means in the domain |
| Constructor / named constructor / factory | `///` — what it builds and when to pick it over the others |
| Method / function (public **and** private) | `///` — what it does, what it returns, what its parameters mean, side effects and constraints |
| Field / property (state, model, DTO, widget field) | `///` — what it holds and what it is used for |
| Getter / setter | `///` — what it derives and from what |
| Top-level constant / global | `///` — what it configures and where it applies |
| Local variable inside a body | `//` above it — what it holds and why it exists at that point |
| A non-obvious step inside a body (workaround, ordering constraint, server quirk) | `//` — the *why* |

`///` for declarations, `//` for local variables and in-body explanations.

There is **no density cap** and no exemption list. A DTO with 20 fields gets 20 field comments. An
enum with 6 values gets 6 value comments. A private helper gets a doc comment exactly like a public
one. `copyWith`, `props`, `fromJson`, `toJson`, `build` are declarations too — they get theirs.

## Rule 3 — What the comment must say

The comment answers what the reader cannot get from the name alone.

**For a class / widget / bloc / repository:** its job, the part of the app it belongs to, and how it
is used — who creates it, what it needs, what it exposes.

**For a function / method:** what it does, what it returns, what each parameter means, what it
changes outside itself (emits a state, writes to the API, mutates a cache), and any constraint on
calling it (must be awaited, only valid after X, throws Y).

**For a variable / field:** what value it holds, what it is used for, and anything the type cannot
show — unit, range, null meaning, who is allowed to change it.

```dart
/// Drives the clients list: paged items, active filter and selected branch.
/// Created by `ClientsScreen` with the shared `ClientsRepository`.
class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  /// Data source for every client request; owned by the screen, not by this bloc.
  final ClientsRepository repository;

  /// Loads one page of clients — appends when [append] is true, else replaces.
  /// Emits a non-empty cache first, then the fresh page; errors keep the cache.
  Future<void> _onLoad(LoadClients event, Emitter<ClientsState> emit) async {
    // Paged off the requested page: the server may ignore `page` and always echo `1`.
    final nextPage = state.query.page + 1;
    ...
  }
}
```

```dart
/// Client's document-verification state, parsed from the `authentication` field.
enum ClientAuthentication {
  /// Documents submitted and approved — the client can buy a tariff.
  verified,

  /// Documents sent but not reviewed yet — shown with the waiting badge.
  pending,

  /// No documents or rejected ones — purchases stay blocked.
  none,
}
```

## Rule 4 — Length: as short as possible, 1–2 lines recommended

Write the shortest comment that still answers Rule 3. **Aim for 1–2 lines** — that is enough for
almost every field, method and class in this project. There is **no hard maximum**: a member whose
usage genuinely cannot be stated in two lines (a bloc other screens must learn to drive, a method
with several constraints) may take a short extra paragraph. Length is earned by content, never
spent by default.

Judge a comment by whether it removes a question, never by its line count. What is always wrong is
*empty* length: repeating the same sentence in three ways, describing the implementation line by
line, or writing prose that the next edit will make false. If a comment keeps growing, the code
needs a better name or a smaller function — not a longer comment.

## Rule 5 — Ban list (never write these)

- **Pure restatement.** `// increment counter` above `counter++`. A field comment must say what the
  value is *for*, not read the identifier aloud: `/// isLoading flag.` is banned;
  `/// True while the first page request is in flight; the list shows a shimmer.` is the comment.
- **History / bug post-mortems.** "This used to be `X` and looped forever because…" — explain the
  current behaviour and, in one line, the constraint that shapes it. Git history holds the past.
- **Section dividers.** `// ===== BUILD =====`, `// --- helpers ---`.
- **Commented-out code.** Delete it.
- **`TODO` without an owner or a concrete next step.**
- **Stale comments.** When you change a member, update its comment in the same edit. A comment that
  contradicts the code is worse than no comment.

## Rule 6 — Editing existing code

When you touch a file, bring it up to this standard in the same change: add the missing comments to
every declaration in it, translate anything non-English, delete the commented-out code and the
dividers, and fix the comments your edit made false. Do not leave a file half-converted.

## Sweep checklist

- [ ] No comment is in a language other than English.
- [ ] Every class, mixin, extension and typedef has a `///` doc comment.
- [ ] Every enum has one, **and so does every one of its values**.
- [ ] Every method, function and constructor — private included — has one stating what it does,
      what it returns and what its parameters mean.
- [ ] Every field, property, getter and top-level constant has one stating what it holds and what
      it is used for.
- [ ] Local variables carry a `//` line explaining what they hold and why.
- [ ] Every comment is as short as it can be — most are 1–2 lines; any longer one earns its length.
- [ ] No comment merely restates the identifier or the line below it.
- [ ] No comment narrates history, a past bug or a rejected approach.
- [ ] No section-divider banners, no commented-out code, no ownerless `TODO`.
- [ ] Every comment matches the code as it is now.
