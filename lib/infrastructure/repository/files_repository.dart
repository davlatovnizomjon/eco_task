import 'package:dio/dio.dart';

import 'package:eco_task/helpers/media_picker.dart';

import '../common/api_links.dart';
import '../common/dio_client.dart';
import '../dto/models/file_attachment.dart';

/// Uploads files and fetches their bytes. Downloaded bytes are kept in memory by id, so a photo shown in a list and
/// again in the viewer is fetched once.
class FilesRepository {
  /// Bytes already downloaded, by file id.
  final Map<int, List<int>> _cache = {};

  /// Uploads [bytes] as [name] with its [contentType]; [durationMs] marks a voice note or video. Answers the stored
  /// file, which can then be attached to a task, a message or a group.
  Future<FileAttachment> upload(
    List<int> bytes, {
    required String name,
    required String contentType,
    int? durationMs,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: name, contentType: DioMediaType.parse(contentType)),
      if (durationMs != null) 'duration_ms': durationMs,
    });
    final response = await dioClient.post(ApiLinks.files, data: form);
    final file = FileAttachment.fromJson((response.data as Map).cast<String, dynamic>());
    _cache[file.id] = bytes;
    return file;
  }

  /// Uploads a file chosen with `MediaPicker`.
  Future<FileAttachment> uploadPicked(PickedFile file) =>
      upload(file.bytes, name: file.name, contentType: file.contentType, durationMs: file.durationMs);

  /// Bytes of file [id]; downloaded on the first call, then served from memory.
  Future<List<int>> bytes(int id) async => _cache[id] ??= await dioClient.bytes(ApiLinks.file(id));
}
