import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:eco_task/constants/constants.dart';

/// The app's only loading indicator: shimmering card placeholders shown while
/// a bloc reports `ScreenStatus.loading` with nothing cached to render.
class SmartLoading extends StatelessWidget {
  /// How many placeholder cards to draw.
  final int count;

  /// Builds the shimmering placeholder list.
  const SmartLoading({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    // One rounded grey block; the shimmer sweeps a highlight over all blocks.
    Widget block(double width, double height, [double radius = 6]) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: theme.cardColorLight, borderRadius: BorderRadius.circular(radius.r)),
    );
    return Shimmer.fromColors(
      baseColor: theme.cardColorLight,
      highlightColor: theme.cardColor,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(0, 8.h, 0, 24.h),
        itemCount: count,
        separatorBuilder: (_, _) => 12.h.height,
        itemBuilder: (_, _) => Container(
          padding: 14.w.all,
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: 14.circular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(70.w, 12.h),
              10.h.height,
              block(double.infinity, 18.h),
              10.h.height,
              block(120.w, 26.h, 13),
            ],
          ),
        ),
      ),
    );
  }
}
