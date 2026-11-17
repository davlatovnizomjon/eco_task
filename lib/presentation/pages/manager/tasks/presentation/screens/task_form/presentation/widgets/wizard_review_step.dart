import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import '../../bloc/bloc.dart';

/// Wizard step 5: a read-only summary in four cards (client, task, deadline and place, assignees), each with a
/// "change" link that jumps back to its step.
class WizardReviewStep extends StatelessWidget {
  /// Builds the step.
  const WizardReviewStep({super.key});

  /// Card with a gray caps [title], a green "change" link to [step] and the [rows] below.
  Widget _card(TaskFormBloc bloc, String title, int step, List<Widget> rows) => CardWidget(
    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    decoration: theme.panelDecor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title.toUpperCase(), style: theme.fieldLabel.copyWith(letterSpacing: 0.5))),
            GestureDetector(
              onTap: () => bloc.add(TaskFormStepChanged(step)),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AppIcon(AppIcons.edit, size: 16.sp, color: theme.primary),
                  4.w.width,
                  Text(
                    TrWords.wzChange.tr(),
                    style: theme.textStyle.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: theme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        10.h.height,
        ...rows,
      ],
    ),
  );

  /// One icon + text line of a card; hidden when [text] is empty.
  Widget _line(String icon, String text) => text.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(icon, size: 20.sp, color: theme.grayText),
              10.w.width,
              Expanded(
                child: Text(
                  text,
                  style: theme.textStyle.copyWith(height: 21 / 15, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ),
        );

  @override
  Widget build(BuildContext context) {
    /// Bloc of the wizard.
    final bloc = context.read<TaskFormBloc>();

    /// Current draft.
    final s = bloc.state;

    /// Price written with its currency; empty without a price.
    final price = MoneyFormatter.parse(s.reward) == 0
        ? ''
        : MoneyFormatter.amount(MoneyFormatter.parse(s.reward), s.currency);
    return Column(
      children: [
        _card(bloc, TrWords.wzClientCard.tr(), 0, [
          Text(
            s.client.isEmpty ? (s.clientIsOrg ? TrWords.wzOrg : TrWords.wzPerson).tr() : s.client,
            style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          Text((s.clientIsOrg ? TrWords.wzOrg : TrWords.wzPerson).tr(), style: theme.cardSubtitle),
        ]),
        12.h.height,
        _card(bloc, TrWords.wzS2.tr(), 1, [
          Text(
            s.title,
            style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
          if (s.description.trim().isNotEmpty) ...[
            4.h.height,
            Text(
              s.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.cardSubtitle.copyWith(fontSize: 14.sp, height: 20 / 14),
            ),
          ],
          _line(AppIcons.coins, price),
        ]),
        12.h.height,
        _card(bloc, TrWords.wzWhenCard.tr(), 2, [
          _line(AppIcons.cal, DateFormatter.dayShortTime(s.due)),
          _line(AppIcons.pin, s.address),
        ]),
        12.h.height,
        _card(bloc, TrWords.wzAssigneesCard.tr(), 3, [
          for (final u in s.assignees)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Row(
                children: [
                  UserAvatar(u, size: 28.w),
                  10.w.width,
                  Expanded(
                    child: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textStyle),
                  ),
                  if (u.role != null) RolePill(u.role!),
                ],
              ),
            ),
        ]),
      ],
    );
  }
}
