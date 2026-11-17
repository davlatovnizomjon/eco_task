import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/dialog_icon.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';

import '../bloc/bloc.dart';
import 'task_wizard_view.dart';
import 'widgets/wizard_about_step.dart';
import 'widgets/wizard_client_step.dart';
import 'widgets/wizard_when_step.dart';
import 'widgets/wizard_who_step.dart';

/// Create (or, with [editId], edit) a task. Creating opens the five-step wizard; editing is one page that stacks the
/// same fields (client type, name, description, price, deadline, address) and an assignees row that opens a picker
/// sheet. Provides [TaskFormBloc] over the app-wide task and team repositories.
class TaskFormScreen extends StatelessWidget {
  /// Id of the task to edit; null opens the creation wizard.
  final String? editId;

  /// Builds the form screen.
  const TaskFormScreen({super.key, this.editId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => TaskFormBloc(
        tasks: RepositoryProvider.of<TasksRepository>(ctx),
        team: RepositoryProvider.of<TeamRepository>(ctx),
        files: RepositoryProvider.of<FilesRepository>(ctx),
        editId: editId,
      )..add(const TaskFormStarted()),
      child: const _TaskFormView(),
    );
  }
}

/// Renders the wizard (create) or the edit page and reacts to a saved task.
class _TaskFormView extends StatelessWidget {
  /// Builds the view.
  const _TaskFormView();

  /// Opens the assignee picker: the wizard's checkable list in a sheet with a "select" button.
  void _pickAssignees(BuildContext context, TaskFormBloc bloc) => showBottomDialog<void>(
    BlocProvider.value(
      value: bloc,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TrWords.tdAssignees.tr(),
            style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
          ),
          10.h.height,
          Flexible(child: SingleChildScrollView(child: const WizardWhoStep())),
          12.h.height,
          Builder(
            builder: (context) =>
                Btn(text: TrWords.fltSelect.tr(), height: 52.h, onPressed: () => Navigator.pop(context)),
          ),
        ],
      ),
    ),
    context,
  );

  @override
  Widget build(BuildContext context) {
    /// Bloc of the form.
    final bloc = context.read<TaskFormBloc>();
    return BlocConsumer<TaskFormBloc, TaskFormState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) {
          if (bloc.editId != null) {
            context.pop();
          } else {
            showCenterDialog(
              PublicDialog(
                icon: DialogIcon.green(),
                title: TrWords.wzOkT.tr(),
                subTitle: TrWords.wzOkD.tr(),
                activeBtnText: TrWords.cOk.tr(),
                onActiveBtnPressed: () => context.pop(),
              ),
              context,
              isCancelable: false,
            );
          }
        }
      },
      builder: (context, state) {
        if (bloc.editId == null) return const TaskWizardView();
        return Scaffold(
          backgroundColor: theme.background,
          bottomNavigationBar: BottomActionBar(
            child: Btn(
              text: TrWords.formSave.tr(),
              height: 52.h,
              isLoading: state.status.isLoading && state.title.isNotEmpty,
              onPressed: () => bloc.add(const TaskFormSubmitted()),
            ),
          ),
          body: Column(
            children: [
              InnerBar(title: TrWords.formEdit.tr()),
              Expanded(
                child: state.status.isLoading && state.title.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3))
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                        children: [
                          const WizardClientStep(),
                          18.h.height,
                          const WizardAboutStep(),
                          18.h.height,
                          const WizardWhenStep(),
                          18.h.height,
                          Text(TrWords.tdAssignees.tr(), style: theme.fieldLabel),
                          6.h.height,
                          GestureDetector(
                            onTap: () => _pickAssignees(context, bloc),
                            child: Container(
                              height: 52.h,
                              padding: EdgeInsets.symmetric(horizontal: 14.w),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: 12.circular,
                                border: Border.all(color: state.visibleAssigneesError == null ? theme.line : theme.red),
                              ),
                              child: Row(
                                children: [
                                  AvatarStack([for (final a in state.assignees) a], size: 26.w),
                                  10.w.width,
                                  Expanded(
                                    child: Text(
                                      state.assignees.isEmpty
                                          ? TrWords.fltAllPeople.tr()
                                          : TrWords.tdNPeople.tr(args: ['${state.assignees.length}']),
                                      style: theme.textStyle.copyWith(fontWeight: FontWeight.w400),
                                    ),
                                  ),
                                  AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText),
                                ],
                              ),
                            ),
                          ),
                          if (state.visibleAssigneesError != null) ...[
                            6.h.height,
                            Text(state.visibleAssigneesError!, style: theme.cardSubtitle.copyWith(color: theme.red)),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
