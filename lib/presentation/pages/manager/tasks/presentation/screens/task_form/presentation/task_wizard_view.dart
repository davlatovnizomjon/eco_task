import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/presentation/public/widgets/app_loader.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';

import '../bloc/bloc.dart';
import 'widgets/wizard_about_step.dart';
import 'widgets/wizard_client_step.dart';
import 'widgets/wizard_review_step.dart';
import 'widgets/wizard_when_step.dart';
import 'widgets/wizard_who_step.dart';

/// The five-step "new task" wizard: a back bar, a five-segment progress line, the step title, the step body and a
/// bottom button ("Keyingi", then "Yaratish va yuborish" on the last step). Back steps one step, then leaves.
class TaskWizardView extends StatelessWidget {
  /// Builds the wizard around the [TaskFormBloc] in scope.
  const TaskWizardView({super.key});

  /// Title of each step.
  static final _titles = [TrWords.wzS1, TrWords.wzS2, TrWords.wzS3, TrWords.wzS4, TrWords.wzS5];

  @override
  Widget build(BuildContext context) {
    /// Bloc of the wizard.
    final bloc = context.read<TaskFormBloc>();
    return BlocBuilder<TaskFormBloc, TaskFormState>(
      buildWhen: (a, b) => a.step != b.step || a.status != b.status,
      builder: (context, state) {
        /// True on the last step, where the button creates the task.
        final last = state.step == 4;
        return PopScope(
          canPop: state.step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) bloc.add(TaskFormStepChanged(state.step - 1));
          },
          child: Scaffold(
            backgroundColor: theme.background,
            bottomNavigationBar: BottomActionBar(
              child: Btn(
                text: (last ? TrWords.wzCreateSend : TrWords.wzNext).tr(),
                height: 52.h,
                icon: last ? null : AppIcons.arrow,
                isLoading: state.status.isLoading && state.candidates.isNotEmpty && last,
                onPressed: () => bloc.add(last ? const TaskFormSubmitted() : TaskFormStepChanged(state.step + 1)),
              ),
            ),
            body: Column(
              children: [
                InnerBar(
                  title: TrWords.wzTitle.tr(),
                  onBack: () => state.step == 0 ? context.pop() : bloc.add(TaskFormStepChanged(state.step - 1)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: TrWords.wzStepN.tr(args: ['${state.step + 1}']),
                        child: Row(
                          children: [
                            for (var i = 0; i < 5; i++) ...[
                              if (i > 0) 6.w.width,
                              Expanded(
                                child: Container(
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: i <= state.step ? theme.primary : theme.line,
                                    borderRadius: 2.circular,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      10.h.height,
                      Text(
                        _titles[state.step].tr(),
                        style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: state.status.isLoading && state.candidates.isEmpty
                      ? const Center(child: AppLoader())
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                          child: switch (state.step) {
                            0 => const WizardClientStep(),
                            1 => const WizardAboutStep(),
                            2 => const WizardWhenStep(),
                            3 => const WizardWhoStep(),
                            _ => const WizardReviewStep(),
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
