import datetime

from django.db import migrations

TERMS = [
    ("Ilova nima uchun", "Eco Task — kompaniya ichida xodimlarga vazifa berish, bajarilishini kuzatish va natijalarni tasdiqlash uchun ichki ilova."),
    ("Kirish huquqi", "Login va parolni faqat kompaniya rahbari beradi. Hisobingizni boshqalarga bermang. Parol 5 marta noto‘g‘ri kiritilsa, kirish 5 daqiqaga bloklanadi."),
    ("Vazifalar va natijalar", "Siz yuborgan rasm, chek, izoh va hisobotlar ishga oid bo‘lishi kerak. Ularni rahbar ko‘radi va tasdiqlaydi yoki qaytaradi."),
    ("Xarajat va to‘lovlar", "Xarajatlar chek bilan kiritiladi. To‘lov va mukofot faqat rahbar tasdiqlagandan keyin hisoblanadi."),
    ("Taqiqlangan harakatlar", "Boshqa xodim nomidan ish yuborish, soxta chek yuklash va tizimni buzishga urinish taqiqlanadi."),
    ("O‘zgarishlar", "Shartlar yangilansa, ilova ichida xabar beramiz."),
]
PRIVACY = [
    ("Qanday ma’lumot yig‘iladi", "Ism, login, lavozim, vazifalar, siz yuklagan rasm va cheklar, vazifa bajarilgan joy (faqat ruxsat bersangiz)."),
    ("Nima uchun kerak", "Vazifalarni taqsimlash, bajarilishini tekshirish, xarajat va mukofotlarni hisoblash uchun."),
    ("Kim ko‘radi", "Faqat kompaniyangiz rahbari va menejerlar, o‘z vakolati doirasida. Ma’lumot uchinchi shaxslarga sotilmaydi."),
    ("Saqlash", "Ma’lumotlar himoyalangan serverda saqlanadi. Ishdan ketganingizda hisobingizni rahbar o‘chiradi."),
    ("Joylashuv va kamera", "Faqat siz vazifa bajarayotganda va ruxsat berganingizda ishlatiladi. Telefon sozlamalarida istalgan vaqt o‘chirish mumkin."),
    ("Bog‘lanish", "Savollar bo‘lsa, kompaniyangiz rahbariga murojaat qiling."),
]


def seed(apps, schema_editor):
    """Publishes the texts the app used to ship in its translations, so the first deploy changes nothing visible."""
    LegalDocument = apps.get_model("legal", "LegalDocument")
    for kind, title, sections in (("terms", "Foydalanish shartlari", TERMS), ("privacy", "Maxfiylik siyosati", PRIVACY)):
        LegalDocument.objects.get_or_create(
            kind=kind,
            language="uz",
            defaults={
                "title": title,
                "message": "\n\n".join(f"{i}. {head}\n{body}" for i, (head, body) in enumerate(sections, 1)),
                "effective_date": datetime.date(2026, 10, 1),
            },
        )


class Migration(migrations.Migration):
    dependencies = [("legal", "0001_initial")]
    operations = [migrations.RunPython(seed, migrations.RunPython.noop)]
