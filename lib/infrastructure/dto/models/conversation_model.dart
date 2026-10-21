import '../../../domain/common/enums/chat_kind.dart';
import 'chat_message.dart';
import 'user_ref.dart';

/// One conversation in the chat list.
class ConversationModel {
  /// Conversation id (UUID).
  final String id;

  /// Direct, group or task chat.
  final ChatKind kind;

  /// Group title or task title; empty for a direct chat.
  final String title;

  /// Id of the task for a task chat, else null.
  final String? taskId;

  /// Messages from others newer than the signed-in user's read marker.
  final int unread;

  /// Newest message, or null for an empty conversation.
  final ChatMessage? last;

  /// Participants (empty for task chats, whose audience is the task's people).
  final List<UserRef> members;

  /// Builds a conversation from its parts.
  const ConversationModel({
    required this.id,
    required this.kind,
    this.title = '',
    this.taskId,
    this.unread = 0,
    this.last,
    this.members = const [],
  });

  /// Parses the backend conversation payload.
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final last = json['last_message'];
    return ConversationModel(
      id: '${json['id']}',
      kind: ChatKind.fromJson(json['kind']),
      title: '${json['title'] ?? ''}',
      taskId: json['task'] == null ? null : '${json['task']}',
      unread: (json['unread_count'] as num?)?.toInt() ?? 0,
      last: last is Map ? ChatMessage.fromJson(last.cast<String, dynamic>()) : null,
      members: [
        for (final m in (json['members'] as List? ?? const [])) UserRef.fromBackend((m as Map).cast<String, dynamic>()),
      ],
    );
  }

  /// The other person of a direct chat, or null for other kinds.
  UserRef? other(String meId) => kind == ChatKind.direct ? members.where((m) => m.id != meId).firstOrNull : null;

  /// Name shown in the list and the header: the other person for a direct chat, else the title.
  String nameFor(String meId) => other(meId)?.name ?? title;

  /// Copy with the given fields replaced.
  ConversationModel copyWith({int? unread, ChatMessage? last}) => ConversationModel(
    id: id,
    kind: kind,
    title: title,
    taskId: taskId,
    unread: unread ?? this.unread,
    last: last ?? this.last,
    members: members,
  );
}
