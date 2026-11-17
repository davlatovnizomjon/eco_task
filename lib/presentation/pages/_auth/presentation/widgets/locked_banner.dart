import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// Amber notice under the sign-in fields while the account is locked: a lock glyph and "Siz vaqtincha bloklangansiz.
/// 04:59 dan keyin qayta urinib ko'ring." with the time in bold and counting down live.
class LockedBanner extends StatelessWidget {
  /// Lock time left.
  final Duration remaining;

  /// Builds the banner.
  const LockedBanner({super.key, required this.remaining});

  /// `04:59` — [d] as minutes and seconds.
  static String clock(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    // The sentence is translated with a marker where the time goes, so each language can place it where it belongs.
    const marker = '\u0000';
    final parts = TrWords.loginLockedB.tr(args: [marker]).split(marker);
    final style = theme.textStyle.copyWith(fontSize: 14.sp, height: 20 / 14, fontWeight: FontWeight.w400);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(color: theme.warnBg, borderRadius: 14.circular),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: AppIcon(AppIcons.lock, size: 20.sp, color: theme.warn),
          ),
          10.w.width,
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(text: parts.first),
                  TextSpan(
                    text: clock(remaining),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                  if (parts.length > 1) TextSpan(text: parts.sublist(1).join(marker)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
