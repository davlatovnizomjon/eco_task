---
name: flutter-ui-bloc
description: >-
  How to drive EVERY piece of UI — a page, a pushed sub-screen, a dialog/bottom sheet, or a
  stateful widget — with a BLoC/Cubit + Repository. Use whenever creating or modifying UI that has
  state: a screen with loading/error/data, a dialog that submits a form, a widget that loads its
  own list, an API call, persisting/reading local data, or connecting UI to a repository. Covers
  the full vertical: UI ⇄ BLoC, BLoC ⇄ Repository, Repository ⇄ HTTP client/API, and the reactive
  Repository ⇄ UI path (ValueNotifier/stream + listenable widget, guest/session mode), plus which
  UI owns its own bloc and which shares its owner's. Enforces a typed error/result model, a status
  enum, and an immutable state pattern. Adapts to the project's names/paths, or creates the missing
  pieces. See references/ for auth, profile, and local-storage recipes.
---

# Flutter UI ⇄ BLoC & Repository Wiring

How every page, sub-screen, dialog and stateful widget is controlled by a BLoC. The goal:
**UI is driven by a BLoC, the BLoC talks to a Repository, the Repository owns parsing and throws
typed errors, and shared/reactive state flows from the Repository back into the UI** — with no
duplicated error handling and no dead "is it ok?" checks after a call.

This skill teaches the **pattern**, not one project's names. Step 0 maps the pattern onto whatever the
current project already uses (or has you create the missing piece). Wherever you see a placeholder
like `<AppFailure>`, `<status enum>`, `<http client>`, substitute the project's real equivalent.

## Architecture layers

```
UI (BlocBuilder/BlocConsumer  +  a listenable widget for reactive state)
    ↓ event                          ↑ state  /  ValueNotifier·Stream
BLoC / Cubit (feature_bloc.dart)
    ↓ repository call                ↑ throws a typed failure
Repository (feature_repository.dart)     ← owns parsing + reactive/session state
    ↓ request
HTTP client wrapper                       ← attaches headers/auth, maps HTTP failures → typed failures
    ↓
API server
```

Two distinct ways UI is controlled:
1. **Imperative (BLoC):** user action → event → repository call → `emit(state)` → `builder` rebuilds.
2. **Reactive (Repository → UI):** the repository holds shared state (a `ValueNotifier`, a stream, or
   a `Cubit`); UI listens directly (`ValueListenableBuilder`, `StreamBuilder`, `BlocBuilder`) and
   rebuilds whenever the repository mutates it — no per-screen event. This is how session/auth mode,
   the current user, theme, etc. reach many screens at once.

## Which UI gets its own bloc

Every piece of UI that has state is answered by one of these — decide it before writing the widget:

| UI | Who drives it |
|---|---|
| A page / screen | Its OWN bloc, provided at the screen entry together with the repository (see §7) |
| A pushed sub-screen (detail, form) | Its OWN bloc in `presentation/screens/{sub}/bloc/`, taking the SAME repository forwarded by the pusher — NEVER the parent's bloc |
| A dialog / bottom sheet that reads or edits its OPENER's state (a picker listing the form bloc's items) | The opener's bloc, passed in with `BlocProvider.value` — it is part of that screen |
| A dialog / sheet that does its OWN work (submits a form, loads its own list, calls its own endpoint) | Its OWN bloc in `presentation/dialogs/{dialog}/bloc/`, same three file names |
| A widget that loads its own data (a self-contained card, a search box hitting the API) | Its OWN bloc, provided by that widget; the screen only places it |
| A presentational widget (no fetching, no submitting) | NO bloc — it takes data + callbacks through its constructor |
| App-wide state (session, current user, theme, connectivity) | NOT a bloc per screen — a repository-owned `ValueNotifier`/stream the UI listens to (see "Controlling the UI FROM the repository") |

A widget never reaches for a bloc it was not given: it either owns one, is inside the subtree of the
one that owns it, or receives its data through its constructor.

## Step 0 — Map the pattern onto the project (do this first)

Detect what the project already has; reuse it. Create a piece only if it's genuinely missing.

1. **State management.** Is it `flutter_bloc` (Bloc/Cubit)? Match the existing style (Bloc with events
   vs. Cubit with methods). If a feature is request-shaped with multiple triggers, prefer a Bloc; for
   one or two simple actions a Cubit is fine.
2. **HTTP client wrapper.** Find the single place requests go through (a Dio wrapper, a `retrofit`
   service, a hand-rolled client). Confirm it (a) attaches auth/headers centrally and (b) converts
   HTTP failures into typed errors. If no typed-error mapping exists, that's the gap to fill (below).
3. **Typed error/result model.** Look for a sealed/abstract failure type (`ScreenResponse`,
   `AppFailure`, `Failure`, an `Either`/`Result`). Call it `<AppFailure>`. If none exists, create a
   minimal sealed hierarchy (see "Error model").
4. **Status enum.** Look for a shared status (`BlocStatus`, `Status`, `RequestStatus`) with
   `initial/loading/success/error`. Call it `<status enum>`. Create one if absent.
5. **DI / repository access.** How are repositories provided — `RepositoryProvider`/`BlocProvider`,
   `get_it`, `provider`, constructor injection? Match it.
6. **Immutable state.** Does the project use `freezed`, or hand-written `copyWith` + `Equatable`?
   Match it. (This skill shows the manual form; if the project uses freezed, use `@freezed`.)
