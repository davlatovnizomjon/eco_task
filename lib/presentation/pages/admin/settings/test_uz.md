# Sozlama oynalari: til va ko‘rinish (admin) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

- [ ] Tarmoq endpointlari yo‘q: bu funksiya faqat mahalliy holatni o‘qiydi/yozadi (2–4-bo‘limlarga qarang).

## 2. Mobil/Web integratsiya testi

- [ ] Tanlov `LocalStore` orqali saqlanadi va ilova qayta ochilganda tiklanadi: mavzu rejimi va bildirishnoma tugmasi; tilni `easy_localization` eslab qoladi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Ikkala oyna ham profil qatorlaridan tutqich, sarlavha va yopish amali bilan ochiladi; faol variant qalin va yashil belgi bilan.
- [ ] Qorong‘i mavzuni tanlash butun ilovani, jumladan oyna ostida ochiq ekranlarni ham darhol qayta chizadi.

## 4. Mantiqiy/biznes test

- [ ] Tilni almashtirish ilova bo‘ylab qayta ishga tushirishsiz qo‘llanadi; xuddi shu tanlov kirish ekranidan hisobga kirmasdan ham mavjud.
