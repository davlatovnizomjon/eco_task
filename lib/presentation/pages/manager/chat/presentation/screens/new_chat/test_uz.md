# Yangi suhbat — Test rejasi

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

- [ ] Boss sifatida: odamni qidiring, bosing, (qayta ishlatilgan) suhbatga tushing; guruh tabi: nom bering, odamlarni belgilang, yarating, unga tushing. Ishchi/mijoz sifatida: faqat shaxsiy tab bor va faqat xodimlar ko‘rinadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli backend bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Qidiruv kechikishsiz yoziladi, tartibsiz kelgan javoblar yangi so‘rov ro‘yxatini hech qachon bosib ketmaydi; belgilangan odamlarda to‘ldirilgan belgi; nom va kamida bitta odam tanlanmaguncha «Yaratish» o‘chiq.
- [ ] Natija bo‘sh bo‘lsa «hech kim topilmadi» ko‘rinishi; yuklash xatosida qayta urinish ko‘rinishi.

## 4. Mantiq/biznes testi

- [ ] Odamni ikki marta tez bosish bitta suhbat ochadi, ikkita emas; ekran o‘zini suhbat bilan almashtiradi, shuning uchun «Orqaga» ro‘yxatga qaytaradi.
