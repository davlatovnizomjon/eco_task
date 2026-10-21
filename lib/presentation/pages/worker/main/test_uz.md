# Xodim UI (chap menyu) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha hech narsa ishga tushirilmaydi.

## 1. API test

- [ ] O‘z endpointlari yo‘q: bo‘limlar o‘z funksiyalarining repozitoriylaridan foydalanadi (`pages/dashboard`, `pages/tasks`, `pages/chat`, `pages/calendar`, `pages/my_tasks`, `pages/today`, `pages/notifications`); ularning rejalariga qarang.
- [ ] Auth xatosi: istalgan bo‘limda muddati o‘tgan token → 401 → sessiya tozalanadi va router kirish ekraniga qaytadi.

## 2. Mobil/Web integratsiya testi

- [ ] `boris` (worker) bilan kiring: chap menyuda Bugun, Vazifalarim, Suhbat, Xabarlar, Taqvim, Tarix, Profil ko‘rinadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Har bir bo‘lim app barindagi menyu tugmasi chap drawerni ochadi; sarlavhada hisob avatari, ismi va roli ko‘rinadi; tanlangan bo‘lim ajratilgan.
- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri ko‘rinadi; o‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz ko‘rinadi.
- [ ] Menyu bandlaridagi o‘qilmagan nishonlar repozitoriylar hisoblagichiga mos keladi.

## 4. Mantiqiy/biznes test

- [ ] Bo‘limlarni almashtirganda holat saqlanadi (`IndexedStack`); yo‘nalishli bandlar (route bor) Orqaga tugmali ekran sifatida ochiladi.
- [ ] Profil bo‘limi hisob kartasi, sozlamalar va chiqishni ko‘rsatadi; chiqish tasdiq so‘raydi, sessiyani tozalaydi va tanlangan bo‘limni qaytaradi.
