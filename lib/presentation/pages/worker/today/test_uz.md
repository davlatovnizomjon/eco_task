# Bugun (xodim bosh sahifasi) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks?group=active`

- [ ] Muvaffaqiyat: the worker's session → 200, only tasks that involve the worker and are open or in review bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: bosh karta kvotali eng yaqin vazifa, aks holda eng yaqin ochiq vazifa; «bugun» bugun yoki undan oldin muddatli ochiq vazifalarni, «ertaga» ertangi muddatlilarni o‘z ichiga oladi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Tabni oching, bosh kartadan progressni yangilang, kartani oching, yangilang.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Yuklanish shimmer kartalarini ko‘rsatadi (spinner yo‘q); bo‘sh natija bo‘sh ko‘rinishni ko‘rsatadi; birinchi yuklash xatosi qayta urinish ko‘rinishini ko‘rsatadi va tugma qayta yuklaydi.
- [ ] Pull-to-refresh to‘la ro‘yxatda, qisqa ro‘yxatda va bo‘sh/xato ko‘rinishda ishlaydi (doim scroll qilinadi); indikator keshli emit’da emas, tarmoq chaqiruvi tugaganda yakunlanadi.
- [ ] Oxirgi qator tizim imo-ishora panelidan tepada qoladi (pastki inset scroll padding’ga kiradi).

## 4. Mantiqiy/biznes test

- [ ] Hech narsasi ochiq bo‘lmagan xodim bo‘sh ekran emas, do‘stona bo‘sh ko‘rinishni ko‘radi.
