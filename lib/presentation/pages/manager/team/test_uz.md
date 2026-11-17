# Jamoa: xodimlar, mijozlar, reyting (menejer) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.getUsers` — GET `users?role=staff|client`

- [ ] Muvaffaqiyat: both directories → 200, paged `AppUser` rows with `activeCount` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: menejer xodimlar ro‘yxatida faqat jamoasi bor; mijozlar hamma uchun bir xil; `activeCount` ochiq vazifalar (xodimlar) yoki ochiq so‘rovlar (mijozlar) soniga teng.
- [ ] Parametr xatosi: `q` filters by name, phone and team; an unmatched `q` returns an empty page → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Sahifalash: ro‘yxatni ochish aynan BITTA so‘rov (1-sahifa, `pageSize` = repository doimiysi) yuboradi; keyingi sahifa faqat oxiriga yaqinlashganda so‘raladi; pull-to-refresh 1-sahifani qayta yuklaydi va ro‘yxatni tiklaydi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Xodimlar (dashboard kartasidan): qidiruv, rol oynasi (Hammasi / Rahbar / Menejer / Oddiy ishchi), Hammasi / Vazifali / Vazifasiz almashtirgichi, «+» taklif formasini ochadi, qatorni bosish profilni ochadi. Mijozlar: qidiruv, Hammasi / Faol so‘rov / So‘rovsiz almashtirgichi, «+» mijoz formasini ochadi. Reyting: davr almashtirgichi, qatorni bosish profilni ochadi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Xodim qatorlarida avatar, ism, rol (menejerlar binafsha) va «N vazifa» / «Bo‘sh»; mijoz qatorlarida manzil va «N so‘rov» / «So‘rov yo‘q» ko‘rinadi; rol tanlanganda filtr tugmasi yashil bo‘ladi.
- [ ] 1.21–1.21f va 1.24–1.24e taxtalar: jamoa ro‘yxatida qidiruv maydoni va ikkita tab (Hammasi / Xodimlar) bor; har bir qator avatar, ism, telefon va ostida “vazifa” yozuvi bilan vazifalar sonini ko‘rsatadi; mijozlar ro‘yxatida Hammasi / Jismoniy shaxs / Tashkilot tablari va telefon hamda “N so‘rov” (yoki “So‘rov yo‘q”) li qatorlar bor; har bir tabning o‘z bo‘sh holati (plitka, sarlavha, izoh) bor.

## 4. Mantiqiy/biznes test

- [ ] Rol va almashtirgich filtrlari yuklangan sahifaga mahalliy qo‘llanadi; qidiruv serverga ketadi (kechiktirilgan); hisob ochilgandan keyin qaytganda ro‘yxat yangilanadi.
