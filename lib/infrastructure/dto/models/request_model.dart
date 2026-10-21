import '../../../domain/common/enums/request_kind.dart';
import '../../../domain/common/enums/request_status.dart';
import 'comment_model.dart';
import 'user_ref.dart';

/// A service request a client sent to the company.
class RequestModel {
  /// Human id such as `R-2041`.
  final String id;

  /// The client who filed it.
  final UserRef client;

  /// What the client wants done, in one line.
  final String title;

  /// Longer explanation; may be empty.
  final String detail;

  /// Service type.
  final RequestKind kind;

  /// Where the work happens.
  final String address;

  /// Preferred time window such as `09:00–12:00`; empty while undecided.
  final String slot;

  /// Lifecycle state.
  final RequestStatus status;

  /// Agreed or preferred day; null while the date is still being agreed.
  final DateTime? date;

  /// Staff member in charge; null until planned.
  final UserRef? assignee;

  /// When the request was filed.
  final DateTime createdAt;

  /// Messages between client and company, oldest first.
  final List<CommentModel> comments;

  /// Builds a request from its parts.
  const RequestModel({
    required this.id,
    required this.client,
    required this.title,
    required this.createdAt,
    this.detail = '',
    this.kind = RequestKind.delivery,
    this.address = '',
    this.slot = '',
    this.status = RequestStatus.accepted,
    this.date,
    this.assignee,
    this.comments = const [],
  });

  /// Parses the API object.
  factory RequestModel.fromJson(Map<String, dynamic> json) => RequestModel(
    id: '${json['id']}',
    client: UserRef.fromJson(json['client'] as Map<String, dynamic>),
    title: '${json['title']}',
    detail: '${json['detail'] ?? ''}',
    kind: RequestKind.fromJson(json['kind']),
    address: '${json['address'] ?? ''}',
    slot: '${json['slot'] ?? ''}',
    status: RequestStatus.fromJson(json['status']),
    date: json['date'] == null ? null : DateTime.parse('${json['date']}'),
    assignee: json['assignee'] == null ? null : UserRef.fromJson(json['assignee'] as Map<String, dynamic>),
    createdAt: DateTime.parse('${json['createdAt']}'),
    comments: [
      for (final c in (json['comments'] as List? ?? const [])) CommentModel.fromJson(c as Map<String, dynamic>),
    ],
  );

  /// Serializes the request.
  Map<String, dynamic> toJson() => {
    'id': id,
    'client': client.toJson(),
    'title': title,
    'detail': detail,
    'kind': kind.name,
    'address': address,
    'slot': slot,
    'status': status.name,
    'date': date?.toIso8601String(),
    'assignee': assignee?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'comments': [for (final c in comments) c.toJson()],
  };

  /// Copy with a new [comments] list.
  RequestModel withComments(List<CommentModel> value) => RequestModel(
    id: id,
    client: client,
    title: title,
    createdAt: createdAt,
    detail: detail,
    kind: kind,
    address: address,
    slot: slot,
    status: status,
    date: date,
    assignee: assignee,
    comments: value,
  );
}
