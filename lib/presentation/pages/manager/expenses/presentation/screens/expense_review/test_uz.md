# Xarajatni tekshirish (boss) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Muvaffaqiyat: the task holding the expense → 200, the expense with note, amount, receipt flag bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.

### `ExpensesRepository.review` — POST `tasks/{id}/expenses/{eid}/review`

- [ ] Muvaffaqiyat: `{amount: 180}` for a 200 expense, and an empty body to reject → 200, status `approved` with `approvedAmount` 180, or `rejected` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: amount 0 or above the entered amount → 400 `detail` shown in the dialog → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: tasdiqlash xodimni tasdiqlangan va kiritilgan summalar bilan xabardor qiladi; vazifaning tasdiqlangan summasi buni aks ettiradi.

## 2. Mobil/Web integratsiya testi

- [ ] Kichikroq summaga tasdiqlang va boshqasini rad eting; ro‘yxatga qayting va ikkalasi kutilayotgan tabdan chiqqanini ko‘ring.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Tasdiqlash tugmasi yorlig‘i yozilgan summani formatlab ko‘rsatadi; summa maydoni kiritilgan summa bilan to‘ldirilgan; noto‘g‘ri summa faqat birinchi qaror urinishidan keyin qizil; chek yo‘qligi ogohlantirish bannerini ko‘rsatadi.

## 4. Mantiqiy/biznes test

- [ ] Tasdiqlangan summa kiritilgandan oshishi ham, nol bo‘lishi ham mumkin emas.
