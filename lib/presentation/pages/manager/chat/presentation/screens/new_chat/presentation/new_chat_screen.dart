import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/dto/models/user_ref.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';
import 'package:eco_task/presentation/public/widgets/inner_bar.dart';
import 'package:eco_task/presentation/public/widgets/list_row.dart';
import 'package:eco_task/presentation/public/widgets/search_field.dart';
import 'package:eco_task/presentation/public/widgets/smart_loading.dart';
import 'package:eco_task/presentation/public/widgets/tone_circle.dart';
import 'package:eco_task/presentation/routes/entity/routes.dart';

import '../bloc/bloc.dart';
import 'widgets/person_pick_row.dart';

/// Pushed "new chat" screen of the manager: search, a "new group" shortcut and the contacts split into staff and
/// clients; tapping a person opens (or reuses) the direct chat. Provides [NewChatBloc].
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

/// Renders the bar, the search field and the contact sections.
class _NewChatView extends StatefulWidget {
  /// Builds the view.
  const _NewChatView();

  @override
  State<_NewChatView> createState() => _NewChatViewState();
}

/// Owns the search controller.
class _NewChatViewState extends State<_NewChatView> {
  /// Search text controller.
  final _search = TextEditingController();

  @override
  void dispose() {
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
        final staff = [
          for (final u in state.contacts)
            if (u.role != UserRole.client) u,
        ];
        final clients = [
          for (final u in state.contacts)
            if (u.role == UserRole.client) u,
        ];
        return Scaffold(
          backgroundColor: theme.background,
          body: Column(
            children: [
              InnerBar(title: TrWords.chatNew.tr()),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h + ScreenSize.bottomInset(context)),
                  children: [
                    SearchField(
                      hint: TrWords.teamSearch.tr(),
                      onChanged: (q) => bloc.add(NewChatSearched(q)),
                      controller: _search,
                    ),
                    12.h.height,
                    ListRow(
                      first: true,
                      leading: ToneCircle(AppIcons.users, tone: StatusTone.primary, size: 40.w),
                      title: TrWords.chatNewGroup.tr(),
                      chevron: false,
                      onTap: () => context.pushReplacement(Routes.groupNew.path),
                    ),
                    if (state.contacts.isEmpty)
                      state.status.isLoading
                          ? const SmartLoading()
                          : SizedBox(
                              height: 260.h,
                              child: EmptyView(
                                title: TrWords.chatNoContacts.tr(),
                                icon: AppIcons.users,
                                onRetry: state.status.isError ? () => bloc.add(const NewChatStarted()) : null,
                              ),
                            ),
                    if (staff.isNotEmpty) ..._section(TrWords.teamTabStaff.tr(), staff, bloc),
                    if (clients.isNotEmpty) ..._section(TrWords.chatClientsTitle.tr(), clients, bloc),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// A captioned run of contact rows.
  List<Widget> _section(String title, List<UserRef> people, NewChatBloc bloc) => [
    ListGroupTitle(title),
    for (final (i, u) in people.indexed)
      PersonPickRow(first: i == 0, user: u, onTap: () => bloc.add(NewChatPersonPicked(u.id))),
  ];
}
