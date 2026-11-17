# Xodim profili (admin)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TeamRepository.getUser` — GET `users/{id}` va `TasksRepository.getTasks` — GET `tasks?who={id}`

- [ ] Muvaffaqiyat: hisob va a’zoning vazifalari yuklanadi; hisoblagichlar qaytgan vazifalar sonini holat bo‘yicha aks ettiradi.
- [ ] Auth xatosi: 401 → `UnAuthorizedResponse`. Noma’lum id → 404 → umumiy xato dialogi.
- [ ] Avval kesh: qayta ochganda keshdagi profil darhol, keyin yangisi ko‘rinadi.

## 2. Mobil/Web integratsiya testi

- [ ] Jamoa ro‘yxatidan va reytingdan oching; “Batafsil” to‘liq vazifalar ro‘yxatini ochadi; bugungi vazifa tafsilotini ochadi; tortib yangilang.
- [ ] `AppConfig.useMockData = true` bilan va jonli API bilan ishga tushiring.

## 3. UI test

- [ ] 1.22–1.22b taxtalar: markazda 96 px avatar, ism, telefon va rol belgisi; Barchasi / Bajarilgan / Bajarilmagan hisoblagichli “Vazifalar” kartasi; “Bugungi vazifalar” qatorlari yoki “Bugun vazifa yo‘q” kartasi.
- [ ] “⋯” menyusi “Tahrirlash” (to‘ldirilgan a’zo formasi, `PATCH users/{id}` bilan saqlanadi) va “O‘chirish” (tasdiq oynasi, so‘ng `DELETE users/{id}`) ni ochadi; xabarda o‘chirildi yoki (tarixi bo‘lsa) faolsizlantirildi deyiladi va ekran yopiladi.
- [ ] 320 px va 768 px da toshish yo‘q; yorug‘ va qorong‘i mavzular; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz.

## 4. Mantiqiy/biznes test

- [ ] Hisoblagichlar faqat shu a’zoning bajarilgan va bajarilmagan vazifalarini sanaydi; “bugun” muddat kuni bugun ekanini bildiradi.
