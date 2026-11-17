# Vazifa formasi (menejer) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.getUsers` — GET `users?role=staff`

- [ ] Muvaffaqiyat: the staff directory → 200, assignable people bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: ijrochi tanlovi barcha faol xodimlarni (ishchilar va menejerlar) hamda kompaniya mijozlarini taklif qiladi.

### `TasksRepository.createTask` / `editTask` — POST `tasks` / PUT `tasks/{id}`

- [ ] Muvaffaqiyat: a valid draft (title, due, assignees with optional quotas, priority, reward) → 200, the created/updated task and a new inbox entry for every assignee except the creator bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: an empty title or no assignees is rejected locally before any request → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: tahrirlash har bir ijrochining bildirilgan `done` progressini saqlaydi; mukofot ajratgichsiz butun son sifatida yuboriladi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Vazifani boshidan oxirigacha yarating: nom, ijrochilar oyna orqali (belgilash qatorlari), har bir ijrochi ulushi, muddat sanasi va vaqti oyna orqali, ikonkali muhimlik almashtirgichi, mukofot, tavsif, kutilgan natija; mavjud vazifani tafsilotdan tahrirlang.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Sana va vaqt maydonlari yonma-yon turadi va ikkalasi ham bir xil sana-vaqt oynasini ochadi; oynada tezkor kun chiplari, oy to‘ri (o‘tgan kunlar o‘chirilgan), vaqt chiplari va tanlangan lahzali tasdiqlash tugmasi bor.
- [ ] Ijrochi oynasida avval «O‘zimga», keyin faol vazifa sonlari bilan xodimlar chiqadi; tanlangan qatorlarda yashil belgi ko‘rinadi; tugma tanlanganlar sonini ko‘rsatadi.
- [ ] Yaratish rejimi besh qadamli wizard (2.3–2.3d taxtalar): 1 mijoz turi (+ tashkilot yoki shaxs nomi), 2 vazifa haqida (nom, tavsif, so‘m / $ bilan narx), 3 muddat va manzil, 4 ijrochilar, 5 tekshirish; besh bo‘lakli progress chizig‘i, qadam sarlavhasi va “Keyingi →” / “Yaratish va yuborish”; orqaga (panel yoki tizim) bir qadam orqaga qaytaradi, so‘ng chiqadi.
- [ ] Qadam bo‘yicha tekshiruv: nomsiz tashkilot (1), bo‘sh vazifa nomi (2) va ijrochisiz (4) “Keyingi” ni umumiy xato dialogi va qizil maydon bilan to‘sadi; birinchi urinishgacha hech narsa qizil emas. Muvaffaqiyatda “Vazifa yaratildi” dialogi chiqadi va ekranni yopadi.
- [ ] Qurilmagan: 3-qadamdagi rasm yuklash (fayl xizmati hali yo‘q); tahrirlash rejimi bir sahifali formani saqlaydi.
- [ ] Tahrirlash rejimi (2.6 tahrirlash, 2.6 ijrochilar taxtalari): bitta sahifada mijoz turi va nomi, vazifa nomi, tavsif, so‘m / $ bilan narx, muddat va manzil (wizard maydonlari), so‘ng ijrochilar qatori (qatorlashgan avatarlar + “N ta ijrochi”) rol belgili tanlagich sheet’ini va “Tanlash” tugmasini ochadi; “Saqlash” saqlaydi. Ijrochilar chegarasi faqat muvaffaqiyatsiz saqlashdan keyin qizil bo‘ladi.
- [ ] Mavjud vazifani ochganda mijoz, manzil va valyuta undan to‘ldiriladi; saqlashda ular qaytarib yuboriladi.

## 4. Mantiqiy/biznes test

- [ ] Bo‘sh nom yoki ijrochisizlik saqlashni to‘xtatadi, birinchi xato dialogda ko‘rsatiladi.
- [ ] Saqlangandan keyin ro‘yxat va tafsilot qaytganda o‘zgarishni aks ettiradi.
