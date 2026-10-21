import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/settings_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';

/// Settings › Deadline reminder: which offsets remind before a deadline, the
/// morning digest and the daily reminder for overdue tasks.
class ReminderScreen extends StatelessWidget {
  /// Builds the screen.
  const ReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = RepositoryProvider.of<SettingsRepository>(context);
    // Reminder offsets: stored key and label.
    final offsets = [('m15', TrWords.setM15), ('h1', TrWords.setH1), ('d1', TrWords.setD1)];
    return ScreenShell(
      title: TrWords.pfReminder.tr(),
      padding: EdgeInsets.zero,
      child: ValueListenableBuilder<AppSettings>(
        valueListenable: repository.settings,
        builder: (context, settings, _) => ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
          children: [
            Text(TrWords.setBefore.tr(), style: theme.sectionLabel),
            8.h.height,
            CardWidget(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, (key, label)) in offsets.indexed)
                    OptionTile(
                      title: label.tr(),
                      first: i == 0,
                      onTap: () => repository.toggleReminder(key),
                      trailing: AppIcon(
                        settings.remind.contains(key) ? AppIcons.checkc : AppIcons.eq,
                        color: settings.remind.contains(key) ? theme.primary : theme.line,
                      ),
                    ),
                ],
              ),
            ),
            6.h.height,
            Text(TrWords.setMulti.tr(), style: theme.cardSubtitle),
            20.h.height,
            Text(TrWords.setDigest.tr(), style: theme.sectionLabel),
            8.h.height,
            CardWidget(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  OptionTile(
                    title: TrWords.setMorning.tr(),
                    subtitle: TrWords.setMorningD.tr(),
                    first: true,
                    trailing: Switch(value: settings.morning, onChanged: repository.setMorning),
                  ),
                  OptionTile(
                    title: TrWords.setSendTime.tr(),
                    trailing: Text('08:30', style: theme.cardTitle),
                  ),
                ],
              ),
            ),
            20.h.height,
            Text(TrWords.setLateTasks.tr(), style: theme.sectionLabel),
            8.h.height,
            CardWidget(
              padding: EdgeInsets.zero,
              child: OptionTile(
                title: TrWords.setDaily.tr(),
                subtitle: TrWords.setDailyD.tr(),
                first: true,
                trailing: Switch(value: settings.daily, onChanged: repository.setDaily),
              ),
            ),
            16.h.height,
            NoticeBanner(text: TrWords.setNeedsPerm.tr()),
          ],
        ),
      ),
    );
  }
}
