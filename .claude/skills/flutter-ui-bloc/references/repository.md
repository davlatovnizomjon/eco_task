# The Repository layer in depth

The repository is the **only** place a feature talks to the outside world (HTTP, local DB, cache). It
owns **parsing** and **reactive/cached state**, and it **throws typed failures** — it never returns raw
maps, never swallows errors, and never re-checks a success flag the HTTP client already validated. BLoCs
above it stay thin (happy path + one `catch`), and the UI never sees a `DioException` or a `Map`.

## 1. Parse here, throw — don't catch

The shared HTTP client (`<http client>` — the project's single wrapped client, e.g. a global
`DioClient` instance) has ALREADY: attached auth/language headers, checked the `{status, data}`
envelope (`status == false` → throws `MessageErrorResponse`), and mapped transport/HTTP failures to typed
`ScreenResponse` values (timeout/offline → `ConnectionErrorResponse`, 401 → `UnAuthorizedResponse` +
logout, other 4xx → `MessageErrorResponse`, else `UnExpectedErrorResponse`).

So a repository method reads only the happy path and returns:

```dart
class ActivityRepository {
  Future<List<ActivityModel>> getActivities(ActivityFilterModel filter) async {
    final res = await dio.get('activities', queryParameters: filter.toJson());
    return (res.data['data'] as List).map(ActivityModel.fromJson).toList();
  }
}
```

Do NOT:
- wrap the call in `try/catch` (the client already mapped errors; the BLoC's `catch` presents them),
- re-check `res.data['status'] == true` (dead code — the client already did),
- define a per-feature `ApiException` (the project already has `ScreenResponse`),
- return `res.data` raw or stringify an error (`e.toString()` loses the type).

The repository's job is **JSON ⇄ typed model**: `fromJson` on the way in, `toJson` (or `.id`/`.name`)
on the way out. Endpoint paths come from a links constant, not inline literals scattered per call.

## 2. Ownership & provision — the ENTRY owns it, sub-screens reuse it

A repository is created **once**, by the feature's entry screen, and shared down the tree. The entry is a
`StatefulWidget` whose `State` owns it:

```dart
class XxxScreen extends StatefulWidget { const XxxScreen({super.key}); ... }

class _XxxScreenState extends State<XxxScreen> {
  late final XxxRepository _repository;

  @override
  void initState() { _repository = XxxRepository(); super.initState(); }

  @override
  void dispose() { _repository.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => RepositoryProvider.value(
        value: _repository,
        child: BlocProvider(
          create: (ctx) => XxxBloc(repository: RepositoryProvider.of<XxxRepository>(ctx))
            ..add(const XxxStarted()),
          child: const _XxxView(),
        ),
      );
}
```

- Read a repository with **`RepositoryProvider.of<XxxRepository>(context)`** (blocs with
  `context.read<XxxBloc>()`).
- **Secondary (pushed) screens NEVER `XxxRepository()` again.** A `Navigator.push` route does not inherit
  the pusher's provider scope, so the pusher wraps the route with `RepositoryProvider.value`, forwarding
  the SAME instance; the pushed screen reads it the same way and builds its OWN bloc:

  ```dart
  Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
    builder: (_) => RepositoryProvider.value(value: repository, child: const XxxDetailScreen()),
  ));
  ```

  Never re-create it there and never re-`dispose` it — the entry that created it owns disposal.
- **A section using several repositories** provides them ALL in one `MultiRepositoryProvider` at the
  entry (each `late final`, each `dispose()`d); inner screens/sheets take them via
  `RepositoryProvider.of<X>(context)`, never ad-hoc.

## 3. Caching lists & details — cached-first, no empty flicker (HARD RULE)

Every revisitable list (a per-day/tab/page list, a filtered index, "my items", an item's
members/participants) and every revisitable detail (an item opened by id) is served cache-first.
For the cache to survive leaving + re-opening the screen, hold it on a **longer-lived holder than the
screen** (a `static` field on the repository), **keyed by the query** that produced the result:

```dart
class ActivityRepository {
  /// Query-keyed list cache — one entry per day/filter/page; survives screen rebuilds.
  static final Map<String, List<ActivityModel>> _listCache = {};

  /// Synchronous lookup the bloc emits BEFORE refetching — an EMPTY list when nothing
  /// useful is cached, never null.
  List<ActivityModel> cachedActivities(Filter f) => _listCache[f.cacheKey] ?? const [];

  Future<List<ActivityModel>> getActivities(Filter f) async {
    final res = await dio.get('activities', queryParameters: f.toQuery());
    return _listCache[f.cacheKey] = _parse(res);
  }
}
```

- The cache key is WHAT produced the result — the selected day, the whole filter set, the page, the
  parent item's id. A parameterless list uses a single entry; a detail caches per id (the detail
  lookup stays nullable — there is no "empty" model).
