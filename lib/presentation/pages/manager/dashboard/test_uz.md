# Dashboard (boss bosh sahifasi) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ReportsRepository.getDashboard` — GET `dashboard`

- [ ] Muvaffaqiyat: the request as admin and as manager → 200, counts, `dueToday` (≤ 3) and `team` (≤ 4) bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Qiymatlar: `inReview` `rev` holatidagi vazifalar soniga teng; `overdue` muddati o‘tgan ochiq vazifalarga teng; `pendingExpenses` `GET expenses?filter=pending` kutilayotgan qatorlariga teng.
- [ ] Qiymatlar: menejer faqat o‘z jamoasining xodimlari va vazifalarini ko‘radi; admin hammani ko‘radi.
- [ ] Qiymatlar: `dueToday` muddat bo‘yicha saralangan va faqat bugun yoki undan oldin muddatli ochiq vazifalarni o‘z ichiga oladi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] Dashboardni oching, yangilang, har bir statistika kartasini (tekshiruv, kechikkan, xarajatlar), «hammasi» havolasi, jamoa hisoboti havolasi va qo‘ng‘iroqni bosing; har biri to‘g‘ri ekranga o‘tadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Birinchi yuklash davomida skeleton shimmer; menejer banneri jamoa nomi va hajmini ko‘rsatadi; FAB yangi vazifa shaklini ochadi.
- [ ] Qo‘ng‘iroq nishoni o‘qilmaganlar hisoblagichiga ergashadi.

## 4. Mantiqiy/biznes test

- [ ] Natijani tasdiqlagan yoki xarajatni boshqa joyda ko‘rib chiqqandan keyin dashboardga qaytsa, yangilangan hisoblagichlar ko‘rinadi (kesh bekor qilingan).
