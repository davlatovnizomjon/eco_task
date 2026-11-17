import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';

import '../../bloc/bloc.dart';
import '../dialogs/due_date_dialog.dart';
import 'task_files_field.dart';

/// Wizard step 3: the deadline (date and time, picked in a sheet) and the address.
class WizardWhenStep extends StatefulWidget {
  /// Builds the step.
  const WizardWhenStep({super.key});

  @override
  State<WizardWhenStep> createState() => _WizardWhenStepState();
}

/// Owns the address controller.
class _WizardWhenStepState extends State<WizardWhenStep> {
  /// Controller of the address field.
  late final _address = TextEditingController(text: context.read<TaskFormBloc>().state.address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Bloc of the wizard.
    final bloc = context.read<TaskFormBloc>();
    return BlocBuilder<TaskFormBloc, TaskFormState>(
      buildWhen: (a, b) => a.due != b.due,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(TrWords.wzDue.tr(), style: theme.fieldLabel),
          6.h.height,
          GestureDetector(
            onTap: () async {
              /// Moment picked in the sheet; null when it was dismissed.
              final picked = await showBottomDialog<DateTime>(
                DueDateDialog(initial: state.due),
                context,
                title: TrWords.formDueSheet.tr(),
              );
              if (picked != null) bloc.add(TaskFormDueChanged(picked));
            },
            child: Container(
              height: 52.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: 12.circular,
                border: Border.all(color: theme.line),
              ),
              child: Row(
                children: [
                  AppIcon(AppIcons.cal, color: theme.grayText),
                  10.w.width,
                  Expanded(
                    child: Text(
                      DateFormatter.weekdayDay(state.due),
                      style: theme.textStyle.copyWith(fontWeight: FontWeight.w400),
                    ),
                  ),
                  Container(width: 1, height: 20.h, color: theme.line),
                  10.w.width,
                  AppIcon(AppIcons.clock, color: theme.grayText),
                  6.w.width,
                  Text(DateFormatter.time(state.due), style: theme.textStyle.copyWith(fontWeight: FontWeight.w400)),
                ],
              ),
            ),
          ),
          18.h.height,
          InputBox(
            controller: _address,
            title: TrWords.wzAddress.tr(),
            leftIcon: AppIcons.pin,
            onChanged: (v) => bloc.add(TaskFormAddressChanged(v)),
          ),
          18.h.height,
          const TaskFilesField(),
        ],
      ),
    );
  }
}
