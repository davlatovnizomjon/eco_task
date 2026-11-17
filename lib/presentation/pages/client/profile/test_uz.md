# Profil (mijoz tabi) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `SupportRepository.getContact` — GET `support/`

- [ ] Muvaffaqiyat: 200 → `phone` va `telegram` `SupportContact` ga tahlil qilinadi; yordam oynasi ularni ko‘rsatadi.
- [ ] Sozlanmagan: 404 → `SupportContact.none`; oynada “Dispetcher kontaktlari hali kiritilmagan.” chiqadi va qatorlar yo‘q.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Avval kesh: tabni qayta ochganda eslab qolingan kontaktlar darhol ishlatiladi, keyin yangilari.

### `SessionRepository.clearSession` — POST `auth/logout`

- [ ] Muvaffaqiyat: token masofadan bekor qilinadi va lokal sessiya tozalanadi; oflayn holatda ham lokal sessiya tozalanadi.

## 2. Mobil/Web integratsiya testi

- [ ] Hisob kartasidagi qalamdan tahrirlash ekranini, qatorlaridan til, ko‘rinish va yordam oynalarini oching, bildirishnomalarni almashtiring, chiqing (tasdiqlang) va boshqa rol bilan kiring.
- [ ] Yordam oynasi: “Qo‘ng‘iroq qilish” terish oynasini, “Telegram orqali yozish” Telegramni ochadi; ikkalasi oynani yopadi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn `Eco Tasks — mobile app` ning 5.1 va 5.3–5.5 taxtalariga yorug‘ va qorong‘i mavzuda 1:1 mos keladi: markazdagi hisob kartasi (yumshoq halqali 84 px avatar, ism, telefon, rol belgisi, qalam tugmasi), 60 px qatorli sozlamalar kartasi va qizil chiqish kartasi.
- [ ] Sozlamalar kartasi joriy tilni, joriy mavzuni va almashtirgich yonida “Yoqilgan” / “O‘chirilgan” ni ko‘rsatadi (til qatori taxtadan tashqari saqlangan, til o‘zgartiriladigan bo‘lib qolishi uchun).
- [ ] Til yoki mavzuni oynasida tanlash darhol qo‘llanadi, oynani yopadi va qator qiymatini yangilaydi; mavzu oynasi joriy tanlovni to‘ldirilgan dumaloq belgi bilan ko‘rsatadi.
- [ ] Chiqish dialogi (5.5): qizil plitka, sarlavha, izoh, “Bekor qilish” va sessiya yopilayotganda aylanadigan qizil “Chiqish”.

## 4. Mantiqiy/biznes test

- [ ] Chiqish har doim avval tasdiqlashni so‘raydi va sessiyani, keshlarni va tanlangan tabni tozalaydi.
- [ ] Bildirishnoma almashtirgichi `SettingsRepository.setNotificationsAllowed` ga yozadi va ilova qayta ishga tushganda saqlanadi.
- [ ] Qiymati yo‘q yordam yo‘li (telefon yo‘q yoki Telegram yo‘q) bo‘sh ko‘rsatilmaydi, yashiriladi.
