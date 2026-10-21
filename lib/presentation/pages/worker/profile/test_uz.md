# Profil (umumiy karkas) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getProfile` — GET `profile/summary`

- [ ] Muvaffaqiyat: each role → 200, role-specific numbers bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: xodimning `monthReward`/`paidReward` uning `done` vazifalari yig‘indisiga teng; boss `pendingExpenses` va `teamSize` oladi, xodimda ular nol.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

## 2. Mobil/Web integratsiya testi

- [ ] Ro‘yxatdan sozlama ekranlarini oching, chiqing (tasdiq) va boshqa rol bilan kiring.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Hisob kartasi; rolning o‘z kartalari (xodim: tarix havolali oylik kartasi; admin/menejer: yo‘q, ularning yorliqlari chap menyuda); sozlama qatorlari joriy til, mavzu va bildirishnoma holatini ko‘rsatadi; eslatma qatori mijozlar uchun yashirin.

## 4. Mantiqiy/biznes test

- [ ] Chiqish doim avval tasdiq so‘raydi va sessiya, keshlar hamda tanlangan tabni tozalaydi.
