import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// Shows the "new version" dialog above the app and returns once it is closed. It looks native to the platform: a
/// compact frosted alert with a split button row on iOS, a Material 3 dialog with a refresh icon and right-aligned
/// text buttons everywhere else. [title] and [subtitle] come from the backend (or the app's fallback text).
/// "Keyinroq" runs [onLater], "Yangilash" runs [onUpdate]; both close the dialog first and it cannot be dismissed
/// any other way. A null [onLater] makes the update mandatory: the "Keyinroq" button is left out and "Yangilash" only
/// opens the store, so the dialog stays on screen until the app is updated.
Future<void> showUpdateDialog(
  BuildContext context, {
  required String title,
  required String subtitle,
  required VoidCallback onUpdate,
  VoidCallback? onLater,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  useRootNavigator: true,
  builder: (dialogContext) {
    void close(VoidCallback action) {
      Navigator.of(dialogContext).pop();
      action();
    }

    final later = onLater;
    final laterLabel = TrWords.updateLater.tr();
    final updateLabel = TrWords.cUpdate.tr();
    return PopScope(
      canPop: false,
      child: Center(
        // 24 px from the screen's left and right edges; the dialog fills the width in between.
        child: Padding(
          padding: 24.w.horizontal,
          child: defaultTargetPlatform == TargetPlatform.iOS
              ? _IosUpdateDialog(
                  title: title,
                  subtitle: subtitle,
                  laterLabel: laterLabel,
                  updateLabel: updateLabel,
                  onLater: later == null ? null : () => close(later),
                  onUpdate: later == null ? onUpdate : () => close(onUpdate),
                )
              : _AndroidUpdateDialog(
                  title: title,
                  subtitle: subtitle,
                  laterLabel: laterLabel,
                  updateLabel: updateLabel,
                  onLater: later == null ? null : () => close(later),
                  onUpdate: later == null ? onUpdate : () => close(onUpdate),
                ),
        ),
      ),
    );
  },
);

/// iOS look: full-width (24 px side margins) frosted alert, centred title and message, two equal buttons split by
/// hairlines.
class _IosUpdateDialog extends StatelessWidget {
  /// Headline.
  final String title;

  /// Text under the headline.
  final String subtitle;

  /// Label of the postponing button.
  final String laterLabel;

  /// Label of the confirming button.
  final String updateLabel;

  /// Runs when the postponing button is tapped; null leaves the button out (mandatory update).
  final VoidCallback? onLater;

  /// Runs when the confirming button is tapped.
  final VoidCallback onUpdate;

  /// Builds the alert.
  const _IosUpdateDialog({
    required this.title,
    required this.subtitle,
    required this.laterLabel,
    required this.updateLabel,
    required this.onLater,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final hairline = BorderSide(color: theme.iosAlertDivider, width: 0.5);
    TextStyle action(FontWeight weight) =>
        theme.textStyle.copyWith(fontSize: 17.sp, fontWeight: weight, color: theme.iosAlertAction);
    Widget button(String label, FontWeight weight, VoidCallback onTap, {bool divider = false}) => Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: divider ? Border(left: hairline) : null),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: action(weight)),
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: 14.circular,
          boxShadow: [BoxShadow(offset: const Offset(0, 10), blurRadius: 40, color: theme.iosAlertShadow)],
        ),
        child: ClipRRect(
          borderRadius: 14.circular,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: ColoredBox(
              color: theme.iosAlertBackground,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16.w, 19.h, 16.w, 18.h),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textStyle.copyWith(
                              fontSize: 17.sp,
                              height: 22 / 17,
                              fontWeight: FontWeight.w600,
                              color: theme.iosAlertText,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            4.h.height,
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: theme.textStyle.copyWith(
                                fontSize: 13.sp,
                                height: 18 / 13,
                                fontWeight: FontWeight.w400,
                                color: theme.iosAlertSubtext,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(border: Border(top: hairline)),
                    // A Material right above the buttons so their ink splash is painted over the frosted surface.
                    child: Material(
                      type: MaterialType.transparency,
                      child: Row(
                        children: [
                          if (onLater != null) button(laterLabel, FontWeight.w400, onLater!),
                          button(updateLabel, FontWeight.w600, onUpdate, divider: onLater != null),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Android look: full-width (24 px side margins) Material 3 dialog with a centred refresh icon and title, a left-aligned message and
/// right-aligned text buttons.
class _AndroidUpdateDialog extends StatelessWidget {
  /// Headline.
  final String title;

  /// Text under the headline.
  final String subtitle;

  /// Label of the postponing button.
  final String laterLabel;

  /// Label of the confirming button.
  final String updateLabel;

  /// Runs when the postponing button is tapped; null leaves the button out (mandatory update).
  final VoidCallback? onLater;

  /// Runs when the confirming button is tapped.
  final VoidCallback onUpdate;

  /// Builds the dialog.
  const _AndroidUpdateDialog({
    required this.title,
    required this.subtitle,
    required this.laterLabel,
    required this.updateLabel,
    required this.onLater,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(String label, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: 20.circular,
      child: Container(
        height: 40.h,
        padding: 12.w.horizontal,
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textStyle.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: theme.m3DialogAction,
          ),
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        padding: 24.w.all,
        decoration: BoxDecoration(
          color: theme.m3DialogBackground,
          borderRadius: 28.circular,
          boxShadow: [BoxShadow(offset: const Offset(0, 8), blurRadius: 28, color: theme.m3DialogShadow)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: AppIcon(AppIcons.refresh, size: 24.sp, color: theme.m3DialogAction),
            ),
            16.h.height,
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textStyle.copyWith(
                fontSize: 24.sp,
                height: 32 / 24,
                fontWeight: FontWeight.w400,
                color: theme.m3DialogTitle,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              16.h.height,
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    subtitle,
                    style: theme.textStyle.copyWith(
                      fontSize: 14.sp,
                      height: 20 / 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.25,
                      color: theme.m3DialogBody,
                    ),
                  ),
                ),
              ),
            ],
            24.h.height,
            // A Material right above the buttons so their ink splash is painted over the dialog surface.
            Material(
              type: MaterialType.transparency,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onLater != null) ...[button(laterLabel, onLater!), 8.w.width],
                  button(updateLabel, onUpdate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
