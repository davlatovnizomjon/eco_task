# Auth (kirish) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `SessionRepository.login` — POST `auth/login`

- [ ] Muvaffaqiyat: `{login, password}` of each demo account (`jamshid`, `malika`, `boris`, `gulnora`, password `1234`) → 200, `{token, user}` and the matching `role` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Noto‘g‘ri hisob: noma’lum login yoki noto‘g‘ri parol → 401 → `MessageErrorResponse(statusCode: 401)` (`UnAuthorizedResponse` emas); sessiya tozalanmaydi.
- [ ] Parametr xatosi: empty `login` or `password` is rejected locally before any request → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: `user.role` bosh sahifa tablarini belgilaydi: owner (admin)/assistant (menejer) → 5 ta boss tabi, worker → 5 ta xodim tabi, client → Telegram-bot ekrani (tabsiz).
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] To‘rtta rolning har biri bilan kiring, to‘g‘ri bosh sahifaga tushing va ilovani qayta ishga tushirgandan keyin sessiyani saqlang (secure storage).
- [ ] Profildan chiqing, so‘ng eskirgan ma’lumotsiz boshqa rol bilan kiring (keshlar tozalanadi).
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Birinchi yuborishgacha hech narsa qizil emas; muvaffaqiyatsiz yuborish BIRINCHI noto‘g‘ri maydonni umumiy xato dialogida ko‘rsatadi, barcha noto‘g‘ri maydonlar qizil bo‘ladi; maydonni tuzatish qizilni darhol tozalaydi.
- [ ] Noto‘g‘ri hisob qolgan urinishlar (5 → 4 → …) bilan qizil banner va qizil maydonlarni dialogsiz ko‘rsatadi.
- [ ] Parol ko‘zi maskani almashtiradi; demo hisob chiplari login va parolni to‘ldiradi.

## 4. Mantiqiy/biznes test

- [ ] Urinishlar hisoblagichi 0 dan pastga tushmaydi va ekran qayta ochilganda tiklanadi.
- [ ] Login katta-kichik harfga sezgir emas va bo‘sh joylardan tozalanadi; parol harf registriga sezgir.