7. **Paths & localization.** Match the project's folder layout (`lib/features/...`,
   `lib/ui/pages/...`, `lib/presentation/...`) and its string strategy (a localization layer vs. raw
   strings) instead of imposing new ones.

Record your substitutions once, then use them consistently for the whole feature.

## Build order — wiring a feature end to end

Follow in order; skip a step only when it genuinely doesn't apply.

### 1. Model (only if you parse an API result into a typed object)

```dart
class FeatureResponse {
  final int id;
  final String name;
  FeatureResponse({required this.id, required this.name});

  factory FeatureResponse.fromJson(Map<String, dynamic> json) =>
      FeatureResponse(id: json['id'] as int, name: json['name'] as String);
}
```

(If the project uses `freezed` + `json_serializable`, generate it that way instead.)

### 2. Repository method — parse here, **throw, don't catch**

The repository uses the shared HTTP client, parses the response, and lets errors propagate. The client
has already mapped transport/HTTP failures to typed `<AppFailure>` values, so don't wrap calls in
try/catch here, and don't re-check a success flag the client already validated.

```dart
class FeatureRepository {
  final ApiClient _api;          // the project's HTTP wrapper
  FeatureRepository(this._api);

  Future<FeatureResponse> getData({required String id}) async {
    final res = await _api.get('feature/get-data/$id');
    return FeatureResponse.fromJson(res.data['result']);
  }
}
```

### 3. State — `<status enum>` + `<AppFailure>?` + immutable `copyWith`

When hand-writing `copyWith`, use a sentinel so a nullable field (the failure) can be set back to
null. (With `freezed`, this is automatic.)

```dart
class FeatureState extends Equatable {
  final Status status;
  final FeatureResponse? data;
  final AppFailure? failure;       // nullable — carries the error to show

  const FeatureState({this.status = Status.initial, this.data, this.failure});

  FeatureState copyWith({
    Status? status,
    FeatureResponse? data,
    Object? failure = _absent,     // sentinel → lets us clear the failure
  }) {
    return FeatureState(
      status: status ?? this.status,
      data: data ?? this.data,
      failure: identical(failure, _absent) ? this.failure : failure as AppFailure?,
    );
  }

  @override
  List<Object?> get props => [status, data, failure];
}

const _absent = Object();
```

`Status { initial, loading, success, error, empty }` — add convenience getters
(`status.isLoading`, `status.isSuccess`, `status.isError`) via an extension.

### 4. Event (Bloc) — or skip for a Cubit

```dart
sealed class FeatureEvent { const FeatureEvent(); }
class GetFeatureData extends FeatureEvent { final String id; const GetFeatureData(this.id); }
class ResetStatus    extends FeatureEvent { const ResetStatus(); }
```

### 5. Handler — `loading → success`; `catch` maps to `<AppFailure>`

```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  final FeatureRepository _repo;

  FeatureBloc(this._repo) : super(const FeatureState()) {
    on<GetFeatureData>(_onGet);
    on<ResetStatus>((e, emit) => emit(state.copyWith(status: Status.initial, failure: null)));
  }

  Future<void> _onGet(GetFeatureData event, Emitter<FeatureState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final data = await _repo.getData(id: event.id);
      emit(state.copyWith(status: Status.success, data: data));
    } catch (e) {
      emit(state.copyWith(
        status: Status.error,
        failure: e is AppFailure ? e : const UnexpectedFailure(),
      ));
    }
  }
}
```

The `catch` always does the same thing: pass `<AppFailure>` through, wrap anything else as "unexpected".
Never re-check a success flag after the call — the client already did, so that branch is dead code.

### 6. UI — provide the BLoC, consume with one error presenter

```dart
class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => FeatureBloc(ctx.read<FeatureRepository>())..add(const GetFeatureData('1')),
      child: const _FeatureBody(),
    );
  }
}

class _FeatureBody extends StatelessWidget {
  const _FeatureBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeatureBloc, FeatureState>(
      listenWhen: (prev, cur) => prev.status != cur.status,   // only fire on what matters
      listener: (context, state) {
        if (state.failure != null) {
          showFailure(context, state.failure!);               // ONE presenter for every failure type
          context.read<FeatureBloc>().add(const ResetStatus()); // reset so the same error can re-show
        }
      },
      builder: (context, state) {
        if (state.status.isLoading) return const Center(child: CircularProgressIndicator());
        if (state.status.isSuccess) return FeatureContent(data: state.data!);
        return const SizedBox.shrink();
      },
    );
  }
}
```

Have **one** presenter (`showFailure`/`showScreenResponse`/a snackbar helper) that maps each failure
subtype to its UI (unauthorized → re-login, no-internet → dialog, message → text, etc.) so screens
never branch on the failure type themselves.

### 7. Wire it up

Register the route the project's way (`go_router`, `Navigator`), and provide the repository/BLoC where
it's needed — page-level `BlocProvider` for screen state, or app-level (`MultiBlocProvider`/`get_it`)
for shared BLoCs.

#### A screen-level provider does NOT reach pushed routes or root-navigator sheets (HARD RULE)

When a repository/BLoC is provided **inside a screen** (page-level `RepositoryProvider`/`BlocProvider`),
it is only visible to that screen's own subtree. Two very common destinations are **outside** it:

- **A pushed route** (`Navigator.push`, `go_router` push) — the new route is a sibling under the
  Navigator, not a child of the pushing screen.
- **A dialog / bottom sheet opened with `useRootNavigator: true`** — it is built under the ROOT
  navigator, above the screen that opened it.

