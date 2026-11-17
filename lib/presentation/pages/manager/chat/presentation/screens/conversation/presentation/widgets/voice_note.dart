import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// A voice note: a play / pause button, a waveform that fills as it plays and the length. The audio is downloaded
/// with the session's token on the first press, then played from memory.
class VoiceNote extends StatefulWidget {
  /// The recording.
  final FileAttachment file;

  /// Color of the button, the waveform and the time.
  final Color color;

  /// Builds the player.
  const VoiceNote({super.key, required this.file, required this.color});

  @override
  State<VoiceNote> createState() => _VoiceNoteState();
}

/// Owns the audio player and the playback position.
class _VoiceNoteState extends State<VoiceNote> {
  /// Heights of the waveform bars, derived from the file id so each note looks different but stays stable.
  late final List<double> _bars = [for (var i = 0; i < 28; i++) 0.25 + ((widget.file.id * 31 + i * 17) % 10) / 14];

  /// Created on the first press.
  AudioPlayer? _player;

  /// Subscriptions to the player.
  final List<StreamSubscription<Object?>> _subs = [];

  /// True while sound is playing.
  bool _playing = false;

  /// Played share of the note, 0–1.
  double _progress = 0;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  /// Plays or pauses; the first call downloads the bytes and wires the player.
  Future<void> _toggle() async {
    if (_player == null) {
      final bytes = await RepositoryProvider.of<FilesRepository>(context).bytes(widget.file.id);
      final player = AudioPlayer();
      _player = player;
      _subs
        ..add(
          player.onPlayerStateChanged.listen(
            (s) => mounted ? setState(() => _playing = s == PlayerState.playing) : null,
          ),
        )
        ..add(
          player.onPositionChanged.listen((p) {
            final total = widget.file.durationMs ?? 0;
            if (mounted && total > 0) setState(() => _progress = (p.inMilliseconds / total).clamp(0, 1));
          }),
        )
        ..add(player.onPlayerComplete.listen((_) => mounted ? setState(() => _progress = 0) : null));
      await player.play(BytesSource(Uint8List.fromList(bytes), mimeType: 'audio/mp4'));
      return;
    }
    await (_playing ? _player!.pause() : _player!.resume());
  }

  @override
  Widget build(BuildContext context) {
    final seconds = ((widget.file.durationMs ?? 0) / 1000).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.18), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(_playing ? AppIcons.pause : AppIcons.play, size: 18.sp, color: widget.color),
          ),
        ),
        10.w.width,
        SizedBox(
          height: 28.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final (i, h) in _bars.indexed)
                Container(
                  width: 3.w,
                  height: 28.h * h,
                  margin: EdgeInsets.only(right: 2.w),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: i / _bars.length < _progress ? 1 : 0.4),
                    borderRadius: 2.circular,
                  ),
                ),
            ],
          ),
        ),
        8.w.width,
        Text(
          '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
          style: theme.cardSubtitle.copyWith(fontSize: 12.sp, color: widget.color),
        ),
      ],
    );
  }
}
