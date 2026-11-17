# Bugungi vazifalar (admin) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getDashboard` — GET `dashboard` (`dueToday` maydoni)

- [ ] Muvaffaqiyat: 200 → ro‘yxat aynan `dueToday` vazifalarini ko‘rsatadi; avval kesh xulosasi ko‘rinadi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → sessiya tozalanadi va router kirish ekraniga qaytaradi.

## 2. Mobil/Web integratsiya testi

- [ ] Dashboarddagi «Hammasi» havolasidan oching; chiplar mahalliy filtrlaydi (Hammasi, Jarayonda, Yangi, Kechikkan) va jonli sonlarni ko‘rsatadi; qatorni bosish vazifani ochadi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Har bir qatorda vaqt (kechikkan bo‘lsa «—»), holat nuqtasi, nomi, ijrochilar (+ kechikish izohi) va holat chipi bor; sana qatorida hafta kuni va «N / M bajarildi» ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Kechikkan vazifalar «Kechikkan» chipida va «Hammasi»da hisoblanadi; bajarilgan vazifalar «bajarildi» raqamida hisoblanadi.
