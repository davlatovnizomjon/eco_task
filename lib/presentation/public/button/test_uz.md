# Button (PrimaryButton) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

- [ ] Tegishli emas: tugma hech qanday endpointni chaqirmaydi va repository yoki blocga ega emas.

## 2. Mobile/Web Integration Test

- [ ] Kirish ekranidagi «Kirish →» tugmasi `PrimaryButton`: bosilsa forma yuboriladi; so‘rov ketayotganda spinner va «Kirilmoqda…» ko‘rsatadi, strelkani olib tashlaydi va keyingi bosishlarni e’tiborsiz qoldiradi.
- [ ] So‘rov tugagach (muvaffaqiyat yoki xato) tugma yana «Kirish →» holatiga qaytadi va bosish ishlaydi.

## 3. UI Test

- [ ] U to‘liq enli, 48 px balandlikda, 12 px burchakli, brend yashil fonda va on-primary rangli yozuvli (15 px, yarim qalin); ixtiyoriy oxirgi belgi 18 px, yozuvdan 8 px keyin.
- [ ] Yuklanish holati: 18 px spinner yozuvdan 8 px oldin; yozuv `loadingText` (yoki berilmagan bo‘lsa `text`).
- [ ] Tugma bosilganda yashil fon ustida standart `InkWell` splash va highlight ko‘rinadi, sichqoncha bilan ustiga borilganda (web, desktop) hover rangi chiqadi; yuklanish paytida splash yo‘q.
- [ ] O‘chirilgan holat (`onPressed: null`): fon och yashil (brend yashili ekran foni ustida 40%), yozuv va oxirgi belgi yumshoq oq (yorug‘da 92%, qorong‘ida 60%), bosish hech narsa qilmaydi, splash ham hover ham yo‘q; yuklanayotgan tugma o‘chirilgan ko‘rinmaydi (to‘liq yashil qoladi).
- [ ] Yorug‘ va qorong‘i mavzu to‘g‘ri ko‘rinadi; uzun tarjima yozuvlari 320 px kenglikda ham bir qatorda toshmasdan turadi.

## 4. Logical/Business Test

- [ ] `isLoading: true` bo‘lsa, takroriy bosishda ham `onPressed` hech qachon chaqirilmaydi.
- [ ] `trailingIcon` berilmasa, belgi ham, ortiqcha bo‘shliq ham chizilmaydi.
