import '../services/local_store.dart';

/// Remembers on the device how long sign-in stays locked after too many wrong passwords, so closing and reopening the
/// app does not shorten the wait: the stored end moment is read back and the countdown continues from what is left.
class LoginLockRepository {
  /// Device preferences the lock end is kept in.
  final LocalStore _store;

  /// Wraps [store].
  LoginLockRepository(LocalStore store) : _store = store;

  /// The moment the lock ends, or null when sign-in is not locked. A lock that has already run out is erased.
  DateTime? get lockedUntil {
    final until = _store.loginLockedUntil;
    if (until == null) return null;
    if (until.isAfter(DateTime.now())) return until;
    _store.setLoginLockedUntil(null);
    return null;
  }

  /// Stores [until] as the end of the lock; null clears it.
  Future<void> save(DateTime? until) => _store.setLoginLockedUntil(until);
}
