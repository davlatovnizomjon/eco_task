# Hisobotlar (admin hisobot tabi)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getReport` — GET `reports?period=`

- [ ] Muvaffaqiyat: 200, `counts`, `overdue`, `weekly`, `people` bilan; reyting ekrani (shu feature’ning bloc’i) ishlatadi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi.
- [ ] Avval kesh: qayta ochganda keshdagi hisobot darhol, keyin yangisi ko‘rinadi.

(Oltita statistika ekrani o‘z rejasiga ega: `presentation/screens/stats/test.md`.)

## 2. Mobil/Web integratsiya testi

- [ ] Tabda oltita karta bor (Moliya, Vazifalar statistikasi, Mening statistikam, Mijozlar, Xodimlar, Menejerlar); har biri o‘z statistika ekranini (`/reports/:kind`) ochadi va orqaga qaytish tabga olib keladi.
- [ ] Haqiqiy yoki emulyatsiya qilingan qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] 4.1 taxta: katta “Hisobot” sarlavhasi va teng balandlikdagi oltita to‘liq enli karta: 48 px plitka, sarlavha, izoh va chevron; oxirgi karta suzuvchi tab panelini yopmaydi.
- [ ] 320 px va 768 px da toshish yo‘q; yorug‘ va qorong‘i mavzular; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz.

## 4. Mantiqiy/biznes test

- [ ] Har bir kartaning sarlavhasi va izohi `StatsKind` dan keladi; kartalar mos turni ochadi.
