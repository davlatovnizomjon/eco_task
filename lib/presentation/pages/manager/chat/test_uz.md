# Chat (menejer ro‘yxati) — Test rejasi

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

- [ ] Tabni oching, yangilash uchun torting, «yangi guruh» va «yangi suhbat» amallarini bosing, Hammasi / Guruhlar / Xodimlar / Mijozlar ni almashtiring, suhbatni oching va qayting (ro‘yxat yangilanadi).
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Guruhlar va vazifa suhbatlari «Guruhlar» ostida, shaxsiy suhbatlar «Shaxsiy» ostida chiqadi; mijoz bilan suhbatda «Mijoz» chipi bor; o‘qilmagan suhbatlarda qalin nom, yashil vaqt va yashil hisoblagich; o‘z oxirgi xabarida belgi ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Xodimlar / Mijozlar almashtirgichi shaxsiy suhbatlarni ikkinchi a’zo roli bo‘yicha filtrlaydi; tab paneli bo‘yicha o‘qilmaganlar jami hisoblagichlar yig‘indisiga teng.
