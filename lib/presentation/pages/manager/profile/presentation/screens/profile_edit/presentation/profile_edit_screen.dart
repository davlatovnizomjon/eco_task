import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';

/// Pushed profile edit screen of the manager: avatar, first and last name, and a shortcut to the login and password
/// screen. Provides [ProfileEditBloc].
class ProfileEditScreen extends StatelessWidget {
  /// Builds the screen.
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ProfileEditBloc(session: RepositoryProvider.of<SessionRepository>(ctx)),
      child: const _ProfileEditView(),
    );
  }
}

/// Renders the bar, the fields and the save bar.
class _ProfileEditView extends StatefulWidget {
  /// Builds the view.
  const _ProfileEditView();

  @override
  State<_ProfileEditView> createState() => _ProfileEditViewState();
}

/// Owns the name controllers.
class _ProfileEditViewState extends State<_ProfileEditView> {
  /// First name controller, filled from the bloc's initial state.
  late final _first = TextEditingController(text: context.read<ProfileEditBloc>().state.first);

  /// Last name controller, filled from the bloc's initial state.
  late final _last = TextEditingController(text: context.read<ProfileEditBloc>().state.last);

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = RepositoryProvider.of<SessionRepository>(context).user.value!.user;
    return BlocConsumer<ProfileEditBloc, ProfileEditState>(
      listenWhen: (prev, cur) => cur.response != null || cur.saved,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.saved) context.pop();
      },
      builder: (context, state) {
        final bloc = context.read<ProfileEditBloc>();
        return Scaffold(
          backgroundColor: theme.background,
          bottomNavigationBar: BottomActionBar(
            child: Btn(
              text: TrWords.cSave.tr(),
              isLoading: state.status.isLoading,
              onPressed: () => bloc.add(const ProfileEditSubmitted()),
            ),
          ),
          body: Column(
            children: [
              InnerBar(title: TrWords.accEditTitle.tr()),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                  children: [
                    Center(child: UserAvatar(me.ref, size: 96.w)),
                    20.h.height,
                    InputBox(
                      controller: _first,
                      title: TrWords.accFirstName.tr(),
                      onChanged: (v) => bloc.add(ProfileEditFirstChanged(v)),
                    ),
                    18.h.height,
                    InputBox(
                      controller: _last,
                      title: TrWords.accLastName.tr(),
                      onChanged: (v) => bloc.add(ProfileEditLastChanged(v)),
                    ),
                    18.h.height,
                    GestureDetector(
                      onTap: () => context.push(Routes.loginChange.path),
                      child: Container(
                        constraints: BoxConstraints(minHeight: 56.h),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: theme.panelDecor,
                        child: Row(
                          children: [
                            AppIcon.tile(AppIcons.key, tone: StatusTone.primary, size: 36),
                            12.w.width,
                            Expanded(
                              child: Text(
                                TrWords.accLoginPwd.tr(),
                                style: theme.textStyle.copyWith(fontWeight: FontWeight.w400),
                              ),
                            ),
                            AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText),
                          ],
                        ),
                      ),
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
