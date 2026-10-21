import 'package:flutter/foundation.dart';

import '../common/api_cache.dart';
import '../common/api_links.dart';
import '../dto/models/chat_message.dart';
import '../dto/models/conversation_model.dart';
import '../dto/models/user_ref.dart';
import '../services/chat_connection.dart';
import '../../domain/common/enums/chat_kind.dart';

import 'package:eco_task/infrastructure/common/dio_client.dart';

/// One page of message history, newest message last.
class ChatHistory {
  /// Messages of the page in reading order (oldest first).
  final List<ChatMessage> messages;

  /// True when older messages exist (request them with `before: messages.first.id`).
  final bool hasMore;

  /// Builds a page.
  const ChatHistory({this.messages = const [], this.hasMore = false});
}

/// Conversations, message history and the live link. REST carries the lists
/// and history; the [ChatConnection] it hands out carries new messages.
/// Provided once at the app root.
class ChatRepository {
  /// Messages per history request.
  static const pageSize = 30;

  /// Opens the live link of one conversation (WebSocket, or the scripted mock).
  final ChatConnector connector;

  /// Total unread messages across all conversations; drives the chat tab badge.
  final ValueNotifier<int> unread = ValueNotifier(0);

  /// Builds the repository over [connector].
  ChatRepository({required this.connector});

  /// Cached conversation list, or an empty one.
  List<ConversationModel> cachedConversations() => ApiCache.read<List<ConversationModel>>('chats') ?? const [];

  /// Loads every conversation of the signed-in user, newest activity first, and refreshes [unread].
  Future<List<ConversationModel>> getConversations() async {
    final response = await dioClient.get(ApiLinks.conversations);
    final list = [
      for (final c in response.data as List) ConversationModel.fromJson((c as Map).cast<String, dynamic>()),
    ];
    unread.value = list.fold(0, (sum, c) => sum + c.unread);
    return ApiCache.write('chats', list);
  }

  /// Loads one conversation.
  Future<ConversationModel> getConversation(String id) async => ConversationModel.fromJson(
    ((await dioClient.get(ApiLinks.conversation(id))).data as Map).cast<String, dynamic>(),
  );

  /// Loads up to [pageSize] messages older than [before] (or the newest ones when null).
  Future<ChatHistory> getMessages(String id, {int? before}) async {
    final response = await dioClient.get(
      ApiLinks.conversationMessages(id),
      queryParameters: {'limit': pageSize, if (before != null) 'before': before},
    );
    final body = (response.data as Map).cast<String, dynamic>();
    final rows = [for (final m in body['results'] as List) ChatMessage.fromJson((m as Map).cast<String, dynamic>())];
    return ChatHistory(messages: rows.reversed.toList(), hasMore: body['has_more'] == true);
  }

  /// Stores a message over REST (used when the socket is down); idempotent by [clientMsgId].
  Future<ChatMessage> sendMessage(String id, String body, String clientMsgId) async {
    final response = await dioClient.post(
      ApiLinks.conversationMessages(id),
      data: {'body': body, 'client_msg_id': clientMsgId},
    );
    return ChatMessage.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Moves the signed-in user's read marker of [id] up to [messageId].
  Future<void> markRead(String id, int messageId) async {
    await dioClient.post(ApiLinks.conversationRead(id), data: {'message_id': messageId});
    ApiCache.invalidate();
  }

  /// People the signed-in user may start a direct chat with, filtered by [search].
  Future<List<UserRef>> getContacts({String search = ''}) async {
    final response = await dioClient.get(ApiLinks.chatContacts, queryParameters: {if (search.isNotEmpty) 'q': search});
    return [for (final u in response.data as List) UserRef.fromBackend((u as Map).cast<String, dynamic>())];
  }

  /// Opens (or reuses) the direct chat with [userId].
  Future<ConversationModel> openDirect(String userId) =>
      _open({'kind': ChatKind.direct.apiName, 'user': int.tryParse(userId) ?? userId});

  /// Opens (or creates) the discussion of task [taskId].
  Future<ConversationModel> openTaskChat(String taskId) => _open({'kind': ChatKind.task.apiName, 'task': taskId});

  /// Creates a group called [title] with [memberIds].
  Future<ConversationModel> createGroup(String title, List<String> memberIds) => _open({
    'kind': ChatKind.group.apiName,
    'title': title,
    'member_ids': [for (final id in memberIds) int.tryParse(id) ?? id],
  });

  /// Posts a create/open request and parses the conversation.
  Future<ConversationModel> _open(Map<String, dynamic> body) async {
    final response = await dioClient.post(ApiLinks.conversations, data: body);
    ApiCache.invalidate();
    return ConversationModel.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Opens the live link of conversation [id]; the caller closes it.
  ChatConnection connect(String id) => connector(id);

  /// Releases the notifier when the app root is torn down.
  void dispose() => unread.dispose();
}