Both throw `ProviderNotFoundException` at runtime while compiling perfectly. Whenever a screen-scoped
dependency must reach one of these, **pass it explicitly at the call site**:

```dart
// pushed route — re-provide the SAME instance
final repository = RepositoryProvider.of<FeatureRepository>(context);
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => RepositoryProvider.value(value: repository, child: DetailScreen(id: id)),
));

// dialog/sheet — read it in the launcher (still inside the screen's tree) and pass it in
static Future<void> show(BuildContext context, {required Foo foo}) => showAppSheet(
      MyDialog(foo: foo, repository: RepositoryProvider.of<FeatureRepository>(context)),
      context,
    );
```

Put the launcher as a `static show(...)` **on the dialog widget itself** so every call site is one line
and the wiring lives in exactly one place.

> This only disappears when the dependency is provided ABOVE the Navigator (app-level). A per-entity
> repository (one client, one order) cannot be — so for those, explicit passing is the rule, not the
> exception.

#### Verify the wiring the way the user will hit it (HARD RULE)

A widget test that **hand-wires the provider itself** (`RepositoryProvider.value(... child: DetailScreen())`)
proves nothing about wiring — it re-creates exactly what the app forgot, so the bug above passes green.
Before calling a feature done:

1. **Test through the real entry point.** Pump the feature's ENTRY screen and drive it with taps —
   open the sub-screen by tapping the list row, open the dialog by tapping the row that opens it.
   Never construct an inner screen directly with a provider you supplied by hand.
2. **Then run it on a real/emulated device** and walk every navigation path once (entry → each
   sub-screen → each dialog), watching the log for `ProviderNotFoundException` and other runtime
   errors. `flutter analyze` + `flutter test` passing is NOT evidence the screen opens.
3. **Prove a new regression test actually fails without the fix** — revert the fix, watch it go red,
   restore it. A test that never failed is not known to test anything.

### 8. Write the feature's test plan — `{feature}/test.md` + `{feature}/test_uz.md`

Create (or update) `test.md` at the feature root, next to the feature barrel — **and its translation
`test_uz.md` beside it, in the same change**. It's a checklist an AI follows to test the feature
later, not test code itself. See "Feature test plan" below and `references/test.md` for the required
structure.

## Controlling the UI FROM the repository (reactive path)

When state must be shared app-wide and survive screen rebuilds (session/auth, current user, theme,
connectivity), the repository owns it and the UI listens directly — no per-screen BLoC, no event.

```dart
class SessionRepository {
  final ValueNotifier<User?> user = ValueNotifier(null);   // or a Stream / a Cubit
  bool get isGuest => user.value == null;

  Future<void> logout() async {
    await _api.post('auth/logout').catchError((_) {});
    await _local.clearUser();
    user.value = null;            // every listener rebuilds → UI flips to guest
  }
}
```

```dart
ValueListenableBuilder(
  valueListenable: session.user,
  builder: (context, user, _) =>
      session.isGuest ? const GuestView() : AuthenticatedView(user: user!),
)
```

Rule of thumb: **per-screen, request-shaped state → BLoC. App-wide identity/session/app state →
a repository-owned `ValueNotifier`/stream + a listenable widget.** Don't mirror this shared state as a
second source of truth inside a feature BLoC.

## List caching — cached-first, then refresh (HARD RULE)

**Any list data the user can revisit MUST be served cache-first.** This applies to every list-shaped
screen or section, whatever it lists: a per-day/tab/page list, a filtered index, a "my items" list,
the members/participants of an item, search results. It equally applies to a revisitable DETAIL
object (an item opened by id).

1. **The repository owns the cache.** Keep the last successful result in a cache field **keyed by the
   query that produced it** (the selected day, the filter set, the page number, the parent item's id;
   a parameterless list uses a single entry). For the cache to survive leaving + re-opening the
   screen, hold it on a longer-lived holder than the screen (e.g. a `static` field on the
   repository). Expose a synchronous `cachedX(query)` lookup next to the async `getX(query)` —
   **for lists it returns an EMPTY list when nothing useful is cached, never null** (a single cached
   detail object stays nullable — there is no "empty" model).
2. **The bloc emits a NON-EMPTY cache first, then refreshes.** On every fetch, if the cached list for
   the CURRENT query is non-empty, emit it immediately as `success` — no loading flicker — THEN await
   the network and re-emit the fresh data. **An empty cache shows `loading`** (an empty list is
   nothing to look at, so the spinner is more honest than a premature empty state).
3. **Errors never wipe cached data.** On a fetch error while a non-empty cache is showing, keep the
   data (status stays `success`) and surface the error through the one-shot failure field; go `error`
   only when the cache is empty.
4. **Mutations invalidate.** Any create/update/delete/join/leave that changes what a cached result
   would contain clears (or patches) the affected cache entries — a knowingly-stale list is never
   presented after a known change.
5. **Guard against out-of-order responses.** When the query can change while a fetch is in flight
   (fast day/tab switches), the handler must drop a response that no longer matches the current
   query instead of emitting it.
6. **Pull-to-refresh completes with the NETWORK, not the cached emit.** With cached-first, the
   first emit after a fetch is the instant cache — a refresh indicator awaiting "not loading"
   retracts immediately and looks broken. Track the in-flight refresh in state (e.g.
   `bool refreshing`, set true when the fetch starts, false when the network settles — success
   AND error paths) and have `onRefresh` await THAT flag.

