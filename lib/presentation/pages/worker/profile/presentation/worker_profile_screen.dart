import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

import 'profile_frame.dart';

/// Profile section of the worker: the account card, this month's reward and paid totals with a history link, the
/// settings and sign-out.
class WorkerProfileScreen extends StatelessWidget {
  /// Builds the profile section.
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileFrame(
      title: TrWords.pfTitle.tr(),
      sections: (context, summary) => [
        if (summary != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(TrWords.pfMonth.tr(), style: theme.sectionLabel)),
                  GestureDetector(
                    onTap: () => context.push(Routes.history.path),
                    child: Text(TrWords.pfHistory.tr(), style: theme.badgeText.copyWith(color: theme.primary)),
                  ),
                ],
              ),
              8.h.height,
              CardWidget(
                child: Column(
                  children: [
                    InfoRow(label: TrWords.teamRewardOk.tr(), value: MoneyFormatter.display(summary.monthReward)),
                    InfoRow(label: TrWords.teamPaid.tr(), value: MoneyFormatter.display(summary.paidReward)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
