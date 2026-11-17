import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';

import '../widgets/app_icon.dart';
import '../widgets/btn.dart';

/// Confirmation of an irreversible action (delete, leave, log out): a red tile, a title, an explanation and the
/// "cancel" / solid red confirm pair. While [onConfirm] runs both buttons are locked and the confirm one spins.
class ConfirmDialog extends StatefulWidget {
  /// SVG asset of the tile glyph.
  final String icon;

  /// Question asked.
  final String title;

  /// What the action does and that it cannot be undone.
  final String message;

  /// Label of the red confirm button.
  final String confirmText;

  /// The action itself; the dialog closes with `true` once it completes.
  final Future<void> Function() onConfirm;

  /// Builds the dialog.
  const ConfirmDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.onConfirm,
  });

  /// Opens the dialog; resolves to `true` after the action ran, `null` when it was dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String icon,
    required String title,
    required String message,
    required String confirmText,
    required Future<void> Function() onConfirm,
  }) => showCenterDialog<bool>(
    ConfirmDialog(icon: icon, title: title, message: message, confirmText: confirmText, onConfirm: onConfirm),
    context,
  );

  @override
  State<ConfirmDialog> createState() => _ConfirmDialogState();
}

/// Tracks whether the confirmed action is still running.
class _ConfirmDialogState extends State<ConfirmDialog> {
  /// True from the confirm tap until the action completes.
  bool _busy = false;

  /// Runs the action once, then closes the dialog with `true`.
  Future<void> _confirm() async {
    setState(() => _busy = true);
    await widget.onConfirm();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.tile(widget.icon, tone: StatusTone.error, size: 52),
          16.h.height,
          Text(
            widget.title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textStyle.copyWith(fontSize: 17.sp, height: 24 / 17, fontWeight: FontWeight.w600),
          ),
          12.h.height,
          Text(
            widget.message,
            textAlign: TextAlign.center,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: theme.textStyle.copyWith(
              fontSize: 14.sp,
              height: 20 / 14,
              fontWeight: FontWeight.w400,
              color: theme.textSecondary,
            ),
          ),
          20.h.height,
          Row(
            children: [
              Expanded(
                child: Btn.unActive(
                  text: TrWords.cCancel.tr(),
                  height: 48.h,
                  onPressed: _busy ? null : () => Navigator.pop(context),
                ),
              ),
              10.w.width,
              Expanded(
                child: Btn(
                  text: _busy ? '' : widget.confirmText,
                  height: 48.h,
                  isLoading: _busy,
                  onPressed: _confirm,
                  decoration: BoxDecoration(color: theme.red, borderRadius: 12.circular),
                  textStyle: theme.textStyle.copyWith(fontWeight: FontWeight.w600, color: theme.cardColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
