import 'file_attachment.dart';
import 'user_ref.dart';

/// Delivery state of a message on this device.
enum ChatDelivery {
  /// Stored on the server.
  sent,

  /// Typed here and waiting for the server's acknowledgement.
  sending,

  /// The send failed; the user can retry.
  failed,
}

/// One message of a conversation.
/// One emoji on a message and who put it there.
class ChatReaction {
  /// The emoji.
  final String emoji;

  /// Ids of the people who reacted with it.
  final List<String> userIds;

  /// Builds a reaction.
  const ChatReaction(this.emoji, this.userIds);

  /// Parses the API `{emoji, user_ids}` object.
  factory ChatReaction.fromJson(Map<String, dynamic> json) =>
      ChatReaction('${json['emoji']}', [for (final id in (json['user_ids'] as List? ?? const [])) '$id']);
}

/// The small card of the message another one answers.
class ChatReply {
  /// Id of the quoted message.
  final int id;

  /// Name of its author.
  final String senderName;

  /// One-line preview of its text; empty when deleted or attachment-only.
  final String body;

  /// True when the quoted message was deleted.
  final bool deleted;

  /// Kind of its attachment, when it has one.
  final FileKind? attachmentKind;

  /// Builds a quote.
  const ChatReply({
    required this.id,
    required this.senderName,
    this.body = '',
    this.deleted = false,
    this.attachmentKind,
  });

  /// Parses the API `reply_to` object.
  factory ChatReply.fromJson(Map<String, dynamic> json) => ChatReply(
    id: (json['id'] as num).toInt(),
    senderName: '${json['sender_name'] ?? ''}',
    body: '${json['body'] ?? ''}',
    deleted: json['deleted'] == true,
    attachmentKind: json['attachment_kind'] == null ? null : FileKind.fromJson(json['attachment_kind']),
  );
}

/// One chat message.
class ChatMessage {
  /// Server-assigned id (increasing within the conversation); 0 while [delivery] is not [ChatDelivery.sent].
  final int id;

  /// Conversation it belongs to.
  final String conversationId;

  /// Author. Over the socket the server sends only the author's id, so the name may be empty until resolved.
  final UserRef sender;

  /// Message text.
  final String body;

  /// Client-generated id; the server de-duplicates retries by it and the UI matches acks with it.
  final String clientMsgId;

  /// When the server stored it (or when it was typed, while pending).
  final DateTime at;

  /// Delivery state on this device.
  final ChatDelivery delivery;

  /// When the author last edited the text; null when never.
  final DateTime? editedAt;

  /// True after the message was deleted: the body is empty and the room shows a placeholder.
  final bool deleted;

  /// Reactions grouped by emoji.
  final List<ChatReaction> reactions;

  /// The message this one answers; null for a plain message.
  final ChatReply? replyTo;

  /// Photo, document, voice note or video circle sent with the message; null for text only.
  final FileAttachment? attachment;

  /// Builds a message from its parts.
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    required this.at,
    this.clientMsgId = '',
    this.delivery = ChatDelivery.sent,
    this.editedAt,
    this.deleted = false,
    this.reactions = const [],
    this.replyTo,
    this.attachment,
  });

  /// Parses a backend message: REST has a nested `sender` object, the socket only the sender's id.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'];
    return ChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: '${json['conversation']}',
      sender: sender is Map ? UserRef.fromBackend(sender.cast<String, dynamic>()) : UserRef(id: '$sender', name: ''),
      body: '${json['body'] ?? ''}',
      clientMsgId: '${json['client_msg_id'] ?? ''}',
      at: DateTime.parse('${json['created_at']}').toLocal(),
      editedAt: json['edited_at'] == null ? null : DateTime.parse('${json['edited_at']}').toLocal(),
      deleted: json['deleted'] == true,
      reactions: [
        for (final r in (json['reactions'] as List? ?? const []))
          ChatReaction.fromJson((r as Map).cast<String, dynamic>()),
      ],
      replyTo: json['reply_to'] is Map ? ChatReply.fromJson((json['reply_to'] as Map).cast<String, dynamic>()) : null,
      attachment: json['attachment'] is Map
          ? FileAttachment.fromJson((json['attachment'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  /// Copy with the given fields replaced.
  ChatMessage copyWith({int? id, UserRef? sender, ChatDelivery? delivery, DateTime? at, String? body}) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId,
    sender: sender ?? this.sender,
    body: body ?? this.body,
    clientMsgId: clientMsgId,
    at: at ?? this.at,
    delivery: delivery ?? this.delivery,
    editedAt: editedAt,
    deleted: deleted,
    reactions: reactions,
    replyTo: replyTo,
    attachment: attachment,
  );

  /// Whether [other] is the same message (by server id, or by client id while unacknowledged).
  bool isSame(ChatMessage other) =>
      (id != 0 && id == other.id) || (clientMsgId.isNotEmpty && clientMsgId == other.clientMsgId);
}
