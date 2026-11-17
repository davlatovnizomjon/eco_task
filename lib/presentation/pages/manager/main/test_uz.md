# Menejer UI (pastki tab paneli) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

- [ ] O‘z endpointlari yo‘q: bo‘limlar o‘z funksiyalarining repositorylaridan foydalanadi; ularning rejalariga qarang.
- [ ] Auth xatosi: istalgan bo‘limda muddati o‘tgan token → 401 → sessiya tozalanadi va router kirish ekraniga qaytaradi.

## 2. Mobil/Web integratsiya testi

- [ ] `jamshid` (menejer) sifatida kiring: suzuvchi pastki panelda Asosiy, Vazifa, Chat (yumaloq yashil katak), Hisobot va Profil ko‘rinadi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Panel yon tomonlardan 12 px masofada va tizim imo-ishora zonasi ustida suzadi; tanlangan tabda tuslangan kapsula (chat katagida kattaroq tuslangan aylana) bor.
- [ ] Chat katagi o‘qilmaganlar sonini qizil nishonda ko‘rsatadi; boshqa tablar o‘z yorlig‘ini ko‘rsatadi.
- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; beshta element teng kenglikda qoladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; o‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Tablar almashganda bo‘lim holati saqlanadi (`IndexedStack`); boshqa barcha ekranlar shell ustida Orqaga belgisi bilan ochiladi.
- [ ] Istalgan ekran `homeTab` orqali tanlangan tabni almashtira oladi (0 asosiy, 1 vazifa, 2 chat, 3 hisobot, 4 profil).
- [ ] Profildan chiqish tasdiq so‘raydi, sessiyani tozalaydi va tanlangan tabni asosiyga qaytaradi.
