# Rollar va ruxsatlar (admin) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.getPermissions` / `savePermissions` — GET/PUT `users/{id}/permissions`

- [ ] Muvaffaqiyat: load, change role and switches, save → 200, the stored `{role, flags}` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: saqlangan o‘zgarish keyingi GET da qaytadi (mock omborda saqlangan).
- [ ] Parametr xatosi: an unknown `role` falls back to `worker` → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.

## 2. Mobil/Web integratsiya testi

- [ ] Admin sifatida xodim profilidan oching, rol va ikkita almashtirgichni o‘zgartiring, saqlang, qayta oching va bir xil qiymatlarni ko‘ring.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Rol segmentli boshqaruvi, ko‘rsatmali ikkita almashtirgich guruhi va doira ogohlantirishi ko‘rinadi; Saqlash yuklanish holatini ko‘rsatadi va muvaffaqiyatda yopiladi.

## 4. Mantiqiy/biznes test

- [ ] Bu ekranni faqat admin ocha oladi (kirish faqat adminning xodim profilida mavjud).
