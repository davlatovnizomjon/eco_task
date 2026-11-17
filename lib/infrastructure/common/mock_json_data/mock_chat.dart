import 'package:eco_task/domain/common/enums/chat_kind.dart';
import 'package:eco_task/domain/common/enums/user_role.dart';
import 'package:eco_task/infrastructure/dto/models/app_user.dart';

import 'mock_files.dart';
import 'mock_seed.dart';
import 'mock_store.dart';

/// One stored mock message (public because the mock socket reads it).
class MockChatMessage {
  /// Increasing id within the conversation.
  final int id;

  /// Author account id.
  final String sender;

  /// Client id the send used, for idempotent retries.
  final String clientId;

  /// When it was stored.
  final DateTime at;

  /// Body; mutable because the author may edit it and a delete wipes it.
  String text;

  /// When the author last edited the text.
  DateTime? editedAt;

  /// True after the message was deleted.
  bool deleted = false;

  /// Id of the message this one answers.
  int? replyTo;

  /// Id of the attached file in `MockFiles`.
  int? attachmentId;

  /// Reaction of each person: user id → emoji.
  final Map<String, String> reactions = {};

  MockChatMessage(this.id, this.sender, String body, this.clientId, this.at) : text = body;
}

/// One stored mock conversation.
class _Chat {
  final String id;
  final ChatKind kind;
  String title;
  final String? taskId;
  final Set<String> members;
  final List<MockChatMessage> messages = [];

  /// Read marker per account id.
  final Map<String, int> read = {};

  /// People who muted this chat.
  final Set<String> muted = {};

  /// Id of the pinned message, if any.
  int? pinned;

