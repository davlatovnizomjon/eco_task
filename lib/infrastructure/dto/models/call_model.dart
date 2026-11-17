import '../../../domain/common/enums/call_kind.dart';
import '../../../domain/common/enums/call_party_state.dart';
import '../../../domain/common/enums/call_status.dart';
import 'user_ref.dart';

/// One person of a call with their state.
class CallParty {
  /// The person.
  final UserRef user;

  /// Whether they ring, are in, declined, missed or left.
  final CallPartyState state;

  /// Builds a party.
  const CallParty({required this.user, required this.state});

  /// Parses a backend participant (`{user, state}`).
  factory CallParty.fromJson(Map<String, dynamic> json) => CallParty(
    user: UserRef.fromBackend((json['user'] as Map).cast<String, dynamic>()),
    state: CallPartyState.fromJson(json['state']),
  );
}

/// A voice or video call inside a direct or group conversation.
class CallModel {
  /// Call id.
  final int id;

  /// Conversation the call belongs to.
  final String conversationId;

  /// Voice or video at the start (people may switch their own camera later).
  final CallKind kind;

  /// Lifecycle status.
  final CallStatus status;

  /// Who started the call; null when that account is gone.
  final UserRef? caller;

  /// When the call was started.
  final DateTime createdAt;

  /// When the first person answered; null while ringing.
  final DateTime? answeredAt;

  /// Everybody invited, with their state.
  final List<CallParty> parties;

  /// Builds a call from its parts.
  const CallModel({
    required this.id,
    required this.conversationId,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.caller,
    this.answeredAt,
    this.parties = const [],
  });

  /// Parses the backend call payload.
  factory CallModel.fromJson(Map<String, dynamic> json) => CallModel(
    id: (json['id'] as num).toInt(),
    conversationId: '${json['conversation']}',
    kind: CallKind.fromJson(json['kind']),
    status: CallStatus.fromJson(json['status']),
    caller: json['caller'] is Map ? UserRef.fromBackend((json['caller'] as Map).cast<String, dynamic>()) : null,
    createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
    answeredAt: json['answered_at'] == null ? null : DateTime.tryParse('${json['answered_at']}'),
    parties: [
      for (final p in (json['participants'] as List? ?? const []))
        CallParty.fromJson((p as Map).cast<String, dynamic>()),
    ],
  );

  /// State of the person with [userId], or null when they are not part of the call.
  CallPartyState? stateOf(String userId) => parties.where((p) => p.user.id == userId).firstOrNull?.state;

  /// People who are in the call right now.
  List<UserRef> get joined => [
    for (final p in parties)
      if (p.state == CallPartyState.joined) p.user,
  ];

  /// People still ringing.
  List<UserRef> get ringing => [
    for (final p in parties)
      if (p.state == CallPartyState.invited) p.user,
  ];
}
