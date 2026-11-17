import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/helpers/dialog_helpers.dart';
import 'package:eco_task/infrastructure/dto/models/support_contact.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/setting_row.dart';
import 'package:eco_task/utils/formatters/phone_formatter.dart';

/// "Help and dispatcher" sheet of the profile: call the dispatcher, write to them in Telegram, and the working
/// hours. A way without a value is hidden.
class SupportSheet extends StatelessWidget {
  /// Dispatcher contacts loaded by the profile.
  final SupportContact contact;

  /// Builds the sheet.
  const SupportSheet({super.key, required this.contact});

  /// Opens the sheet for [contact].
  static Future<void> show(BuildContext context, SupportContact contact) =>
      showBottomDialog<void>(SupportSheet(contact: contact), context);

  /// Leaves the app for [url] and closes the sheet.
  Future<void> _open(BuildContext context, String url) async {
    Navigator.pop(context);
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          TrWords.pfHelp.tr(),
          style: theme.textStyle.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        4.h.height,
        if (contact.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text(TrWords.supportEmptyDesc.tr(), style: theme.cardSubtitle),
          ),
        if (contact.phone.isNotEmpty)
          SettingRow(
            first: true,
            inset: 0,
            icon: AppIcons.phone,
            title: TrWords.supportCall.tr(),
            subtitle: PhoneFormatter.display(contact.phone),
            onTap: () => _open(context, 'tel:${PhoneFormatter.apiValue(contact.phone)}'),
          ),
        if (contact.telegram.isNotEmpty)
          SettingRow(
            first: contact.phone.isEmpty,
            inset: 0,
            icon: AppIcons.send,
            title: TrWords.supportTelegram.tr(),
            subtitle: contact.telegram,
            onTap: () => _open(context, 'https://t.me/${contact.telegram.replaceFirst('@', '')}'),
          ),
        8.h.height,
        Row(
          children: [
            AppIcon(AppIcons.clock, size: 16.sp, color: theme.grayText),
            8.w.width,
            Text(TrWords.pfHours.tr(), style: theme.cardSubtitle),
          ],
        ),
      ],
    );
  }
}
