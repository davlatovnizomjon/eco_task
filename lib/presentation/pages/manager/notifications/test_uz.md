# Bildirishnomalar inboxi — Test rejasi

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

- [ ] Boshqa rol sifatida voqealar yarating (natija yuboring, izoh qoldiring, so‘rovni rejalashtiring) va mos inbox yozuvlarini ko‘ring; birini ochish uni o‘qilgan qiladi va boss review/expense yozuvlari uchun navbatga o‘tkazadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Yuklanish shimmer kartalarini ko‘rsatadi (spinner yo‘q); bo‘sh natija bo‘sh ko‘rinishni ko‘rsatadi; birinchi yuklash xatosi qayta urinish ko‘rinishini ko‘rsatadi va tugma qayta yuklaydi.
- [ ] Pull-to-refresh to‘la ro‘yxatda, qisqa ro‘yxatda va bo‘sh/xato ko‘rinishda ishlaydi (doim scroll qilinadi); indikator keshli emit’da emas, tarmoq chaqiruvi tugaganda yakunlanadi.
- [ ] Oxirgi qator tizim imo-ishora panelidan tepada qoladi (pastki inset scroll padding’ga kiradi).
- [ ] Filtr pillalari rolga qarab farqlanadi (boss: beshta, boshqalar: hammasi/o‘qilmagan); yozuvlar Bugun / Kecha / sana bo‘yicha guruhlanadi; o‘qilmaganlar qalin va nuqtali; ruxsat o‘chiq banneri Sozlamalarga olib boradi.

## 4. Mantiqiy/biznes test

- [ ] «Hammasini o‘qilgan qilish» tab nishonini nolga tushiradi va o‘qilmaganlar filtri bo‘sh bo‘ladi.
