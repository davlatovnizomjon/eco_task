import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/select_mark.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../../bloc/bloc.dart';

/// Wizard step 4: a checkable list of the staff to give the task to; the counter shows how many are picked.
class WizardWhoStep extends StatelessWidget {
  /// Builds the step.
  const WizardWhoStep({super.key});

  @override
  Widget build(BuildContext context) {
    /// Bloc of the wizard.
    final bloc = context.read<TaskFormBloc>();
    return BlocBuilder<TaskFormBloc, TaskFormState>(
      buildWhen: (a, b) => a.assignees != b.assignees || a.candidates != b.candidates || a.showErrors != b.showErrors,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(TrWords.wzWhoHint.tr(), style: theme.cardSubtitle)),
              if (state.assignees.isNotEmpty)
                Text(
                  TrWords.wzNPicked.tr(args: ['${state.assignees.length}']),
                  style: theme.textStyle.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.primary),
                ),
            ],
          ),
          10.h.height,
          CardWidget(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: theme.panelDecor.copyWith(
              border: Border.all(color: state.visibleAssigneesError == null ? theme.line : theme.red),
            ),
            child: Column(
              children: [
                for (final (i, u) in state.candidates.indexed)
                  InkWell(
                    onTap: () {
                      /// Picked people with [u] toggled.
                      final next = [...state.assignees];
                      final at = next.indexWhere((p) => p.id == u.id);
                      at >= 0 ? next.removeAt(at) : next.add(u.ref);
                      bloc.add(TaskFormAssigneesChanged(next));
                    },
                    child: Container(
                      constraints: BoxConstraints(minHeight: 60.h),
                      decoration: BoxDecoration(
                        border: i == 0 ? null : Border(top: BorderSide(color: theme.line)),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(u.ref, size: 36.w),
                          12.w.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textStyle),
                                3.h.height,
                                RolePill(u.role),
                              ],
                            ),
                          ),
                          SelectMark(shape: SelectShape.circle, on: state.assignees.any((p) => p.id == u.id)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (state.visibleAssigneesError != null) ...[
            6.h.height,
            Text(state.visibleAssigneesError!, style: theme.cardSubtitle.copyWith(color: theme.red)),
          ],
        ],
      ),
    );
  }
}
