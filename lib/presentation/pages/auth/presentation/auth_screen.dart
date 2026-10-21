import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/app_config.dart';
import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/logo.dart';
import 'package:eco_task/presentation/public/widgets/notice_banner.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';

import '../bloc/bloc.dart';

/// Login and password sign-in — the app's entry while there is no session.
/// Provides [AuthBloc] over the app-wide [SessionRepository].
class AuthScreen extends StatelessWidget {
  /// Builds the sign-in screen.
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AuthBloc(repository: RepositoryProvider.of<SessionRepository>(ctx)),
      child: const _AuthView(),
    );
  }
}

/// Holds the two field controllers and renders the form.
class _AuthView extends StatefulWidget {
  /// Builds the form body.
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

/// Owns the controllers and disposes them with the screen.
class _AuthViewState extends State<_AuthView> {
  /// Controller of the login field.
  final _login = TextEditingController();

  /// Controller of the password field.
  final _password = TextEditingController();

  /// True while the password is masked; toggled by the eye button.
  bool _obscure = true;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Nothing here navigates on success: signing in publishes the session and
      // the router's redirect sends the user on.
      listenWhen: (prev, cur) => cur.response != null,
      listener: (context, state) => showScreenResponse(context, state.response!),
      builder: (context, state) {
        final bloc = context.read<AuthBloc>();
        final wrong = state.credentialsWrong;
        return ScreenShell(
          title: TrWords.loginTitle.tr(),
          showBack: false,
          padding: EdgeInsets.zero,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
            children: [
              Logo(size: 26.sp),
              12.h.height,
              Text(
                TrWords.loginHint.tr(),
                style: theme.textStyle.copyWith(fontWeight: FontWeight.w400, color: theme.textSecondary),
              ),
              24.h.height,
              if (wrong) ...[
                NoticeBanner(
                  text: TrWords.loginWrong.tr(args: ['${state.attemptsLeft}']),
                  tone: StatusTone.error,
                  icon: AppIcons.alert,
                ),
                16.h.height,
              ],
              InputBox(
                controller: _login,
                title: TrWords.loginLogin.tr(),
                leftIcon: AppIcons.user,
                errorText: wrong ? '' : state.visibleLoginError,
                onChanged: (v) => bloc.add(AuthLoginChanged(v)),
              ),
              18.h.height,
              InputBox(
                controller: _password,
                title: TrWords.loginPassword.tr(),
                leftIcon: AppIcons.lock,
                isPassword: _obscure,
                errorText: wrong ? '' : state.visiblePasswordError,
                onChanged: (v) => bloc.add(AuthPasswordChanged(v)),
                rightWidget: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: AppIcon(AppIcons.eye, color: theme.grayText),
                ),
              ),
              28.h.height,
              Btn(
                text: TrWords.loginSubmit.tr(),
                isLoading: state.status.isLoading,
                onPressed: () => bloc.add(const AuthSubmitted()),
              ),
              16.h.height,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIcon(AppIcons.shield, size: 18.sp, color: theme.primary),
                  8.w.width,
                  Expanded(
                    child: Text(
                      TrWords.loginInfo.tr(),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: theme.cardSubtitle.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
              if (AppConfig.useMockData) ...[
                28.h.height,
                Text(TrWords.loginDemo.tr(), style: theme.sectionLabel),
                8.h.height,
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final (login, role) in [
                      ('jamshid', UserRole.owner),
                      ('malika', UserRole.assistant),
                      ('boris', UserRole.worker),
                    ])
                      FilterPill(
                        label: '$login · ${role.title}',
                        onTap: () {
                          _login.text = login;
                          _password.text = '1234';
                          bloc.add(AuthLoginChanged(login));
                          bloc.add(const AuthPasswordChanged('1234'));
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
