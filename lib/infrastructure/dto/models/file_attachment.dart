/// Kind of an uploaded file.
enum FileKind {
  /// A photo.
  image,

  /// A document (PDF, Word, Excel, text).
  document,

  /// A voice note.
  audio,

  /// A video circle or clip.
  video;

  /// Kind parsed from the API's upper-case name.
  factory FileKind.fromJson(Object? name) =>
      values.firstWhere((k) => k.name == '$name'.toLowerCase(), orElse: () => FileKind.document);
}

/// One uploaded file as the API describes it.
class FileAttachment {
  /// Server id.
  final int id;

  /// What the file is.
  final FileKind kind;

  /// Original file name.
  final String name;

  /// Size in bytes.
  final int size;

  /// Length of a voice note or video, in milliseconds; null for other kinds.
  final int? durationMs;

  /// Builds an attachment.
  const FileAttachment({required this.id, required this.kind, required this.name, this.size = 0, this.durationMs});

  /// Parses the API object.
  factory FileAttachment.fromJson(Map<String, dynamic> json) => FileAttachment(
    id: (json['id'] as num).toInt(),
    kind: FileKind.fromJson(json['kind']),
    name: '${json['name'] ?? ''}',
    size: (json['size'] as num?)?.toInt() ?? 0,
    durationMs: (json['duration_ms'] as num?)?.toInt(),
  );

  /// Serializes back to the API's shape (used by the mock backend).
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name.toUpperCase(),
    'name': name,
    'size': size,
    'duration_ms': durationMs,
  };

  /// Size written for people: `240 KB`, `1.2 MB`.
  String get sizeLabel => size >= 1048576 ? '${(size / 1048576).toStringAsFixed(1)} MB' : '${(size / 1024).ceil()} KB';
}
