import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/public/widgets/app_loader.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/search_field.dart';
import 'package:eco_task/presentation/public/widgets/select_mark.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../../bloc/bloc.dart';

/// Assignee picker of the task filter: a searchable staff list with a round check per person and the "N selected"
/// counter. Lists the staff its opener's [TasksBloc] loaded; "select" resolves to the picked ids.
class AssigneeFilterDialog extends StatefulWidget {
  /// Ids picked before the sheet opened.
  final Set<String> initial;

  /// Builds the sheet.
  const AssigneeFilterDialog({super.key, required this.initial});

  /// Opens the picker over the filter sheet; resolves to the picked ids, or null when it was dismissed.
  static Future<Set<String>?> show(BuildContext context, TasksBloc bloc, Set<String> initial) =>
      showBottomDialog<Set<String>>(
        BlocProvider.value(
          value: bloc,
          child: AssigneeFilterDialog(initial: initial),
        ),
        context,
      );

  @override
  State<AssigneeFilterDialog> createState() => _AssigneeFilterDialogState();
}

/// Holds the picked ids and the search text.
class _AssigneeFilterDialogState extends State<AssigneeFilterDialog> {
  /// Ids currently checked.
  late final Set<String> _picked = {...widget.initial};

  /// Lower-cased search text; empty shows everyone.
  String _search = '';

  @override
  Widget build(BuildContext context) {
    /// State of the tasks tab: the staff list and whether it is still loading.
    final state = context.watch<TasksBloc>().state;

    /// Staff whose name contains the search text.
    final people = state.staff.where((u) => u.name.toLowerCase().contains(_search)).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  TrWords.fltPeople.tr(),
                  style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
                ),
              ),
              if (_picked.isNotEmpty)
                Text(
                  TrWords.fltNSelected.tr(args: ['${_picked.length}']),
                  style: theme.textStyle.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.primary),
                ),
            ],
          ),
          10.h.height,
          SearchField(
            hint: TrWords.fltSearchStaff.tr(),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
          6.h.height,
          Expanded(
            child: state.staffLoading
                ? const Center(child: AppLoader())
                : people.isEmpty
                ? EmptyView.tile(title: TrWords.fltStaffEmpty.tr(), icon: AppIcons.users)
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: people.length,
                    itemBuilder: (context, i) => InkWell(
                      onTap: () => setState(() {
                        if (!_picked.remove(people[i].id)) _picked.add(people[i].id);
                      }),
                      child: Container(
                        constraints: BoxConstraints(minHeight: 60.h),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: theme.line)),
                        ),
                        child: Row(
                          children: [
                            UserAvatar(people[i].ref, size: 36.w),
                            12.w.width,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    people[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textStyle,
                                  ),
                                  3.h.height,
                                  RolePill(people[i].role),
                                ],
                              ),
                            ),
                            SelectMark(shape: SelectShape.circle, on: _picked.contains(people[i].id)),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          12.h.height,
          Row(
            children: [
              Expanded(
                flex: 10,
                child: Btn.unActive(text: TrWords.cCancel.tr(), height: 52.h, onPressed: () => Navigator.pop(context)),
              ),
              10.w.width,
              Expanded(
                flex: 16,
                child: Btn(
                  text: TrWords.fltSelect.tr(),
                  height: 52.h,
                  onPressed: () => Navigator.pop(context, _picked),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
