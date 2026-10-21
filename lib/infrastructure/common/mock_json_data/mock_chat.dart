import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';

import 'mock_seed.dart';
import 'mock_store.dart';

/// One stored mock message (public because the mock socket reads it).
class MockChatMessage {
  /// Increasing id within the conversation.
  final int id;

  /// Author account id.
  final String sender;

  /// Text.
  final String body;

  /// Client id the send used, for idempotent retries.
  final String clientId;

  /// When it was stored.
  final DateTime at;

  MockChatMessage(this.id, this.sender, this.body, this.clientId, this.at);
}

/// One stored mock conversation.
class _Chat {
  final String id;
  final ChatKind kind;
  final String title;
  final String? taskId;
  final Set<String> members;
  final List<MockChatMessage> messages = [];

  /// Read marker per account id.
  final Map<String, int> read = {};

  _Chat(this.id, this.kind, this.members, {this.title = '', this.taskId});
}

/// The chat half of the mock backend: it answers the `conversations/...`
/// endpoints with the very JSON of `backend/apps/chat` (nested sender objects,
/// `unread_count`, `last_message`, `{results, has_more}` history), so the chat
/// repository and blocs run unchanged against it.
class MockChat {
  /// Private constructor — use [instance].
  MockChat._() {
    _seed();
  }

  /// The one in-memory chat backend of the running app.
  static final MockChat instance = MockChat._();

  final List<_Chat> _chats = [];
  int _chatSeq = 0;
  int _msgSeq = 100;

  /// Account with [id], or throws 404.
  AppUser _user(String id) => MockStore.instance.users.firstWhere(
    (u) => u.id == id,
    orElse: () => throw const MockFailure(404, 'Foydalanuvchi topilmadi.'),
  );

  /// Backend `UserBrief` JSON of an account.
  Map<String, dynamic> _brief(String id) {
    final u = _user(id);
    return {'id': u.id, 'username': u.id, 'full_name': u.name, 'role': u.role.apiName, 'color': u.color};
  }

  /// Backend message JSON.
  Map<String, dynamic> _json(_Chat chat, MockChatMessage m) => {
    'id': m.id,
    'conversation': chat.id,
    'sender': _brief(m.sender),
    'body': m.body,
    'client_msg_id': m.clientId,
    'created_at': m.at.toUtc().toIso8601String(),
  };

  /// Adds a message to [chat] and moves the author's read marker.
  MockChatMessage _add(_Chat chat, String sender, String body, {String clientId = '', DateTime? at}) {
    final m = MockChatMessage(_msgSeq++, sender, body, clientId, at ?? DateTime.now());
    chat.messages.add(m);
    chat.read[sender] = m.id;
    return m;
  }

  /// Seeds a few conversations between the demo accounts.
  void _seed() {
    final dm = _Chat('c${_chatSeq++}', ChatKind.direct, {'jamshid', 'malika'});
    _add(dm, 'jamshid', 'Malika, ertangi yetkazib berish rejasi tayyormi?', at: MockSeed.ago(190));
    _add(dm, 'malika', 'Ha, soat 10:00 da mashina yo‘lga chiqadi.', at: MockSeed.ago(170));
    _add(dm, 'jamshid', 'Zo‘r, rahmat!', at: MockSeed.ago(165));
    final group = _Chat('c${_chatSeq++}', ChatKind.group, {'jamshid', 'malika', 'boris'}, title: 'Ertalabki smena');
    _add(group, 'malika', 'Hammaga xayrli tong! Bugun 50 ta ko‘chat yuklanadi.', at: MockSeed.ago(75));
    _add(group, 'boris', 'Tushunarli, tayyorlab qo‘yaman.', at: MockSeed.ago(60));
    final worker = _Chat('c${_chatSeq++}', ChatKind.direct, {'boris', 'malika'});
    _add(worker, 'malika', 'Boris, mijozga qo‘ng‘iroq qilib qo‘ydingizmi?', at: MockSeed.ago(25));
    _chats.addAll([dm, group, worker]);
  }

  /// Chats [me] may open.
  Iterable<_Chat> _mine(AppUser me) =>
      _chats.where((c) => c.kind == ChatKind.task ? me.role != UserRole.client : c.members.contains(me.id));

  /// Chat [id] if [me] may open it, else 404 (same answer for unknown and forbidden).
  _Chat _chat(AppUser me, String id) =>
      _mine(me).firstWhere((c) => c.id == id, orElse: () => throw const MockFailure(404, 'Suhbat topilmadi.'));

  /// Backend conversation payload for [me].
  Map<String, dynamic> _payload(_Chat chat, AppUser me) {
    final marker = chat.read[me.id] ?? 0;
    final last = chat.messages.lastOrNull;
    return {
      'id': chat.id,
      'kind': chat.kind.apiName,
      'title': chat.title,
      'task': chat.taskId,
      'unread_count': chat.messages.where((m) => m.id > marker && m.sender != me.id).length,
      'last_message': last == null ? null : _json(chat, last),
      'members': chat.kind == ChatKind.task ? const [] : [for (final id in chat.members) _brief(id)],
    };
  }