See `references/repository.md` §3 for the code shape.

## List paging — load ONE page, never the whole table (HARD RULE)

**Opening a list screen must issue exactly ONE request for exactly ONE page.** Never walk the
server's pages in a loop to assemble the full dataset "so the client can filter/sort/paginate it" —
that turns opening a screen into multiple multi-megabyte requests, grows silently with the table, and
is the single most common performance defect in this layer.

1. **Push paging to the server.** Send `page` + the project's page-size parameter on every list call
   and read `last_page`/`total` from the response meta. Page size is a **named constant on the
   repository** (~20–40 rows — enough to fill a tall screen plus a little), never a literal, and the
   SAME constant is used everywhere the list is sliced.
2. **The next page is fetched on demand only** — when the user reaches the end of the list. The bloc
   appends it to the current items (`append: true`), tracks `isLoadingMore` separately from the main
   loading status, and refuses to fetch when a fetch is already in flight or `currentPage >= lastPage`.
3. **Filters and search go to the server too**, so paging stays correct. Verify against the live API
   which parameters it actually honours — a parameter that is silently ignored is worse than a missing
   one, because the screen then shows a filtered heading over unfiltered data.
4. **A server-unsupported filter is the ONLY excuse for loading everything**, because a paged response
   cannot be filtered client-side without breaking the totals. Confine that path to exactly the
   queries that need it (`if (unsupportedFilterSelected) …`), cap it with a page limit, document why,
   and delete the branch as soon as the backend supports the filter. It must never be the default.
5. **Pull-to-refresh reloads page 1** and resets the accumulated list — it never re-fetches every page
   the user had scrolled through.

Check it the way the user sees it: open the screen with the network log visible. More than one list
request before you scroll — or a page size in the hundreds — is a bug, whatever the response time
looks like on a fast dev network.

## Image upload — compress BEFORE uploading (HARD RULE)

Never upload a picked image file as-is. Before any multipart upload, run the image through the
project's image-compression service (find it in Step 0; if none exists, create one that downscales
and recompresses on a background isolate — e.g. quality ~70–90, max width ~1024). Large originals
(multi-MB camera shots) must arrive at the server already reduced. This applies to every upload
path in the repository layer — profile photos, covers, chat/complaint attachments alike. A picker
`imageQuality:` hint alone is NOT enough — route the final file through the compression service so
the rule holds no matter where the file came from.

## Feature test plan — `{feature}/test.md` + `{feature}/test_uz.md` (HARD RULE)

Every feature gets a **`test.md` file at its root**, alongside the feature barrel `{feature}.dart`,
**and a `test_uz.md` translation beside it** — the pair is atomic, never one without the other. It's
a test PLAN written for an AI to execute against — checklists and concrete scenarios, not test source
code — covering exactly four sections, in order:

1. **API test** — per repository method/endpoint: the success response, an auth error (bad/expired
   token → exact failure + message), a parameter error (missing/invalid field → exact message),
   format validation (phone/date/money/etc. — the backend must reject other formats, with the exact
   error message recorded), and — the step most often skipped — **value correctness: assert the
   NUMBERS, not just the status code.** Cross-check the same fact coming from two endpoints record by
   record, verify arithmetic identities (`start + income − expense == end`, `sum(pages) == total`),
   prove every parameter the app sends actually changes the result (and that a per-record scope really
   is per-record), and sanity-check dates/counts/labels against reality. Cover create/update calls,
   not just reads.
2. **Mobile/Web integration test** — the full vertical (model → repository → HTTP → bloc → UI) exercised
   together with zero unhandled errors, run on a real/emulated Android/iOS device (or a real browser for
   web) — not only `flutter test` in isolation.
3. **UI test** — overflow/clipping at small and large widths, conformance to the design, every
   navigation path, and animation smoothness.
4. **Logical/business test** — domain-logic bugs that pass type checks but are still wrong (nonexistent
   dates, invalid ages, double-booking, time conflicts). Flutter-side logical errors are reproduced by
   running the app; backend-side ones (one item sold to several buyers, overlapping bookings/sessions)
   are reproduced with an API test.

**Writing the plan is part of building a feature; RUNNING anything is not (HARD RULE).**

After a code change the user did not ask you to verify, you run **NOTHING**: no `flutter test` (not
the full suite, not a single file), no `flutter analyze`, no API sweep, no app launch, no UI driving.
Every one of those costs the user minutes of waiting, and the user asked for an edit, not a report.
Deliver the edit and stop.

Run them only when the user explicitly asks — "testla", "test qil", "tekshirib chiq", "analyze qil",
"ishlayaptimi?", or a direct question about whether something works live. The request scopes the run:
"testla" after one screen means that screen's tests, not `flutter test` over the whole repo. Never
widen it on your own, and never re-run "just to confirm" after a fix — one run per request.

If a change genuinely cannot be trusted without a run (a refactor across many call sites, a
generated-code regeneration), say so in ONE sentence and wait for the answer. Do not run it and
apologise afterwards.

Two things that stay your job without asking, because they are part of writing the code, not of
verifying it: **updating** the affected tests when your edit changes their expectations, and
**updating** `test.md` / `test_uz.md`. Write them, leave them unexecuted, and tell the user in one
line which tests you touched so they can run them when they choose.

Do not run `dart format` over a directory either — format only the files you actually edited, by
path. A repo-wide format rewrites files the user is working in and destroys their diff.

