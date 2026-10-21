# Tekshiruv navbati (boss) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks?status=rev`

- [ ] Muvaffaqiyat: the boss session → 200, results waiting for a decision bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: menejer faqat o‘z jamoasi yuborganlarini ko‘radi.

### `ExpensesRepository.getExpenses` — GET `expenses?filter=pending`

- [ ] Muvaffaqiyat: the boss session → 200, pending expenses bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: har bir qator `hasReceipt` dan chek belgisini ko‘rsatadi.

### Decisions — POST `tasks/{id}/approve`, `tasks/{id}/return`

- [ ] Muvaffaqiyat: approve and return (with and without extend) → 200, the updated task; both lists reload and the row disappears bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

## 2. Mobil/Web integratsiya testi

- [ ] Bitta natijani tasdiqlang, boshqasini har bir sabab bilan qaytaring; dashboard hisoblagichlari va ijrochi inboxi ikkalasini aks ettiradi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Tablar ikkita sonni ko‘rsatadi; har bir natija kartasi yuboruvchi, vaqt, id, nom, natija matni, rasm tasmasi, kechikish chipi va ikkita tugmani ko‘rsatadi; bo‘sh navbat bo‘sh ko‘rinishni ko‘rsatadi; pull-to-refresh ishlaydi.

## 4. Mantiqiy/biznes test

- [ ] Muddatdan keyin yuborilgan natija `submittedAt − due` dan hisoblangan «N kun kech» chipini ko‘rsatadi.
