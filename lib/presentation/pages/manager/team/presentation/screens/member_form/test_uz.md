# Hisob ochish: xodim yoki mijoz (menejer) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.addUser` — POST `users`

- [ ] Muvaffaqiyat: a staff and a client payload with a generated temporary password → 200, the created `AppUser` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Band login → 409 `detail` «login band» dialogda ko‘rsatiladi.
- [ ] Parametr xatosi: empty name or login, or a phone that is not `+998` with 9 digits, is rejected locally → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: yangi hisob `login` va ko‘rsatilgan vaqtinchalik parol bilan kira oladi va mos bosh sahifaga tushadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Xodim formasini (ism, telefon, login, yangilash tugmali vaqtinchalik parol, yagona “Xodim” rol radiosi — menejer menejer yarata olmaydi) va mijoz formasini (ism, telefon, login, parol, manzil) oching; yuboring va login hamda parol bilan topshirish dialogini o‘qing.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Mahkamlangan pastki panel asosiy tugma ustida «Hisob ochilgach, login va parolni ulashasiz» maslahatini ko‘rsatadi; rol qatorlarida radio belgisi bor.
- [ ] 1.23 / 1.25 taxtalar: xodim formasi “Xodim qo‘shish” — ism, telefon, login, parol va bir qatorli rol ro‘yxati (“Xodim”), “Saqlash” bilan saqlanadi; mijoz formasida “Jismoniy shaxs / Tashkilot” tablari bor (birinchi maydon “Tashkilot nomi” bo‘ladi), manzil va “Mijoz hisobini ochish” bilan tugaydi; tashkilot belgisi `isOrg` sifatida yuboriladi.

## 4. Mantiqiy/biznes test

- [ ] Bo‘sh ism yoki login va noto‘g‘ri telefon yuborishni to‘xtatadi, birinchi xato dialogda; band loginni API xabar qiladi.
- [ ] Tashkilot tabida “Mas‘ul shaxs” (`contactPerson`), har bir mijozda “Izoh” (`note`) ham bor; ikkalasi `POST users` va `PATCH users/{id}` ga yuboriladi.
- [ ] Tahrirlash rejimi (`/team/new?edit=<id>`): hisobni yuklaydi, ism, telefon, manzil, tashkilot belgisi, mas‘ul shaxs va izohni to‘ldiradi; login, parol va rol qatorlari yashirin; saqlaganda `true` bilan yopiladi.
