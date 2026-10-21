/// In-memory, query-keyed cache that outlives screens, so a revisited list
/// opens instantly while the fresh page loads. Repositories write into it on
/// every successful read and call [invalidate] after any mutation.
abstract final class ApiCache {
  /// Cached results by query key; the value type is whatever the writer stored.
  static final Map<String, Object> _store = {};

  /// Cached value for [key], or null when nothing (of type [T]) is stored.
  static T? read<T>(String key) {
    final value = _store[key];
    return value is T ? value : null;
  }

  /// Stores [value] under [key] and returns it, so a call can be `return`ed.
  static T write<T extends Object>(String key, T value) => _store[key] = value;

  /// Drops every entry; called after a create/update/delete so no list is
  /// presented knowingly stale.
  static void invalidate() => _store.clear();
}
