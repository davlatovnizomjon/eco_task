import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/app_config.dart';
import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/legal_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/login_lock_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/auth_field.dart';
import 'package:eco_task/presentation/public/widgets/brand_mark.dart';
import 'package:eco_task/presentation/public/widgets/filter_pill.dart';
import 'package:eco_task/presentation/public/button/button.dart';
import 'package:eco_task/presentation/public/toast/toast.dart';

import '../bloc/bloc.dart';
import 'dialogs/legal/legal_sheet.dart';
import 'widgets/locked_banner.dart';

/// Sign-in screen shared by every role: brand row with the language button, title, login and password fields, the
/// primary button, the terms line and a top toast for empty fields and wrong credentials. After too many wrong attempts
/// after too many wrong attempts an amber banner with a live countdown appears under the fields and the button is disabled until the lock runs out (the lock survives closing the app). Provides [AuthBloc].
class AuthScreen extends StatelessWidget {
  /// Builds the screen.
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => AuthBloc(
        repository: RepositoryProvider.of<SessionRepository>(ctx),
        lockRepository: RepositoryProvider.of<LoginLockRepository>(ctx),
      ),
      child: const _AuthView(),
    );
  }
}

/// Renders the form and the toast.
class _AuthView extends StatefulWidget {
  /// Builds the view.
  const _AuthView();

  @override
  State<_AuthView> createState() => _AuthViewState();
}

/// Owns the field controllers and the password visibility.
class _AuthViewState extends State<_AuthView> {
  /// Login controller.
  final _login = TextEditingController();

  /// Password controller.
  final _password = TextEditingController();

  /// Whether the password is hidden.
  bool _obscure = true;

  /// Opens the terms of use when the terms link is tapped.
  late final _termsTap = TapGestureRecognizer()..onTap = () => showLegalSheet(context, LegalKind.terms);

  /// Opens the privacy policy when the privacy link is tapped.
  late final _privacyTap = TapGestureRecognizer()..onTap = () => showLegalSheet(context, LegalKind.privacy);

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  /// Shows the toast [state] asks for through the shared `showTopToast`.
  void _showToast(BuildContext context, AuthState state) {
    switch (state.toast) {
      case AuthToast.none:
        return;
      case AuthToast.empty:
        showTopToast(
          context,
          icon: AppIcons.alert,
          tone: StatusTone.warn,
          title: TrWords.loginEmptyT.tr(),
          message: TrWords.loginEmptyB.tr(),
        );
      case AuthToast.wrong:
        showTopToast(
          context,
          icon: AppIcons.xc,
          tone: StatusTone.error,
          title: state.toastTitle ?? TrWords.loginWrongT.tr(),
          message: state.toastMessage,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, cur) => cur.toastSeq != prev.toastSeq,
      listener: _showToast,
      child: BlocConsumer<AuthBloc, AuthState>(
        // Nothing here navigates on success: signing in publishes the session and
        // the router's redirect sends the user on.
        listenWhen: (prev, cur) => cur.response != null,
        listener: (context, state) => showScreenResponse(context, state.response!),
        builder: (context, state) {
          final bloc = context.read<AuthBloc>();
          final linkStyle = TextStyle(color: theme.primary, fontWeight: FontWeight.w600);
          return Scaffold(
            backgroundColor: theme.background,
            body: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, MediaQuery.of(context).padding.top + 12.h, 20.w, 0),
                          child: Row(
                            children: [
                              BrandMark(size: 40.w),
                              10.w.width,
                              Text(
                                AppConfig.brandName,
                                style: theme.textStyle.copyWith(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 48.h, 24.w, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                TrWords.loginTitle.tr(),
                                style: theme.textStyle.copyWith(
                                  fontSize: 28.sp,
                                  height: 34 / 28,
                                  fontWeight: FontWeight.w600,
                                  fontVariations: const [FontVariation.weight(650)],
                                  letterSpacing: -0.56,
                                ),
                              ),
                              6.h.height,
                              Text(
                                TrWords.loginHint.tr(),
                                style: theme.textStyle.copyWith(
                                  fontWeight: FontWeight.w400,
                                  height: 22 / 15,
                                  color: theme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 32.h, 24.w, 0),
                          child: Column(
                            children: [
                              AuthField(
                                controller: _login,
                                label: TrWords.loginLogin.tr(),
                                hint: TrWords.loginLoginHint.tr(),
                                icon: AppIcons.user,
                                invalid: state.loginInvalid,
                                onChanged: (v) => bloc.add(AuthLoginChanged(v)),
                              ),
                              18.h.height,
                              AuthField(
                                controller: _password,
                                label: TrWords.loginPassword.tr(),
                                hint: TrWords.loginPasswordHint.tr(),
                                icon: AppIcons.lock,
                                obscure: _obscure,
                                invalid: state.passwordInvalid,
                                onChanged: (v) => bloc.add(AuthPasswordChanged(v)),
                                onSubmitted: (_) => bloc.add(const AuthSubmitted()),
                                trailing: GestureDetector(
                                  onTap: () => setState(() => _obscure = !_obscure),
                                  behavior: HitTestBehavior.opaque,
                                  child: SizedBox(
                                    width: 44.w,
                                    height: 44.w,
                                    child: Center(
                                      child: AppIcon(AppIcons.eye, size: 20.sp, color: theme.grayText),
                                    ),
                                  ),
                                ),
                              ),
                              if (state.locked) ...[22.h.height, LockedBanner(remaining: state.remaining)],
                              26.h.height,
                              PrimaryButton(
                                text: TrWords.loginSubmit.tr(),
                                loadingText: TrWords.loginLoading.tr(),
                                isLoading: state.status.isLoading,
                                trailingIcon: AppIcons.arrow,
                                onPressed: state.locked ? null : () => bloc.add(const AuthSubmitted()),
                              ),
                              if (AppConfig.useMockData) ...[
                                20.h.height,
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
                        ),
                        const Spacer(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 36.h),
                          child: Text.rich(
                            TextSpan(
                              text: TrWords.loginAgreePre.tr(),
                              children: [
                                TextSpan(text: TrWords.loginTerms.tr(), style: linkStyle, recognizer: _termsTap),
                                TextSpan(text: TrWords.loginAgreeMid.tr()),
                                TextSpan(text: TrWords.loginPrivacy.tr(), style: linkStyle, recognizer: _privacyTap),
                                TextSpan(text: TrWords.loginAgreePost.tr()),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: theme.cardSubtitle.copyWith(height: 20 / 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
