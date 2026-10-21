# Mijoz boti ekrani — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `SessionRepository.login` — POST `auth/login/` mijoz sifatida

- [ ] Muvaffaqiyat: CLIENT akkaunti kiradi (200, token va `role: CLIENT`); sessiya saqlanadi va router ilovani `/telegram` ga o‘tkazadi.
- [ ] Auth xatosi: noto‘g‘ri parol → 401, kirish formasi backend xabarini ko‘rsatadi (yo‘naltirish yo‘q).
- [ ] Mock/jonli tenglik: mock backenddagi `gulnora` va jonli API dagi CLIENT akkaunti bir xil ishlaydi.

## 2. Mobil/Web integratsiya testi

- [ ] Mijoz sifatida kiring: bot ekrani ochiladi; `/home`, `/tasks/...`, `/chat/...` ni ochishga har bir urinish (deep link yoki Orqaga) yana `/telegram` ga tushadi.
- [ ] Saqlangan mijoz sessiyasi bilan ilovani qayta ishga tushiring: u bosh sahifada emas, shu ekranda ochiladi.
- [ ] Chiqish kirish ekraniga qaytaradi; keyin xodim sifatida kirsangiz oddiy bosh sahifa ko‘rinadi.
- [ ] `AppConfig.useMockData = true` bilan haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q.
- [ ] Chap menyu menyu tugmasidan ochiladi va Telegram-bot xabari, Til va Ko‘rinish bandlarini ko‘rsatadi; sarlavhada hisob ko‘rinadi; Til va Ko‘rinish sozlama ekranlarini ochadi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri ko‘rinadi; o‘zbek lotin, kirill va rus tillari yetishmayotgan kalitlarsiz chiqadi.
- [ ] Matn `--dart-define=TELEGRAM_BOT=@nom` bilan berilgan botni ataydi; «Nusxalash» aynan shu nomni clipboardga qo‘yadi va «Nusxalandi» xabarini ko‘rsatadi.

## 4. Mantiq/biznes testi

- [ ] Mijoz ilova orqali xodim ma’lumotiga hech qachon yeta olmaydi: rol mijoz ekan, na tab, na deep link, na pushed route ochiladi.
