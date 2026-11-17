import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/infrastructure/dto/models/file_attachment.dart';
import 'package:eco_task/presentation/public/dialogs/pick_source_sheet.dart';
import 'package:eco_task/presentation/public/dialogs/photo_viewer.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/auth_image.dart';

import '../../bloc/bloc.dart';

/// "Files" field of a task form: a 3-column grid of photo thumbnails with a corner "x", one row per document, and an
/// "add photo" tile that asks for the camera, the gallery or a document. Uploads happen at once; the form keeps the
/// ids.
class TaskFilesField extends StatelessWidget {
  /// Builds the field.
  const TaskFilesField({super.key});

  @override
  Widget build(BuildContext context) {
    /// Bloc of the form.
    final bloc = context.read<TaskFormBloc>();
    return BlocBuilder<TaskFormBloc, TaskFormState>(
      buildWhen: (a, b) => a.attachments != b.attachments || a.uploading != b.uploading,
      builder: (context, state) {
        final images = [
          for (final a in state.attachments)
            if (a.kind == FileKind.image) a,
        ];
        final docs = [
          for (final a in state.attachments)
            if (a.kind == FileKind.document) a,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(TrWords.flFiles.tr(), style: theme.fieldLabel)),
                Text(
                  TrWords.flCounts.tr(args: ['${images.length}', '10', '${docs.length}', '5']),
                  style: theme.cardSubtitle.copyWith(fontSize: 12.sp),
                ),
              ],
            ),
            8.h.height,
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final (i, a) in images.indexed)
                  GestureDetector(
                    onTap: () => PhotoViewer.show(context, count: images.length, initial: i, files: images),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AuthImage(a.id, radius: 14.r),
                        Positioned(
                          top: 5.w,
                          right: 5.w,
                          child: GestureDetector(
                            onTap: () => bloc.add(TaskFormFileRemoved(a.id)),
                            child: Container(
                              width: 22.w,
                              height: 22.w,
                              decoration: const BoxDecoration(color: Color(0x8C000000), shape: BoxShape.circle),
                              child: AppIcon(AppIcons.x, size: 12.sp, color: const Color(0xFFFFFFFF)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: state.uploading
                      ? null
                      : () async {
                          for (final f in await PickSourceSheet.show(context)) {
                            bloc.add(TaskFormFilePicked(f));
                          }
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: 14.circular,
                      border: Border.all(color: theme.line),
                    ),
                    child: state.uploading
                        ? Center(
                            child: SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: CircularProgressIndicator(strokeWidth: 2.w, color: theme.primary),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(AppIcons.camera, size: 26.sp, color: theme.primary),
                              4.h.height,
                              Text(
                                TrWords.flAddPhoto.tr(),
                                textAlign: TextAlign.center,
                                style: theme.textStyle.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: theme.primary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
            for (final d in docs)
              Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: 12.circular,
                  border: Border.all(color: theme.line),
                ),
                child: Row(
                  children: [
                    AppIcon.tile(AppIcons.file, tone: StatusTone.info, size: 40),
                    12.w.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textStyle),
                          Text(d.sizeLabel, style: theme.cardSubtitle),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => bloc.add(TaskFormFileRemoved(d.id)),
                      icon: AppIcon(AppIcons.x, size: 18.sp, color: theme.grayText),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
