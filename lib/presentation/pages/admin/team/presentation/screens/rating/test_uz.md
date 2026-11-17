# Xodimlar reytingi (admin) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports` (`people` maydoni)

- [ ] Muvaffaqiyat: har bir davr uchun → 200; ekran `people` ni `done` bo‘yicha, eng yaxshisi birinchi tartiblaydi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → sessiya tozalanadi va router kirish ekraniga qaytaradi.

## 2. Mobil/Web integratsiya testi

- [ ] Dashboarddagi «Reyting» havolasidan oching; Shu hafta / Shu oy / Chorak ni almashtiring; xodim profilini ochish uchun qatorni bosing.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Birinchi o‘rin to‘ldirilgan yashil doira, 2–3-o‘rinlar tuslangan doira, qolganlari oddiy kulrang raqam; har bir qatorda avatar, ism, `bajarilgan/jami`, progress chizig‘i va o‘z vaqtidagi foiz bor.

## 4. Mantiqiy/biznes test

- [ ] Foiz — o‘z vaqtida bajarilganlar bo‘lingan bajarilgan vazifalar (hech narsa bajarilmagan bo‘lsa 0).
