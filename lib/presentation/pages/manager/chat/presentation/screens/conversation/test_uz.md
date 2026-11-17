# Suhbat (menejer) — Test rejasi

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

- [ ] Ro‘yxatdan, vazifa chat amalidan yoki yangi suhbatdan oching; yuboring, jonli qabul qiling, muvaffaqiyatsiz xabarni qayta yuboring, eski xabarlarni yuklang, soket qayta ulanayotganda chiqing.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Panel suhbat nomini yashil «onlayn» / «N a’zo» qatori bilan markazga qo‘yadi; xabarlar sahifa fonida turadi, o‘z pufakchalari yashil va vaqt hamda yetkazish belgilarini (soat, belgi, o‘qilganda qo‘sh belgi) ko‘rsatadi; kun sarlavhalari (Bugun, Kecha, sana) kunlarni ajratadi.
- [ ] Kiritish panelida yumaloq ko‘p qatorli maydon va imo-ishora zonasi ustida yumaloq yashil yuborish tugmasi bor; soket uzilganda oflayn izoh uning tepasida chiqadi.
- [ ] Xabarni bosib turish (kutilayotgan yoki o‘chirilgan emas) amallar oynasini ochadi: 11 ta tezkor emoji (tanlangani ajratilgan; yana bossangiz olib tashlanadi), nusxa olish (toast), tahrirlash (faqat o‘zinikini), pin / pinni olib tashlash, o‘chirish (o‘zinikini, yoki xodim uchun istalganini, tasdiqlash dialogidan keyin).
- [ ] Tahrirlangan xabarlarda vaqt yonida “tahrirlandi” va yangi matn ko‘rinadi; o‘chirilganlarda kursiv “Xabar o‘chirildi” chiqadi va munosabatlari yo‘qoladi; pufak ostidagi munosabat chiplari emoji va sonni ko‘rsatadi, o‘zinikisi ajratilgan, bosish uni almashtiradi.
- [ ] Pin qilingan xabar panel ostidagi bannerda ko‘rinadi (yashil sarlavha, bir qator, «x» tozalaydi); pin qilingan xabarni o‘chirish pinni tozalaydi; boshqa a’zo o‘zgartirgan pin jonli keladi (`conversation.pinned`), tahrir va munosabatlar `message.updated` sifatida keladi.
- [ ] Tahrirlash rejimi: kiritish maydoni “Xabarni tahrirlash” va «x» ni ko‘rsatadi; yuborish tahrirni saqlaydi (matn o‘zgarmasa hech narsa yuborilmaydi).
- [ ] Sarlavhani bosish shaxsiy yoki guruh suhbatining ma’lumot sahifasini ochadi (vazifa suhbatlari uchun emas).
- [ ] Uzoq bosish → “Javob berish”: kiritish maydoni ustida iqtibos muallifi va matni bilan javob paneli chiqadi (“x” yopadi); yuborilgan pufakchada iqtibos kartasi ko‘rinadi; `reply_to` socket va REST orqali ketadi; o‘chirilgan xabar iqtibosida “Xabar o‘chirildi” yoziladi.
- [ ] Skrepka tugmasi: kamera / galereya / hujjat varag‘i; fayl yuklanadi (`POST files/`, ingichka progress chizig‘i) va `attachment_id` bilan alohida xabar bo‘lib yuboriladi; rasmlar `PhotoViewer`da, hujjatlar `DocumentViewer`da ochiladi.
- [ ] Bo‘sh maydonda mikrofon: bosib turish ovozli xabar yozadi (taymer, chapga surish bekor qiladi, 1 soniyadan qisqasi tashlanadi), qo‘yib yuborish yuboradi; mikrofonni bosish kameraga (video-krujok) almashtiradi, uni uzoq bosish old kamerani ochadi (eng ko‘pi 60 s); pufakchalarda ovozli xabar uchun to‘lqinli play tugmasi, krujok uchun 180 px dumaloq pleer ko‘rinadi. Qurilma kerak: mikrofon/kamera ruxsatlari, ijro.

## 4. Mantiqiy/biznes test

- [ ] Yuborish optimistik va `client_msg_id` bo‘yicha takrorlanishdan tozalanadi; muvaffaqiyatsiz xabarni bosib qayta yuborish mumkin.
