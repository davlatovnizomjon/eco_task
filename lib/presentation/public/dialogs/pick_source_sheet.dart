import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/status_tone.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/helpers/media_picker.dart';

import '../widgets/setting_row.dart';

/// Where a file comes from.
enum PickSource {
  /// A new photo from the camera.
  camera,

  /// Photos from the gallery.
  gallery,

  /// A document file.
  document,
}

/// Bottom sheet that asks where to take a file from (camera, gallery, optionally a document) and then opens the
/// matching device picker. [PickSourceSheet.show] resolves to the picked files, empty when the person cancels.
class PickSourceSheet extends StatelessWidget {
  /// True to offer the document row.
  final bool documents;

  /// Builds the sheet.
  const PickSourceSheet({super.key, required this.documents});

  /// Asks, then picks; never throws on cancel.
  static Future<List<PickedFile>> show(BuildContext context, {bool documents = true}) async {
    /// The source chosen in the sheet; null when dismissed.
    final source = await showBottomDialog<PickSource>(PickSourceSheet(documents: documents), context);
    switch (source) {
      case PickSource.camera:
        return MediaPicker.photos(camera: true);
      case PickSource.gallery:
        return MediaPicker.photos();
      case PickSource.document:
        return [if (await MediaPicker.document() case final f?) f];
      case null:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingRow(
          first: true,
          inset: 0,
          icon: AppIcons.camera,
          title: TrWords.flCamera.tr(),
          onTap: () => Navigator.pop(context, PickSource.camera),
        ),
        SettingRow(
          inset: 0,
          icon: AppIcons.image,
          title: TrWords.flGallery.tr(),
          onTap: () => Navigator.pop(context, PickSource.gallery),
        ),
        if (documents)
          SettingRow(
            inset: 0,
            icon: AppIcons.file,
            tone: StatusTone.info,
            title: TrWords.flDocument.tr(),
            onTap: () => Navigator.pop(context, PickSource.document),
          ),
      ],
    );
  }
}
