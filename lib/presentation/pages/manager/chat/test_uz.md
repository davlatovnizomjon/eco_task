# Chat (suhbatlar ro‘yxati) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ChatRepository.getConversations` — GET `conversations/`

- [ ] Muvaffaqiyat: kirgan sessiya → 200 va JSON massiv; har bir qatorda `id`, `kind` (`DIRECT|GROUP|TASK`), `title`, `task`, `unread_count`, `last_message` (null bo‘lishi mumkin) va `members` bor; tahlil qilingan `ConversationModel` javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: faqat foydalanuvchi a’zo bo‘lgan (direct/group) yoki vazifasini ko‘ra oladigan suhbatlar; oxirgi xabar bo‘yicha saralangan; `unread_count` faqat boshqalarning o‘qish belgisidan yangi xabarlarini sanaydi; yig‘indisi tab belgisiga teng.
- [ ] Foydalanuvchi huquqini yo‘qotgan vazifa suhbatlari (ijrochilikdan olingan xodim) ro‘yxatdan yo‘qoladi.
- [ ] Keshdan oldin: tabni qayta ochganda kesh darhol ko‘rinadi, keyin yangi ro‘yxat almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` (`MockChat`) va jonli API (`AppConfig.useMockData`) bilan o‘tadi; ikkalasida ham JSON shakli backendniki.

## 2. Mobil/Web integratsiya testi

- [ ] Har bir rol bilan Suhbat tabini oching, suhbatni oching, xabar yuboring, orqaga qayting: qatorda «Siz: …» bilan yangi oxirgi xabar ko‘rinadi va o‘qilmagan belgisi o‘chadi.
- [ ] Ikki qurilma/akkaunt: biridan yuborilgan xabar ikkinchisining ochiq suhbatida bir soniya ichida ko‘rinadi va yangilashdan so‘ng ro‘yxat belgisini oshiradi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli backend bilan (`--dart-define=API_HOST=...`) ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Qatorlar: avatar (shaxs) yoki dumaloq belgi (guruh/vazifa), nom, oxirgi xabar ko‘rinishi (o‘qilmaganda qalin), nisbiy vaqt, o‘qilmagan belgisi; sarlavhadagi «+» yangi suhbat ekranini ochadi.
- [ ] Birinchi yuklashda shimmer; bo‘sh ro‘yxat bo‘sh ko‘rinishni ko‘rsatadi; birinchi yuklash xatosi qayta urinish ko‘rinishini ko‘rsatadi; pull-to-refresh to‘la, qisqa va bo‘sh ro‘yxatda ishlaydi.

## 4. Mantiq/biznes testi

- [ ] Mijoz faqat xodimlar bilan suhbatlarni va o‘z vazifalarining suhbatlarini ko‘radi, boshqa mijozniki hech qachon.
- [ ] Tab belgisi `unread_count` yig‘indisiga teng va o‘qilgan deb belgilashdan keyin manfiy bo‘lmaydi.
