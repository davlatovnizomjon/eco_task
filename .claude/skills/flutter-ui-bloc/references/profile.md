# Reference — Profile

A portable recipe for a profile/account feature in a BLoC + Repository Flutter app. Substitute the
project's real names for the placeholders.

Profile is the canonical **Repository → UI reactive** feature: which view shows (guest vs.
authenticated) is decided by listening to the session repository, and the authenticated data is loaded
by a `ProfileBloc`.

## Shape

```
SessionRepository.user        # reactive source of identity (guest vs auth)
ProfileBloc                    # loads profile/balance/etc. for the authenticated view
ProfileView / GuestView       # the two views the page switches between
sub-features (edit photo, change name, history, ...) each with their own BLoC/Cubit
```

## Guest vs authenticated — reactive switch

Never branch on a cached boolean. Listen to the session repository's reactive state so the page flips
the instant the session changes (login, logout):

```dart
ValueListenableBuilder(
  valueListenable: session.user,
  builder: (context, user, _) =>
      session.isGuest ? const GuestProfileView() : ProfileView(user: user!),
)
```

(If the project exposes session as a stream or a `Cubit`, use `StreamBuilder`/`BlocBuilder` instead —
same idea.)

## ProfileBloc — parallel initial load

The authenticated view often needs several things at once; load them in one event with `Future.wait`
and emit once:

```dart
Future<void> _onLoad(LoadProfile e, Emitter<ProfileState> emit) async {
  emit(state.copyWith(status: Status.loading));
  try {
    final results = await Future.wait([
      _repo.getProfile(),
      _repo.getBalance(),
      _repo.getPlan(),
    ]);
    emit(state.copyWith(
      status: Status.success,
      profile: results[0] as Profile,
      balance: results[1] as Balance,
      plan:    results[2] as Plan,
    ));
  } catch (e) {
    emit(state.copyWith(status: Status.error, failure: e is AppFailure ? e : const UnexpectedFailure()));
  }
}
```

Handlers follow the standard shape (`loading → success`, `catch → failure`).

## Updating profile data

Mutations go through the repository, which calls the API and refreshes the reactive user so every
listener updates:

```dart
Future<void> updateName(String name) async {
  await _api.post('profile/update-name', data: {'name': name});
  user.value = await _fetchMe();   // re-fetch → notifies → ProfileView rebuilds
}
```

### File/photo upload — compress first

Compress large images before upload to avoid jank/ANR, and send as `FormData`:

```dart
final compressed = await ImageCompressor.compress(file);
await repo.updatePhoto(compressed.path);   // multipart
```

## Logout

```dart
await _session.logout();          // clears local + sets user = null
// reactive: every ValueListenableBuilder flips to the guest view automatically
// navigation: context.go(Routes.signIn);
```

## Profile do / don't

- ✅ Decide guest/auth with a listenable widget on the session repository, not a local flag.
- ✅ Load multi-source views with `Future.wait` in a single event.
- ✅ Route mutations through the repository and refresh the reactive user (`/me`) after writes.
- ✅ Compress images before upload; send via `FormData`.
- ❌ Don't read a global/static `isLoggedIn`/`token`.
- ❌ Don't keep the user in the BLoC as the source of truth — the session repository owns it.
