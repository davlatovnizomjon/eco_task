import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';

/// In-memory file store of the mock backend: keeps the bytes and the description of every upload.
class MockFiles {
  /// Private constructor — use [instance].
  MockFiles._();

  /// The one shared store.
  static final MockFiles instance = MockFiles._();

  /// Seeded photo ids are 1..9; uploads start above them.
  int _seq = 100;

  /// Uploaded descriptions by id.
  final Map<int, FileAttachment> _meta = {};

  /// Uploaded bytes by id.
  final Map<int, List<int>> _bytes = {};

  /// Stores an upload and answers its description.
  FileAttachment add(List<int> bytes, {required String name, required String contentType, int? durationMs}) {
    final kind = contentType.startsWith('image/')
        ? FileKind.image
        : contentType.startsWith('audio/')
        ? FileKind.audio
        : contentType.startsWith('video/')
        ? FileKind.video
        : FileKind.document;
    final file = FileAttachment(id: _seq++, kind: kind, name: name, size: bytes.length, durationMs: durationMs);
    _meta[file.id] = file;
    _bytes[file.id] = bytes;
    return file;
  }

  /// Description of file [id], or null.
  FileAttachment? meta(int id) => _meta[id];

  /// Bytes of file [id], or null (seeded placeholders have none).
  List<int>? bytes(int id) => _bytes[id];
}