When the user later asks to test a feature, read that feature's `test.md` first and drive the actual
testing from it. Update **both files** whenever the feature's endpoints, states, or screens change — a
stale plan is worse than none, and a stale translation is worse still. `test_uz.md` mirrors `test.md`
1:1 (same headings, order, items, `[ ]`/`[x]` states); identifiers, paths, endpoints, HTTP verbs, JSON
keys and error-type names stay untranslated. Full section-by-section guidance, what to record in each,
the translation rules, and a copyable template → `references/test.md`.

## Error model — a typed failure hierarchy

If the project lacks one, create a minimal sealed hierarchy and have the HTTP wrapper throw these
(never raw `DioException`/`Exception`) so BLoCs and the UI presenter stay simple:

```dart
sealed class AppFailure { const AppFailure(); }
class UnauthorizedFailure extends AppFailure { const UnauthorizedFailure(); }      // 401
class ConnectionFailure   extends AppFailure { const ConnectionFailure(); }        // no internet
class ServerFailure       extends AppFailure { const ServerFailure(); }            // 5xx
class UnexpectedFailure   extends AppFailure { const UnexpectedFailure(); }        // fallback
class MessageFailure extends AppFailure {                                          // API message
  final String message; final String? description;
  const MessageFailure(this.message, {this.description});
}
```

The HTTP wrapper maps status codes → these (e.g. 401 → `UnauthorizedFailure` and trigger logout;
`status == false`/4xx → `MessageFailure`; timeout → `ConnectionFailure`). After that, repositories
write only the happy path and BLoCs catch with `e is AppFailure ? e : UnexpectedFailure()`.

## Anti-patterns (do not do these)

```dart
// ❌ Re-checking a success flag after a repository call — the client already handled it (dead code)
final r = await repo.getData();
if (r['status'] == true) { ... } else { emit(error); }

// ❌ Turning a typed failure into a useless string (e.g. a generic getMessage) — loses the type
emit(state.copyWith(errorMessage: e.toString())); // → "Instance of 'MessageFailure'"

// ❌ BlocConsumer without listenWhen — listener fires on every rebuild
BlocConsumer(listener: ...);

// ❌ Not resetting the failure — the same error won't re-trigger the listener next time
// ✅ Reset it in the listener after presenting.

// ❌ Reading session via a global/static singleton — use the repository's reactive state instead

// ❌ Fire-and-forget async persistence whose result the next step depends on
local.saveToken(t);                 // ✅ await local.saveToken(t);

// ❌ Stack-clearing navigation inside a multi-step flow — use replacement navigation in flows

// ❌ Alias/passthrough wrapper — a class OR function that just forwards to an existing one under a
//    new name (1:1 params, no new behaviour). Applies to widgets, helpers, repositories, services.
void myShowSheet(Widget c, BuildContext ctx) => showBottomDialog(c, ctx);   // ❌ just a rename
class FeatureRepo { final ApiRepo _r; getX() => _r.getX(); }                // ❌ adds nothing
// ✅ Call the real thing directly. Need a preset? Add a named constructor/factory ON the original
//    (Btn.unActive, TileWidget.dropdown, InputBox.search) — not a second differently-named type.
//    Only create a new named type/function when it adds real behaviour the original lacks.
```

## Resolved conventions — the Step-0 record (MANDATORY once filled in)

Step 0 above asks you to detect what the project already has. **Write the answers down in this
section once**, then apply them directly on every feature instead of re-deriving them. Rules are
written with the shape they must take plus **example** names; replace each with the current project's
real equivalent, and create the missing piece in that shape when the project has none. Never carry
another project's names in — a name belongs here only after you confirmed it exists in THIS repo.
Pair this with the `flutter-project-rules` skill's `references/project_conventions.md`.

- **State management:** `flutter_bloc` with **events** (Bloc, not Cubit) for request-shaped features.
- **Bloc file names are FIXED: `bloc.dart` + `event.dart` + `state.dart`** — NOT `{feature}_bloc.dart`.
  Every `bloc/` folder (feature-level, sub-screen, or dialog) uses exactly these three names. The class
  inside keeps its descriptive name (`class ContractBloc`, `class ContractFormBloc`), but the *files* are
  always `bloc.dart` / `event.dart` / `state.dart`. This is non-negotiable and overrides any older
  `{feature}_bloc.dart` examples elsewhere in this doc.
