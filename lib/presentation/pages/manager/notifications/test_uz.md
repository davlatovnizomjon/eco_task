# Bildirishnomalar (menejer) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `NotificationsRepository.getInbox` — GET `notifications?group=…`

- [ ] Muvaffaqiyat: `all`, `unread`, `review`, `deadlines`, `expenses` → 200, a paged list with `unread` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: `unread` `isRead = false` yozuvlar soniga teng; har bir tur o‘z ikonkasi, rangi va lokalizatsiyalangan sarlavha/matn bilan ko‘rinadi.
- [ ] Sahifalash: ro‘yxatni ochish aynan BITTA so‘rov (1-sahifa, `pageSize` = repository doimiysi) yuboradi; keyingi sahifa faqat oxiriga yaqinlashganda so‘raladi; pull-to-refresh 1-sahifani qayta yuklaydi va ro‘yxatni tiklaydi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

### `NotificationsRepository.markRead` — POST `notifications/read`

- [ ] Muvaffaqiyat: one id and no id (all) → 200, the entries become read and the badge decreases bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.

## 2. Mobil/Web integratsiya testi

- [ ] Dashboard qo‘ng‘iroqchasidan oching; chiplarni almashtiring (Hammasi, O‘qilmagan N, Tekshiruv, Muddatlar, Xarajatlar), «O‘qildi» ni bosing (hammasini o‘qilgan qilish), qatorni bosing (o‘qilgan qiladi va tekshiruv → vazifalar tabi, xarajat → xarajatlar, so‘rov → mijozlar ni ochadi).
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] 1.14–1.20 taxtalar: ikkita tab (Hammasi / O‘qilmagan); har bir yozuv uchun chegarali karta: qalin sarlavha, o‘qilmaganda yashil vaqt va nuqta hamda ikki qatorli xabar; kartani bosish uni o‘qilgan qiladi va to‘liq xabarli oynani ochadi (yozuv ekranga ishora qilsa “Ochish” bilan); hech narsa o‘qilmagan bo‘lmasa panel’dagi belgilar amali xiralashadi; bo‘sh (hammasi / o‘qilmagan) va xato holatlari mos plitka va qayta urinish bilan.

## 4. Mantiqiy/biznes test

- [ ] Qo‘ng‘iroqcha nishoni va o‘qilmagan tab o‘qilgandan keyin sinxron qoladi; “hammasini o‘qilgan qilish” o‘qilmagan tabni darhol bo‘shatadi.
