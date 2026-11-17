import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/call_kind.dart';
import 'package:eco_task/domain/common/enums/call_party_state.dart';
import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/helpers/response_helper.dart';
import 'package:eco_task/infrastructure/repository/call_repository.dart';
import 'package:eco_task/infrastructure/repository/chat_repository.dart';
import 'package:eco_task/infrastructure/repository/session_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_loader.dart';
import 'package:eco_task/presentation/public/widgets/call_backdrop.dart';

import '../bloc/bloc.dart';
import 'widgets/call_result_view.dart';
import 'widgets/direct_call_view.dart';
import 'widgets/incoming_call_view.dart';

/// Full-screen call: shows the ringing, incoming, active or finished state of one call of a direct or group
/// conversation. Provides [CallBloc]. [callId] is a call id, or `new` to start one in [conversationId].
class CallScreen extends StatelessWidget {
  /// Call to show, or `new`.
  final String callId;

  /// Conversation to call when [callId] is `new`.
  final String conversationId;

  /// Media of the call to start when [callId] is `new`.
  final CallKind kind;

  /// Builds the screen.
  const CallScreen({super.key, required this.callId, this.conversationId = '', this.kind = CallKind.audio});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => CallBloc(
        repository: RepositoryProvider.of<CallRepository>(ctx),
        chats: RepositoryProvider.of<ChatRepository>(ctx),
        meId: RepositoryProvider.of<SessionRepository>(ctx).user.value!.user.id,
        callId: callId,
        conversationId: conversationId,
        kind: kind,
      )..add(const CallStarted()),
      child: const _CallView(),
    );
  }
}

/// Picks the layout for the current state.
class _CallView extends StatelessWidget {
  /// Builds the view.
  const _CallView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    final meId = RepositoryProvider.of<SessionRepository>(context).user.value!.user.id;
    return BlocConsumer<CallBloc, CallState>(
      listenWhen: (prev, cur) => cur.response != null || cur.closeScreen,
      listener: (context, state) {
        if (state.response != null) showScreenResponse(context, state.response!);
        if (state.closeScreen && context.canPop()) context.pop();
      },
      builder: (context, state) {
        final call = state.call;
        final conversation = state.conversation;
        Widget body;
        if (call == null || conversation == null) {
          body = Center(
            child: state.status == ScreenStatus.error ? const SizedBox.shrink() : const AppLoader(size: 32),
          );
        } else if (!call.status.isLive) {
          body = CallResultView(state: state, meId: meId);
        } else if (call.stateOf(meId) == CallPartyState.invited) {
          body = IncomingCallView(state: state, meId: meId);
        } else {
          body = DirectCallView(state: state, meId: meId, media: bloc.media);
        }
        return PopScope(
          // The back button minimizes the screen: the call (and its sound) goes on in the repository.
          child: Scaffold(
            backgroundColor: theme.callBottom,
            body: CallBackdrop(child: body),
          ),
        );
      },
    );
  }
}
