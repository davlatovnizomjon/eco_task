import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// One step of a [TimelineView].
class TimelineStep {
  /// Main text of the step.
  final String title;

  /// Dimmer second line (who and when); omitted when null.
  final String? subtitle;

  /// SVG asset (an `AppIcons` constant) inside the step's dot.
  final String icon;

  /// True for steps that already happened — their dot is filled.
  final bool done;

  /// Builds a step.
  const TimelineStep({required this.title, required this.icon, this.subtitle, this.done = true});
}

/// Vertical timeline with a dot and connector per step. Shared by the task
/// activity log and the request status history.
class TimelineView extends StatelessWidget {
  /// Steps from top to bottom.
  final List<TimelineStep> steps;

  /// Builds the timeline.
  const TimelineView({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: steps[i].done ? theme.primary : theme.cardColorLight,
                      ),
                      child: AppIcon(
                        steps[i].icon,
                        size: 15.sp,
                        color: steps[i].done ? theme.onPrimary : theme.grayText,
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(width: 2.w, color: theme.line),
                      ),
                  ],
                ),
                12.w.width,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textStyle.copyWith(
                            fontSize: 14.sp,
                            color: steps[i].done ? theme.text : theme.grayText,
                          ),
                        ),
                        if (steps[i].subtitle != null)
                          Text(
                            steps[i].subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.cardSubtitle,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
