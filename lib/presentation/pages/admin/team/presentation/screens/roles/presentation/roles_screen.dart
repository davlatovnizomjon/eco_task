import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Role and permission switches of a staff member (admin). Provides
/// [RolesBloc] over the app-wide [TeamRepository].
class RolesScreen extends StatelessWidget {
  /// Id of the staff member to edit.
  final String userId;

  /// Builds the screen.
  const RolesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          RolesBloc(repository: RepositoryProvider.of<TeamRepository>(ctx), userId: userId)..add(const RolesStarted()),
      child: const _RolesView(),
    );
  }
}

/// Renders the role switch and the permission groups.
class _RolesView extends StatelessWidget {
  /// Builds the screen body.
  const _RolesView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RolesBloc, RolesState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) context.pop();
      },
      builder: (context, state) {
        final bloc = context.read<RolesBloc>();
        final user = state.user;
        final permissions = state.permissions;
        if (user == null || permissions == null) {
          return ScreenShell(
            title: TrWords.perm2Title.tr(),
            child: state.status.isError
                ? EmptyView(
                    title: TrWords.cLoadFailed.tr(),
                    message: TrWords.cLoadFailedDesc.tr(),
                    icon: AppIcons.alert,
                    onRetry: () => bloc.add(const RolesStarted()),
                  )
                : const SmartLoading(count: 2),
          );
        }
        // Switch groups: the group label and its (key, label, optional subtitle) rows.
        final groups = [
          (
            TrWords.perm2Tasks,
            [
              ('create', TrWords.perm2Create, null),
              ('reward', TrWords.perm2Reward, null),
              ('approve', TrWords.perm2Approve, null),
              ('editOthers', TrWords.perm2EditOthers, TrWords.perm2OnlyOwn.tr()),
            ],
          ),
          (
            TrWords.perm2Finance,
            [
              ('approveExpense', TrWords.perm2ApproveExp, TrWords.perm2Limit.tr(args: [MoneyFormatter.display(100)])),
              ('viewPayments', TrWords.perm2ViewPay, null),
            ],
          ),
        ];
        return ScreenShell(
          title: TrWords.perm2Title.tr(),
          padding: EdgeInsets.zero,
          bottomBar: Btn(
            text: TrWords.cSave.tr(),
            isLoading: state.busy,
            onPressed: () => bloc.add(const RolesSaved()),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            children: [
              Row(
                children: [
                  UserAvatar(user.ref, size: 44.w),
                  12.w.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.cardTitle),
                        Text(PhoneFormatter.display(user.phone), style: theme.cardSubtitle),
                      ],
                    ),
                  ),
                ],
              ),
              16.h.height,
              Text(TrWords.teamRole.tr(), style: theme.fieldLabel),
              6.h.height,
              SegmentedTabs(
                labels: [UserRole.worker.title, UserRole.assistant.title, UserRole.owner.title],
                selected: [UserRole.worker, UserRole.assistant, UserRole.owner].indexOf(permissions.role),
                onChanged: (i) => bloc.add(RolesRoleChanged([UserRole.worker, UserRole.assistant, UserRole.owner][i])),
              ),
              16.h.height,
              CardWidget(
                padding: EdgeInsets.zero,
                child: OptionTile(
                  title: TrWords.perm2TeamManaged.tr(),
                  subtitle: user.team,
                  first: true,
                  leading: AppIcon(AppIcons.users, color: theme.textSecondary),
                ),
              ),
              for (final (label, rows) in groups) ...[
                20.h.height,
                Text(label.tr(), style: theme.sectionLabel),
                8.h.height,
                CardWidget(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, (key, rowLabel, subtitle)) in rows.indexed)
                        OptionTile(
                          title: rowLabel.tr(),
                          subtitle: subtitle,
                          first: i == 0,
                          trailing: Switch(
                            value: permissions.flags[key] ?? false,
                            onChanged: (_) => bloc.add(RolesFlagToggled(key)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              16.h.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.shield, size: 18.sp, color: theme.primary),
                  8.w.width,
                  Expanded(child: Text(TrWords.perm2Scope.tr(), style: theme.cardSubtitle)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
