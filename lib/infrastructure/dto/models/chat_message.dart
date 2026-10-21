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

  /// Builds a message from its parts.
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.body,
    required this.at,
    this.clientMsgId = '',
    this.delivery = ChatDelivery.sent,
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
    );
  }

  /// Copy with the given fields replaced.
  ChatMessage copyWith({int? id, UserRef? sender, ChatDelivery? delivery, DateTime? at}) => ChatMessage(
    id: id ?? this.id,
    conversationId: conversationId,
    sender: sender ?? this.sender,
    body: body,
    clientMsgId: clientMsgId,
    at: at ?? this.at,
    delivery: delivery ?? this.delivery,
  );

  /// Whether [other] is the same message (by server id, or by client id while unacknowledged).
  bool isSame(ChatMessage other) =>
      (id != 0 && id == other.id) || (clientMsgId.isNotEmpty && clientMsgId == other.clientMsgId);
}
