# Vazifa eslatmalari (shaxsiy vazifaning eslatmalari)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Muvaffaqiyat: 200; `comments` eng eskisi birinchi bo‘lib qaytadi va `CommentModel` ga tahlil qilinadi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`.

### `TasksRepository.addComment` — POST `tasks/{id}/comments`

- [ ] `{text}` bilan muvaffaqiyat: javobda yangi eslatma oxirida turadi; keshdagi ro‘yxatlar bekor qilinadi.
- [ ] Parametr xatosi: bo‘sh `text` → 400 → `ValidationErrorResponse`; ilova bo‘sh matn yubormaydi.

### `TasksRepository.deleteComment` — DELETE `tasks/{id}/comments/{index}`

- [ ] Mock’da muvaffaqiyat: `index` dagi eslatma yo‘qoladi va qolganlari tartibini saqlaydi.
- [ ] Jonli API: bunday endpoint hali yo‘q → `MessageErrorResponse` (501); ro‘yxat qayta yuklanadi va eslatma qaytadi.

## 2. Mobil/Web integratsiya testi

- [ ] Shaxsiy vazifa ekranidagi eslatma kartasidan eslatmalarni oching; eslatma yozib yuboring → u oxirida “Oxirgi” belgisi bilan chiqadi va maydon tozalanadi.
- [ ] Eslatmani chapga suring → qizil “O‘chirish” paneli ko‘rinadi; surishni tugatsangiz u o‘chadi.
- [ ] Tortib yangilash ro‘yxatni qayta yuklaydi; `AppConfig.useMockData = true` bilan va jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Dizayn `Eco Tasks — mobile app` ning 1.10 va 1.10a taxtalariga yorug‘ va qorong‘i mavzuda 1:1 mos keladi.
- [ ] Bo‘sh ro‘yxat “Hali eslatma yo‘q” ni ko‘rsatadi va tortiladigan bo‘lib qoladi; kiritish paneli klaviatura ustiga ko‘tariladi.
- [ ] Uzun eslatmalar ko‘p nuqta bilan qisqaradi; 320 px da toshish yo‘q; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] “Oxirgi” faqat eng yangi eslatmani belgilaydi va bitta eslatma bo‘lsa yashiriladi.
- [ ] Faqat bo‘shliqdan iborat eslatma yuborilmaydi.
