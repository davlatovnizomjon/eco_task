# Reference — Authentication

A portable recipe for building an auth flow in a BLoC + Repository Flutter app. Substitute the
project's real names for the placeholders (`<AppFailure>`, `<status enum>`, the HTTP wrapper, etc.).

Auth is the clearest example of the two control paths from the main skill: **BLoCs/Cubits** drive the
step-by-step screens (identify → verify → register), while a **session repository's reactive state**
(a `ValueNotifier`/stream) drives every other screen's guest/authenticated mode.

## Components

```
SessionRepository / AuthRepository   # single owner of identity + token; mutates reactive state
SignInBloc / VerifyBloc / RegisterBloc (or Cubits)   # per-step screen logic
LocalStore (shared_preferences/secure)               # persists token + user
PasscodeCubit (optional)                              # PIN / biometrics gate
```

## Typical flow

```
GUEST (session.user == null)
  → [Login] → identify (phone/email)         → exists | new | notFound
  → request OTP / submit password            → Verify screen
      → existing:  verify → repo.login()      → Home
      → new:       verify → Register screen
          → collect profile fields
          → register() → token + user         → Home
```

Each step is one event on a small BLoC; the BLoC calls a repository method that performs the request,
persists, and updates the reactive session.

## Session lives on the repository

One repository owns identity. It restores the persisted session on construction, exposes `isGuest`,
and is the **only** thing that mutates the reactive user. Pick the reactive primitive the project uses
(`ValueNotifier`, a broadcast `Stream`, or a `Cubit`).

```dart
class SessionRepository {
  final ApiClient _api;
  final LocalStore _local;
  final ValueNotifier<User?> user = ValueNotifier(null);

  SessionRepository(this._api, this._local) {
    user.value = _local.readUser();          // restore session at startup
  }

  bool get isGuest => user.value == null;

  Future<void> login({required String phone, required String code}) async {
    final res = await _api.post('auth/verify', data: {'phone': phone, 'code': code});
    final token = res.data['result']['token'] as String;
    await _local.saveToken(token);           // persist FIRST
    user.value = await _fetchMe();           // then load profile → notifies UI
  }

  Future<void> logout() async {
    await _api.post('auth/logout').catchError((_) {});  // ignore network error on logout
    await _local.clearSession();
    user.value = null;                       // UI flips to guest
  }
}
```

## Auth BLoC handler — same shape as any feature

```dart
Future<void> _onVerify(VerifyOtp event, Emitter<VerifyState> emit) async {
  emit(state.copyWith(status: Status.loading));
  try {
    await _session.login(phone: state.phone, code: event.code);
    emit(state.copyWith(status: Status.success));
  } catch (e) {
    emit(state.copyWith(status: Status.error, failure: e is AppFailure ? e : const UnexpectedFailure()));
  }
}
```

UI navigates on success, shows errors via the single presenter, then resets the status:

```dart
listener: (context, state) {
  if (state.failure != null) showFailure(context, state.failure!);
  if (state.status.isSuccess) context.go(Routes.home);
  context.read<VerifyBloc>().add(const ResetStatus());
}
```

## Registration form

- Use two forms when an external lookup pre-fills data: an **input** form (enabled) for what the user
  types, and a **display** form (read-only) populated from the lookup response.
- Validate with the project's form/validation layer; submit as `FormData` when files are involved.
- On success: load the user (`/me`), then navigate to the landing route.

## App entry + lifecycle

```dart
String initialRoute() {
  if (session.isGuest) return Routes.home;                 // guest → home (or onboarding)
  if (local.hasPasscode) return Routes.lockScreen;         // session + PIN → lock
  return Routes.home;
}

// On resume after N seconds in background, re-lock if a PIN is set:
if (!session.isGuest && local.hasPasscode) router.push(Routes.lockScreen);
```

## PIN / biometrics (optional gate)

```dart
enum PasscodeStep { create, confirm, check, none }
// create → confirm → await local.savePasscode(pin) → done
// check  → compare with local.passcode → ok / wrong
// biometrics: local_auth (Face ID / fingerprint) → on success, unlock
```

## Auth do / don't

- ✅ Mutate session only through the repository; read it via `repo.isGuest` and a listenable widget.
- ✅ Use dialogs for branching decisions (confirm new registration, "not found", etc.).
- ✅ Use replacement navigation inside the multi-step flow; full `go()` only for the final landing.
- ✅ Persist the token **before** fetching `/me`; `await` every persistence call.
- ❌ No global/static `isLoggedIn`/`token` singletons — guest mode is exactly `user.value == null`.
- ❌ Don't keep a second copy of the user inside a feature BLoC as the source of truth.
