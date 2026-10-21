import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/task_status.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/info_row.dart';
import 'package:eco_task/presentation/public/widgets/language_options.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/status_chip.dart';
import 'package:eco_task/utils/formatters/date_formatter.dart';
import 'package:eco_task/utils/formatters/money_formatter.dart';

/// Settings › Language: the language card plus a live sample of how dates,
/// amounts and statuses read in the chosen language.
class LanguageSettingsScreen extends StatelessWidget {
  /// Builds the screen.
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: TrWords.pfLang.tr(),
      padding: EdgeInsets.zero,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
        children: [
          Text(TrWords.langAppLang.tr(), style: theme.sectionLabel),
          8.h.height,
          const LanguageOptions(),
          20.h.height,
          Text(TrWords.langSample.tr(), style: theme.sectionLabel),
          8.h.height,
          CardWidget(
            child: Column(
              children: [
                InfoRow(
                  label: TrWords.langDate.tr(),
                  value: '${DateFormatter.day(DateTime.now())} ${DateTime.now().year}',
                ),
                InfoRow(label: TrWords.langAmount.tr(), value: MoneyFormatter.display(1000)),
                Row(
                  children: [
                    Expanded(child: Text(TrWords.langStatus.tr(), style: theme.cardSubtitle)),
                    StatusChip.task(TaskStatus.prog),
                  ],
                ),
              ],
            ),
          ),
          12.h.height,
          Text(TrWords.langNote.tr(), style: theme.cardSubtitle.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
