# Dashboard (menejer bosh sahifasi)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getDashboard` — GET `dashboard`

- [ ] Muvaffaqiyat: menejer sifatidagi so‘rov → 200, hisoblagichlar, `dueToday` va `team` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Qiymatlar: `pendingNew` + `pendingClient` hali boshlanmagan vazifalar soniga teng va ularni mijoz yaratgan-yaratmaganiga qarab ajratadi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: `dueToday` muddat bo‘yicha saralangan va faqat bugun yoki undan oldin muddati tugaydigan ochiq vazifalarni o‘z ichiga oladi.
- [ ] Shu yuklanishning qo‘shimcha chaqiruvlari: `GET reports?period=week` (haftalik karta), `GET tasks?who=<me>&status=new,prog` (mening vazifalarim to‘plami), xodimlar va mijozlar uchun `GET users` (sonlar, `total`); bitta chaqiruv muvaffaqiyatsiz bo‘lsa kesh saqlanadi va xato dialogi ko‘rsatiladi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh xulosasi darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Dashboardni oching, yangilash uchun torting, avatar (profil tabini ochadi), qo‘ng‘iroqcha (bildirishnomalar), xodimlar va mijozlar kartalari, haftalik karta (hisobot tabini ochadi), «Reyting» havolasi, «Hammasi» havolasi, ikkala «Tasdiq kutmoqda» qatori (vazifalar tabini ochadi) va bo‘sh blokdagi har bir «+» (yangi vazifa formasini ochadi)ni bosing; har biri to‘g‘ri ekranga olib boradi.
- [ ] Yangi kompaniyada uchta birinchi qadam qatori xodim formasini, mijoz formasini va yangi vazifa formasini ochadi.
- [ ] «Mening vazifalarim» to‘plamini vertikal suring: old karta almashadi va o‘ngdagi nuqtalar unga ergashadi; kartani bosish tafsilotni ochadi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Birinchi yuklanish davomida skelet shimmer.
- [ ] Bo‘sh bloklar (1.5 taxta): shaxsiy vazifa yo‘q → «+» li “Sizda vazifa yo‘q” kartasi; vazifasiz hafta → kulrang halqa, `0` va izoh, chevron yo‘q; hech kim vazifa bajarmagan → “Hali reyting yo‘q” kartasi va «Reyting» havolasi yo‘q; bugunga hech narsa yo‘q → «+» li “Bugunga vazifa yo‘q” kartasi va «Hammasi» havolasi yo‘q.
- [ ] Yangi kompaniya (1.4 taxta): menejerdan boshqa xodim yo‘q, mijoz yo‘q, vazifa yo‘q → “Xush kelibsiz,” salomi, markazdagi “Hali hech narsa yo‘q” bloki va uchta “Ishni boshlang” qatori.
- [ ] Haftalik karta: donut yoylari bajarildi / jarayonda / kechikkan / bajarilmadi tartibida va legenda sonlari ularga mos.
- [ ] “Tasdiq kutmoqda” faqat ikki hisoblagichidan kamida bittasi noldan katta bo‘lsa chiziladi; nol hisoblagich qizil nishonini yashiradi.
- [ ] Qo‘ng‘iroqcha nishoni o‘qilmagan hisoblagichga ergashadi; pastki tab paneli oxirgi qatorni yopmaydi (pastki inset aylantirish chekinishining bir qismi).

## 4. Mantiqiy/biznes test

- [ ] Boshqa joyda vazifa yaratilgandan yoki yopilgandan keyin dashboardga qaytganda yangi sonlar ko‘rinadi (kesh bekor qilingan).
- [ ] Eng faol xodim — shu hafta eng ko‘p vazifa bajargan va kamida bitta bajargan xodim; halqa bajarilgan / jami nisbatini foizda ko‘rsatadi; kechikkan vazifalarda amber budilnik belgisi va “N kun kech”, qolganlarida vaqti ko‘rinadi.
