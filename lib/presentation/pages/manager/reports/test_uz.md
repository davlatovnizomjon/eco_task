# Hisobotlar (boss) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=week|month|quarter`

- [ ] Muvaffaqiyat: each period → 200, counts per status, `overdue`, `lateDelivered`, `weekly`, money totals, `people` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: `sum(counts) == total`; qisqaroq davr uzunroq davrdan ko‘p vazifa haqida xabar bermaydi; pul jami shu vazifalar yig‘indisiga teng.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Uch davrni almashtiring va yangilang; raqamlarni vazifalar ro‘yxati filtrlari bilan solishtiring.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Holat kartasi, haftalik ustun diagramma (oxirgi ustun ajratilgan, ustunlar eng balandiga moslashadi) va pul kartasi ko‘rinadi; diagramma nol yoki katta qiymatlarda overflow qilmaydi.

## 4. Mantiqiy/biznes test

- [ ] Davrni tez almashtirish faqat oxirgi tanlangan davr raqamlarini ko‘rsatadi.
