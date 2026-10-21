import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/btn.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/input_box.dart';
import 'package:eco_task/presentation/public/widgets/option_tile.dart';
import 'package:eco_task/presentation/public/widgets/screen_shell.dart';
import 'package:eco_task/presentation/public/widgets/segmented_tabs.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/user_avatar.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';

/// Start a chat: search the people one may write to and tap one for a direct
/// chat, or (bosses) switch to the group tab, tick people, name the group and
/// create it. Provides [NewChatBloc] over the app-wide [ChatRepository].
class NewChatScreen extends StatelessWidget {
  /// Builds the screen.
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => NewChatBloc(repository: RepositoryProvider.of<ChatRepository>(ctx))..add(const NewChatStarted()),
      child: const _NewChatView(),
    );
  }
}

/// Renders the tabs, the search box and the people.
class _NewChatView extends StatefulWidget {
  /// Builds the body.
  const _NewChatView();

  @override
  State<_NewChatView> createState() => _NewChatViewState();
}

/// Owns the search and title controllers.
class _NewChatViewState extends State<_NewChatView> {
  /// Controller of the search field.
  final _search = TextEditingController();

  /// Controller of the group title field.
  final _title = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBoss = RepositoryProvider.of<SessionRepository>(context).role?.isBoss ?? false;
    return BlocConsumer<NewChatBloc, NewChatState>(
      listenWhen: (prev, cur) => cur.response != null || cur.openedId != prev.openedId,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.openedId != null) context.pushReplacement(Routes.chat.of(state.openedId!));
      },
      builder: (context, state) {
        final bloc = context.read<NewChatBloc>();
        return ScreenShell(
          title: TrWords.chatNew.tr(),
          bottomBar: state.group
              ? Btn(
                  text: TrWords.chatCreate.tr(),
                  isLoading: state.busy,
                  onPressed: state.selected.isEmpty || _title.text.trim().isEmpty
                      ? null
                      : () => bloc.add(NewChatGroupSubmitted(_title.text)),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBoss) ...[
                SegmentedTabs(
                  labels: [TrWords.chatDirect.tr(), TrWords.chatGroup.tr()],
                  selected: state.group ? 1 : 0,
                  onChanged: (i) => bloc.add(NewChatTabChanged(group: i == 1)),
                ),
                12.h.height,
              ],
              if (state.group) ...[
                InputBox(
                  controller: _title,
                  title: TrWords.chatGroupTitle.tr(),
                  hint: TrWords.chatGroupTitleHint.tr(),
                  onChanged: (_) => setState(() {}),
                ),
                12.h.height,
              ],
              InputBox(
                controller: _search,
                hint: TrWords.chatSearch.tr(),
                leftIcon: AppIcons.search,
                onChanged: (q) => bloc.add(NewChatSearched(q)),
              ),
              12.h.height,
              Expanded(
                child: state.contacts.isEmpty
                    ? (state.status.isLoading
                          ? const SmartLoading()
                          : EmptyView(
                              title: TrWords.chatNoContacts.tr(),
                              icon: AppIcons.users,
                              onRetry: state.status.isError ? () => bloc.add(const NewChatStarted()) : null,
                            ))
                    : SingleChildScrollView(
                        child: CardWidget(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (final (i, u) in state.contacts.indexed)
                                OptionTile(
                                  title: u.name,
                                  first: i == 0,
                                  leading: UserAvatar(u, size: 36.w),
                                  trailing: state.group
                                      ? AppIcon(
                                          state.selected.contains(u.id) ? AppIcons.checkc : AppIcons.plus,
                                          color: state.selected.contains(u.id) ? theme.primary : theme.grayText,
                                        )
                                      : null,
                                  onTap: () =>
                                      bloc.add(state.group ? NewChatMemberToggled(u.id) : NewChatPersonPicked(u.id)),
                                ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
