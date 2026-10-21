# Xarajat shakli (xodim) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.addExpense` — POST `tasks/{id}/expenses`

- [ ] Muvaffaqiyat: `{amount, kind, note, hasReceipt}` → 200, the task with a new `pending` expense bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: amount 0 or empty is rejected locally → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: xarajat boss tekshiruv navbatida paydo bo‘ladi va boss formatlangan summa bilan `expense` inbox yozuvini oladi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Chek bilan va cheksiz xarajat qo‘shing; u xodimning vazifa tafsilotida kutilmoqda sifatida va boss tekshiruv navbatida ko‘rinadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Summa maydoni mingliklarni guruhlaydi va `($)` ni ko‘rsatadi; tur chiplari (transport, material, boshqa) bittasini tanlaydi; chek plitkasi namunaviy rasmni qo‘shadi/olib tashlaydi; bo‘sh summa xatosi faqat birinchi yuborishdan keyin qizil.

## 4. Mantiqiy/biznes test

- [ ] Cheksiz xarajatni yuborish mumkin, lekin boss uchun «chek yo‘q» deb belgilanadi.
- [ ] Bu shaklga faqat vazifaga biriktirilgan xodimlar kira oladi.
