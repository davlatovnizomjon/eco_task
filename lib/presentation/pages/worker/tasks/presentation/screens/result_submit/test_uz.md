# Natijani yuborish (xodim) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.submitResult` — POST `tasks/{id}/submit`

- [ ] Muvaffaqiyat: `{text}` after attaching at least one photo → 200, the task in status `rev` with `submittedAt` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: no photo attached is rejected locally with the photo message → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: boss `review` inbox yozuvini oladi va vazifa tekshiruv navbatida paydo bo‘ladi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Muvaffaqiyat: `ECO-142` → 200, the task used for the checklist bilan; tahlil qilingan model javobga mos keladi.

## 2. Mobil/Web integratsiya testi

- [ ] Natijani yuboring: bu ekran ham, tafsilot ekrani ham yopiladi, vazifa «tekshiruvda» ko‘rinadi va xodim ro‘yxati yangilanadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Uch bandli ro‘yxat haqiqiy ma’lumotni aks ettiradi (kvotaga erishildi, xarajatlar kiritildi, rasmlar biriktirildi) va rasm qo‘shilganda yangilanadi; rasm xatosi faqat birinchi yuborishdan keyin ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Ro‘yxat ma’lumot uchun: kvotasi bajarilmagan vazifani ham yuborish mumkin (qarorni boss qabul qiladi).
- [ ] Yuborilgan vazifani qaytarilmaguncha qayta yuborib bo‘lmaydi.
