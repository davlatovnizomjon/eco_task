import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';
import 'package:eco_task/infrastructure/repository/tasks_repository.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/dialog_icon.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';

import '../bloc/bloc.dart';
import 'task_wizard_view.dart';
import 'widgets/wizard_about_step.dart';
import 'widgets/wizard_when_step.dart';

/// Create (or, with [editId], edit) an order. Creating opens the three-step wizard; editing is one page that stacks the
/// same fields (name, description, price, deadline, address, photos). Provides [TaskFormBloc] over the app-wide task
/// and files repositories.
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
                title: TrWords.clOkT.tr(),
                subTitle: TrWords.clOkD.tr(),
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
              InnerBar(title: TrWords.clEdit.tr()),
              Expanded(
                child: state.status.isLoading && state.title.isEmpty
                    ? const Padding(padding: EdgeInsets.all(16), child: SmartLoading(count: 3))
                    : ListView(
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                        children: [const WizardAboutStep(), 18.h.height, const WizardWhenStep()],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
