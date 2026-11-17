import 'package:flutter/services.dart';

import 'package:eco_task/constants/constants.dart';

/// Formats amounts for display and for typing, and parses them back to a plain
/// integer before they reach the API. A bare `num` is never shown.
class MoneyFormatter {
  /// Private constructor — the class is a namespace of statics.
  const MoneyFormatter._();

  /// Thousands-separated number: `1 000`.
  static String number(num value) {
    final digits = value.round().abs().toString();
    final out = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      // A space goes in front of every complete group of three from the right.
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(' ');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// Amount with the currency sign: `1 000 $`.
  static String display(num value) => '${number(value)} \$';

  /// Amount in the task's own currency: `1 200 000 so‘m` for `uzs`, `1 000 $` otherwise.
  static String amount(num value, String currency) =>
      currency == 'uzs' ? TrWords.tdSum.tr(args: [number(value)]) : display(value);

  /// The integer typed into a money field; 0 when it holds no digits.
  static int parse(String? text) => int.tryParse((text ?? '').replaceAll(RegExp(r'\D'), '')) ?? 0;
}

/// Text-field formatter that groups digits by thousands while typing
/// (`1000` → `1 000`). Pair it with `FilteringTextInputFormatter.digitsOnly`'s
/// effect: it strips every non-digit itself.
class MoneyInputFormatter extends TextInputFormatter {
  /// Builds the formatter.
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = MoneyFormatter.number(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
