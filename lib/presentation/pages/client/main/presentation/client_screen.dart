import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/side_menu_shell.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import 'package:eco_task/presentation/pages/client/client_bot/client_bot.dart';

/// Signed-in UI of the client: a left menu with the Telegram-bot notice (the client's only section) and the
/// language and appearance settings pushed from it.
class ClientScreen extends StatelessWidget {
  /// Builds the client shell.
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SideMenuShell(
      items: [
        SideMenuItem.section(TrWords.botTitle.tr(), AppIcons.send, const ClientBotScreen()),
        SideMenuItem.push(TrWords.pfLang.tr(), AppIcons.globe, Routes.settingsLanguage.path),
        SideMenuItem.push(TrWords.pfLook.tr(), AppIcons.system, Routes.settingsAppearance.path),
      ],
    );
  }
}
