# Yangi suhbat va yangi guruh (admin) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ChatRepository.getContacts` — GET `conversations/contacts/?q=`

- [ ] Muvaffaqiyat: 200 va qisqa foydalanuvchilar (`id`, `username`, `full_name`, `role`); `password`, `is_superuser` yoki token hech qachon yo‘q.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`.
- [ ] Qiymatlar: xodimlar (admin, menejer) o‘zidan boshqa hammani oladi; ishchi yoki mijoz faqat xodimlarni oladi; nofaol foydalanuvchilar yo‘q.
- [ ] Parametrlar natijani o‘zgartiradi: `q` login va to‘liq ism bo‘yicha filtrlaydi (katta-kichik harfga e’tiborsiz); hech kim mos kelmasa bo‘sh ro‘yxat.

### `ChatRepository.openDirect` — POST `conversations/` `{kind: DIRECT, user}` bilan

- [ ] Muvaffaqiyat: 201 va suhbat; uni yana (har ikki tomondan) ochish bir xil id qaytaradi.
- [ ] Qoidalar: ishchi ↔ ishchi, ishchi ↔ mijoz, mijoz ↔ mijoz va o‘ziga yozish → 403 `forbidden`; noma’lum foydalanuvchi → 404.

### `ChatRepository.createGroup` — POST `conversations/` `{kind: GROUP, title, member_ids}` bilan

- [ ] Muvaffaqiyat: boss → 201; yaratuvchi ro‘yxatda bo‘lmasa ham a’zo.
- [ ] Qoidalar: ishchi/mijoz → 403; nom yo‘q → maydon nomi bilan 400.

## 2. Mobil/Web integratsiya testi

- [ ] Yangi suhbat: qidiruv, «Yangi guruh» ni bosish (guruh ekranini ochadi), odamni bosish (shaxsiy suhbatni ochadi yoki qayta ishlatadi). Yangi guruh: nom kiriting, a’zolarni belgilang (tepada chiplar chiqadi, olib tashlash uchun chipni bosing), «Hammasini tanlash», yarating.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Kontaktlar «Xodimlar» va «Mijozlar» sarlavhalariga bo‘linadi, rol qo‘shimcha matn sifatida; guruh ekrani «Xodimlar · N ta tanlandi» hisoblagichi va yumaloq belgilarni ko‘rsatadi; nom va kamida bitta a’zo bo‘lmaguncha «Yaratish» amali kulrang.
- [ ] 3.2 / 3.3 taxtalar: yangi suhbat ro‘yxati odamlarni ism ostida rol belgisi bilan ko‘rsatadi (tepada “Yangi guruh” qatori); yangi guruh sahifasida kamera plitkasi va nom maydoni, «x» li tanlangan odamlar chiplari, dumaloq belgili qidiriladigan ro‘yxat va “Hammasini tanlash”, hamda pastga mahkamlangan “Guruh yaratish” tugmasi bor (nom va a’zo bo‘lgach faollashadi). Rasm yuklash qurilmagan.

## 4. Mantiqiy/biznes test

- [ ] Guruh yaratish formani o‘rniga uning suhbatini ochadi; shaxsiy suhbatni ikki marta ochish bir xil suhbatni qayta ishlatadi.
