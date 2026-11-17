import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/card_widget.dart';

/// Bottom sheet of a task's address: the address itself and the ways to open it — Yandex Maps, Google Maps or the
/// system share sheet.
class MapsSheet extends StatelessWidget {
  /// Address the task happens at.
  final String address;

  /// Builds the sheet.
  const MapsSheet({super.key, required this.address});

  /// Opens the sheet for [address].
  static Future<void> show(BuildContext context, String address) =>
      showBottomDialog<void>(MapsSheet(address: address), context);

  /// Opens [url] in its own app and closes the sheet.
  Future<void> _open(BuildContext context, String url) async {
    Navigator.pop(context);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    /// The address, escaped for a map search query.
    final query = Uri.encodeComponent(address);

    /// Rows of the sheet: brand gradient of the tile, label and the link it opens.
    final rows = [
      (
        colors: const [Color(0xFFFC3F1D), Color(0xFFFF8A00)],
        label: TrWords.mtMapYandex.tr(),
        url: 'https://yandex.com/maps/?text=$query',
      ),
      (
        colors: const [Color(0xFF34A853), Color(0xFF4285F4)],
        label: TrWords.mtMapGoogle.tr(),
        url: 'https://www.google.com/maps/search/?api=1&query=$query',
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TrWords.mtAddress.tr(),
          style: theme.textStyle.copyWith(fontSize: 20.sp, height: 26 / 20, fontWeight: FontWeight.w700),
        ),
        4.h.height,
        Text(
          address,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.cardSubtitle.copyWith(fontSize: 14.sp, height: 19 / 14),
        ),
        16.h.height,
        CardWidget(
          padding: EdgeInsets.zero,
          decoration: theme.panelDecor,
          child: Column(
            children: [
              for (final (i, row) in rows.indexed)
                InkWell(
                  onTap: () => _open(context, row.url),
                  child: Container(
                    constraints: BoxConstraints(minHeight: 56.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      border: i == 0 ? null : Border(top: BorderSide(color: theme.line, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            borderRadius: 9.circular,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: row.colors,
                            ),
                          ),
                        ),
                        12.w.width,
                        Expanded(
                          child: Text(
                            row.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textStyle.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w400),
                          ),
                        ),
                        AppIcon(AppIcons.right, color: theme.grayText),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
