# Hisob shakli (xodim/mijoz) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.addUser` — POST `users`

- [ ] Muvaffaqiyat: a staff and a client payload with a generated temporary password → 200, the created `AppUser` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Band login → 409 `detail` «login band» dialogda ko‘rsatiladi.
- [ ] Parametr xatosi: empty name or login, or a phone that is not `+998` with 9 digits, is rejected locally → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: yangi hisob `login` va ko‘rsatilgan vaqtinchalik parol bilan kira oladi va mos bosh sahifaga tushadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Xodim hisobini (xodim va menejer rollari) va mijoz hisobini oching; har biri bilan kiring.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Birinchi yuborishgacha hech narsa qizil emas; muvaffaqiyatsiz yuborish birinchi xabarni dialogda ko‘rsatadi va barcha noto‘g‘ri maydonlarni belgilaydi; telefon maydoni `+998 90 123 45 67` niqoblanadi; yangilash yangi parol beradi; muvaffaqiyat dialogi login + parolni ko‘rsatadi va yopish katalogga qaytaradi.

## 4. Mantiqiy/biznes test

- [ ] Rol tanlovi faqat xodimlar uchun taklif etiladi; yangi xodim jamoasi yaratuvchining jamoasi.
