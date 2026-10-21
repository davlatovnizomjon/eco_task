import 'package:flutter/widgets.dart';

/// System-inset helpers every scrollable and pinned bottom bar uses, so the
/// last item is never hidden behind the Android gesture bar.
@immutable
class ScreenSize {
  /// Private constructor — the class is a namespace, never instantiated.
  const ScreenSize._();

  /// Fallback inset used on devices that report no bottom view padding.
  static const double _fallbackInset = 16;

  /// Bottom system inset, or [_fallbackInset] on devices that report none.
  /// Add it to a scrollable's bottom padding or to a pinned bottom bar.
  static double bottomInset(BuildContext context) {
    // Devices with hardware buttons report 0 here; a bare 0 would glue the
    // last item to the screen edge.
    final inset = MediaQuery.of(context).viewPadding.bottom;
    return inset == 0 ? _fallbackInset : inset;
  }

  /// Keyboard height, or [_fallbackInset] when the keyboard is closed.
  /// Used by sheets that must stay above the keyboard.
  static double keyboardInset(BuildContext context) {
    // `viewInsets.bottom` is the keyboard; 0 means it is closed.
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return inset == 0 ? _fallbackInset : inset;
  }
}
