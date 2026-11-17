import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';

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

  /// Color family of the glyph tile; null keeps the classic round green halo.
  final StatusTone? tone;

  /// Builds the empty/error panel.
  const EmptyView({super.key, required this.title, this.message = '', this.icon, this.onRetry}) : tone = null;

  /// Admin look of an empty list: a rounded-square tile tinted with [tone], a larger title and hint.
  const EmptyView.tile({
    super.key,
    required this.title,
    this.message = '',
    this.icon,
    this.onRetry,
    StatusTone this.tone = StatusTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tone == null)
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(color: theme.primaryTint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AppIcon(icon ?? AppIcons.board, size: 30.sp, color: theme.primaryDark),
              )
            else
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(color: tone!.bgColor, borderRadius: 20.circular),
                alignment: Alignment.center,
                child: AppIcon(icon ?? AppIcons.board, size: 30.sp, color: tone!.color),
              ),
            16.h.height,
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tone == null
                  ? theme.cardTitle
                  : theme.textStyle.copyWith(fontSize: 19.sp, height: 25 / 19, fontWeight: FontWeight.w700),
            ),
            if (message.isNotEmpty) ...[
              6.h.height,
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: tone == null
                    ? theme.cardSubtitle.copyWith(height: 1.4)
                    : theme.cardSubtitle.copyWith(fontSize: 15.sp, height: 21 / 15),
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
