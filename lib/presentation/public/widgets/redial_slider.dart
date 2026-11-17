import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// "Swipe right to call again" control of a finished call: a green thumb that follows the finger and fires [onRedial]
/// once it passes the end of the track.
class RedialSlider extends StatefulWidget {
  /// Text on the track.
  final String text;

  /// Runs when the thumb reaches the end.
  final VoidCallback onRedial;

  /// Builds the slider.
  const RedialSlider({super.key, required this.text, required this.onRedial});

  @override
  State<RedialSlider> createState() => _RedialSliderState();
}

/// Tracks how far the thumb has been dragged.
class _RedialSliderState extends State<RedialSlider> {
  /// Thumb offset from the left edge of the track, in logical pixels.
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    final height = 64.w;
    final thumb = 56.w;
    return LayoutBuilder(
      builder: (context, box) {
        final max = box.maxWidth - thumb - 8.w;
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: theme.callVeil.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(left: 52.w),
                  child: Opacity(
                    opacity: (1 - _dx / (max <= 0 ? 1 : max)).clamp(0.0, 1.0),
                    child: Text(
                      '${widget.text}  ›››',
                      style: theme.textStyle.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: theme.callInk,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 4.w + _dx,
                top: 4.w,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) =>
                      setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, max < 0 ? 0.0 : max)),
                  onHorizontalDragEnd: (_) {
                    final done = max > 0 && _dx >= max * 0.9;
                    setState(() => _dx = 0);
                    if (done) widget.onRedial();
                  },
                  onTap: widget.onRedial,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.callGreen,
                      boxShadow: [
                        BoxShadow(
                          color: theme.callGreen.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: AppIcon(AppIcons.handset, size: 26.sp, color: theme.callInk),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
