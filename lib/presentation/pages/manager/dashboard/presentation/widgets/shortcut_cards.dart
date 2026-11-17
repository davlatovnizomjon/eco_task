import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/presentation/public/widgets/link_stat_card.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

/// Two side-by-side shortcuts to the employees and clients lists with their head counts.
class ShortcutCards extends StatelessWidget {
  /// Number of staff accounts.
  final int staff;

  /// Number of client accounts.
  final int clients;

  /// Builds the row.
  const ShortcutCards({super.key, required this.staff, required this.clients});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinkStatCard(
            icon: AppIcons.users,
            tone: StatusTone.primary,
            value: '$staff',
            label: TrWords.dashTeamMine.tr(),
            onTap: () => context.push(Routes.team.path),
          ),
        ),
        10.w.width,
        Expanded(
          child: LinkStatCard(
            icon: AppIcons.user,
            tone: StatusTone.info,
            value: '$clients',
            label: TrWords.dashClients.tr(),
            onTap: () => context.push(Routes.clients.path),
          ),
        ),
      ],
    );
  }
}
