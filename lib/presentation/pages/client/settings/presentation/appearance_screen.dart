import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/infrastructure/repository/settings_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';

/// Settings › Appearance: theme mode (system / light / dark) and the
/// "follow the phone's font size" switch. Choices apply instantly and persist.
class AppearanceScreen extends StatelessWidget {
  /// Builds the screen.
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<SettingsRepository>(context);
    // Each theme choice: mode, label, glyph.
    final modes = [
      (ThemeMode.system, TrWords.setSystem, AppIcons.system),
      (ThemeMode.light, TrWords.setLight, AppIcons.sun),
      (ThemeMode.dark, TrWords.setDark, AppIcons.moon),
    ];
    return ScreenShell(
      title: TrWords.pfLook.tr(),
      padding: EdgeInsets.zero,
      child: ValueListenableBuilder<AppSettings>(
        valueListenable: repository.settings,
        builder: (context, settings, _) => ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
          children: [
            Text(TrWords.setTheme.tr(), style: theme.sectionLabel),
            8.h.height,
            CardWidget(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, (mode, label, icon)) in modes.indexed)
                    OptionTile(
                      title: label.tr(),
                      first: i == 0,
                      leading: AppIcon(icon, color: theme.textSecondary),
                      onTap: () => repository.setThemeMode(mode),
                      trailing: AppIcon(
                        settings.themeMode == mode ? AppIcons.checkc : AppIcons.eq,
                        color: settings.themeMode == mode ? theme.primary : theme.line,
                      ),
                    ),
                ],
              ),
            ),
            12.h.height,
            NoticeBanner(text: TrWords.setThemeNote.tr(), tone: StatusTone.primary),
            20.h.height,
            Text(TrWords.setExtra.tr(), style: theme.sectionLabel),
            8.h.height,
            CardWidget(
              padding: EdgeInsets.zero,
              child: OptionTile(
                title: TrWords.setBigger.tr(),
                subtitle: TrWords.setBiggerD.tr(),
                first: true,
                leading: AppIcon.tile(AppIcons.edit, tone: StatusTone.info, size: 36),
                trailing: Switch(value: settings.bigText, onChanged: repository.setBigText),
              ),
            ),
            8.h.height,
            Text(TrWords.setSavedNote.tr(), style: theme.cardSubtitle),
          ],
        ),
      ),
    );
  }
}
