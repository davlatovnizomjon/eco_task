import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/presentation/public/widgets/bottom_action_bar.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/search_field.dart';
import 'package:eco_task/presentation/public/widgets/select_mark.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/tone_circle.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';
import 'widgets/person_pick_row.dart';

/// Pushed "new group" screen of the manager: a group name, the chosen members as removable avatars, a search field
/// and the contact list with round check marks. Provides [NewChatBloc] already switched to group mode.
class NewGroupScreen extends StatelessWidget {
  /// Builds the screen.
  const NewGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => NewChatBloc(repository: RepositoryProvider.of<ChatRepository>(ctx))
        ..add(const NewChatTabChanged(group: true))
        ..add(const NewChatStarted()),
      child: const _NewGroupView(),
    );
  }
}

/// Renders the bar, the name row, the member chips and the list.
class _NewGroupView extends StatefulWidget {
  /// Builds the view.
  const _NewGroupView();

  @override
  State<_NewGroupView> createState() => _NewGroupViewState();
}

/// Owns the name and search controllers.
class _NewGroupViewState extends State<_NewGroupView> {
  /// Group name controller.
  final _title = TextEditingController();

  /// Member search controller.
  final _search = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NewChatBloc, NewChatState>(
      listenWhen: (prev, cur) => cur.response != null || cur.openedId != prev.openedId,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.openedId != null) context.pushReplacement(Routes.chat.of(state.openedId!));
      },
      builder: (context, state) {
        final bloc = context.read<NewChatBloc>();
        final chosen = [
          for (final u in state.contacts)
            if (state.selected.contains(u.id)) u,
        ];
        final ready = state.selected.isNotEmpty && _title.text.trim().isNotEmpty && !state.busy;
        return Scaffold(
          backgroundColor: theme.background,
          bottomNavigationBar: BottomActionBar(
            child: Btn(
              text: TrWords.chatCreateGroup.tr(),
              height: 52.h,
              isLoading: state.busy,
              onPressed: ready ? () => bloc.add(NewChatGroupSubmitted(_title.text)) : null,
            ),
          ),
          body: Column(
            children: [
              InnerBar(title: TrWords.chatNewGroup.tr()),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
                  children: [
                    Row(
                      children: [
                        ToneCircle(AppIcons.camera, tone: StatusTone.primary, size: 56.w),
                        12.w.width,
                        Expanded(
                          child: Container(
                            height: 48.h,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: 14.circular,
                              border: Border.all(color: theme.line),
                            ),
                            child: TextField(
                              controller: _title,
                              onChanged: (_) => setState(() {}),
                              cursorColor: theme.primary,
                              style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w400),
                              decoration: InputDecoration(
                                hintText: TrWords.chatGroupTitle.tr(),
                                hintStyle: theme.textStyle.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w400,
                                  color: theme.grayText,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (chosen.isNotEmpty) ...[
                      14.h.height,
                      SizedBox(
                        height: 76.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: chosen.length,
                          separatorBuilder: (_, _) => 14.w.width,
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => bloc.add(NewChatMemberToggled(chosen[i].id)),
                            child: SizedBox(
                              width: 56.w,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Column(
                                    children: [
                                      UserAvatar(chosen[i], size: 48.w),
                                      4.h.height,
                                      Text(
                                        chosen[i].firstName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.cardSubtitle.copyWith(fontSize: 12.sp, color: theme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: 2.w,
                                    child: Container(
                                      width: 18.w,
                                      height: 18.w,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: theme.grayText,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: theme.background, width: 2),
                                      ),
                                      child: AppIcon(AppIcons.x, size: 10.sp, color: const Color(0xFFFFFFFF)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    14.h.height,
                    SearchField(
                      hint: TrWords.chatAddMember.tr(),
                      controller: _search,
                      onChanged: (q) => bloc.add(NewChatSearched(q)),
                    ),
                    10.h.height,
                    if (state.contacts.isEmpty)
                      state.status.isLoading
                          ? const SmartLoading()
                          : SizedBox(
                              height: 240.h,
                              child: EmptyView(title: TrWords.chatNoContacts.tr(), icon: AppIcons.users),
                            )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              TrWords.chatSelectedN.tr(args: ['${state.selected.length}']).toUpperCase(),
                              style: theme.textStyle.copyWith(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => bloc.add(const NewChatAllToggled()),
                            child: Text(
                              TrWords.chatSelectAll.tr(),
                              style: theme.textStyle.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      for (final (i, u) in state.contacts.indexed)
                        PersonPickRow(
                          first: i == 0,
                          user: u,
                          trailing: SelectMark(shape: SelectShape.circle, on: state.selected.contains(u.id)),
                          onTap: () => bloc.add(NewChatMemberToggled(u.id)),
                        ),
                    ],
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
