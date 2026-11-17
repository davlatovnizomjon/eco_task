import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';

import '../bloc/bloc.dart';

/// Pushed login and password screen of the manager: the login field and a "change password" block (current, new,
/// repeat). Provides [LoginChangeBloc].
class LoginChangeScreen extends StatelessWidget {
  /// Builds the screen.
  const LoginChangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = RepositoryProvider.of<SessionRepository>(context);
    final id = session.user.value!.user.id;
    return BlocProvider(
      create: (ctx) => LoginChangeBloc(
        session: session,
        // A live backend identifies accounts by a numeric id, which is not the login.
        initialLogin: int.tryParse(id) == null ? id : '',
      ),
      child: const _LoginChangeView(),
    );
  }
}

/// Renders the bar, the fields and the save bar.
class _LoginChangeView extends StatefulWidget {
  /// Builds the view.
  const _LoginChangeView();

  @override
  State<_LoginChangeView> createState() => _LoginChangeViewState();
}

/// Owns the login controller.
class _LoginChangeViewState extends State<_LoginChangeView> {
  /// Login controller, filled from the bloc's initial login.
  late final _login = TextEditingController(text: context.read<LoginChangeBloc>().initialLogin);

  @override
  void dispose() {
    _login.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginChangeBloc, LoginChangeState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) context.pop();
      },
      builder: (context, state) {
        final bloc = context.read<LoginChangeBloc>();
        return Scaffold(
          backgroundColor: theme.background,
          bottomNavigationBar: BottomActionBar(
            child: Btn(
              text: TrWords.cSave.tr(),
              isLoading: state.status.isLoading,
              onPressed: () => bloc.add(const LoginChangeSubmitted()),
            ),
          ),
          body: Column(
            children: [
              InnerBar(title: TrWords.accLoginTitle.tr()),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                  children: [
                    InputBox(
                      controller: _login,
                      title: TrWords.teamLogin.tr(),
                      leftIcon: AppIcons.user,
                      onChanged: (v) => bloc.add(LoginChangeLoginEdited(v)),
                    ),
                    6.h.height,
                    Text(TrWords.accLoginHelp.tr(), style: theme.cardSubtitle),
                    24.h.height,
                    Text(
                      TrWords.accChangePwd.tr().toUpperCase(),
                      style: theme.sectionLabel.copyWith(letterSpacing: 0.3),
                    ),
                    12.h.height,
                    InputBox(
                      title: TrWords.accCurrent.tr(),
                      isPassword: true,
                      onChanged: (v) => bloc.add(LoginChangeCurrentEdited(v)),
                    ),
                    18.h.height,
                    InputBox(
                      title: TrWords.accNewPwd.tr(),
                      isPassword: true,
                      onChanged: (v) => bloc.add(LoginChangeNextEdited(v)),
                    ),
                    6.h.height,
                    Text(TrWords.accMin8.tr(), style: theme.cardSubtitle),
                    18.h.height,
                    InputBox(
                      title: TrWords.accRepeat.tr(),
                      isPassword: true,
                      onChanged: (v) => bloc.add(LoginChangeRepeatEdited(v)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
