import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/app_config.dart';
import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';

import '../bloc/bloc.dart';

/// What a signed-in client sees: clients are served by the Telegram bot, so
/// this screen names it (copyable) and offers to sign out. Provides
/// [ClientBotBloc] over the app-wide [SessionRepository].
class ClientBotScreen extends StatelessWidget {
  /// Builds the screen.
  const ClientBotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ClientBotBloc(session: RepositoryProvider.of<SessionRepository>(ctx)),
      child: const _ClientBotView(),
    );
  }
}

/// Renders the explanation and the two buttons.
class _ClientBotView extends StatelessWidget {
  /// Builds the body.
  const _ClientBotView();

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: TrWords.botTitle.tr(),
      showBack: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.w,
            height: 72.w,
            decoration: BoxDecoration(color: theme.primaryTint, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(AppIcons.send, size: 32.sp, color: theme.primaryDark),
          ),
          20.h.height,
          Text(
            TrWords.botTitle.tr(),
            textAlign: TextAlign.center,
            style: theme.cardTitle.copyWith(fontSize: 20.sp),
          ),
          8.h.height,
          Text(
            TrWords.botDesc.tr(args: [AppConfig.telegramBot]),
            textAlign: TextAlign.center,
            style: theme.cardSubtitle.copyWith(height: 1.4),
          ),
          24.h.height,
          Btn(
            text: TrWords.botCopy.tr(),
            icon: AppIcons.clip,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: AppConfig.telegramBot));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(TrWords.botCopied.tr())));
              }
            },
          ),
          10.h.height,
          Btn.unActive(
            text: TrWords.cLogout.tr(),
            icon: AppIcons.logout,
            onPressed: () => context.read<ClientBotBloc>().add(const ClientBotSignedOut()),
          ),
        ],
      ),
    );
  }
}
