import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/settings_repository.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/public/widgets/select_mark.dart';
import 'package:eco_task/presentation/public/widgets/setting_row.dart';

/// Appearance sheet: system, light and dark theme as radio rows; choosing one repaints the app at once.
class ThemeSheet extends StatelessWidget {
  /// Builds the sheet.
  const ThemeSheet({super.key});

  /// Label of [mode] in the current language.
  static String labelOf(ThemeMode mode) => switch (mode) {
    ThemeMode.system => TrWords.setSystem.tr(),
    ThemeMode.light => TrWords.setLight.tr(),
    ThemeMode.dark => TrWords.setDark.tr(),
  };

  /// Opens the sheet over the profile tab.
  static Future<void> show(BuildContext context) => showBottomDialog<void>(const ThemeSheet(), context);

  @override
  Widget build(BuildContext context) {
    /// Device settings the choice is stored in.
    final repository = RepositoryProvider.of<SettingsRepository>(context);

    /// Each choice: mode and glyph.
    final modes = [
      (ThemeMode.system, AppIcons.system),
      (ThemeMode.light, AppIcons.sun),
      (ThemeMode.dark, AppIcons.moon),
    ];
    return ValueListenableBuilder<AppSettings>(
      valueListenable: repository.settings,
      builder: (context, settings, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TrWords.pfLook.tr(),
            style: theme.textStyle.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
          ),
          4.h.height,
          for (final (i, (mode, icon)) in modes.indexed)
            SettingRow(
              first: i == 0,
              inset: 0,
              icon: icon,
              title: labelOf(mode),
              bold: settings.themeMode == mode,
              trailing: SelectMark(shape: SelectShape.circle, on: settings.themeMode == mode),
              onTap: () {
                repository.setThemeMode(mode);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
