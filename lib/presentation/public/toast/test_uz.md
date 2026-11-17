# Toast — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

- [ ] Tegishli emas: toast hech qanday endpointni chaqirmaydi va repository yoki blocga ega emas.

## 2. Mobile/Web Integration Test

- [ ] Istalgan ekrandan `showTopToast(context, ...)` toastni ko‘rsatadi, ekranda `Stack` yoki o‘rin tutuvchi widget kerak emas; kirish ekranining bo‘sh maydon va noto‘g‘ri ma’lumot toastlari shu orqali o‘tadi.
- [ ] Toast root overlay’da turadi: keyin ochilgan sheet va dialoglar ustida qoladi va vaqti tugaguncha sahifa almashganda ham yo‘qolmaydi.
- [ ] Biri ko‘rinib turganda ikkinchisi ko‘rsatilsa, birinchisini darhol almashtiradi (ekranda hech qachon ikkita emas); bir xil toast ketma-ket ikki marta chaqirilsa, ikki marta ko‘rinadi.
- [ ] Toast tagidagi narsalarga (sarlavha tugmalari, maydonlar) bosish toast orqali o‘tadi.
- [ ] Toast 4 soniyadan (yoki berilgan `duration` dan) keyin o‘zi yo‘qoladi; yopish tugmasi yo‘q.

## 3. UI Test

- [ ] U `Toast` maketiga mos: 36 px rangli yumaloq belgi, 15 px yarim qalin sarlavha (qalinligi 650), 13 px matn, o‘ngdan 14 px bo‘shliq, tonga mos chegara (muvaffaqiyat, ma’lumot, ogohlantirish, xato), 16 px burchak va yumshoq soya; qorong‘i mavzuda chuqurroq ikki qatlamli soya.
- [ ] U holat satridan 8 px pastda, chap va o‘ngdan 12 px bo‘shliq bilan turadi; notch bilan ham, holat satri yashirin bo‘lganda ham ishlaydi.
- [ ] Paydo bo‘lganda ekran chetidan tepadan pastga tushadi (taxminan 320 ms), ketayotganda tepaga siljib ko‘rinmay qoladi (taxminan 260 ms).
- [ ] Uzun sarlavha va matn toshmasdan o‘raladi; yorug‘ va qorong‘i mavzu to‘g‘ri ko‘rinadi; o‘zbek lotin, kirill va rus matnlari sig‘adi.

## 4. Logical/Business Test

- [ ] Vaqti tugamasdan ekrani yopilgan toast ham o‘z vaqtida yo‘qoladi va overlay’da iz qoldirmaydi.
- [ ] Tez-tez ketma-ket chaqiruvlardan keyin oxirida aynan bitta overlay yozuvi qoladi.
