import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/infrastructure/repository/team_repository.dart';
import 'package:eco_task/presentation/public/dialogs/public_dialog.dart';
import 'package:eco_task/presentation/public/widgets/dialog_icon.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

import '../bloc/bloc.dart';

import 'package:eco_task/domain/common/enums/screen_status.dart';

/// Open a staff (or, with [client], a client) account. Provides
/// [MemberFormBloc] over the app-wide [TeamRepository].
class MemberFormScreen extends StatelessWidget {
  /// True when a client account is being opened.
  final bool client;

  /// Builds the form screen.
  const MemberFormScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final team = RepositoryProvider.of<SessionRepository>(context).user.value!.user.team;
    return BlocProvider(
      create: (ctx) =>
          MemberFormBloc(repository: RepositoryProvider.of<TeamRepository>(ctx), client: client, team: team),
      child: const _MemberFormView(),
    );
  }
}

/// Renders the account fields and the credentials dialog after creation.
class _MemberFormView extends StatelessWidget {
  /// Builds the form body.
  const _MemberFormView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<MemberFormBloc>();
    return BlocConsumer<MemberFormBloc, MemberFormState>(
      listenWhen: (prev, cur) => cur.response != null || cur.created != null,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        final created = state.created;
        if (created == null) return;
        // Hand-over dialog: the boss shares these two values with the new user.
        showCenterDialog(
          PublicDialog(
            icon: DialogIcon.green(),
            title: TrWords.teamCreated.tr(),
            subTitle: '${TrWords.teamLogin.tr()}: ${created.id}\n${TrWords.teamTempPwd.tr()}: ${state.password}',
            warningText: TrWords.teamShareCreds.tr(),
            onActiveBtnPressed: () => context.pop(),
          ),
          context,
          isCancelable: false,
        );
      },
      builder: (context, state) => ScreenShell(
        title: bloc.client ? TrWords.teamAddClient.tr() : TrWords.teamAddEmp.tr(),
        backIcon: AppIcons.x,
        padding: EdgeInsets.zero,
        bottomBar: Btn(
          text: bloc.client ? TrWords.teamOpenClient.tr() : TrWords.teamOpenAcc.tr(),
          isLoading: state.status.isLoading,
          onPressed: () => bloc.add(const MemberFormSubmitted()),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          children: [
            InputBox(
              title: TrWords.teamFullName.tr(),
              errorText: state.visibleNameError,
              onChanged: (v) => bloc.add(MemberFormNameChanged(v)),
            ),
            16.h.height,
            InputBox(
              title: TrWords.teamPhone.tr(),
              hint: '+998 90 123 45 67',
              leftIcon: AppIcons.phone,
              inputType: TextInputType.phone,
              inputFormatters: const [PhoneInputFormatter()],
              errorText: state.visiblePhoneError,
              onChanged: (v) => bloc.add(MemberFormPhoneChanged(v)),
            ),
            16.h.height,
            InputBox(
              title: TrWords.teamLogin.tr(),
              errorText: state.visibleLoginError,
              onChanged: (v) => bloc.add(MemberFormLoginChanged(v)),
            ),
            16.h.height,
            Text(TrWords.teamTempPwd.tr(), style: theme.fieldLabel),
            6.h.height,
            CardWidget(
              child: Row(
                children: [
                  Expanded(child: Text(state.password, style: theme.cardTitle.copyWith(letterSpacing: 1))),
                  Btn.ghost(
                    text: TrWords.teamRegen.tr(),
                    icon: AppIcons.refresh,
                    onPressed: () => bloc.add(const MemberFormPasswordRegenerated()),
                  ),
                ],
              ),
            ),
            6.h.height,
            Text(TrWords.teamPwdHelp.tr(), style: theme.cardSubtitle),
            16.h.height,
            if (bloc.client) ...[
              InputBox(
                title: TrWords.teamAddressOpt.tr(),
                leftIcon: AppIcons.pin,
                onChanged: (v) => bloc.add(MemberFormAddressChanged(v)),
              ),
              16.h.height,
              NoticeBanner(text: TrWords.teamShareCreds.tr(), tone: StatusTone.info),
            ] else ...[
              Text(TrWords.teamRole.tr(), style: theme.fieldLabel),
              6.h.height,
              CardWidget(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, (role, description)) in [
                      (UserRole.worker, TrWords.teamWorkerDesc),
                      (UserRole.assistant, TrWords.teamManagerDesc),
                    ].indexed)
                      OptionTile(
                        title: role.title,
                        subtitle: description.tr(),
                        first: i == 0,
                        onTap: () => bloc.add(MemberFormRoleChanged(role)),
                        trailing: AppIcon(
                          state.role == role ? AppIcons.checkc : AppIcons.eq,
                          color: state.role == role ? theme.primary : theme.line,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
