# Xodim vazifalari (admin)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTasks` — GET `tasks?who={id}`

- [ ] Muvaffaqiyat: a’zoning vazifalari 1-sahifasi; har bir element shu a’zoni o‘z ichiga oladi.
- [ ] Auth xatosi: 401 → `UnAuthorizedResponse`.
- [ ] Avval kesh: qayta ochganda keshdagi qatorlar darhol, keyin yangilari ko‘rinadi; keshli qatorlar bilan xato ularni saqlab dialog ko‘rsatadi.

## 2. Mobil/Web integratsiya testi

- [ ] Profildagi “Batafsil” dan oching; uchta tabni almashtiring; qatorni bosing → vazifa tafsiloti; tortib yangilang; xatodan keyin qayta urining.
- [ ] `AppConfig.useMockData = true` bilan va jonli API bilan ishga tushiring.

## 3. UI test

- [ ] 1.22c–1.22g taxtalar: sarlavha “{ism} vazifalari”; Barchasi / Bajarilgan / Bajarilmagan tablari; holat belgisi, nom, holat so‘zi va muddat kuni bilan qatorlar; yuklanishda shimmer; uchta bo‘sh holat (plitka, sarlavha, izoh).
- [ ] 320 px va 768 px da toshish yo‘q; yorug‘ va qorong‘i mavzular; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz.

## 4. Mantiqiy/biznes test

- [ ] “Bajarilgan” faqat bajarilgan, “Bajarilmagan” faqat bajarilmagan vazifalarni ko‘rsatadi; “Barchasi” ochiqlarini ham qo‘shib hammasini.
