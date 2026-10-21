import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

/// Shows [dialog] centred on a dimmed background. Every confirm/error/success
/// dialog goes through here, so feature code never calls `showDialog`.
/// Returns whatever the dialog pops with.
Future<T?> showCenterDialog<T>(Widget dialog, BuildContext context, {bool isCancelable = true}) => showDialog<T>(
  context: context,
  barrierDismissible: isCancelable,
  useRootNavigator: true,
  builder: (_) => Center(
    child: Padding(
      padding: 28.w.horizontal,
      child: Material(
        color: theme.dialogBackground,
        borderRadius: 20.circular,
        child: Padding(padding: 20.w.all, child: dialog),
      ),
    ),
  ),
);

/// Shows [dialog] as a bottom sheet with the app's drag handle, optional
/// [title] and the keyboard/safe-area padding already applied.
Future<T?> showBottomDialog<T>(Widget dialog, BuildContext context, {String? title, bool isCancelable = true}) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: isCancelable,
      enableDrag: isCancelable,
      backgroundColor: theme.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: 20.circularRadius)),
      builder: (sheetContext) => Padding(
        // Lifts the sheet above the keyboard while an input inside it is focused.
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: 12.h.top,
              width: 52.w,
              height: 5.h,
              decoration: BoxDecoration(color: theme.line, borderRadius: 5.circular),
            ),
            if (title != null)
              Padding(
                padding: EdgeInsets.only(top: 14.h),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            Flexible(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 20.h + ScreenSize.bottomInset(sheetContext)),
                child: dialog,
              ),
            ),
          ],
        ),
      ),
    );
