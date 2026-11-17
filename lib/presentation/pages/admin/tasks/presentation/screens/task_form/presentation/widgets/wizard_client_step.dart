import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/select_mark.dart';

import '../../bloc/bloc.dart';

/// Wizard step 1: choose whether the task is for a private person or an organization, and name the organization or
/// the person. Reads and writes [TaskFormBloc].
class WizardClientStep extends StatefulWidget {
  /// Builds the step.
  const WizardClientStep({super.key});

  @override
  State<WizardClientStep> createState() => _WizardClientStepState();
}

/// Owns the controller of the name field.
class _WizardClientStepState extends State<WizardClientStep> {
  /// Controller of the name field, filled from the bloc when the step opens.
  late final _name = TextEditingController(text: context.read<TaskFormBloc>().state.client);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Bloc of the wizard.
    final bloc = context.read<TaskFormBloc>();
    return BlocBuilder<TaskFormBloc, TaskFormState>(
      buildWhen: (a, b) => a.clientIsOrg != b.clientIsOrg || a.showErrors != b.showErrors,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (isOrg, icon, title, hint) in [
            (false, AppIcons.user, TrWords.wzPerson, TrWords.wzPersonD),
            (true, AppIcons.building, TrWords.wzOrg, TrWords.wzOrgD),
          ]) ...[
            GestureDetector(
              onTap: () => bloc.add(TaskFormClientChanged(isOrg: isOrg, name: _name.text)),
              child: Container(
                padding: EdgeInsets.all(16.w),
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: state.clientIsOrg == isOrg ? theme.primary.withValues(alpha: 0.06) : theme.cardColor,
                  borderRadius: 16.circular,
                  border: Border.all(color: state.clientIsOrg == isOrg ? theme.primary : theme.line, width: 1.5),
                ),
                child: Row(
                  children: [
                    AppIcon.tile(icon, tone: StatusTone.primary, size: 44),
                    14.w.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.tr(),
                            style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w700),
                          ),
                          2.h.height,
                          Text(hint.tr(), style: theme.cardSubtitle),
                        ],
                      ),
                    ),
                    SelectMark(shape: SelectShape.radio, on: state.clientIsOrg == isOrg),
                  ],
                ),
              ),
            ),
          ],
          8.h.height,
          InputBox(
            controller: _name,
            title: (state.clientIsOrg ? TrWords.wzOrgName : TrWords.wzPersonName).tr(),
            hint: state.clientIsOrg ? TrWords.wzOrgHint.tr() : '',
            errorText: state.showErrors && state.step == 0 ? state.stepError : null,
            onChanged: (v) => bloc.add(TaskFormClientChanged(isOrg: state.clientIsOrg, name: v)),
          ),
        ],
      ),
    );
  }
}
