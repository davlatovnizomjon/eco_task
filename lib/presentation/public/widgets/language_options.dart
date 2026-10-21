import 'package:flutter/material.dart';

import 'package:eco_task/constants/constants.dart';

import 'app_icon.dart';
import 'card_widget.dart';
import 'option_tile.dart';

/// The three supported languages as one selectable card (Uzbek Latin, Uzbek
/// Cyrillic, Russian). Tapping a row switches the app language immediately;
/// used by the Settings language screen.
class LanguageOptions extends StatelessWidget {
  /// Builds the language card.
  const LanguageOptions({super.key});

  /// Each language: its own-script name, the subtitle key and its locale.
  static final _languages = [
    ('O‘zbekcha', TrWords.langLatin, const Locale('uz')),
    ('Ўзбекча', TrWords.langCyrl, Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl')),
    ('Русский', TrWords.langRu, const Locale('ru')),
  ];

  /// Own-script name of [locale], e.g. `Русский`; falls back to the first language.
  static String nameOf(Locale locale) =>
      _languages.firstWhere((l) => l.$3 == locale, orElse: () => _languages.first).$1;

  @override
  Widget build(BuildContext context) {
    return CardWidget(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, (name, subtitle, locale)) in _languages.indexed)
            OptionTile(
              title: name,
              subtitle: subtitle.tr(),
              first: i == 0,
              onTap: () => context.setLocale(locale),
              trailing: AppIcon(
                context.locale == locale ? AppIcons.checkc : AppIcons.eq,
                color: context.locale == locale ? theme.primary : theme.line,
              ),
            ),
        ],
      ),
    );
  }
}
