import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';
import 'package:eco_task/presentation/public/widgets/app_icon.dart';

/// Language choice sheet: the three UI languages as radio rows; choosing one switches the app language at once.
class LanguageSheet extends StatelessWidget {
  /// Builds the sheet.
  const LanguageSheet({super.key});

  /// Languages offered: native name and locale.
  static final _languages = [
    ('O‘zbekcha', const Locale('uz')),
    ('Ўзбекча', Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl')),
    ('Русский', const Locale('ru')),
  ];

  /// Native name of [locale], falling back to the Latin Uzbek entry.
  static String nameOf(Locale locale) =>
      _languages.firstWhere((l) => l.$2 == locale, orElse: () => _languages.first).$1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, (name, locale)) in _languages.indexed)
          _PickRow(
            first: i == 0,
            title: name,
            selected: context.locale == locale,
            onTap: () {
              context.setLocale(locale);
              Navigator.pop(context);
            },
          ),
        20.h.height,
      ],
    );
  }
}

/// One option row of a picker sheet: optional leading glyph, title and a green check on the selected one.
class _PickRow extends StatelessWidget {
  /// True for the first row (no top hairline).
  final bool first;

  /// Option label.
  final String title;

  /// Whether the option is the current choice.
  final bool selected;

  /// SVG asset drawn before the title; omitted when null.
  final String? icon;

  /// Tap handler.
  final VoidCallback onTap;

  /// Builds the row.
  const _PickRow({required this.first, required this.title, required this.selected, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 4.w),
        decoration: BoxDecoration(
          border: first ? null : Border(top: BorderSide(color: theme.line)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[AppIcon(icon!, size: 22.sp, color: theme.textSecondary), 14.w.width],
            Expanded(
              child: Text(
                title,
                style: theme.textStyle.copyWith(
                  fontSize: 16.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            if (selected) AppIcon(AppIcons.check, size: 20.sp, color: theme.primary),
          ],
        ),
      ),
    );
  }
}
