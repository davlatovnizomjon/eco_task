# Vazifa tafsiloti (admin) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Muvaffaqiyat: `ECO-142` → 200, the task with assignees, expenses, comments and log bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Noma’lum id → 404 → dialogda `MessageErrorResponse(statusCode: 404)` ko‘rsatiladi.
- [ ] Qiymatlar: `ratio = totalDone / totalShare`; `isOverdue` faqat muddati o‘tgan ochiq vazifalar uchun; jurnal yangi birinchi.
- [ ] Keshdan oldin: ekranni qayta ochganda kesh darhol ko‘rinadi (yuklanish miltillashisiz), keyin yangi ma’lumot almashtiradi; muvaffaqiyatsiz yangilash keshni saqlaydi va xato dialogini ko‘rsatadi.

### Actions — POST `tasks/{id}/comments`, `/progress`, `/approve`, `/return`, `/cancel`

- [ ] Muvaffaqiyat: each action as the right role → 200, the updated task bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Parametr xatosi: an empty comment is rejected locally; `done` above the worker's share is clamped by the stepper → backend `detail` matni umumiy dialogda o‘zgarishsiz ko‘rsatiladi.
- [ ] Qiymatlar: progress `fresh` vazifani `prog`ga o‘tkazadi va jurnal qatorlarini qo‘shadi; `cant=true` → `fail`; tasdiqlash → `done`; qaytarish → `prog` (uzaytirilsa +2 kun); bekor qilish → `canc`.
- [ ] Qiymatlar: tasdiqlash/qaytarish har bir ijrochi uchun inbox yozuvini yaratadi; izohlar boshqa ishtirokchilarni xabardor qiladi.

## 2. Mobil/Web integratsiya testi

- [ ] Ro‘yxatdan, dashboarddan, taqvimdan va xodim profilidan oching; «⋯» → “Tahrirlash” formani ochadi va qaytganda vazifa qayta yuklanadi; «⋯» → “O‘chirish” tasdiqlashni so‘raydi, aylanadi va ekran yopiladi; qaror kutayotgan natijani tasdiqlang / qaytaring; rasmni bosing → ko‘ruvchi shu rasmda ochiladi; “Yana N kishi” to‘liq ijrochilar oynasini ochadi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] 2.6 taxtalar: panelda “Vazifa tafsiloti” va «⋯» amali; keyin sarlavha va tavsif, faktlar kartasi (Holat chipi, Tashkilot nomi / Mijoz, Muddat, Manzil, vazifa valyutasidagi Narx, Yaratgan, Yaratilgan sana — ma’lumotsiz qatorlar yashirin), rasm eskizlari va rol belgili birinchi uchta ijrochi (Xodim yashil, Menejer ko‘k, Admin amber).
- [ ] Pastki panel Rad etish / Tasdiqlash ni faqat tekshiruvdagi vazifada ko‘rsatadi; ochiq va yopilgan vazifalarda panel yo‘q (tahrirlash va o‘chirish «⋯» menyusida).

## 4. Mantiqiy/biznes test

- [ ] Tasdiqlash yoki o‘chirish ekranni yopadi va ro‘yxatlar buni aks ettiradi; natijani qaytarish ekranni yangilangan vazifa bilan ochiq qoldiradi; o‘chirish avval tasdiqlashni talab qiladi.
- [ ] Narx vazifaning o‘z valyutasida yoziladi (`uzs` → “so‘m”, aks holda “$”); mijozsiz vazifada mijoz qatori yashiriladi, jismoniy shaxs uchun u “Mijoz” deb nomlanadi.
- [ ] «⋯» menyusi istalgan vazifa uchun «Tahrirlash» va «O‘chirish» ni taklif qiladi (egasi va menejer istalgan vazifani o‘chira oladi).
