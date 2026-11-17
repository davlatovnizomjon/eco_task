# Guruhni tahrirlash (menejer)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `PATCH conversations/{id}` (sarlavha), `POST .../members/`, `DELETE .../members/{id}/`

- [ ] Muvaffaqiyat: yangi sarlavha va a’zolar farqi shu tartibda qo‘llanadi; ishchining urinishi → 403; bo‘sh sarlavha → 400.
- [ ] Begona id → 404; o‘rtada xato bo‘lsa allaqachon qo‘llanganlari qoladi va xato dialogi chiqadi.

## 2. Mobil/Web integratsiya testi

- [ ] `AppConfig.useMockData = true` bilan va jonli API bilan ishga tushiring; tortib yangilang; xatodan keyin qayta urining.

## 3. UI test

- [ ] 3.4 tahrirlash taxtasi: guruh plitkasi, “Guruh nomi” maydoni, “A’zo qo‘shish” qatori (guruhda hali yo‘q odamlar tanlagichini ochadi) va qizil minusli a’zo qatorlari (chaqiruvchining o‘z qatorida yo‘q); “Saqlash” hammasini qo‘llaydi va yopadi. Bo‘sh sarlavha maydonni faqat birinchi saqlash urinishidan keyin qizil qiladi.
- [ ] Rasm almashtirish qurilmagan (fayl xizmati yo‘q).
- [ ] 320 px va 768 px da toshish yo‘q; yorug‘ va qorong‘i mavzular; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz.

## 4. Mantiqiy/biznes test

- [ ] Chaqiruvchi bu yerda o‘zini chiqara olmaydi (“Guruhdan chiqish” dan foydalaning).
- [ ] Qoralama server holatiga teng bo‘lsa hech narsa yuborilmaydi.
