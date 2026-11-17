import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import '../widgets/app_icon.dart';

/// One row of an [ActionMenu]: glyph, label, whether it is destructive (red) and what a tap does.
typedef MenuAction = ({String icon, String label, bool danger, VoidCallback onTap});

/// iOS-style popup menu that drops from the "⋯" button of an inner screen: a blurred rounded panel under the bar's
/// right edge with one row per action. Open it with [ActionMenu.show].
class ActionMenu extends StatelessWidget {
  /// Rows from top to bottom.
  final List<MenuAction> actions;

  /// Builds the panel.
  const ActionMenu({super.key, required this.actions});

  /// Shows the menu over a barely dimmed screen; a tap outside closes it, a tap on a row closes it and runs the
  /// row's action.
  static Future<void> show(BuildContext context, List<MenuAction> actions) => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x14000000),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (_, _, _) => ActionMenu(actions: actions),
    transitionBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 48.h, right: 12.w),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 190.w,
            decoration: BoxDecoration(borderRadius: 12.circular, boxShadow: theme.menuShadow),
            child: ClipRRect(
              borderRadius: 12.circular,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: ColoredBox(
                  color: theme.menuSurface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, action) in actions.indexed)
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            action.onTap();
                          },
                          child: Container(
                            height: 42.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              border: i == 0 ? null : Border(top: BorderSide(color: theme.line, width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                AppIcon(action.icon, size: 17.sp, color: action.danger ? theme.red : theme.text),
                                10.w.width,
                                Expanded(
                                  child: Text(
                                    action.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textStyle.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                      color: action.danger ? theme.red : theme.text,
                                    ),
                                  ),
                                ),
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
        ),
      ),
    );
  }
}
