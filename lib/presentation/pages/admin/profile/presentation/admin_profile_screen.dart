import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/support_contact.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/settings_repository.dart';
import 'package:eco_task/infrastructure/repository/support_repository.dart';
import 'package:eco_task/presentation/pages/admin/settings/settings.dart';
import 'package:eco_task/presentation/public/dialogs/confirm_dialog.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/eco_switch.dart';
import 'package:eco_task/presentation/public/widgets/floating_tab_bar.dart';
import 'package:eco_task/presentation/public/widgets/large_title_header.dart';
import 'package:eco_task/presentation/public/widgets/refresh_list.dart';
import 'package:eco_task/presentation/public/widgets/role_pill.dart';
import 'package:eco_task/presentation/public/widgets/setting_row.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';
import 'package:eco_task/presentation/routes/home_tab.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';
import 'dialogs/support_sheet.dart';

/// Admin profile tab: the account card (avatar, name, phone, role, edit), the settings card (language, appearance,
/// notifications, help) and sign-out. Provides [ProfileBloc].
class AdminProfileScreen extends StatelessWidget {
  /// Builds the tab.
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ProfileBloc(
        support: RepositoryProvider.of<SupportRepository>(ctx),
        session: RepositoryProvider.of<SessionRepository>(ctx),
      )..add(const ProfileStarted()),
      child: const _ProfileView(),
    );
  }
}

/// Renders the account card and the settings.
class _ProfileView extends StatelessWidget {
  /// Builds the view.
  const _ProfileView();

  /// Asks to confirm, then signs out; the confirm button spins until the session is gone.
  void _signOut(BuildContext context) {
    /// Bloc of this tab, captured before the dialog's own route is pushed.
    final bloc = context.read<ProfileBloc>();
    ConfirmDialog.show(
      context,
      icon: AppIcons.logout,
      title: TrWords.pfSignoutQ.tr(),
      message: TrWords.pfSignoutD.tr(),
      confirmText: TrWords.cLogout.tr(),
      onConfirm: () async {
        homeTab.value = 0;
        bloc.add(const ProfileSignedOut());
        // The tab (and its bloc) is disposed once the router leaves for sign-in: wait for that, at most ten seconds.
        await bloc.stream
            .firstWhere((_) => false, orElse: () => bloc.state)
            .timeout(const Duration(seconds: 10), onTimeout: () => bloc.state);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Signed-in account shown on the card.
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;

    /// Device settings: theme mode and the notifications switch.
    final settings = RepositoryProvider.of<SettingsRepository>(context);
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        /// Bloc of this tab.
        final bloc = context.read<ProfileBloc>();
        return Column(
          children: [
            LargeTitleHeader(title: TrWords.pfTitle.tr()),
            Expanded(
              child: RefreshList(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, FloatingTabBar.inset(context)),
                gap: 14,
                onRefresh: () async {
                  bloc.add(const ProfileRefreshed());
                  await bloc.stream.firstWhere((s) => !s.refreshing);
                },
                children: [
                  CardWidget(
                    padding: EdgeInsets.zero,
                    decoration: theme.panelDecor.copyWith(borderRadius: 20.circular),
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 18.h),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Container(
                                  padding: 4.w.all,
                                  decoration: BoxDecoration(
                                    color: theme.primary.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: UserAvatar(me.ref, size: 84.w),
                                ),
                                12.h.height,
                                Text(
                                  me.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textStyle.copyWith(
                                    fontSize: 20.sp,
                                    height: 26 / 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (me.phone.isNotEmpty) ...[
                                  4.h.height,
                                  Text(
                                    PhoneFormatter.display(me.phone),
                                    style: theme.cardSubtitle.copyWith(fontSize: 14.sp),
                                  ),
                                ],
                                12.h.height,
                                RolePill(me.role),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12.h,
                          right: 12.w,
                          child: GestureDetector(
                            onTap: () => context.push(Routes.profileEdit.path),
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.primary.withValues(alpha: 0.12),
                                borderRadius: 12.circular,
                              ),
                              child: AppIcon(AppIcons.edit, size: 18.sp, color: theme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<AppSettings>(
                    valueListenable: settings.settings,
                    builder: (context, s, _) => CardWidget(
                      padding: EdgeInsets.zero,
                      decoration: theme.panelDecor,
                      child: Column(
                        children: [
                          SettingRow(
                            first: true,
                            icon: AppIcons.system,
                            title: TrWords.pfLook.tr(),
                            subtitle: ThemeSheet.labelOf(s.themeMode),
                            onTap: () => ThemeSheet.show(context),
                          ),
                          SettingRow(
                            icon: AppIcons.bell,
                            title: TrWords.pfNotifs.tr(),
                            subtitle: (s.permOn ? TrWords.pfOn : TrWords.pfOff).tr(),
                            trailing: EcoSwitch(
                              value: s.permOn,
                              onChanged: (v) => settings.setNotificationsAllowed(allowed: v),
                            ),
                          ),
                          SettingRow(
                            icon: AppIcons.headset,
                            title: TrWords.pfHelp.tr(),
                            subtitle: TrWords.pfHelpD.tr(),
                            onTap: () => SupportSheet.show(context, state.contact ?? SupportContact.none),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CardWidget(
                    padding: EdgeInsets.zero,
                    decoration: theme.panelDecor,
                    child: SettingRow(
                      first: true,
                      icon: AppIcons.logout,
                      tone: StatusTone.error,
                      title: TrWords.cLogout.tr(),
                      onTap: () => _signOut(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
