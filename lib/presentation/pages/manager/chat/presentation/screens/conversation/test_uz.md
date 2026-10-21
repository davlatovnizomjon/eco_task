# Suhbat — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ChatRepository.getConversation` — GET `conversations/{id}/`

- [ ] Muvaffaqiyat: o‘z suhbat id’si → 200 va payload; tahlil qilingan model unga mos keladi.
- [ ] Auth xatosi: token yo‘q yoki muddati o‘tgan → 401 → `UnAuthorizedResponse`.
- [ ] Begona yoki mavjud bo‘lmagan id → bir xil 404 `not_found` (id’larni tekshirib bo‘lmaydi).

### `ChatRepository.getMessages` — GET `conversations/{id}/messages/?limit=30&before=`

- [ ] Muvaffaqiyat: 200 va `{results (yangisi birinchi), has_more}`; ekran ularni eskisidan boshlab ko‘rsatadi.
- [ ] Parametrlar natijani o‘zgartiradi: `before=<id>` faqat eskiroq xabarlarni qaytaradi; 100 dan katta `limit` kesiladi; butun bo‘lmagan `before` → 400 `invalid_query`.
- [ ] Oxirgi sahifada `has_more` false va «oldingi xabarlar» tugmasi yo‘qoladi.

### `ChatRepository.sendMessage` — POST `conversations/{id}/messages/`

- [ ] Muvaffaqiyat: `{body, client_msg_id}` → 201 va saqlangan xabar; xuddi shu `client_msg_id` yana → 200 va AYNAN SHU xabar (dublikat yo‘q).
- [ ] Parametr xatolari: bo‘sh yoki 4000 belgidan uzun matn → 400 `invalid_message`, umumiy dialogda ko‘rsatiladi.

### `ChatRepository.markRead` — POST `conversations/{id}/read/`

- [ ] Muvaffaqiyat: `{message_id}` → 200 `{last_read_message_id}`; kichikroq id belgini hech qachon orqaga surmaydi.

### `ChatRepository.openTaskChat` — POST `conversations/` `{kind: TASK, task}` bilan

- [ ] Muvaffaqiyat: foydalanuvchi ko‘ra oladigan vazifa → 201 va har safar bir xil suhbat; ko‘rinmaydigan vazifa → 404.

### WebSocket `ws(s)://host/ws/chat/{id}/` (subprotocol `bearer, <token>`)

- [ ] Ulanish: to‘g‘ri token va ruxsat → `presence.snapshot`; token yo‘q/noto‘g‘ri → 4401 bilan yopiladi; ruxsat yo‘q → 4403; foydalanuvchi limitidan oshsa → 4429.
- [ ] `message.send` → barcha ishtirokchilarga `message.new`; yuboruvchiga ham xuddi shu `client_msg_id` bilan `message.ack`; takroriy `client_msg_id` → `duplicate: true` va yangi qator yo‘q.
- [ ] `message.read` → boshqalarga `message.read`; `ping` → `pong`; noma’lum tur / noto‘g‘ri JSON / katta frame → `error` yoki 1009 bilan yopiladi.
- [ ] Ruxsat olib qo‘yilsa (xodim vazifadan olinsa) → bir soniya ichida `revoked` va 4403 bilan yopiladi.
- [ ] Daqiqada `CHAT_MESSAGES_PER_MINUTE` dan ko‘p yuborish → `error: rate_limited`.

## 2. Mobil/Web integratsiya testi

- [ ] Ro‘yxatdan, vazifadan (vazifa sarlavhasidagi chat belgisi) va yangi suhbat yaratilgandan so‘ng oching; yuboring, qabul qiling, orqaga qayting.
- [ ] Ekran ochiqligida tarmoqni o‘chiring: «qayta ulanmoqda» banneri chiqadi, shu orada yuborilgan xabar REST orqali ketadi, tarmoq qaytgach socket qayta ulanadi va o‘tkazib yuborilgan xabarlar dublikatsiz paydo bo‘ladi.
- [ ] `AppConfig.useMockData = true` bilan (skriptli «Qabul qilindi 👍» javobi) haqiqiy yoki emulyator Android/iOS qurilmada, so‘ng jonli backend bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida overflow yoki kesilish yo‘q; uzun ismlar va tarjima matnlari ko‘p nuqta bilan qisqaradi.
- [ ] Yorug‘ va qorong‘i mavzular ikkalasi ham to‘g‘ri ko‘rinadi; Sozlamalarda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Xabarlar ro‘yxati pastdan boshlanadi, eng yangisi pastda; o‘z pufakchalari o‘ngda brend rangida, boshqalarniki chapda; guruh va vazifa suhbatlarida muallif avatari va ismi ko‘rinadi; uzun so‘zlar o‘raladi va overflow bermaydi.
- [ ] Yetkazish belgilari: yuborilayotganda soat, saqlanganda bitta belgi, o‘qilganda ikkita belgi; yuborilmagan xabarda qizil ogohlantirish va «qayta urinish uchun bosing».
- [ ] Klaviatura kiritish maydonini yopmaydi; klaviatura ochilganda eng yangi xabar ko‘rinib turadi.

## 4. Mantiq/biznes testi

- [ ] Bir xil matnni ikki marta tez yuborish ikkita xabar yaratadi (turli client id); BITTA yuborishning tarmoq takrori hech qachon ikkita yaratmaydi.
- [ ] Socket orqali kelgan va REST bilan ham yuklangan xabar bir marta ko‘rinadi.
- [ ] Suhbatni ochish boshqalarning xabarlarini bir marta o‘qilgan deb belgilaydi va qaytgach ro‘yxat belgisi kamayadi.
