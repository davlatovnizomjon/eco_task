# Mening vazifam (adminning shaxsiy vazifasi)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `TasksRepository.getTask` — GET `tasks/{id}`

- [ ] Muvaffaqiyat: 200, `address`, `remindAt`, `createdAt`, `docName`, `files` va `comments` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`; sessiya tozalanadi va router kirish ekraniga qaytaradi.
- [ ] Noma’lum id → 404 → backend matni bilan `MessageErrorResponse`.

### `TasksRepository.approve` — POST `tasks/{id}/approve`

- [ ] Muvaffaqiyat: vazifa `done` holati bilan qaytadi; keshdagi barcha ro‘yxatlar bekor qilinadi.

### `TasksRepository.failTask` — POST `tasks/{id}/fail`

- [ ] `{reason}` bilan muvaffaqiyat: vazifa `fail` holati bilan qaytadi va sabab natija sifatida saqlanadi.
- [ ] Parametr xatosi: bo‘sh sababni jonli API rad etadi (400 → `ValidationErrorResponse`); ilova bo‘sh sabab yubormaydi.

### `TasksRepository.deleteTask` — DELETE `tasks/{id}`

- [ ] Mock’da muvaffaqiyat: vazifa barcha ro‘yxatlardan yo‘qoladi.
- [ ] Jonli API: o‘chirish endpointi hali yo‘q → `MessageErrorResponse` (501) ko‘rsatiladi va vazifa qoladi.

## 2. Mobil/Web integratsiya testi

- [ ] Dashboarddagi «mening vazifalarim» to‘plamidan kartani bosing → shu vazifa bilan bu ekran ochiladi; tortib yangilash uni qayta yuklaydi.
- [ ] «⋯» → “Tahrirlash” vazifa formasini ochadi va qaytganda ekran qayta yuklanadi; “O‘chirish” tasdiqlashni ochadi, tasdiqlash tugmasi aylanadi va ekran dashboardga qaytadi.
- [ ] “Bajarilmadi” sabab sheet’ini ochadi; sabab yuborilsa vazifa yopiladi va ekran qaytadi; “Bajarildi” vazifani yopadi va qaytadi.
- [ ] Manzil qatori xarita sheet’ini ochadi (Yandex / Google havolalari ilovadan chiqadi); rasmlar qatori ko‘ruvchini ochadi; eslatma kartasi eslatmalar ekranini ochadi va qaytganda oxirgi eslatma yangi bo‘ladi.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Dizayn `Eco Tasks — mobile app` ning 1.8–1.9e va 1.11–1.12 taxtalariga yorug‘ va qorong‘i mavzuda 1:1 mos keladi.
- [ ] Tavsif: besh qatorga qisqartirilgan va “Ko‘proq” bor; bosilsa ochiladi va havola “Kamroq” bo‘ladi; qisqa tavsifda havola yo‘q (1.8a, 1.8b).
- [ ] Ma’lumotlar kartasi ma’lumoti yo‘q qatorlarni yashiradi: rasm yo‘q (1.8c–1.8e), hujjat yo‘q, eslatma yo‘q, manzil yo‘q.
- [ ] Muddat qatori “· N soat” ni amber rangda faqat 24 soat ichida muddati tugaydigan ochiq vazifada ko‘rsatadi.
- [ ] Yopilgan vazifada pastki panel yashiriladi; ikkala tugma 52 px balandlikda va kenglikni teng bo‘ladi.
- [ ] Sabab sheet’i: birinchi yuborishgacha hech narsa qizil emas; bo‘sh yuborish maydonni “Sababini yozing” bilan qizil qiladi; hisoblagich matnga 500 gacha ergashadi.
- [ ] 320 px va 768 px kengliklarda toshish yo‘q; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz ko‘rinadi.

## 4. Mantiqiy/biznes test

- [ ] Bajarildi yoki bajarilmadi deb yopilgan vazifa dashboarddagi «mening vazifalarim» to‘plamida boshqa ko‘rinmaydi.
- [ ] O‘chirish avval tasdiqlashni talab qiladi; dialogni yopish hech narsani o‘zgartirmaydi.
- [ ] Sheet’da yozilgan sabab bajarilmagan vazifada saqlangan sababning o‘zi.
