import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';

/// One line of a details card: a gray glyph, a gray label and the value at the right edge. Put several inside a
/// `CardWidget(padding: horizontal 16, vertical 4)`; every row but the [first] draws a hairline above itself, and a
/// tappable row ends with a chevron.
class DetailRow extends StatelessWidget {
  /// SVG asset of the leading glyph.
  final String icon;

  /// Gray caption of the row.
  final String label;

  /// Value text; ignored when [trailing] is given.
  final String? value;

  /// True to draw [value] bold (the deadline, the client).
  final bool bold;

  /// Small tinted remark after the value ("· 4 soat").
  final String? note;

  /// Widget drawn instead of [value] (a status chip, photo thumbnails).
  final Widget? trailing;

  /// Tap handler; a tappable row shows a chevron.
  final VoidCallback? onTap;

  /// True for the first row of a card — it draws no hairline.
  final bool first;

  /// Builds the row.
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.bold = false,
    this.note,
    this.trailing,
    this.onTap,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 48.h),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: theme.line)),
        ),
        child: Row(
          children: [
            AppIcon(icon, color: theme.grayText),
            8.w.width,
            Text(label, style: theme.cardSubtitle),
            12.w.width,
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    trailing ??
                    Text(
                      value ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: theme.textStyle.copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
                    ),
              ),
            ),
            if (note != null) ...[6.w.width, Text(note!, style: theme.cardSubtitle.copyWith(color: theme.warn))],
            if (onTap != null) ...[8.w.width, AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText)],
          ],
        ),
      ),
    );
  }
}
