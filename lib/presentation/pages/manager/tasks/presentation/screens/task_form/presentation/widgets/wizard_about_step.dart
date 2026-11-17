import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../../bloc/bloc.dart';

/// Wizard step 2: the task name, the description and the price with a so‘m / $ switch.
class WizardAboutStep extends StatefulWidget {
  /// Builds the step.
  const WizardAboutStep({super.key});

  @override
  State<WizardAboutStep> createState() => _WizardAboutStepState();
}

/// Owns the three text controllers.
class _WizardAboutStepState extends State<WizardAboutStep> {
  /// Controller of the name field.
  late final _title = TextEditingController(text: context.read<TaskFormBloc>().state.title);

  /// Controller of the description field.
  late final _desc = TextEditingController(text: context.read<TaskFormBloc>().state.description);

  /// Controller of the price field.
  late final _price = TextEditingController(text: context.read<TaskFormBloc>().state.reward);

  @override
  void dispose() {
    for (final c in [_title, _desc, _price]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Bloc of the wizard.
    final bloc = context.read<TaskFormBloc>();
    return BlocBuilder<TaskFormBloc, TaskFormState>(
      buildWhen: (a, b) => a.currency != b.currency || a.showErrors != b.showErrors,
      builder: (context, state) => Column(
        children: [
          InputBox(
            controller: _title,
            title: TrWords.wzTaskName.tr(),
            errorText: state.visibleTitleError,
            onChanged: (v) => bloc.add(TaskFormTitleChanged(v)),
          ),
          18.h.height,
          InputBox(
            controller: _desc,
            title: TrWords.wzDesc.tr(),
            lines: 4,
            onChanged: (v) => bloc.add(TaskFormDescriptionChanged(v)),
          ),
          18.h.height,
          InputBox(
            controller: _price,
            title: TrWords.wzPrice.tr(),
            inputType: TextInputType.number,
            inputFormatters: const [MoneyInputFormatter()],
            onChanged: (v) => bloc.add(TaskFormRewardChanged(v)),
            rightWidget: Padding(
              padding: EdgeInsets.all(6.w),
              child: Container(
                padding: 3.w.all,
                decoration: BoxDecoration(color: theme.cardColorLight, borderRadius: 10.circular),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (code, label) in [('uzs', TrWords.wzCurUzs), ('usd', TrWords.wzCurUsd)])
                      GestureDetector(
                        onTap: () => bloc.add(TaskFormCurrencyChanged(code)),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: state.currency == code ? theme.cardColor : null,
                            borderRadius: 8.circular,
                          ),
                          child: Text(
                            label.tr(),
                            style: theme.textStyle.copyWith(
                              fontSize: 14.sp,
                              fontWeight: state.currency == code ? FontWeight.w700 : FontWeight.w500,
                              color: state.currency == code ? theme.text : theme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
