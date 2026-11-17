# Statistika (xodimning oltita statistika ekrani)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getStats` — GET `reports/stats?kind=&period=&offset=`

- [ ] Har bir `kind` (`finance`, `tasks`, `mine`, `clients`, `staff`, `managers`) va `period` (`week`, `month`, `year`) uchun muvaffaqiyat: 200, tur talab qilgan `total`, `delta`, `bars`, `facts`, `people` bilan; tahlil qilingan `StatsReport` mos keladi.
- [ ] Auth xatosi: 401 → `UnAuthorizedResponse`; sessiya tozalanadi.
- [ ] Qiymatlar: `split` yig‘indisi `total` ga teng (vazifalar); `delta` oldingi oynaga nisbatan foiz (xodimlar: soni); `bars` hafta / oy / yil uchun 7 / 4 / 12 ta; `plan` ≥ 0.
- [ ] Mock/jonli moslik: jonli backend’da bunday endpoint hali yo‘q — u paydo bo‘lguncha jonli ilova bu chaqiruvga mock do‘koni bilan javob beradi.

### `ReportsRepository.exportStats` — POST `reports/export`

- [ ] Muvaffaqiyat: 200; ekran “Hisobot yuklab olindi” dialogini ko‘rsatadi. Xato: umumiy xato dialogi.

## 2. Mobil/Web integratsiya testi

- [ ] Hisobot tabidan har bir turni oching; Hafta / Oy / Yil ni almashtiring (oyna joriyga qaytadi); o‘qlar bilan suring («keyingi» o‘q joriy oynada xiralashgan); tortib yangilang; xatodan keyin qayta urining.
- [ ] Yuklab olish: amal aylanuvchiga aylanadi, so‘ng muvaffaqiyat dialogi; yuklanayotganda yoki oyna bo‘sh bo‘lsa o‘chirilgan.
- [ ] Haqiqiy yoki emulyatsiya qilingan qurilmada `AppConfig.useMockData = true` bilan va jonli API bilan ishga tushiring.

## 3. UI test

- [ ] 4.2–4.7 taxtalar (barcha davrlar, yuklanish, yuklab olish, bo‘sh, xato variantlari) yorug‘ va qorong‘i mavzuda 1:1 mos: 30 px raqamli va yashil / qizil o‘zgarish chipli bosh karta, plitkalar, ustunli diagramma (eng balandi to‘liq rangda), reja kartasi, fakt qatorlari, odam qatorlari, mijozlar ekranidagi “Yangi / Hammasi” pill’lari.
- [ ] Moliya hech narsa kutilmayotganda “Kutilayotgan to‘lovlar” ni yashiradi; vazifalar va shaxsiy statistika kechikkan bo‘lmasa “Kechikkan vazifa yo‘q” ni ko‘rsatadi; mijozlar oynada hech kim qo‘shilmagan bo‘lsa “Yangi mijoz yo‘q” kartasini ko‘rsatadi.
- [ ] Bo‘sh oyna → turning plitkasi, sarlavhasi va izohi; muvaffaqiyatsiz birinchi yuklanish → “Qayta urinish” bilan “Ma’lumotni yuklab bo‘lmadi”.
- [ ] 320 px va 768 px da toshish yo‘q; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz.

## 4. Mantiqiy/biznes test

- [ ] Foydalanuvchi allaqachon tark etgan oynaning javobi tashlanadi (o‘qlarni tez bosish faqat oxirgi oynani ko‘rsatadi).
- [ ] Kelajak mavjud emas: offset hech qachon 0 dan oshmaydi.
- [ ] Keshdagi oyna qaytganda darhol ko‘rsatiladi, so‘ng yangilanadi; keshli ma’lumot bilan xato uni saqlab dialog ko‘rsatadi.

## Xodim farqlari (`Xd*` 4.4 taxtalar)

- [ ] Statistika qobiqning to‘rtinchi tabi “Statistika” (orqaga tugmasi yo‘q, suzuvchi panelni yopmaydi) va faqat “Mening statistikam”ni ko‘rsatadi: xodimga berilgan vazifalar, bajarilgan, o‘z vaqtida ulushi, kechikkan va sabab bilan yopilgan; daromad plitkasi faqat backend summa yuborganda chiqadi. Boshqa turlarga backend 403 qaytaradi.
