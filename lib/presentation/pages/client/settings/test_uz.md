# Sozlamalar (til, ko‘rinish, bildirishnomalar, eslatmalar) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

- [ ] Tarmoq endpointlari yo‘q: bu feature faqat lokal holatni o‘qiydi/yozadi (2–4 bo‘limlarga qarang).

## 2. Mobil/Web integratsiya testi

- [ ] Har bir almashtirgich va tanlov `LocalStore` orqali saqlanadi va ilova qayta ishga tushgach tiklanadi: mavzu rejimi, kattaroq matn, bildirishnoma almashtirgichlari, eslatma vaqtlari, jim soatlar, kunlik xulosa, kunlik eslatma.
- [ ] Til o‘zgarishi butun ilovada darhol qo‘llanadi (qayta ishga tushirishsiz) va `easy_localization` tomonidan eslab qolinadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Ko‘rinish: tizim / yorug‘ / qorong‘i qatorlarida faol qatorda belgi bor; qorong‘ini tanlash butun ilovani, jumladan ostida ochiq ekranlarni ham darhol qayta chizadi.
- [ ] Bildirishnoma ekrani: almashtirgichlar ro‘yxati rolga qarab farqlanadi (boss: tekshiruv, xarajat, so‘rov; xodim: faqat qaror; mijoz: guruhlar yo‘q).
- [ ] Eslatma ekrani: vaqtlarni bir nechta tanlash mumkin; ertalabki xulosa vaqti qatori ma’lumot uchun.

## 4. Mantiqiy/biznes test

- [ ] Telefon ruxsati almashtirgichini o‘chirish bildirishnomalar ekranida va inboxda ogohlantirish bannerini ko‘rsatadi.
- [ ] Kirmasdan turib (kirish ekranidan) ochiladigan til ekrani ishlaydi va sessiya talab qilmaydi.
