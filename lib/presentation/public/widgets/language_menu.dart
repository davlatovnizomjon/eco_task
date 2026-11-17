import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';
import 'flag_icon.dart';

/// The UI languages the app offers: locale, native name and the short code shown on the button.
const _languages = [
  (Locale('uz'), 'O‘zbekcha', 'Uz'),
  (Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'), 'Ўзбекча', 'Ўз'),
  (Locale('ru'), 'Русский', 'Ru'),
];

/// Compact language button (flag, short code, chevron) that opens a small popup menu under itself; choosing a
/// language switches the app language at once.
class LanguageMenuButton extends StatelessWidget {
  /// Builds the button.
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final current = _languages.firstWhere((l) => l.$1 == context.locale, orElse: () => _languages.first);
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        height: 32.h,
        padding: EdgeInsets.fromLTRB(9.w, 0, 6.w, 0),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: 9.circular,
          border: Border.all(color: theme.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlagIcon(current.$1, width: 21.w),
            6.w.width,
            Text(
              current.$3,
              style: theme.textStyle.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            4.w.width,
            AppIcon(AppIcons.down, size: 14.sp, color: theme.grayText),
          ],
        ),
      ),
    );
  }

  /// Shows the popup under the button, right-aligned with it.
  void _open(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final rightGap = MediaQuery.of(context).size.width - origin.dx - box.size.width;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: TrWords.langAppLang.tr(),
      barrierColor: const Color(0xFF0A140F).withValues(alpha: 0.22),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, _, _) => Stack(
        children: [
          Positioned(
            top: origin.dy + box.size.height + 8.h,
            right: rightGap,
            width: 200.w,
            child: _Menu(
              selected: context.locale,
              onPick: (locale) {
                context.setLocale(locale);
                Navigator.pop(dialogContext);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The popup card with one radio row per language.
class _Menu extends StatelessWidget {
  /// Locale currently in use.
  final Locale selected;

  /// Called with the chosen locale.
  final ValueChanged<Locale> onPick;

  /// Builds the menu.
  const _Menu({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: 4.w.all,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: 16.circular,
          border: Border.all(color: theme.line),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 14),
              blurRadius: 36,
              color: const Color(0xFF0F1914).withValues(alpha: theme.dark ? 0.5 : 0.18),
            ),
          ],
        ),
        // A Material right above the rows so the ink splash is painted over the card's own background.
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, (locale, name, _)) in _languages.indexed)
                InkWell(
                  onTap: () => onPick(locale),
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? 12.circularRadius : Radius.zero,
                    bottom: i == _languages.length - 1 ? 12.circularRadius : Radius.zero,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
                    decoration: BoxDecoration(
                      border: i == 0 ? null : Border(top: BorderSide(color: theme.line)),
                    ),
                    child: Row(
                      children: [
                        FlagIcon(locale, width: 22.w),
                        10.w.width,
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textStyle.copyWith(
                              fontSize: 15.sp,
                              fontWeight: selected == locale ? FontWeight.w600 : FontWeight.w500,
                              fontVariations: selected == locale ? const [FontVariation.weight(650)] : null,
                            ),
                          ),
                        ),
                        if (selected == locale) AppIcon(AppIcons.check, size: 20.sp, color: theme.primary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