  /// Id of the group's photo in `MockFiles`.
  int? avatarId;

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
    'body': m.deleted ? '' : m.text,
    'client_msg_id': m.clientId,
    'created_at': m.at.toUtc().toIso8601String(),
    'edited_at': m.editedAt?.toUtc().toIso8601String(),
    'deleted': m.deleted,
    'reply_to': _quote(chat, m.replyTo),
    'attachment': m.deleted || m.attachmentId == null ? null : MockFiles.instance.meta(m.attachmentId!)?.toJson(),
    'reactions': [
      for (final emoji in m.reactions.values.toSet())
        {
          'emoji': emoji,
          'user_ids': [
            for (final e in m.reactions.entries)
              if (e.value == emoji) e.key,
          ],
        },
    ],
  };

  /// The small card of the quoted message [id], as the API's `reply_to`.
  Map<String, dynamic>? _quote(_Chat chat, int? id) {
    final parent = chat.messages.where((x) => x.id == id).firstOrNull;
    if (parent == null) return null;
    return {
      'id': parent.id,
      'sender_name': _brief(parent.sender)['full_name'],
      'body': parent.deleted ? '' : (parent.text.length > 120 ? parent.text.substring(0, 120) : parent.text),
      'deleted': parent.deleted,
      'attachment_kind': parent.deleted || parent.attachmentId == null
          ? null
          : MockFiles.instance.meta(parent.attachmentId!)?.kind.name.toUpperCase(),
    };
  }

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
      'muted': chat.muted.contains(me.id),
      'avatar': chat.avatarId == null ? null : MockFiles.instance.meta(chat.avatarId!)?.toJson(),
      'pinned_message': chat.pinned == null ? null : _json(chat, chat.messages.firstWhere((m) => m.id == chat.pinned)),
    };
  }

  /// Calls started in this session, by id; the mock keeps them so the call actions can answer for them.
  final Map<int, Map<String, dynamic>> _calls = {};

  /// `POST conversations/{id}/calls/` — the mock has no ringing devices, so everybody invited picks up at once.
  Map<String, dynamic> _startCall(AppUser me, _Chat chat, Map<String, dynamic> body) {
    if (chat.kind == ChatKind.task) throw const MockFailure(400, 'Qo‘ng‘iroq faqat shaxsiy va guruh chatlarida.');
    final others = chat.members.where((id) => id != me.id).toList();
    if (others.isEmpty) throw const MockFailure(400, 'Qo‘ng‘iroq qilinadigan odam yo‘q.');
    final id = _calls.length + 1;
    final now = DateTime.now().toIso8601String();
    return _calls[id] = {
      'id': id,
      'conversation': chat.id,
      'kind': '${body['kind'] ?? 'AUDIO'}',
      'status': 'ACTIVE',
      'caller': _brief(me.id),
      'created_at': now,
      'answered_at': now,
      'participants': [
        for (final uid in [me.id, ...others]) {'user': _brief(uid), 'state': 'JOINED'},
      ],
    };
  }

  /// `GET/POST calls/{id}[/answer|decline|end|invite]` for a call of this session.
  Map<String, dynamic> callAction(AppUser me, List<String> seg, Map<String, dynamic> body) {
    final call = _calls[int.tryParse(seg.length > 1 ? seg[1] : '')];
    if (call == null) throw const MockFailure(404, 'Qo‘ng‘iroq topilmadi.');
    if (seg.length > 2 && (seg[2] == 'end' || seg[2] == 'decline')) call['status'] = 'ENDED';
    return call;
  }

  /// Routes `conversations/...` for the account [me].
  Object? route(AppUser me, String method, List<String> seg, Map<String, dynamic> body, Map<String, dynamic> query) {
    if (seg.length == 1) return method == 'POST' ? _open(me, body) : _list(me);
    if (seg[1] == 'contacts') return _contacts(me, '${query['q'] ?? ''}');
    final chat = _chat(me, seg[1]);
    if (seg.length == 2) return method == 'PATCH' ? _update(me, chat, body) : _payload(chat, me);
    if (seg[2] == 'messages' && seg.length >= 4) return _messageAction(me, chat, method, seg, body);
    switch (seg[2]) {
      case 'pin':
        return _pin(me, chat, method == 'PUT' ? (body['message_id'] as num).toInt() : null);
      case 'members':
        return _members(me, chat, method, seg, body);
      case 'messages':
        return method == 'POST' ? _send(me, chat, body) : _history(chat, query);
      case 'calls':
        return method == 'POST' ? _startCall(me, chat, body) : const <Object>[];
      case 'read':
        return {'last_read_message_id': markRead(me, chat.id, (body['message_id'] as num).toInt())};
    }
    throw MockFailure(404, 'Mock uchun bu endpoint yozilmagan: ${seg.join('/')}');
  }

  /// `GET conversations/`, newest activity first.
  /// `PATCH conversations/{id}` — rename a group and/or switch the caller's mute.
  Map<String, dynamic> _update(AppUser me, _Chat chat, Map<String, dynamic> body) {
    if (body['title'] != null) {
      if (chat.kind != ChatKind.group) throw const MockFailure(400, 'Faqat guruhning nomi bor.');
      if (!me.role.isBoss) throw const MockFailure(403, 'Guruh nomini o‘zgartirish mumkin emas.');
      final title = '${body['title']}'.trim();
      if (title.isEmpty) throw const MockFailure(400, 'Nom bo‘sh bo‘lishi mumkin emas.');
      chat.title = title;
    }
    if (body['avatar_id'] != null) {
      if (chat.kind != ChatKind.group || !me.role.isBoss)
        throw const MockFailure(403, 'Guruh rasmini o‘zgartirish mumkin emas.');
      chat.avatarId = (body['avatar_id'] as num).toInt();
    }
    if (body['muted'] != null) body['muted'] == true ? chat.muted.add(me.id) : chat.muted.remove(me.id);
    return _payload(chat, me);
  }

  /// `PUT/DELETE conversations/{id}/pin`.
  Map<String, dynamic> _pin(AppUser me, _Chat chat, int? messageId) {
    if (messageId != null &&
        chat.messages
            .firstWhere((m) => m.id == messageId, orElse: () => throw const MockFailure(404, 'Xabar topilmadi.'))
            .deleted) {
      throw const MockFailure(409, 'O‘chirilgan xabarni pin qilib bo‘lmaydi.');
    }
    chat.pinned = messageId;
    return _payload(chat, me);
  }

  /// Members of a group: add (`POST`) and remove or leave (`DELETE .../{userId}`).
  Map<String, dynamic> _members(AppUser me, _Chat chat, String method, List<String> seg, Map<String, dynamic> body) {
    if (chat.kind != ChatKind.group) throw const MockFailure(400, 'Faqat guruhga a’zo qo‘shiladi.');
    if (method == 'POST') {
      if (!me.role.isBoss) throw const MockFailure(403, 'A’zo qo‘shish mumkin emas.');
      chat.members.addAll([for (final id in (body['user_ids'] as List? ?? const [])) '$id']);
    } else if (seg.length == 4) {
      if (seg[3] != me.id && !me.role.isBoss) throw const MockFailure(403, 'A’zoni chiqarish mumkin emas.');
      chat.members.remove(seg[3]);
    }
    return _payload(chat, me);
  }

  /// Edit, delete and react on one message.
  Map<String, dynamic> _messageAction(
    AppUser me,
    _Chat chat,
    String method,
    List<String> seg,
    Map<String, dynamic> body,
  ) {
    final message = chat.messages.firstWhere(
      (m) => m.id == int.tryParse(seg[3]),
      orElse: () => throw const MockFailure(404, 'Xabar topilmadi.'),
    );
    if (seg.length == 5 && seg[4] == 'reaction') {
      if (message.deleted) throw const MockFailure(409, 'O‘chirilgan xabarga munosabat bildirib bo‘lmaydi.');
      method == 'PUT' ? message.reactions[me.id] = '${body['emoji']}' : message.reactions.remove(me.id);
    } else if (method == 'PATCH') {
      if (message.sender != me.id) throw const MockFailure(403, 'Faqat o‘z xabaringizni tahrirlay olasiz.');
      if (message.deleted) throw const MockFailure(409, 'O‘chirilgan xabarni tahrirlab bo‘lmaydi.');
      final text = '${body['body']}'.trim();
      if (text.isEmpty || text.length > 4000)
        throw const MockFailure(400, 'Xabar 1–4000 belgidan iborat bo‘lishi kerak.');
      message
        ..text = text
        ..editedAt = DateTime.now();
    } else if (method == 'DELETE') {
      if (message.sender != me.id && !me.role.isBoss) throw const MockFailure(403, 'Bu xabarni o‘chirib bo‘lmaydi.');
      message
        ..deleted = true
        ..reactions.clear();
      if (chat.pinned == message.id) chat.pinned = null;
    }
    return _json(chat, message);
  }

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
  Map<String, dynamic> _send(AppUser me, _Chat chat, Map<String, dynamic> body) => _json(
    chat,
    send(
      me,
      chat.id,
      '${body['body'] ?? ''}',
      '${body['client_msg_id'] ?? ''}',
      replyTo: (body['reply_to'] as num?)?.toInt(),
      attachmentId: (body['attachment_id'] as num?)?.toInt(),
    ).$1,
  );

  /// Stores a message of [me]; returns it with `true` when new (a repeated [clientId] returns the original).
  (MockChatMessage, bool) send(
    AppUser me,
    String chatId,
    String text,
    String clientId, {
    int? replyTo,
    int? attachmentId,
  }) {
    final chat = _chat(me, chatId);
    final body = text.trim();
    if ((body.isEmpty && attachmentId == null) || body.length > 4000) {
      throw const MockFailure(400, 'Xabar 1–4000 belgidan iborat bo‘lishi kerak.');
    }
    if (clientId.isNotEmpty) {
      final dup = chat.messages.where((m) => m.sender == me.id && m.clientId == clientId).firstOrNull;
      if (dup != null) return (dup, false);
    }
    final stored = _add(chat, me.id, body, clientId: clientId)
      ..replyTo = replyTo
      ..attachmentId = attachmentId;
    return (stored, true);
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
