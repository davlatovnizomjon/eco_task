import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';
import 'btn.dart';

/// The shared "nothing here" / "it failed" panel. Used for empty lists and
/// for a failed load with a retry button, so both read the same everywhere.
/// Scrollable on its own so pull-to-refresh works even on an empty screen.
class EmptyView extends StatelessWidget {
  /// Headline of the panel.
  final String title;

  /// Sentence explaining what is missing or what went wrong.
  final String message;

  /// SVG asset (an `AppIcons` constant) in the round halo above [title].
  final String? icon;

  /// Retry handler; the button is omitted when null.
  final VoidCallback? onRetry;

  /// Builds the empty/error panel.
  const EmptyView({super.key, required this.title, this.message = '', this.icon, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(color: theme.primaryTint, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AppIcon(icon ?? AppIcons.board, size: 30.sp, color: theme.primaryDark),
            ),
            16.h.height,
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.cardTitle,
            ),
            if (message.isNotEmpty) ...[
              6.h.height,
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.cardSubtitle.copyWith(height: 1.4),
              ),
            ],
            if (onRetry != null) ...[
              18.h.height,
              Btn.unActive(
                text: TrWords.cRetry.tr(),
                icon: AppIcons.refresh,
                onPressed: onRetry,
                margin: EdgeInsets.symmetric(horizontal: 40.w),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
