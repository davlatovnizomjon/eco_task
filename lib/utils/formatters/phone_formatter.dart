import 'package:flutter/services.dart';

/// Formats Uzbek phone numbers for display and for typing, and strips them
/// back to digits before they reach the API.
///
/// Every phone the user sees or types goes through here — a raw `+998...`
/// string is never rendered and a formatted one is never sent.
class PhoneFormatter {
  /// Private constructor — the class is a namespace of statics.
  const PhoneFormatter._();

  /// Country code every stored number carries.
  static const _countryCode = '998';

  /// Digits in a full national number, country code included.
  static const _fullLength = 12;

  /// Shortest number the form accepts, country code included.
  ///
  /// A mobile number is 12 digits, but the backend also issues shorter
  /// accounts (10 digits, country code included), and rejecting one here
  /// would make signing in impossible. Length is checked loosely; the server
  /// is what actually decides the number exists.
  static const _minLength = 10;

  /// Renders [raw] as `+998 90 123 45 67`. A number that is not a full
  /// Uzbek one is returned untouched rather than mangled.
  static String display(String? raw) {
    final digits = digitsOf(raw);
    if (digits.length != _fullLength) return raw ?? '';
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8, 10)} '
        '${digits.substring(10)}';
  }

  /// The API form of [raw] — `+998901234567`, or an empty string when the
  /// input holds no digits.
  static String apiValue(String? raw) {
    final digits = digitsOf(raw);
    return digits.isEmpty ? '' : '+$digits';
  }

  /// True when [raw] holds an Uzbek number the form may submit.
  static bool isValid(String? raw) {
    final digits = digitsOf(raw);
    return digits.length >= _minLength && digits.length <= _fullLength && digits.startsWith(_countryCode);
  }

  /// Every digit in [raw], with spaces, `+` and separators removed.
  static String digitsOf(String? raw) => (raw ?? '').replaceAll(RegExp(r'\D'), '');
}

/// Text-field formatter that types an Uzbek phone as `+998 90 123 45 67`.
/// Attach it to every phone input; the field's raw text is converted with
/// [PhoneFormatter.apiValue] before submitting.
class PhoneInputFormatter extends TextInputFormatter {
  /// Builds the formatter.
  const PhoneInputFormatter();

  /// Digit positions after which a space is inserted.
  static const _spaceAfter = {3, 5, 8, 10};

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Always rebuild from the digits, so deleting inside the string behaves
    // the same as deleting at the end.
    var digits = PhoneFormatter.digitsOf(newValue.text);
    if (digits.isEmpty) return const TextEditingValue();
    if (!digits.startsWith('998')) digits = '998$digits';
    if (digits.length > 12) digits = digits.substring(0, 12);

    final buffer = StringBuffer('+');
    for (var i = 0; i < digits.length; i++) {
      if (_spaceAfter.contains(i)) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