- The bloc's fetch handler emits `cachedX(query)` first (as `success`) when NON-EMPTY, THEN awaits the
  network and re-emits fresh data — an empty cache shows `loading` (an empty list is nothing to look
  at, so the spinner is more honest than a premature empty state).
- On a fetch error while a non-empty cache is showing, keep `success` (show the cache) and surface the
  error via the one-shot failure field; only go `error` when the cache is empty.
- **Mutations invalidate**: create/update/delete/join/leave clears (or patches) the affected entries.
- **Drop out-of-order responses**: if the query changed while the fetch was in flight (fast day/tab
  switches), the handler must not emit the stale result over the newer one.

## 4. Reactive repository state (session / shared)

State that must be shared app-wide and survive screen rebuilds (auth/session, current user, theme,
connectivity) lives ON the repository as a `ValueNotifier`/stream/`Cubit`; the UI listens directly and
the repository mutates it — no per-screen bloc, no event:

```dart
class SessionRepository {
  final ValueNotifier<User?> user = ValueNotifier(null);
  bool get isGuest => user.value == null;

  Future<void> logout() async {
    await dio.post('auth/logout').catchError((_) {});
    await _local.clearUser();
    user.value = null;            // every ValueListenableBuilder flips to guest
  }
}
```

Rule of thumb: **per-screen, request-shaped state → BLoC; app-wide identity/session/app state →
repository-owned `ValueNotifier` + a listenable widget.** Never mirror this shared state as a second
source of truth inside a feature BLoC, and never read it via a global/static singleton.

## 5. Data sources & mocks (no API yet)

When the API isn't ready, keep the repository's shape identical and feed it from a **mock that produces
JSON-shaped maps**, parsed through the same `Model.fromJson` the API will use — so swapping to `dio` later
touches only the method body:

```dart
// {feature}/repository/{feature}_mock_data.dart
class ActivityMockData {
  static List<Map<String, dynamic>> generate() { /* deterministic JSON maps */ }
}

// repository
static final _store = ActivityMockData.generate().map(ActivityModel.fromJson).toList();
// later: final res = await dio.get('activities'); ... res.data['data'].map(ActivityModel.fromJson)
```

Put the mock generator in the repository folder, keep it deterministic (a seeded `Random`), and encode
enums by their `name`/`id` so `fromJson` exercises the real parsing path.

## 6. Shape & disposal

- A plain concrete class (no abstract+Impl needed) in `{feature}/repository/`.
- Holds reference lists and any cache; exposes `void dispose()` to clear the cache (called from the
  entry `State`'s `dispose`).
- Methods are `async`, read the payload, map to typed models, and **return**.

## Worked reference — a full-featured feature repository

A schedule-style feature (`{feature}/repository/{feature}_repository.dart`) pulls the whole convention
together:

- One concrete repository over the live API: the reads (`getItems(filter)`, `getMyItems`,
  `getItem(id)`), the writes (`createItem`/`updateItem`, `joinItem`/`leaveItem`, `cancelOwnItem`,
  `markAttendance`); it throws the typed message failure for domain errors; the reference lists
  (categories, names, options) and the domain constants live here, not in the bloc.
- `static` query-keyed caches (list per filter, my-items per user, model per id, a per-month index)
  implement the cached-first rule of §3 and are invalidated by every mutation above.
- The feature ENTRY screen owns the repository and provides it; the detail / my-items / form
  sub-screens are pushed with `RepositoryProvider.value` and each builds its OWN bloc.

See also `profile.md` (reactive guest/auth user on the repository) and `local-storage.md` (persisting
through a typed wrapper, the await-everything rule).
