import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// A file chosen on the device, read into memory and ready for upload.
class PickedFile {
  /// File content.
  final List<int> bytes;

  /// File name with its extension.
  final String name;

  /// MIME type guessed from the extension.
  final String contentType;

  /// Length of a recording, when known.
  final int? durationMs;

  /// Builds a picked file.
  const PickedFile({required this.bytes, required this.name, required this.contentType, this.durationMs});

  /// MIME types by extension; anything else is sent as a generic download the server will refuse.
  static const _types = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
  };

  /// MIME type of [name] by its extension.
  static String typeOf(String name) => _types[name.split('.').last.toLowerCase()] ?? 'application/octet-stream';
}

/// Device pickers behind one small API: photos from the gallery or camera, a document, a short camera video. Each
/// answers nothing when the person cancels.
abstract final class MediaPicker {
  /// The shared image picker.
  static final _images = ImagePicker();

  /// Photos from the gallery (several at once) or one shot from the camera.
  static Future<List<PickedFile>> photos({bool camera = false}) async {
    final files = camera
        ? [if (await _images.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2048) case final f?) f]
        : await _images.pickMultiImage(imageQuality: 85, maxWidth: 2048);
    return [
      for (final f in files)
        PickedFile(bytes: await f.readAsBytes(), name: f.name, contentType: PickedFile.typeOf(f.name)),
    ];
  }

  /// One document (PDF, Word, Excel or text).
  static Future<PickedFile?> document() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'xlsx', 'txt'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || file.bytes == null) return null;
    return PickedFile(bytes: file.bytes!, name: file.name, contentType: PickedFile.typeOf(file.name));
  }

  /// A video of up to 60 seconds recorded with the camera — the "video circle".
  static Future<PickedFile?> videoCircle() async {
    final video = await _images.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
      preferredCameraDevice: CameraDevice.front,
    );
    if (video == null) return null;
    return PickedFile(bytes: await video.readAsBytes(), name: video.name, contentType: PickedFile.typeOf(video.name));
  }
}
