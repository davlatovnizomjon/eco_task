# Login va parol (menejer) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `SessionRepository.changePassword` — POST `account/password` (jonli: `POST auth/password/`)

- [ ] Muvaffaqiyat: `{oldPassword, newPassword}` → 200, `{token}` bilan; yangi token saqlanganini almashtiradi va keyingi so‘rovlar undan foydalanadi.
- [ ] Parametr xatosi: noto‘g‘ri joriy parol → 400, backend `detail` umumiy dialogda ko‘rsatiladi; hech narsa o‘zgarmaydi.
- [ ] Auth xatosi: muddati o‘tgan token → 401 → sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Login o‘zgartirish: `PATCH account {login}` jonli APIda hisob loginini almashtiradi; mock aniq xabar bilan rad etadi.

## 2. Mobil/Web integratsiya testi

- [ ] Profilni tahrirlash ekranidan oching; faqat parolni, faqat loginni, ikkalasini yoki hech narsani o‘zgartiring (saqlash shunda shunchaki yopadi).
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Parol maydonlari yashirilgan; «Faqat lotin harflari, raqam va nuqta» va «Kamida 8 ta belgi» maslahatlari maydonlari ostida turadi.

## 4. Mantiqiy/biznes test

- [ ] Yangi parol joriy parolni, kamida 8 belgini va bir xil takrorni talab qiladi; birinchi buzilgan qoida dialogda ko‘rsatiladi va hech narsa yuborilmaydi.
