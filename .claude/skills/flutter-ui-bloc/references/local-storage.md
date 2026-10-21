# Reference — Local storage (SharedPreferences / Hive / secure)

A portable recipe for persisting and reading local data in a Flutter app. The default lightweight
store is a typed wrapper over `shared_preferences`, exposed as a single instance.

## A typed wrapper — the recommended convention

Wrap `shared_preferences` in one class with a typed getter/setter pair per key, initialized once at
startup and injected where needed. Don't scatter raw `SharedPreferences.getInstance()` calls.

```dart
class LocalStore {
  final SharedPreferences _prefs;
  LocalStore(this._prefs);

  static Future<LocalStore> create() async => LocalStore(await SharedPreferences.getInstance());

  static const _passcode = 'passcode';      // one const key per value
  String get passcode => _prefs.getString(_passcode) ?? '';
  Future<void> setPasscode(String v) => _prefs.setString(_passcode, v);

  Future<void> clear() => _prefs.clear();   // wipe on logout/reset
}
```

Initialize in `main()` before `runApp`, then hand it to repositories:

```dart
final local = await LocalStore.create();
runApp(MyApp(session: SessionRepository(api, local)));
```

### Adding a new persisted value

1. Add a `static const _key = 'key';`.
2. Add a typed getter with a safe default (`?? ''`, `?? false`, `?? []`, `?? -1`).
3. Add a setter using the matching typed call (`setString`/`setBool`/`setInt`/`setStringList`).
4. Keep the **right type** — don't stringify numbers/bools.

### Storing a whole object

Two options:
- **Separate typed keys** per field — simplest for a handful of scalars.
- **One JSON key** holding the full object — serialize with `jsonEncode(obj.toJson())`, read with
  `Obj.fromJson(jsonDecode(raw))`. Prefer this when the fields always travel together (e.g. the
  session user), so "logged out" is simply "this key is null".

## Who reads local storage

- **Repositories** read/write the store directly (restore session in the constructor, persist on
  login, clear on logout).
- **BLoCs/Cubits** go through their repository, or read simple flags via the store the repository
  exposes.
- **UI** never touches the store directly — always through a repository/BLoC.

## await rule

Treat persistence as async and `await` it whenever the next step depends on the write having landed
(saving a token before fetching `/me`; saving a passcode before navigating). Fire-and-forget risks
acting before the value is stored. Make wrapper setters `Future`-returning and `await` them in ordered
flows; plain `void` setters are fine only for non-critical flags.

## When to reach beyond SharedPreferences

| Need | Use |
|------|-----|
| Small flags, tokens, a single object as JSON | `shared_preferences` (typed wrapper) — the default |
| Large/structured/queryable data, lists of typed objects, offline cache | **Hive** (`hive`/`hive_ce`) with a typed box + adapter, or **Isar**/`drift` for relational queries |
| Sensitive secrets (refresh tokens, keys) | **flutter_secure_storage** (Keychain / Keystore) |

If you introduce Hive:
1. Define a model + `TypeAdapter` (hand-written or `@HiveType`/`@HiveField` + build_runner).
2. `registerAdapter(...)` and open the box once at startup, beside the `LocalStore` init.
3. Wrap box access in a repository — never open boxes from the UI.
4. Keep the same layering: UI → BLoC → repository → box.

## Local-storage do / don't

- ✅ One wrapper instance, initialized once in `main()`, injected into repositories.
- ✅ One typed getter/setter pair per key, with a safe default.
- ✅ `await` persistence the next step depends on; `clear()` on logout/reset.
- ✅ Pick the right store: prefs for flags/session, Hive/Isar for bulk/structured, secure for secrets.
- ❌ Don't call `SharedPreferences.getInstance()` ad-hoc in widgets/BLoCs.
- ❌ Don't store secrets in plain `shared_preferences`.
- ❌ Don't keep a duplicate in-memory copy as the source of truth — the repository owns it and
  notifies the UI (e.g. a reactive `user` mirroring the persisted session).
