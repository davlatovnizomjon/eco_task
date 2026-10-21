/// Request lifecycle every bloc state carries as its `status` field; the UI
/// switches on it to pick between spinner, content and retry view.
enum ScreenStatus {
  /// Nothing has been requested yet — the screen shows its idle state.
  initial,

  /// A request is in flight and there is no cached content to show.
  loading,

  /// The screen has content to render, fresh or cached.
  success,

  /// The request failed and there is nothing cached — show a retry view.
  error,
}

/// Readable checks so widgets write `state.status.isLoading` instead of
/// comparing enum values inline.
extension ScreenStatusX on ScreenStatus {
  /// True while a request is in flight with nothing to show.
  bool get isLoading => this == ScreenStatus.loading;

  /// True when the screen has content to render.
  bool get isSuccess => this == ScreenStatus.success;

  /// True when the screen has nothing to render and the load failed.
  bool get isError => this == ScreenStatus.error;
}
