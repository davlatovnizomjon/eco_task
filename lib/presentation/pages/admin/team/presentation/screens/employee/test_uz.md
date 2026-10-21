# Xodim profili (boss) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.getUser` — GET `users/{id}`

- [ ] Muvaffaqiyat: a worker id → 200, the account with `activeCount` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Noma’lum id → 404 dialogda ko‘rsatiladi.

### `TasksRepository.getTasks` — GET `tasks?who={id}`

- [ ] Muvaffaqiyat: the employee id → 200, only tasks involving that employee bilan; tahlil qilingan model javobga mos keladi.
- [ ] Qiymatlar: faol + tarix sonlari jamiga teng; «o‘z vaqtida» muddatdan kech bo‘lmay tugagan `done` vazifalarni hisoblaydi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

## 2. Mobil/Web integratsiya testi

- [ ] Xodimni katalogdan va vazifaning ijrochi qatoridan oching; faol/tarixni almashtiring; admin ruxsatlar tugmasini ko‘radi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Uchta hisoblagich, pul kartasi (mukofotlar, to‘langan, tasdiqlangan xarajatlar, ko‘rib chiqilmoqda) va vazifalar ro‘yxati shu xodimning vazifa tafsilotlari bilan mos.

## 4. Mantiqiy/biznes test

- [ ] Menejer o‘z jamoasidan tashqari xodimlarni ko‘ra olmaydi (404).
