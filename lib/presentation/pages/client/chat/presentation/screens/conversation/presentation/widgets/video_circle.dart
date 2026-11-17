import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';
import 'package:eco_task/infrastructure/repository/files_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// A video circle: a round 180-px video that starts muted-less playback on tap and loops back to the poster at the
/// end. The bytes are downloaded with the session's token and played from a temporary file.
class VideoCircle extends StatefulWidget {
  /// The recording.
  final FileAttachment file;

  /// Builds the circle.
  const VideoCircle({super.key, required this.file});

  @override
  State<VideoCircle> createState() => _VideoCircleState();
}

/// Owns the video controller and the temporary file behind it.
class _VideoCircleState extends State<VideoCircle> {
  /// Created on the first tap.
  VideoPlayerController? _controller;

  /// True while the file downloads.
  bool _loading = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Downloads once, then plays or pauses.
  Future<void> _toggle() async {
    if (_controller == null) {
      setState(() => _loading = true);
      try {
        final bytes = await RepositoryProvider.of<FilesRepository>(context).bytes(widget.file.id);
        final dir = await getTemporaryDirectory();
        final file = await File('${dir.path}/circle_${widget.file.id}.mp4').writeAsBytes(bytes);
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        await controller.setLooping(false);
        controller.addListener(() => mounted ? setState(() {}) : null);
        _controller = controller;
      } catch (_) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      if (mounted) setState(() => _loading = false);
    }
    final c = _controller!;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.position >= c.value.duration) await c.seekTo(Duration.zero);
      await c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final playing = c?.value.isPlaying ?? false;
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: 180.w,
        height: 180.w,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.cardColorLight,
          border: Border.all(color: theme.line),
        ),
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            if (c != null && c.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
              ),
            if (!playing)
              Center(
                child: _loading
                    ? SizedBox(
                        width: 28.w,
                        height: 28.w,
                        child: CircularProgressIndicator(strokeWidth: 2.5.w, color: theme.primary),
                      )
                    : AppIcon(AppIcons.play2, size: 40.sp, color: theme.primary),
              ),
          ],
        ),
      ),
    );
  }
}
