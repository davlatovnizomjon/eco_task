import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/domain/common/enums/screen_status.dart';
import 'package:eco_task/infrastructure/dto/models/support_contact.dart';
import 'package:eco_task/infrastructure/repository/support_repository.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';
import 'package:eco_task/presentation/public/widgets/app_loader.dart';
import 'package:eco_task/presentation/public/widgets/empty_view.dart';

import 'bloc/bloc.dart';

/// "Contact the dispatcher" sheet: a close button, a round headset, the title with a short explanation and then a call
/// row and a Telegram row. On the first opening it loads the contacts from the backend and shows a spinner while waiting
/// (later openings reuse the remembered contacts), an empty panel when none are published and a retry panel when the
/// request fails. Tapping a row dials the number or opens the Telegram chat; when the device cannot, the value is
/// copied instead and the row confirms with "Nusxalandi".
class SupportSheet extends StatelessWidget {
  /// Builds the sheet.
  const SupportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          SupportBloc(repository: RepositoryProvider.of<SupportRepository>(ctx))..add(const SupportStarted()),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 16.h),
                child: Column(
                  children: [
                    Container(
                      width: 52.w,
                      height: 52.w,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: theme.primaryTint, shape: BoxShape.circle),
                      child: AppIcon(AppIcons.headset, size: 26.sp, color: theme.primaryDark),
                    ),
                    10.h.height,
                    Text(
                      TrWords.supportTitle.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textStyle.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
                    ),
                    6.h.height,
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 290.w),
                      child: Text(
                        TrWords.supportHint.tr(),
                        textAlign: TextAlign.center,
                        style: theme.cardSubtitle.copyWith(fontSize: 14.sp, height: 20 / 14),
                      ),
                    ),
                  ],
                ),
              ),
              const _SupportBody(),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 40.w,
                height: 40.w,
                child: Center(
                  child: AppIcon(AppIcons.x, size: 22.sp, color: theme.textSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Switches between the loading, error, empty and contacts views of the sheet.
class _SupportBody extends StatelessWidget {
  /// Height of the spinner / empty / error panels, so the sheet does not jump around.
  static const _panelHeight = 160.0;

  /// Builds the body.
  const _SupportBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupportBloc, SupportState>(
      builder: (context, state) {
        if (state.status.isError) {
          return SizedBox(
            height: _panelHeight.h,
            child: EmptyView(
              title: TrWords.cLoadFailed.tr(),
              message: TrWords.cLoadFailedDesc.tr(),
              icon: AppIcons.alert,
              onRetry: () => context.read<SupportBloc>().add(const SupportStarted()),
            ),
          );
        }
        if (!state.status.isSuccess) {
          return SizedBox(
            height: _panelHeight.h,
            child: const Center(child: AppLoader()),
          );
        }
        if (state.contact.isEmpty) {
          return SizedBox(
            height: _panelHeight.h,
            child: EmptyView(
              title: TrWords.supportEmpty.tr(),
              message: TrWords.supportEmptyDesc.tr(),
              icon: AppIcons.phone,
            ),
          );
        }
        return _ContactRows(contact: state.contact);
      },
    );
  }
}

/// The call and Telegram rows; a row whose value is missing is left out.
class _ContactRows extends StatefulWidget {
  /// Contacts to list.
  final SupportContact contact;

  /// Builds the rows.
  const _ContactRows({required this.contact});

  @override
  State<_ContactRows> createState() => _ContactRowsState();
}

/// Opens the links and remembers which row was just copied.
class _ContactRowsState extends State<_ContactRows> {
  /// Index of the row that shows the "copied" note, or null.
  int? _copied;

  /// Opens [link] for row [index]; when nothing can handle it, copies [value] and flags the row for two seconds.
  Future<void> _open(int index, Uri link, String value) async {
    try {
      if (await launchUrl(link, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // No dialer / Telegram on this device: fall back to copying.
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    setState(() => _copied = index);
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = null);
      }),
    );
  }

  /// [phone] reduced to what a `tel:` link accepts: digits and a leading plus.
  static String _dialable(String phone) => phone.replaceAll(RegExp(r'[^\d+]'), '');

  @override
  Widget build(BuildContext context) {
    final phone = widget.contact.phone;
    final telegram = widget.contact.telegram;
    // Rows: glyph, label, what a tap opens, the value that gets copied as a fallback.
    final rows = [
      if (phone.isNotEmpty)
        (AppIcons.phone, TrWords.supportCall.tr(), Uri(scheme: 'tel', path: _dialable(phone)), phone),
      if (telegram.isNotEmpty)
        (
          AppIcons.send,
          TrWords.supportTelegram.tr(),
          Uri.parse('https://t.me/${telegram.replaceFirst('@', '')}'),
          telegram,
        ),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 14.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, (icon, label, link, value)) in rows.indexed)
            InkWell(
              onTap: () => _open(i, link, value),
              child: Container(
                height: 56.h,
                padding: 4.w.horizontal,
                decoration: BoxDecoration(
                  border: i == 0 ? null : Border(top: BorderSide(color: theme.line, width: 0.5)),
                ),
                child: Row(
                  children: [
                    AppIcon(icon, size: 22.sp, color: theme.primary),
                    14.w.width,
                    Expanded(
                      child: Text(
                        _copied == i ? TrWords.botCopied.tr() : label,
                        style: theme.textStyle.copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w400,
                          color: _copied == i ? theme.primary : theme.text,
                        ),
                      ),
                    ),
                    AppIcon(AppIcons.right, size: 18.sp, color: theme.grayText),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
