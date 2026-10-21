import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// Row of photo placeholders (the MVP has no real uploads) with an optional
/// dashed "add photo" tile at the end. Used for task files, comment photos,
/// receipts and request photos.
class PhotoStrip extends StatelessWidget {
  /// How many photos to draw.
  final int count;

  /// Adds one more photo; the add tile is hidden when null.
  final VoidCallback? onAdd;

  /// Edge length of every tile; defaults to 56.w.
  final double? size;

  /// Builds the strip.
  const PhotoStrip({super.key, required this.count, this.onAdd, this.size});

  /// Gradient pairs the placeholder photos cycle through.
  static const _gradients = [
    [Color(0xFFB7D8C4), Color(0xFF5E9C7A)],
    [Color(0xFFE6D5B8), Color(0xFFB08A56)],
    [Color(0xFFCFD9E8), Color(0xFF6F89B3)],
  ];

  @override
  Widget build(BuildContext context) {
    final edge = size ?? 56.w;
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: edge,
            height: edge,
            decoration: BoxDecoration(
              borderRadius: 10.circular,
              gradient: LinearGradient(
                colors: _gradients[i % _gradients.length],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(child: AppIcon(AppIcons.image, color: const Color(0xB3FFFFFF))),
          ),
        if (onAdd != null)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: edge,
              height: edge,
              decoration: BoxDecoration(
                borderRadius: 10.circular,
                color: theme.cardColorLight,
                border: Border.all(color: theme.line),
              ),
              child: Center(child: AppIcon(AppIcons.camera)),
            ),
          ),
      ],
    );
  }
}
