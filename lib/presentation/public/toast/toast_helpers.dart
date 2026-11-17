import 'dart:async';

import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';

import 'top_toast.dart';

/// The toast on screen right now, so a new one can replace it; null while none is shown.
_ToastHandle? _current;

/// Shows a [TopToast] over the whole app: it slides down from above the screen edge under the status bar, stays for
/// [duration] and slides back up. It lives in the root overlay, so a screen only calls this function — it needs no
/// `Stack` or placeholder widget — and the toast stays above sheets and dialogs. Taps pass through it. A toast shown
/// while another is visible replaces it.
void showTopToast(
  BuildContext context, {
  required String icon,
  required StatusTone tone,
  required String title,
  required String message,
  Duration duration = const Duration(seconds: 4),
}) {
  _current?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  final handle = _ToastHandle();
  handle.entry = OverlayEntry(
    builder: (_) => _ToastView(
      handle: handle,
      duration: duration,
      child: TopToast(icon: icon, tone: tone, title: title, message: message),
    ),
  );
  _current = handle;
  overlay.insert(handle.entry);
}

/// Ties the overlay entry to the view that animates it, so the toast can be removed from outside.
class _ToastHandle {
  /// The entry in the root overlay.
  late OverlayEntry entry;

  /// Whether the entry has already been removed.
  bool removed = false;

  /// Removes the entry at once (used when a newer toast replaces this one or the view finished its exit).
  void remove() {
    if (removed) return;
    removed = true;
    entry.remove();
    entry.dispose();
    if (identical(_current, this)) _current = null;
  }
}

/// Positions the toast under the status bar, slides it in, waits and slides it out.
class _ToastView extends StatefulWidget {
  /// Owner entry.
  final _ToastHandle handle;

  /// How long the toast rests on screen.
  final Duration duration;

  /// The toast itself.
  final Widget child;

  /// Builds the view.
  const _ToastView({required this.handle, required this.duration, required this.child});

  @override
  State<_ToastView> createState() => _ToastViewState();
}

/// Runs the enter and exit animation and the dismiss timer.
class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  /// How far above its resting place the toast starts and ends, in toast heights (enough to leave the screen).
  static const _hiddenOffset = -2.5;

  /// Progress of the slide: 0 hidden, 1 resting.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 260),
  );

  /// Eased slide from above the screen to the resting place.
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, _hiddenOffset),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic));

  /// Starts the exit once the toast has rested long enough.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.handle.remove();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8.h,
      left: 12.w,
      right: 12.w,
      child: IgnorePointer(
        child: Material(
          type: MaterialType.transparency,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(opacity: _controller, child: widget.child),
          ),
        ),
      ),
    );
  }
}
