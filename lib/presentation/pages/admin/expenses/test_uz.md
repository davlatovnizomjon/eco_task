# Xarajatlar va to‘lovlar (boss) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ExpensesRepository.getExpenses` — GET `expenses?filter=…`

- [ ] Muvaffaqiyat: each tab `pending`, `approved`, `rejected`, `paid` → 200, a paged list bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: qator aynan bitta tabda chiqadi: `approved` to‘langanlarni chiqarmaydi, `paid` faqat `isPaid` ni o‘z ichiga oladi.
- [ ] Sahifalash: ro‘yxatni ochish aynan BITTA so‘rov (1-sahifa, `pageSize` = repository doimiysi) yuboradi; keyingi sahifa faqat oxiriga yaqinlashganda so‘raladi; pull-to-refresh 1-sahifani qayta yuklaydi va ro‘yxatni tiklaydi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

### `ExpensesRepository.getTotals` — GET `expenses/summary`

- [ ] Muvaffaqiyat: the boss session → 200, `entered`, `approved`, `rejected`, `paidOut`, `counts` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Qiymatlar: `approved` tasdiqlangan summalar yig‘indisiga teng; har bir tab hisoblagichi shu tabning to‘liq ro‘yxati uzunligiga teng.

### Payouts — POST `tasks/{id}/expenses/{eid}/pay`, POST `tasks/{id}/pay`

- [ ] Muvaffaqiyat: paying an approved expense and a completed task reward → 200, `isPaid = true`; totals `paidOut` increases by the paid amount bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.

## 2. Mobil/Web integratsiya testi

- [ ] To‘rt tabni aylanib chiqing, kutilayotgan qatorni oching (tekshiruv), tasdiqlangan qatorni to‘lang (tasdiq dialogi), mukofotni to‘lang; jami va hisoblagichlar qayta yuklanadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Yuklanish shimmer kartalarini ko‘rsatadi (spinner yo‘q); bo‘sh natija bo‘sh ko‘rinishni ko‘rsatadi; birinchi yuklash xatosi qayta urinish ko‘rinishini ko‘rsatadi va tugma qayta yuklaydi.
- [ ] Pull-to-refresh to‘la ro‘yxatda, qisqa ro‘yxatda va bo‘sh/xato ko‘rinishda ishlaydi (doim scroll qilinadi); indikator keshli emit’da emas, tarmoq chaqiruvi tugaganda yakunlanadi.
- [ ] Oxirgi qator tizim imo-ishora panelidan tepada qoladi (pastki inset scroll padding’ga kiradi).
- [ ] Jami kartasi, hisoblagichli filtr pillalari, xarajat qatorlari (summa, chek belgisi) va mukofot to‘lovlari bo‘limi ko‘rinadi; ikkala to‘lov amali ham tasdiq so‘raydi.

## 4. Mantiqiy/biznes test

- [ ] Ikki marta to‘lash mumkin emas: to‘langan qator `approved` tabidan chiqadi va uning mukofot qatori bosish amalini yo‘qotadi.
