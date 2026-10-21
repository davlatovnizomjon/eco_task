import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/settings_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/language_options.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

/// Settings list shared by every role's profile: language, appearance, notifications and (optionally) the reminder.
class ProfileSettingsCard extends StatelessWidget {
  /// Whether the daily-reminder row is offered; clients do not get it.
  final bool showReminder;

  /// Builds the card.
  const ProfileSettingsCard({super.key, this.showReminder = true});

  @override
  Widget build(BuildContext context) {
    final settings = RepositoryProvider.of<SettingsRepository>(context).settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TrWords.pfSettings.tr(), style: theme.sectionLabel),
        8.h.height,
        ValueListenableBuilder<AppSettings>(
          valueListenable: settings,
          builder: (context, s, _) => CardWidget(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                OptionTile(
                  title: TrWords.pfLang.tr(),
                  first: true,
                  subtitle: LanguageOptions.nameOf(context.locale),
                  leading: AppIcon(AppIcons.globe),
                  onTap: () => context.push(Routes.settingsLanguage.path),
                ),
                OptionTile(
                  title: TrWords.pfLook.tr(),
                  subtitle: switch (s.themeMode) {
                    ThemeMode.system => TrWords.setSystem.tr(),
                    ThemeMode.light => TrWords.setLight.tr(),
                    ThemeMode.dark => TrWords.setDark.tr(),
                  },
                  leading: AppIcon(AppIcons.system),
                  onTap: () => context.push(Routes.settingsAppearance.path),
                ),
                OptionTile(
                  title: TrWords.pfNotifs.tr(),
                  subtitle: (s.permOn ? TrWords.pfOn : TrWords.pfOff).tr(),
                  leading: AppIcon(AppIcons.bell),
                  onTap: () => context.push(Routes.settingsNotifications.path),
                ),
                if (showReminder)
                  OptionTile(
                    title: TrWords.pfReminder.tr(),
                    leading: AppIcon(AppIcons.alarm),
                    onTap: () => context.push(Routes.settingsReminder.path),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
