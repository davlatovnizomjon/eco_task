# Vazifalar (mijoz ro‘yxati) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks`

- [ ] Muvaffaqiyat: `page=1&pageSize=20&sort=due` → 200, a paged list `{items, page, lastPage, total}` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: an unknown `status` value is ignored by the backend, never crashes the app → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: har bir filtr natijani haqiqatan o‘zgartiradi: `status=prog` → faqat `prog`; `late=1` → faqat kechikkanlar; `who=boris,malika` → ulardan biri ishtirok etgan; `due=today|week|month` → shu oyna; `due=range&from=…&to=…` → oraliq ichidagi muddatlar (chegaralar bilan); `q=ECO-142` → shu vazifa; mumkin bo‘lmagan filtr bo‘sh sahifa qaytaradi.
- [ ] Qiymatlar: `sort=due` muddat bo‘yicha o‘sish tartibida, `sort=priority` yuqori → past, `sort=created` yangi id birinchi.
- [ ] Qiymatlar: menejer ro‘yxatida faqat jamoa vazifalari bor; mijoz ro‘yxatida hammasi.
- [ ] Sahifalash: ro‘yxatni ochish aynan BITTA so‘rov (1-sahifa, `pageSize` = repository doimiysi) yuboradi; keyingi sahifa faqat oxiriga yaqinlashganda so‘raladi; pull-to-refresh 1-sahifani qayta yuklaydi va ro‘yxatni tiklaydi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Qidiruv (kechiktirilgan) va oltita holat tabi (Hammasi / Yangi / Jarayonda / Kechikkan / Bajarilgan / Bajarilmagan); har biri ro‘yxatni BITTA yangi so‘rov orqali o‘zgartiradi va tablar qatori yon tomonga aylanadi.
- [ ] Filtr oynasi: holat, muddat oynasi (Bugun / Shu hafta / Shu oy) yoki “Sanani tanlash” → oraliq oynasi → chip `20-okt — 26-okt` ni «x» bilan ko‘rsatadi; ijrochi qatorini oching → xodimlar bir marta yuklanadi, qidiruv ularni toraytiradi, belgilar almashadi, “Tanlash” “N ta” ni qaytaradi; “Tozalash” qoralamani tiklaydi; “Natijani ko‘rsatish” uni BITTA so‘rov bilan qo‘llaydi.
- [ ] Eski arxiv ekrani olib tashlandi (kalendar, xarajatlar va arxiv dizaynda yo‘q); yopilgan vazifalar ro‘yxat tablari orqali topiladi.
- [ ] Qidiruv maydonida tez yozish faqat oxirgi so‘rov natijasini ko‘rsatadi (eskirgan javoblar tashlanadi).
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Ro‘yxat tekis (2.1–2.1e taxtalar): har bir qator holat doirasi, nomi, tavsifning birinchi qatori, soat belgisi bilan `22-okt, 16:00` va rangli holat belgisi, o‘ngda ijrochilar avatarlari (uchta, keyin “+N”) va chevronni ko‘rsatadi; kechikkan ochiq vazifada amber budilnik doirasi va belgisiz “N kun kechikdi” chiqadi.
- [ ] Sarlavhada faqat «+» amali bor; muddat yoki ijrochi filtri faol bo‘lsa filtr tugmasi burchagida qizil nuqta chiqadi.
- [ ] Har bir tabning bo‘sh holati (2.1f–2.1k taxtalar): plitka ikonkasi va rangi, sarlavha va izoh tabga mos.
- [ ] Filtr oynalari (2.2–2.2e taxtalar): tanlangan chiplar yashil; pastdagi ikki tugma 52 px balandlikda, 1 : 1.6 nisbatda.
- [ ] Yuklanish shimmer o‘rinbosarlarini ko‘rsatadi; bo‘sh natija bo‘sh ko‘rinishni; muvaffaqiyatsiz birinchi yuklanish qayta urinish ko‘rinishini ko‘rsatadi; pull-to-refresh uchalasida ishlaydi; oxirgi qator suzuvchi tab panelini yopmaydi.

## 4. Mantiqiy/biznes test

- [ ] Vazifa yaratish yoki tahrirlash qaytganda ro‘yxatda aks etadi (kesh bekor qilingan).
- [ ] Muddati o‘tgan va hali ochiq vazifa ro‘yxatda, “Kechikkan” tabida va filtr natijasida bir xil kechikkan deb ko‘rsatiladi.
- [ ] Filtr oynasida tanlangan holat va tanlangan tab bir-biriga mos turadi (ikkalasi bitta so‘rovni tahrirlaydi).
- [ ] Oxiridan boshlab tanlangan oraliq boshidan saqlanadi; bitta bosilgan kun bir kunlik oraliq.
- [ ] Bajarilgan va bajarilmagan vazifalar o‘z tablarida va “Hammasi”da ko‘rinadi; yopilgan vazifalar tablar orqali ko‘rinishda qoladi.
