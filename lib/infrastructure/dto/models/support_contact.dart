/// How people reach the dispatcher, as `GET support/` returns it.
class SupportContact {
  /// Phone number exactly as the admin entered it (`+998 71 200 00 00`).
  final String phone;

  /// Telegram username with its leading `@`.
  final String telegram;

  /// Builds a contact from its parts.
  const SupportContact({required this.phone, required this.telegram});

  /// Nothing published: the backend has no contact row yet.
  static const none = SupportContact(phone: '', telegram: '');

  /// True when neither a phone nor a Telegram username is available.
  bool get isEmpty => phone.trim().isEmpty && telegram.trim().isEmpty;

  /// Parses the backend payload `{phone, telegram}`.
  factory SupportContact.fromJson(Map<String, dynamic> json) =>
      SupportContact(phone: '${json['phone'] ?? ''}'.trim(), telegram: '${json['telegram'] ?? ''}'.trim());
}
