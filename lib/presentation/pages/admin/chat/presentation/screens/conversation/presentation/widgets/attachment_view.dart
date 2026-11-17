import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';
import 'package:eco_task/presentation/public/dialogs/document_viewer.dart';
import 'package:eco_task/presentation/public/dialogs/photo_viewer.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/auth_image.dart';

import 'video_circle.dart';
import 'voice_note.dart';

/// What a message carries besides text, drawn per kind: a tappable photo, a document row, a voice note or a video
/// circle. [color] is the foreground of the bubble it sits in.
class AttachmentView extends StatelessWidget {
  /// The attachment.
  final FileAttachment file;

  /// Foreground color of the surrounding bubble.
  final Color color;

  /// Builds the view.
  const AttachmentView({super.key, required this.file, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (file.kind) {
      case FileKind.image:
        return GestureDetector(
          onTap: () => PhotoViewer.show(context, count: 1, files: [file]),
          child: SizedBox(
            width: 220.w,
            height: 200.h,
            child: AuthImage(file.id, radius: 12.r),
          ),
        );
      case FileKind.audio:
        return VoiceNote(file: file, color: color);
      case FileKind.video:
        return VideoCircle(file: file);
      case FileKind.document:
        return GestureDetector(
          onTap: () => DocumentViewer.show(context, file.name),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.tile(AppIcons.file, tone: StatusTone.info, size: 40),
              10.w.width,
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textStyle.copyWith(color: color),
                    ),
                    Text(
                      file.sizeLabel,
                      style: theme.cardSubtitle.copyWith(fontSize: 12.sp, color: color.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
