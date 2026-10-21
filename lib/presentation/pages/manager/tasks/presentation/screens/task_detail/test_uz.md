# Vazifa tafsiloti — Test rejasi

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

- [ ] Boss yo‘li: `rev` vazifani oching → tasdiqlang (ekran yopiladi) va har bir sabab bilan rad eting (varaq, uzaytirish almashtirgichi) → holat `prog`ga qaytadi.
- [ ] Xodim yo‘li: biriktirilgan vazifani oching → progressni yangilang (stepper, natija, izoh), rasmlar bilan izoh qoldiring, xarajat qo‘shing, natijani yuboring.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan yana ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Bo‘limlar faqat mazmuni bo‘lganda ko‘rinadi (natija, mukofot/xarajatlar, fayllar, faollik); boss har bir kishi progressi bilan ijrochi qatorlarini ko‘radi, xodim o‘z ulushi kartasi va faqat o‘z xarajatlarini ko‘radi.
- [ ] Rol/holatga qarab pastki panel: tasdiqlash+rad etish (boss, `rev`), bekor qilish+tahrirlash (boss, ochiq), to‘rtta xodim amali (xodim, ochiq), yopiq vazifalar uchun yo‘q; bekor qilish avval tasdiq so‘raydi.
- [ ] Pull-to-refresh ishlaydi; izoh maydoni yuboradi va tozalanadi; vaqt chizig‘i eng yangi jurnal qatorini belgilaydi.

## 4. Mantiqiy/biznes test

- [ ] Biriktirilmagan xodim xodim amallariga yeta olmaydi; menejer o‘z jamoasidan tashqari vazifalarni ocha olmaydi (backenddan 404).
- [ ] Ikki marta tasdiqlash yoki bekor qilingan vazifada amal UI (tugmalar yashirin) va backend tomonidan rad etiladi.
