/// Public surface of the toast feature: the [TopToast] look and the `showTopToast` function every screen calls.
///
/// It owns no repository or bloc: a toast is a one-shot overlay entry.
library;

export 'toast_helpers.dart';
export 'top_toast.dart';