- **`part` / `part of` (REQUIRED for every bloc):** the event and state files are `part of` the bloc
  library — they are NOT standalone files with their own imports.
  - `bloc.dart` declares the library: all `import`s live here, then `export '../repository/...';`
    (exports must precede parts), then `part 'event.dart';` `part 'state.dart';`.
  - `event.dart` and `state.dart` each start with `part of 'bloc.dart';` and have **no imports of their
    own** (they see the bloc file's imports). Reference: any bloc folder in the repo that already
    follows this shape — record one here as the canonical example.
- **`bloc/` contains ONLY `bloc.dart` + `event.dart` + `state.dart` — nothing else.** No `*_utils.dart`,
  no `*_helpers.dart`, no extra `*_selection.dart`, and no subfolders (never `bloc/permissions/`).
  - Pure domain helpers / typedefs that operate on models go in `{feature}/model/` (in the model file,
    or a sibling model file with a `model/` barrel).
  - Form-validation logic that produces a failure goes **inside the bloc** as a private static method
    returning a `ScreenResponse?` (see error handling below) — not a separate file.
  - A bloc that drives a sub-screen or dialog gets its OWN sub-feature `bloc/` folder
    (`presentation/screens/{subscreen}/bloc/`, `presentation/dialogs/{dialog}/bloc/`), same three names.
- **State shape — ONE immutable state class per bloc with `copyWith` (never scattered
  `...Initial/...Loading/...Loaded/...Error` classes).** The screen drives itself off a **`ScreenStatus`**
  field, not separate state types.
  - `ScreenStatus` (the project's shared status enum — record its file, e.g.
    `<ui-root>/public/enum/screen_status.dart`): `{ initial, loading, success, error }`.
    Every state has `final ScreenStatus status;` and the UI switches on it
    (`status == ScreenStatus.loading` → shimmer/spinner, `.error` → empty/retry, `.success` → content).
  - Feedback uses a single one-shot `final ScreenResponse? response;` (success OR error — `MessageSuccessResponse`
    / `MessageErrorResponse` / the transport failures). Make `copyWith` **reset `response` to the passed
    value (default null), NOT `?? this.response`** — so it fires once per emit and the listener can re-show
    the same message; no manual "clear feedback" event needed.
  - The data lives in typed fields (`List<X> items`, selected values, etc.) on the same state.
  - Mirror an existing state file in the repo that already has this shape (a single `copyWith` state
    with `ScreenStatus status` + `ScreenResponse? response`) — record which one here.
- **Repository list caching — show the previously-loaded data instantly on re-entry.** The repository
  keeps the last successful list in a cache field; `getX()` updates it. The bloc's fetch handler emits the
  **cached list first** (as `status: success`) when the cache is non-empty, THEN awaits the network and
  re-emits fresh data — so a returning user never sees an empty/loading flicker. On fetch error when a
  cache exists, keep `status: success` (show cache) and surface the error via `response`; only go
  `status: error` when there is nothing cached to show. (For the cache to survive leaving + re-opening the
  screen, keep it on a longer-lived holder than the screen — e.g. a `static` field on the repository.)
- **HTTP client — use the project's single wrapped client (`dioClient`; record its file, e.g.
  `lib/domain/common/dio.dart`).** Call `dioClient.get/post/put/delete/patch`. Its `request` ALREADY: attaches auth headers, checks the
  `{status, data, message}` envelope (`status == false` → throws `MessageErrorResponse`), and maps
  transport/HTTP failures to typed `ScreenResponse` values (timeout/no-connection →
  `ConnectionErrorResponse`, 401 → `UnAuthorizedResponse` + clears token, other 4xx →
  `MessageErrorResponse`, else `UnExpectedErrorResponse`).
  > Do NOT use the raw, un-wrapped `dio` instance the wrapper holds (`dioClient.dio`) — it skips
  > status/error handling. Do NOT define a per-feature `ApiException`. Do NOT re-check
  > `status == true` after the call — `dioClient` already did, so that branch is dead code.
- **Repository:** lives in `{feature}/repository/`. It calls `dioClient.x`, reads the happy-path payload
  (`response.data['data']` or `['result']`), maps to typed models, and **returns** — no try/catch, no
  status re-check, no `ApiException`. The `bloc.dart` re-exports the repository (`export '../repository/...';`).
- **Error model & presenter — `ScreenResponse` + `showScreenResponse` (record the presenter's file,
  e.g. `<ui-root>/helpers/response_helper.dart`).** This IS the project's `<AppFailure>` + single-presenter. Subtypes: `UnAuthorizedResponse`,
  `ConnectionErrorResponse`, `ServerErrorResponse`, `UnExpectedErrorResponse`,
  `MessageErrorResponse(message, {description})`, `MessageSuccessResponse(message, {description})`.
  - Bloc state carries a nullable `ScreenResponse? failure` (clearable). The handler's `catch` maps
    `e is ScreenResponse ? e : UnExpectedErrorResponse()` — never `e.toString()`, never a custom string
    extractor.
  - UI presents EVERY failure with `showScreenResponse(context, state.failure!)` (a centered
    shared dialog), then resets the failure so the same error can re-show. Do NOT use a toast or an
    ad-hoc message extractor for API errors.
  - Local validation failures are also surfaced this way: build a `MessageErrorResponse("...")` in the
    bloc and emit it as the failure.
