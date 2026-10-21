# Taqvim — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getCalendar` — GET `tasks/calendar?month=YYYY-M`

- [ ] Muvaffaqiyat: the current and the next month → 200, every visible task whose deadline falls into the month bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: xodim faqat o‘z vazifalarini, menejer jamoasinikini, admin hammasini ko‘radi; muddatsiz oy bo‘sh ro‘yxat qaytaradi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Oylarni suring, kunlarni bosing, kun ro‘yxatidan vazifani oching; nuqtalar pastdagi ro‘yxatga mos.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Nuqtalar: yashil = muddat, sariq = muhim ochiq vazifa, qizil = kechikkan; hafta kuni va oy nomlari uchala tilda lokalizatsiyalangan; izoh va kun sarlavhasi (`hafta kuni, kun · N`) ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Oyni o‘zgartirish faqat shu oyni yuklaydi; endi ko‘rinmayotgan oy javobi tashlanadi.
