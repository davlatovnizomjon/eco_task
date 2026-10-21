import 'user_ref.dart';

/// A comment on a task or a request.
class CommentModel {
  /// Author of the comment.
  final UserRef user;

  /// Comment text.
  final String text;

  /// When it was posted.
  final DateTime at;

  /// Builds a comment from its parts.
  const CommentModel({required this.user, required this.text, required this.at});

  /// Parses the API object.
  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    user: UserRef.fromJson(json['user'] as Map<String, dynamic>),
    text: '${json['text']}',
    at: DateTime.parse('${json['at']}'),
  );

  /// Serializes the comment.
  Map<String, dynamic> toJson() => {'user': user.toJson(), 'text': text, 'at': at.toIso8601String()};
}
