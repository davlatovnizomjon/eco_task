# Jamoa katalogi (boss) — Test rejasi

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

- [ ] Xodimlar/mijozlarni almashtiring, qidiring, xodimni oching, yuqoridagi tugmadan hisob shaklini oching.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Yuklanish shimmer kartalarini ko‘rsatadi (spinner yo‘q); bo‘sh natija bo‘sh ko‘rinishni ko‘rsatadi; birinchi yuklash xatosi qayta urinish ko‘rinishini ko‘rsatadi va tugma qayta yuklaydi.
- [ ] Pull-to-refresh to‘la ro‘yxatda, qisqa ro‘yxatda va bo‘sh/xato ko‘rinishda ishlaydi (doim scroll qilinadi); indikator keshli emit’da emas, tarmoq chaqiruvi tugaganda yakunlanadi.
- [ ] Oxirgi qator tizim imo-ishora panelidan tepada qoladi (pastki inset scroll padding’ga kiradi).
- [ ] Xodimlar jamoa bo‘yicha rahbar nomi bilan guruhlanadi; menejerlarda rol chipi bor; mijozlarda tuman va so‘rovlar soni ko‘rinadi; mijozlar yordam qatori ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Hisob yaratish uni qaytganda katalogda ko‘rsatadi (kesh bekor qilingan).