  /// Routes `conversations/...` for the account [me].
  Object? route(AppUser me, String method, List<String> seg, Map<String, dynamic> body, Map<String, dynamic> query) {
    if (seg.length == 1) return method == 'POST' ? _open(me, body) : _list(me);
    if (seg[1] == 'contacts') return _contacts(me, '${query['q'] ?? ''}');
    final chat = _chat(me, seg[1]);
    if (seg.length == 2) return _payload(chat, me);
    switch (seg[2]) {
      case 'messages':
        return method == 'POST' ? _send(me, chat, body) : _history(chat, query);
      case 'read':
        return {'last_read_message_id': markRead(me, chat.id, (body['message_id'] as num).toInt())};
    }
    throw MockFailure(404, 'Mock uchun bu endpoint yozilmagan: ${seg.join('/')}');
  }

  /// `GET conversations/`, newest activity first.
  List<Map<String, dynamic>> _list(AppUser me) {
    final chats = _mine(me).toList()
      ..sort((a, b) => (b.messages.lastOrNull?.id ?? 0).compareTo(a.messages.lastOrNull?.id ?? 0));
    return [for (final c in chats) _payload(c, me)];
  }

  /// `GET conversations/contacts/`: staff may write to anyone, others only to staff.
  List<Map<String, dynamic>> _contacts(AppUser me, String q) {
    final needle = q.trim().toLowerCase();
    return [
      for (final u in MockStore.instance.users)
        if (u.id != me.id &&
            (me.role.isBoss || u.role.isBoss) &&
            (needle.isEmpty || u.name.toLowerCase().contains(needle) || u.id.contains(needle)))
          _brief(u.id),
    ];
  }

  /// `POST conversations/`: opens (or reuses) a direct chat, a task chat, or creates a group.
  Map<String, dynamic> _open(AppUser me, Map<String, dynamic> body) {
    final kind = ChatKind.fromJson(body['kind']);
    _Chat chat;
    switch (kind) {
      case ChatKind.direct:
        final other = _user('${body['user']}');
        if (other.id == me.id || !(me.role.isBoss || other.role.isBoss)) {
          throw const MockFailure(403, 'Bu foydalanuvchiga yozish mumkin emas.');
        }
        chat = _chats.firstWhere(
          (c) => c.kind == ChatKind.direct && c.members.containsAll({me.id, other.id}),
          orElse: () => _create(_Chat('c${_chatSeq++}', ChatKind.direct, {me.id, other.id})),
        );
      case ChatKind.task:
        final taskId = '${body['task']}';
        chat = _chats.firstWhere(
          (c) => c.taskId == taskId,
          orElse: () => _create(_Chat('c${_chatSeq++}', ChatKind.task, {}, taskId: taskId)),
        );
      case ChatKind.group:
        if (!me.role.isBoss) throw const MockFailure(403, 'Guruh yaratish mumkin emas.');
        final ids = {me.id, for (final id in (body['member_ids'] as List? ?? const [])) '$id'};
        chat = _create(_Chat('c${_chatSeq++}', ChatKind.group, ids, title: '${body['title']}'));
    }
    return _payload(chat, me);
  }

  /// Stores a new chat.
  _Chat _create(_Chat chat) {
    _chats.add(chat);
    return chat;
  }

  /// `GET conversations/{id}/messages/`: newest first, `before` cursor, `limit`.
  Map<String, dynamic> _history(_Chat chat, Map<String, dynamic> query) {
    final limit = (int.tryParse('${query['limit'] ?? 30}') ?? 30).clamp(1, 100);
    final before = int.tryParse('${query['before'] ?? 0}') ?? 0;
    final rows = chat.messages.reversed.where((m) => before == 0 || m.id < before).toList();
    return {
      'results': [for (final m in rows.take(limit)) _json(chat, m)],
      'has_more': rows.length > limit,
    };
  }

  /// `POST conversations/{id}/messages/`.
  Map<String, dynamic> _send(AppUser me, _Chat chat, Map<String, dynamic> body) =>
      _json(chat, send(me, chat.id, '${body['body']}', '${body['client_msg_id'] ?? ''}').$1);

  /// Stores a message of [me]; returns it with `true` when new (a repeated [clientId] returns the original).
  (MockChatMessage, bool) send(AppUser me, String chatId, String text, String clientId) {
    final chat = _chat(me, chatId);
    final body = text.trim();
    if (body.isEmpty || body.length > 4000)
      throw const MockFailure(400, 'Xabar 1–4000 belgidan iborat bo‘lishi kerak.');
    if (clientId.isNotEmpty) {
      final dup = chat.messages.where((m) => m.sender == me.id && m.clientId == clientId).firstOrNull;
      if (dup != null) return (dup, false);
    }
    return (_add(chat, me.id, body, clientId: clientId), true);
  }

  /// Moves [me]'s read marker; returns the new marker.
  int markRead(AppUser me, String chatId, int messageId) {
    final chat = _chat(me, chatId);
    final newest = chat.messages.where((m) => m.id <= messageId).map((m) => m.id).fold(0, (a, b) => a > b ? a : b);
    if (newest > (chat.read[me.id] ?? 0)) chat.read[me.id] = newest;
    return chat.read[me.id] ?? 0;
  }

  /// Backend message JSON of a stored message (used by the mock socket).
  Map<String, dynamic> messageJson(String chatId, MockChatMessage m) =>
      _json(_chats.firstWhere((c) => c.id == chatId), m);

  /// Participants of [chatId] other than [meId] (who can "reply" in the mock).
  List<String> others(String chatId, String meId) =>
      _chats.firstWhere((c) => c.id == chatId).members.where((id) => id != meId).toList();

  /// Stores a scripted message from [sender] (the mock "reply").
  MockChatMessage reply(String chatId, String sender, String text) =>
      _add(_chats.firstWhere((c) => c.id == chatId), sender, text);
}
