import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/profile_summary.dart';
import 'package:eco_task/infrastructure/repository/reports_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';

import '../bloc/bloc.dart';
import 'widgets/profile_account_card.dart';
import 'widgets/profile_settings_card.dart';

/// Builds a role's own profile cards from the loaded [ProfileSummary] (null until the first answer).
typedef ProfileSections = List<Widget> Function(BuildContext context, ProfileSummary? summary);

/// Profile page skeleton every role reuses: account card, the role's own [sections], the settings card and sign-out.
/// Provides [ProfileBloc] over the app-wide reports and session repositories.
class ProfileFrame extends StatelessWidget {
  /// App bar title of the role's profile.
  final String title;

  /// The role's own cards, placed between the account card and the settings.
  final ProfileSections sections;

  /// Whether the settings card offers the daily reminder.
  final bool showReminder;

  /// Builds the profile page.
  const ProfileFrame({super.key, required this.title, required this.sections, this.showReminder = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ProfileBloc(
        reports: RepositoryProvider.of<ReportsRepository>(ctx),
        session: RepositoryProvider.of<SessionRepository>(ctx),
      )..add(const ProfileStarted()),
      child: _ProfileView(title: title, sections: sections, showReminder: showReminder),
    );
  }
}

/// Renders the frame's cards and handles pull-to-refresh, feedback and sign-out.
class _ProfileView extends StatelessWidget {
  /// App bar title.
  final String title;

  /// The role's own cards.
  final ProfileSections sections;

  /// Whether the reminder row is offered.
  final bool showReminder;

  /// Builds the view.
  const _ProfileView({required this.title, required this.sections, required this.showReminder});

  @override
  Widget build(BuildContext context) {
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<ProfileBloc>();
        return ScreenShell(
          title: title,
          big: true,
          showBack: false,
          padding: EdgeInsets.zero,
          child: RefreshList(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            gap: 20,
            onRefresh: () async {
              bloc.add(const ProfileRefreshed());
              await bloc.stream.firstWhere((s) => !s.refreshing);
            },
            children: [
              ProfileAccountCard(me: me),
              ...sections(context, state.summary),
              ProfileSettingsCard(showReminder: showReminder),
              Btn.unActive(
                text: TrWords.cLogout.tr(),
                icon: AppIcons.logout,
                onPressed: () => showCenterDialog(
                  PublicDialog.confirm(
                    title: TrWords.pfLogoutQ.tr(),
                    subTitle: TrWords.pfLogoutD.tr(),
                    activeBtnText: TrWords.cLogout.tr(),
                    unActiveBtnText: TrWords.cCancel.tr(),
                    onActiveBtnPressed: () {
                      homeTab.value = 0;
                      bloc.add(const ProfileSignedOut());
                    },
                  ),
                  context,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
