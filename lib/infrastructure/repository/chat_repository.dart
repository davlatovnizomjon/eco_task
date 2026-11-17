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
  Future<ChatMessage> sendMessage(String id, String body, String clientMsgId, {int? replyTo, int? attachmentId}) async {
    final response = await dioClient.post(
      ApiLinks.conversationMessages(id),
      data: {
        'body': body,
        'client_msg_id': clientMsgId,
        if (replyTo != null) 'reply_to': replyTo,
        if (attachmentId != null) 'attachment_id': attachmentId,
      },
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

  /// Replaces the text of own message [messageId]; answers the stored message.
  Future<ChatMessage> editMessage(String id, int messageId, String body) async {
    final response = await dioClient.patch(ApiLinks.conversationMessage(id, messageId), data: {'body': body});
    return ChatMessage.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Deletes message [messageId] (the row stays, its text is wiped); answers the stored message.
  Future<ChatMessage> deleteMessage(String id, int messageId) async {
    final response = await dioClient.delete(ApiLinks.conversationMessage(id, messageId));
    ApiCache.invalidate();
    return ChatMessage.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Sets the caller's reaction on [messageId] to [emoji], or removes it when [emoji] is null.
  Future<ChatMessage> react(String id, int messageId, String? emoji) async {
    final response = emoji == null
        ? await dioClient.delete(ApiLinks.messageReaction(id, messageId))
        : await dioClient.put(ApiLinks.messageReaction(id, messageId), data: {'emoji': emoji});
    return ChatMessage.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Pins [messageId] (or clears the pin when null); answers the conversation.
  Future<ConversationModel> pin(String id, int? messageId) async {
    final response = messageId == null
        ? await dioClient.delete(ApiLinks.conversationPin(id))
        : await dioClient.put(ApiLinks.conversationPin(id), data: {'message_id': messageId});
    return ConversationModel.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Renames a group and/or switches the caller's mute; answers the conversation.
  Future<ConversationModel> updateConversation(String id, {String? title, bool? muted, int? avatarId}) async {
    final response = await dioClient.patch(
      ApiLinks.conversation(id),
      data: {
        if (title != null) 'title': title,
        if (muted != null) 'muted': muted,
        if (avatarId != null) 'avatar_id': avatarId,
      },
    );
    ApiCache.invalidate();
    return ConversationModel.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Adds [userIds] to a group; answers the conversation.
  Future<ConversationModel> addMembers(String id, List<String> userIds) async {
    final response = await dioClient.post(
      ApiLinks.conversationMembers(id),
      data: {
        'user_ids': [for (final u in userIds) int.tryParse(u) ?? u],
      },
    );
    ApiCache.invalidate();
    return ConversationModel.fromJson((response.data as Map).cast<String, dynamic>());
  }

  /// Removes [userId] from a group (the caller leaves when it is their own id).
  Future<void> removeMember(String id, String userId) async {
    await dioClient.delete(ApiLinks.conversationMember(id, userId));
    ApiCache.invalidate();
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
