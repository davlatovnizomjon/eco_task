# Vazifalar holati (boss) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=…`

- [ ] Muvaffaqiyat: each period → 200, per-status counts and `overdue` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: katta jami oltita holat qatori yig‘indisiga teng; kechikkan qator holatga bog‘liq emas.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

## 2. Mobil/Web integratsiya testi

- [ ] Dashboarddagi kechikkan kartasidan oching, davrlarni almashtiring, qatorni bosing (vazifalar tabiga o‘tadi).
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Sonli oltita holat chipi va sariq kechikkan qatori ko‘rinadi; jami kartasida jamoa nomi chiqadi.

## 4. Mantiqiy/biznes test

- [ ] Menejer faqat jamoasi hisoblagichlarini ko‘radi.
