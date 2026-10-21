# Vazifa shakli (yaratish/tahrirlash) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.getUsers` — GET `users?role=staff`

- [ ] Muvaffaqiyat: the staff directory → 200, assignable people bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: menejer faqat o‘z jamoasini oladi; admin barcha xodimlarni oladi.

### `TasksRepository.createTask` / `editTask` — POST `tasks` / PUT `tasks/{id}`

- [ ] Muvaffaqiyat: a valid draft (title, due, assignees with optional quotas, priority, reward) → 200, the created/updated task and a new inbox entry for every assignee except the creator bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: an empty title or no assignees is rejected locally before any request → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: tahrirlash har bir ijrochining bildirilgan `done` progressini saqlaydi; mukofot ajratgichsiz butun son sifatida yuboriladi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Bir va bir nechta ijrochi uchun (kishi kvotalari bilan va kvotasiz) vazifa yarating, so‘ng tafsilot ekranidan tahrirlang; ro‘yxat va tafsilot o‘zgarishni ko‘rsatadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Birinchi Saqlashgacha hech narsa qizil emas; bo‘sh shaklda Saqlash dialogda nom xabarini ko‘rsatadi va nom hamda ijrochilarni qizil qiladi; maydonni tuzatish xatoni tozalaydi.
- [ ] Ijrochi varag‘i qidiriladi va bossni «o‘zimga» sifatida ko‘rsatadi; muddat varag‘ida tezkor kunlar, oylik taqvim va soat chiplari bor va bitta lahzani qaytaradi; mukofot maydoni yozayotganda mingliklarni guruhlaydi va `($)` birligini ko‘rsatadi.

## 4. Mantiqiy/biznes test

- [ ] O‘tmishdagi muddatni saqlash mumkin, lekin vazifa darhol kechikkan ko‘rinadi; 0 yoki bo‘sh kvota progress chizig‘isiz ha/yo‘q vazifani bildiradi.
- [ ] Shakldan tizim orqaga tugmasi bilan chiqish qoralamani saqlamasdan bekor qiladi.