- **Screen provisioning — the entry is a `StatefulWidget` that OWNS the repository and provides repository
  + bloc.** This is the required shape for every bloc-backed screen:
  1. The public screen others navigate to is a `StatefulWidget` (`XxxScreen`). Its `State`:
     - declares `late final XxxRepository _repository;`
     - `initState`: `_repository = XxxRepository();` (then `super.initState();`)
     - `dispose`: `_repository.dispose();` (then `super.dispose();`)
     - `build` returns the two providers, taking the repository from the field:
       ```dart
       RepositoryProvider(
         create: (_) => _repository,
         child: BlocProvider(
           create: (ctx) => XxxBloc(repository: RepositoryProvider.of<XxxRepository>(ctx))
             ..add(const XxxStarted()),
           child: const _XxxView(),   // forward screen args via widget.xxx
         ),
       )
       ```
     Both providers go HERE. The repository is owned by this State (created in `initState`, disposed in
     `dispose`) and handed to `RepositoryProvider` via `create: (_) => _repository`; the bloc is built by
     `BlocProvider` reading it with `RepositoryProvider.of<XxxRepository>(ctx)` (this is how you read a
     repository — not `ctx.read<XxxRepository>()`). Never `BlocProvider(create:)` inline in some inner
     widget, and never construct a `XxxRepository()` ad-hoc inside a method.
  2. The inner widget (`_XxxView`) holds only **UI-local state** (search text, controllers, toggles). Make
     it a `StatefulWidget` only if such state exists (controllers must still be disposed); otherwise a
     `StatelessWidget` is fine. It reads the bloc with `context.read<XxxBloc>()` / `context.watch` /
     `BlocBuilder` — it does NOT create the bloc/repository.
  3. **Only the feature ENTRY creates the repository. Secondary screens reuse it — they NEVER
     `XxxRepository()` again.** A detail/form screen pushed from the entry is provided the SAME instance:
     the pusher wraps the route, and the pushed screen just reads it:
     ```dart
     // pusher (inside the entry/list screen):
     final repository = RepositoryProvider.of<XxxRepository>(context);
     Navigator.of(context).push(MaterialPageRoute(
       builder: (_) => RepositoryProvider.value(value: repository, child: const XxxFormScreen()),
     ));

     // the pushed screen is a StatelessWidget that reads the inherited repository:
     class XxxFormScreen extends StatelessWidget {
       @override
       Widget build(BuildContext context) => BlocProvider(
         create: (ctx) => XxxFormBloc(repository: RepositoryProvider.of<XxxRepository>(ctx))..add(...),
         child: const _XxxFormView(),
       );
     }
     ```
     (A `Navigator.push` route does NOT inherit the pusher's provider scope, so wrap the route with
     `RepositoryProvider.value` — never re-create the repository, never re-`dispose` it there; the entry
     that created it owns disposal.) Always read a repository with
     `RepositoryProvider.of<XxxRepository>(context)` — not `context.read<XxxRepository>()`.
- **A pushed sub-screen (form/detail) is driven by its OWN bloc — NEVER by the parent screen's bloc
  (HARD RULE).** Passing the parent's bloc into a pushed route via `BlocProvider.value` so it also
  handles the sub-screen's work (loading its picker lists, submitting its form) is a violation: it
  bloats the parent state with form-only fields (`servicesStatus`, `saveAct`-style action flags) and
  forces `ModalRoute.isCurrent` hacks in shared listeners. Instead create the sub-screen's own
  `presentation/screens/{subscreen}/bloc/` (same three files, e.g. `ActFormBloc`) that takes the SAME
  repository (forwarded by the pusher with `RepositoryProvider.value`), and return the outcome via
  `Navigator.pop(true)` — the pusher awaits the result and refreshes its own list/state.
  `BlocProvider.value` sharing IS correct for bottom sheets/dialogs that read or edit their OWNER's
  state (a picker sheet listing the form bloc's loaded items) — they are part of the same screen, not
  a pushed route with its own lifecycle.
- **One feature section = one `MultiRepositoryProvider` at the section entry.** When a feature subtree
  uses more than one repository (e.g. `ContractRepository` + `CurrencyRepository` in contracts), the
  entry screen's State owns ALL of them (`late final`, created in `initState`, each `dispose()`d) and
  provides them together in a single `MultiRepositoryProvider`. Inner screens, sheets, and shared
  widgets take them via `RepositoryProvider.of<X>(context)` (shared widgets accept an optional
  `repository` param) — NEVER `XxxRepository()` ad-hoc inside the subtree. Pushers forward ALL section
  repositories with `MultiRepositoryProvider` of `RepositoryProvider.value` entries.
- **Repository shape:** a plain concrete class (no abstract+Impl needed) in `{feature}/repository/`, owned
  by the entry `State` and exposed through `RepositoryProvider`. It may cache the last-loaded list as a
  field and exposes `void dispose()` to clear it (called from the State's `dispose`). Endpoint paths come
  from the project's endpoint-constants class (e.g. `ApiLinks`; record its file), not inline string literals.
- **DI:** the project's service locator (e.g. `get_it`'s `getIt`) is used for app-wide shared services;
  per-screen repositories/blocs are provided via `RepositoryProvider`/`BlocProvider` in the entry
  `StatefulWidget` as above.
- **Localization:** the project's localization package (e.g. `easy_localization`) — record it, and
  record the language user-facing copy is written in.
- **Formatted values (HARD RULE):** money/phone/date shown to the user — typed OR displayed — MUST go
  through the project's formatters folder (e.g. `lib/utils/formatters/`: a price format extension +
  a thousands-separator input formatter for sum/price, a phone formatter, a date formatter). Strip
  separators / use the raw value before sending to the API; never display a bare `num`, raw phone, or
  ISO date. See `flutter-project-rules/references/project_conventions.md` for the full rule.
- **Barrels:** exactly ONE per feature — `{feature}.dart`, named after the feature folder (NOT
  `{feature}_index.dart`), at the feature root re-exports the public API (bloc [which re-exports
  event/state/repository], model/s, enum/s, repository, main + secondary screens) so outside code
  imports one file. A **nested screen folder that owns its own `bloc/`/`model/`/`repository/`** (e.g.
  `screens/client_detail/`) is its OWN sub-feature with its OWN `{sub_feature}.dart` barrel, which the
  parent barrel re-exports. Do NOT add per-subfolder barrels — `widgets/`, `parts/`, and `model/` get
  none; widgets/parts are feature-internal and imported directly by relative path. See
  `flutter-project-rules/references/project_conventions.md`.

## Enums for closed sets (status / type / state / level)

