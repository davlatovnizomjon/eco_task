import 'dart:async';

import 'package:eco_task/infrastructure/dto/models/app_user.dart';
import 'package:eco_task/infrastructure/dto/models/chat_message.dart';
import 'package:eco_task/infrastructure/services/chat_connection.dart';

import 'mock_chat.dart';

/// Scripted stand-in for the chat WebSocket: it behaves like the server —
/// every send is stored, echoed as `message.new`, acknowledged, and a few
/// moments later another participant "answers" — so the chat screen can be
/// demoed and developed without a backend.
class MockChatConnection implements ChatConnection {
  /// Conversation to join.
  final String conversationId;

  /// The signed-in mock account, resolved lazily.
  final AppUser Function() me;

  /// Builds the connection; it reports "connected" on the next microtask.
  MockChatConnection({required this.conversationId, required this.me}) {
    scheduleMicrotask(() {
      _emit(const ChatLinkChanged(connected: true));
      final others = MockChat.instance.others(conversationId, me().id);
      _emit(ChatPresenceSnapshot({if (others.isNotEmpty) others.first}));
    });
  }

  /// Delay before the scripted participant answers.
  static const _replyAfter = Duration(milliseconds: 1600);

  final _events = StreamController<ChatEvent>.broadcast();
  bool _closed = false;

  @override
  Stream<ChatEvent> get events => _events.stream;

  void _emit(ChatEvent event) {
    if (!_closed) _events.add(event);
  }

  @override
  void send(String body, String clientMsgId, {int? replyTo, int? attachmentId}) {
    final chat = MockChat.instance;
    final (message, created) = chat.send(
      me(),
      conversationId,
      body,
      clientMsgId,
      replyTo: replyTo,
      attachmentId: attachmentId,
    );
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (created) _emit(ChatMessageArrived(ChatMessage.fromJson(chat.messageJson(conversationId, message))));
      _emit(ChatMessageAcked(clientMsgId, message.id));
    });
    final others = chat.others(conversationId, me().id);
    if (created && others.isNotEmpty) {
      Future<void>.delayed(_replyAfter, () {
        if (_closed) return;
        final answer = chat.reply(conversationId, others.first, 'Qabul qilindi 👍');
        _emit(ChatMessageArrived(ChatMessage.fromJson(chat.messageJson(conversationId, answer))));
      });
    }
  }

  @override
  void markRead(int messageId) => MockChat.instance.markRead(me(), conversationId, messageId);

  @override
  Future<void> close() async {
    _closed = true;
    await _events.close();
  }
}
