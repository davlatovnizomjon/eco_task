import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'media_picker.dart';

/// Records a voice note to a temporary AAC file and hands it back as a [PickedFile]. One recording at a time.
class VoiceRecorder {
  /// The platform recorder.
  final AudioRecorder _recorder = AudioRecorder();

  /// When the current recording started; null while idle.
  DateTime? _startedAt;

  /// Path of the temporary file being written.
  String? _path;

  /// True while a recording is running.
  bool get recording => _startedAt != null;

  /// Starts recording; false when the microphone permission was refused.
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 44100), path: _path!);
    _startedAt = DateTime.now();
    return true;
  }

  /// Stops and returns the recording, or null when [discard] is set or it was shorter than a second.
  Future<PickedFile?> stop({bool discard = false}) async {
    final started = _startedAt;
    final path = await _recorder.stop() ?? _path;
    _startedAt = null;
    if (started == null || path == null) return null;
    final file = File(path);
    final elapsed = DateTime.now().difference(started);
    try {
      if (discard || elapsed < const Duration(seconds: 1)) return null;
      return PickedFile(
        bytes: await file.readAsBytes(),
        name: 'voice.m4a',
        contentType: 'audio/mp4',
        durationMs: elapsed.inMilliseconds,
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  /// Releases the platform recorder.
  Future<void> dispose() => _recorder.dispose();
}
