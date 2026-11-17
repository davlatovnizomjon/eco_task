/// The legal texts the mock backend answers `legal/terms/` and `legal/privacy/` with, in the live API's shape: a title
/// and one message whose sections are separated by a blank line, each starting with `N. Heading`.
class MockLegal {
  /// Private constructor — the class is a namespace of statics.
  const MockLegal._();

  /// Terms sections: heading and text.
  static const _terms = [
    (
      'Ilova nima uchun',
      'Eco Task — kompaniya ichida xodimlarga vazifa berish, bajarilishini kuzatish va natijalarni tasdiqlash uchun ichki ilova.',
    ),
    (
      'Kirish huquqi',
      'Login va parolni faqat kompaniya rahbari beradi. Hisobingizni boshqalarga bermang. Parol 5 marta noto‘g‘ri kiritilsa, kirish 5 daqiqaga bloklanadi.',
    ),
    (
      'Vazifalar va natijalar',
      'Siz yuborgan rasm, chek, izoh va hisobotlar ishga oid bo‘lishi kerak. Ularni rahbar ko‘radi va tasdiqlaydi yoki qaytaradi.',
    ),
    (
      'Xarajat va to‘lovlar',
      'Xarajatlar chek bilan kiritiladi. To‘lov va mukofot faqat rahbar tasdiqlagandan keyin hisoblanadi.',
    ),
    (
      'Taqiqlangan harakatlar',
      'Boshqa xodim nomidan ish yuborish, soxta chek yuklash va tizimni buzishga urinish taqiqlanadi.',
    ),
    ('O‘zgarishlar', 'Shartlar yangilansa, ilova ichida xabar beramiz.'),
  ];

  /// Privacy sections: heading and text.
  static const _privacy = [
    (
      'Qanday ma’lumot yig‘iladi',
      'Ism, login, lavozim, vazifalar, siz yuklagan rasm va cheklar, vazifa bajarilgan joy (faqat ruxsat bersangiz).',
    ),
    ('Nima uchun kerak', 'Vazifalarni taqsimlash, bajarilishini tekshirish, xarajat va mukofotlarni hisoblash uchun.'),
    (
      'Kim ko‘radi',
      'Faqat kompaniyangiz rahbari va menejerlar, o‘z vakolati doirasida. Ma’lumot uchinchi shaxslarga sotilmaydi.',
    ),
    ('Saqlash', 'Ma’lumotlar himoyalangan serverda saqlanadi. Ishdan ketganingizda hisobingizni rahbar o‘chiradi.'),
    (
      'Joylashuv va kamera',
      'Faqat siz vazifa bajarayotganda va ruxsat berganingizda ishlatiladi. Telefon sozlamalarida istalgan vaqt o‘chirish mumkin.',
    ),
    ('Bog‘lanish', 'Savollar bo‘lsa, kompaniyangiz rahbariga murojaat qiling.'),
  ];

  /// The terms (when [terms] is true) or the privacy policy as the API's JSON.
  static Map<String, dynamic> document(bool terms) {
    final sections = terms ? _terms : _privacy;
    return {
      'title': terms ? 'Foydalanish shartlari' : 'Maxfiylik siyosati',
      'message': [for (final (i, (head, body)) in sections.indexed) '${i + 1}. $head\n$body'].join('\n\n'),
      'updated_at': '2026-10-01T09:00:00Z',
    };
  }
}
