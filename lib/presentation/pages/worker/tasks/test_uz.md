# Vazifalar (boss vazifalar ro‘yxati) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks`

- [ ] Muvaffaqiyat: `page=1&pageSize=20&sort=due` → 200, a paged list `{items, page, lastPage, total}` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: an unknown `status` value is ignored by the backend, never crashes the app → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: har bir filtr natijani haqiqatan o‘zgartiradi: `status=prog` → faqat `prog`; `late=1` → faqat kechikkanlar; `who=boris` → faqat Boris ishtirok etgan; `due=today` → faqat bugungi; `q=ECO-142` → shu vazifa; mumkin bo‘lmagan filtr bo‘sh sahifa qaytaradi.
- [ ] Qiymatlar: `sort=due` muddat bo‘yicha o‘sish tartibida, `sort=priority` yuqori → past, `sort=created` yangi id birinchi.
- [ ] Qiymatlar: menejer ro‘yxatida faqat jamoa vazifalari bor; admin ro‘yxatida hammasi.
- [ ] Sahifalash: ro‘yxatni ochish aynan BITTA so‘rov (1-sahifa, `pageSize` = repository doimiysi) yuboradi; keyingi sahifa faqat oxiriga yaqinlashganda so‘raladi; pull-to-refresh 1-sahifani qayta yuklaydi va ro‘yxatni tiklaydi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Qidiruv (debounce), tezkor chiplar, filtr varag‘i (holat, muddat, kechikkan, ijrochi, saralash), tozalash va qo‘llash; har biri ro‘yxatni BITTA yangi so‘rov orqali o‘zgartiradi.
- [ ] Qidiruv maydoniga tez yozganda faqat oxirgi so‘rov natijasi ko‘rinadi (eskirgan javoblar tashlanadi).
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Yuklanish shimmer kartalarini ko‘rsatadi (spinner yo‘q); bo‘sh natija bo‘sh ko‘rinishni ko‘rsatadi; birinchi yuklash xatosi qayta urinish ko‘rinishini ko‘rsatadi va tugma qayta yuklaydi.
- [ ] Pull-to-refresh to‘la ro‘yxatda, qisqa ro‘yxatda va bo‘sh/xato ko‘rinishda ishlaydi (doim scroll qilinadi); indikator keshli emit’da emas, tarmoq chaqiruvi tugaganda yakunlanadi.
- [ ] Oxirgi qator tizim imo-ishora panelidan tepada qoladi (pastki inset scroll padding’ga kiradi).
- [ ] Filtr nishoni faol filtrlar sonini ko‘rsatadi; chiplar mos so‘rovni ajratadi; kartani bosish vazifa tafsilotini ochadi.

## 4. Mantiqiy/biznes test

- [ ] Vazifani yaratish yoki tahrirlash qaytganda ro‘yxatda ko‘rinadi (kesh bekor qilingan).
- [ ] Muddati o‘tgan va hali ochiq vazifa ro‘yxatda, chiplar qatorida va filtr natijasida izchil kechikkan deb ko‘rsatiladi.