Model any **fixed, known set** (request status, domain state, kind, level, role, result) as an **enum** — never a `String`, `int`, or cluster of `bool` flags. Put per-value data/behaviour (`title`, `icon`/`Widget get badge`, `color`, `factory fromJson`, predicates, transitions) **inside the enum**, so the UI reads `value.title` / `value.icon` / `value.color` directly and never re-`switch`es on it. One enum per file at `{feature}/enum/{name}.dart`; **export every enum from the feature barrel** (an unexported enum is an incomplete feature). Models store the enum, not its raw code.

**Full guide, the member checklist, and a worked example → `references/enum.md`.**

## References (read the matching one for the task)

- `references/auth.md` — building an auth flow (phone/email → OTP/password → register → token),
  guest/session transitions, PIN/biometrics, and keeping the session on a repository.
- `references/profile.md` — building a profile feature: reactive guest/auth views, parallel data
  loads, the user model, and updates (photo, name, etc.).
- `references/local-storage.md` — persisting/reading local data: a typed `shared_preferences` wrapper,
  when to reach for Hive / secure storage, and the await-everything rule.
- `references/enum.md` — modelling closed sets as enums: where to put `title`/`icon`/`color`/parsing,
  exporting from the barrel, and keeping enum→UI mapping out of widgets.
- `references/repository.md` — the repository layer in depth: parse-and-throw, the global HTTP client,
  ownership & provision (entry owns it, pushed sub-screens reuse it), list caching, reactive shared
  state, mock/JSON data sources, and multi-repository sections.
- `references/test.md` — the feature's `test.md` + `test_uz.md` test plan: the four required sections
  (API, mobile/web integration, UI, logical/business), what to record in each, the translation-pair
  rules, and a copyable template.

Comments in every file this skill produces — BLoC, event, state, model, enum, repository — follow
**`flutter-project-rules/references/comments.md`**: English only, a comment on EVERY class, enum
value, method (private included), field and variable, saying what it does / what it is used for, kept
as short as possible — 1–2 lines is the target, longer only when the member earns it.

## Definition of done (checklist)

- [ ] Bloc folder has EXACTLY `bloc.dart` + `event.dart` + `state.dart` (part/of), nothing else, no subfolders
- [ ] Feature ENTRY is a `StatefulWidget` owning `late final _repository` (created `initState`, disposed `dispose`); its `build` returns `RepositoryProvider(create: (_) => _repository)` + `BlocProvider(create: (ctx) => Bloc(repository: RepositoryProvider.of<Repository>(ctx))..add(...))`; inner view only holds UI state and reads the bloc from context
- [ ] Repository is read with `RepositoryProvider.of<Repository>(context)` (NOT `context.read<Repository>()`); blocs are read with `context.read<Bloc>()`/`BlocBuilder`
- [ ] Secondary (pushed) screens DON'T create a repository — pusher wraps the route with `RepositoryProvider.value(value: RepositoryProvider.of<Repository>(context), ...)`; the pushed screen reads it the same way
- [ ] Every stateful piece of UI is routed per "Which UI gets its own bloc": a dialog/sheet doing its own work has its OWN `presentation/dialogs/{dialog}/bloc/`, one only reading its opener's state gets it via `BlocProvider.value`, a self-loading widget owns its bloc, a presentational widget takes data through its constructor
- [ ] Pushed sub-screens (forms/details) have their OWN bloc — the parent's bloc is never passed into a pushed route via `BlocProvider.value`; outcome returns via `pop(true)` and the pusher refreshes
- [ ] A section using several repositories provides them ALL in one `MultiRepositoryProvider` at the entry; nothing inside the subtree constructs a repository ad-hoc
- [ ] Repository is concrete, created once by the entry State, exposes `dispose()`, paths from `ApiLinks`
- [ ] Repository calls `dioClient.x`, reads the payload and **returns** (no try/catch, no status re-check, no `ApiException`)
- [ ] State carries a nullable `ScreenResponse? failure` (clearable)
- [ ] Handler is `loading → success`; `catch` maps to `e is ScreenResponse ? e : UnExpectedErrorResponse()`
- [ ] UI consumes with `listenWhen`, presents every failure via `showScreenResponse`, and resets the failure
- [ ] Validation failures are emitted as `MessageErrorResponse` (no toast/string extractor)
- [ ] Pure model helpers live in `model/`, validation lives in the bloc — never a `bloc/*_utils.dart`
- [ ] Repository/BLoC provided the project's way (page-level for screen state, app-level for shared)
- [ ] Every revisitable list/detail fetch is cached-first: query-keyed cache on the repository, list lookups return an empty list (never null), the bloc emits a NON-EMPTY cache as `success` then refreshes (empty cache → `loading`), errors keep a non-empty cache, mutations invalidate, stale in-flight responses are dropped, pull-to-refresh awaits the network (a `refreshing` flag), not the first non-loading emit
- [ ] App-wide identity/session state read reactively from the repository, not duplicated in a BLoC
- [ ] No global/static session singletons; async persistence the next step depends on is `await`ed
- [ ] Route registered; user-facing strings go through the project's localization
- [ ] `{feature}/test.md` created/updated with all four sections (API — including the value/parameter
  cross-checks —, mobile/web integration, UI,
  logical/business) per `references/test.md` — AND `{feature}/test_uz.md` written in the SAME change as
  a 1:1 mirror (same headings, order, items, `[ ]`/`[x]` states; identifiers/paths/endpoints
  untranslated); every sub-feature that owns its own bloc/repository has its OWN pair
