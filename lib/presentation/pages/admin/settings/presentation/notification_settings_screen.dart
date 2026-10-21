import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/settings_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

/// Settings › Notifications: phone permission status, per-kind switches that
/// depend on the role, deadline reminders and quiet hours.
class NotificationSettingsScreen extends StatelessWidget {
  /// Builds the screen.
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<SettingsRepository>(context);
    final role = RepositoryProvider.of<SessionRepository>(context).role ?? UserRole.worker;
    // Switches of the "tasks" group (everyone but clients) and the "review & finance" group.
    final taskSwitches = [('newTask', TrWords.setNNew), ('state', TrWords.setNState), ('comment', TrWords.setNComment)];
    final financeSwitches = [
      if (role.isBoss) ...[
        ('review', TrWords.setNReview),
        ('expense', TrWords.setNExpense),
        ('request', TrWords.setNRequest),
      ],
      ('decision', TrWords.setNDecision),
    ];
    return ScreenShell(
      title: TrWords.pfNotifs.tr(),
      padding: EdgeInsets.zero,
      child: ValueListenableBuilder<AppSettings>(
        valueListenable: repository.settings,
        builder: (context, settings, _) => ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
          children: [
            CardWidget(
              padding: EdgeInsets.zero,
              child: OptionTile(
                title: (settings.permOn ? TrWords.setPhoneOk : TrWords.setPhoneOff).tr(),
                subtitle: (settings.permOn ? TrWords.setPushOn : TrWords.setPushOff).tr(),
                first: true,
                leading: AppIcon.tile(AppIcons.bell, tone: settings.permOn ? StatusTone.primary : StatusTone.warn),
                trailing: Switch(
                  value: settings.permOn,
                  onChanged: (v) => repository.setNotificationsAllowed(allowed: v),
                ),
              ),
            ),
            if (role != UserRole.client) ...[
              20.h.height,
              Text(TrWords.setGTasks.tr(), style: theme.sectionLabel),
              8.h.height,
              CardWidget(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, (key, label)) in taskSwitches.indexed)
                      OptionTile(
                        title: label.tr(),
                        first: i == 0,
                        trailing: Switch(
                          value: !settings.off.contains(key),
                          onChanged: (_) => repository.toggleNotification(key),
                        ),
                      ),
                    OptionTile(title: TrWords.pfReminder.tr(), onTap: () => context.push(Routes.settingsReminder.path)),
                  ],
                ),
              ),
              20.h.height,
              Text(TrWords.setGFin.tr(), style: theme.sectionLabel),
              8.h.height,
              CardWidget(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, (key, label)) in financeSwitches.indexed)
                      OptionTile(
                        title: label.tr(),
                        first: i == 0,
                        trailing: Switch(
                          value: !settings.off.contains(key),
                          onChanged: (_) => repository.toggleNotification(key),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            12.h.height,
            CardWidget(
              padding: EdgeInsets.zero,
              child: OptionTile(
                title: TrWords.setQuiet.tr(),
                subtitle: TrWords.setQuietD.tr(),
                first: true,
                leading: AppIcon(AppIcons.moon, color: theme.textSecondary),
                trailing: Switch(value: settings.quiet, onChanged: repository.setQuiet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
