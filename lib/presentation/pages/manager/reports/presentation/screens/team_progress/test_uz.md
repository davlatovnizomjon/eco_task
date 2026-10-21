# Jamoa natijasi (menejer) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=week|month`

- [ ] Muvaffaqiyat: the manager session → 200, `people` stats of the team's workers bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: `done <= total`, `onTime <= done` va `lateDays > 0` faqat kechikkan ochiq vazifasi bor xodimlar uchun.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

## 2. Mobil/Web integratsiya testi

- [ ] Menejer dashboardidagi hisobot havolasidan oching; hafta/oyni almashtiring.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Har bir xodimga bitta karta: avatar, ism, «o‘z vaqtida x / y» yoki sariq kechikish qatori va bajarilgan/jami hisoblagich; faqat jamoa ogohlantirishi ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Faqat menejerning o‘z jamoa a’zolari ro‘yxatda.
