import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_priority.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/picker_box.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../bloc/bloc.dart';
import 'dialogs/assignee_picker_dialog.dart';
import 'dialogs/due_date_dialog.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Create (or, with [editId], edit) a task. Provides [TaskFormBloc] over the
/// app-wide task and team repositories.
class TaskFormScreen extends StatelessWidget {
  /// Id of the task to edit; null opens an empty form.
  final String? editId;

  /// Builds the form screen.
  const TaskFormScreen({super.key, this.editId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TaskFormBloc(
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
        team: RepositoryProvider.of<TeamRepository>(ctx),
        editId: editId,
      )..add(const TaskFormStarted()),
      child: const _TaskFormView(),
    );
  }
}

/// Holds the text controllers and renders the form.
class _TaskFormView extends StatefulWidget {
  /// Builds the form body.
  const _TaskFormView();

  @override
  State<_TaskFormView> createState() => _TaskFormViewState();
}

/// Owns every controller; fills them once when an edited task arrives.
class _TaskFormViewState extends State<_TaskFormView> {
  /// Controller of the title field.
  final _title = TextEditingController();

  /// Controller of the reward field.
  final _reward = TextEditingController();

  /// Controller of the description field.
  final _description = TextEditingController();

  /// Controller of the expected-result field.
  final _expected = TextEditingController();

  /// One quota controller per assignee id, created on demand.
  final Map<String, TextEditingController> _quotas = {};

  /// True after the edited task's values were copied into the controllers.
  bool _filled = false;

  @override
  void dispose() {
    for (final c in [_title, _reward, _description, _expected, ..._quotas.values]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskFormBloc>();
    return BlocConsumer<TaskFormBloc, TaskFormState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved || (!_filled && cur.status.isSuccess),
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) context.pop();
        // Copy the loaded task into the controllers exactly once (edit mode).
        if (!_filled && state.status.isSuccess) {
          _filled = true;
          _title.text = state.title;
          _reward.text = state.reward;
          _description.text = state.description;
          _expected.text = state.expected;
        }
      },
      builder: (context, state) {
        final editing = bloc.editId != null;
        return ScreenShell(
          title: editing ? TrWords.formEdit.tr() : TrWords.formNew.tr(),
          backIcon: AppIcons.x,
          padding: EdgeInsets.zero,
          bottomBar: Btn(
            text: editing ? TrWords.formSave.tr() : TrWords.formCreate.tr(),
            isLoading: state.status.isLoading && state.title.isNotEmpty,
            onPressed: () => bloc.add(const TaskFormSubmitted()),
          ),
          child: state.status.isLoading && state.title.isEmpty
              ? const SmartLoading(count: 3)
              : ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  children: [
                    InputBox(
                      controller: _title,
                      title: TrWords.formName.tr(),
                      errorText: state.visibleTitleError,
                      onChanged: (v) => bloc.add(TaskFormTitleChanged(v)),
                    ),
                    18.h.height,
                    Text(TrWords.formTo.tr(), style: theme.fieldLabel),
                    6.h.height,
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final person in state.assignees)
                          FilterPill(
                            label: person.firstName,
                            leading: UserAvatar(person, size: 24.w),
                            icon: AppIcons.x,
                            selected: true,
                            onTap: () => bloc.add(
                              TaskFormAssigneesChanged([
                                for (final p in state.assignees)
                                  if (p.id != person.id) p,
                              ]),
                            ),
                          ),
                        Btn.ghost(
                          text: TrWords.cAdd.tr(),
                          icon: AppIcons.plus,
                          onPressed: () => showBottomDialog(
                            BlocProvider.value(value: bloc, child: const AssigneePickerDialog()),
                            context,
                            title: TrWords.formPickTitle.tr(),
                          ),
                        ),
                      ],
                    ),
                    if (state.visibleAssigneesError != null)
                      Padding(
                        padding: EdgeInsets.only(top: 6.h, left: 4.w),
                        child: Text(state.visibleAssigneesError!, style: theme.cardSubtitle.copyWith(color: theme.red)),
                      ),
                    if (state.assignees.isNotEmpty) ...[
                      12.h.height,
                      CardWidget(
                        padding: EdgeInsets.zero,
                        child: OptionTile(
                          title: TrWords.formShareEach.tr(),
                          first: true,
                          trailing: Switch(value: state.split, onChanged: (v) => bloc.add(TaskFormSplitToggled(v))),
                        ),
                      ),
                    ],
                    if (state.split)
                      for (final person in state.assignees) ...[
                        12.h.height,
                        Row(
                          children: [
                            UserAvatar(person),
                            10.w.width,
                            Expanded(
                              child: Text(
                                person.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textStyle,
                              ),
                            ),
                            SizedBox(
                              width: 120.w,
                              child: InputBox(
                                controller: _quotas.putIfAbsent(
                                  person.id,
                                  () => TextEditingController(text: state.shares[person.id] ?? ''),
                                ),
                                hint: TrWords.formQty.tr(),
                                inputType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                onChanged: (v) => bloc.add(TaskFormShareChanged(person.id, v)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    18.h.height,
                    PickerBox(
                      title: TrWords.formDue.tr(),
                      leftIcon: AppIcons.cal,
                      value: DateFormatter.dayTime(state.due),
                      onTap: () async {
                        final picked = await showBottomDialog<DateTime>(
                          DueDateDialog(initial: state.due),
                          context,
                          title: TrWords.formDueSheet.tr(),
                        );
                        if (picked != null) bloc.add(TaskFormDueChanged(picked));
                      },
                    ),
                    18.h.height,
                    Text(TrWords.formPriority.tr(), style: theme.fieldLabel),
                    6.h.height,
                    SegmentedTabs(
                      labels: [for (final p in TaskPriority.values) p.title],
                      selected: state.priority.index,
                      onChanged: (i) => bloc.add(TaskFormPriorityChanged(TaskPriority.values[i])),
                    ),
                    18.h.height,
                    InputBox(
                      controller: _reward,
                      title: '${TrWords.formReward.tr()} (\$)',
                      leftIcon: AppIcons.coins,
                      inputType: TextInputType.number,
                      inputFormatters: const [MoneyInputFormatter()],
                      onChanged: (v) => bloc.add(TaskFormRewardChanged(v)),
                    ),
                    6.h.height,
                    Text(TrWords.formRewardHelp.tr(), style: theme.cardSubtitle),
                    22.h.height,
                    Text(TrWords.formExtra.tr(), style: theme.sectionLabel),
                    10.h.height,
                    InputBox(
                      controller: _description,
                      title: TrWords.formDesc.tr(),
                      lines: 3,
                      onChanged: (v) => bloc.add(TaskFormDescriptionChanged(v)),
                    ),
                    14.h.height,
                    InputBox(
                      controller: _expected,
                      title: TrWords.formExpected.tr(),
                      leftIcon: AppIcons.flag,
                      onChanged: (v) => bloc.add(TaskFormExpectedChanged(v)),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
