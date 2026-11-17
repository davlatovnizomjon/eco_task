# Profilni tahrirlash (xodim) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `SessionRepository.updateAccount` — PATCH `account` (jonli: `PATCH users/{me}/`)

- [ ] Muvaffaqiyat: `{name}` → 200, yangilangan hisob bilan; saqlangan sessiya va `user` notifier darhol yangi ismni olib yuradi.
- [ ] Auth xatosi: muddati o‘tgan token → 401 → sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Mock/jonli tenglik: mock loginni o‘zgarmas qoldirib faqat ismni almashtiradi; jonli API foydalanuvchilar endpointi orqali almashtiradi.

## 2. Mobil/Web integratsiya testi

- [ ] Profil sarlavhasidagi amaldan oching; ism va familiyani tahrirlang va saqlang; profil sarlavhasi va dashboard salomlashuvi yangi ismni ko‘rsatadi.
- [ ] «Login va parolni o‘zgartirish» qatori login va parol ekranini ochadi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).

## 4. Mantiqiy/biznes test

- [ ] Bo‘sh ism saqlashni to‘xtatadi va xato dialogini ko‘rsatadi; familiya ixtiyoriy.
