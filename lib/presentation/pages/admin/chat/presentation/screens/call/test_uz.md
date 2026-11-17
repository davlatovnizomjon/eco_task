# Qo‘ng‘iroq (admin)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha hech narsa ishga tushirilmaydi.

## 1. API testi

### `CallRepository.start` — POST `conversations/{id}/calls/`; `get` — GET `calls/{id}/`; `answer` / `decline` / `end` — POST `calls/{id}/{action}/`; `invite` — POST `calls/{id}/invite/`

- [ ] Muvaffaqiyat: `start` → 201, `status` RINGING, qo‘ng‘iroq qilgan JOINED, qolgan a’zolar INVITED; `answer` → ACTIVE va `answered_at` to‘ladi; shaxsiy qo‘ng‘iroqda yagona taklif qilingan odam `decline` qilsa → DECLINED; qo‘ng‘iroq qilgan javobdan oldin `end` qilsa → CANCELED, keyin → ENDED; `invite` guruh a’zolarini INVITED qilib qo‘shadi.
- [ ] Avtorizatsiya xatosi: 401 → `UnAuthorizedResponse`; begonaning qo‘ng‘irog‘i → 404.
- [ ] Qoidalar: vazifa chati → 400; jiringlayotgan suhbatda ikkinchi qo‘ng‘iroq → 409 `call_in_progress`; qo‘ng‘iroq qilinadigan odam yo‘q → 400; javobsiz qo‘ng‘iroq `CALL_RING_SECONDS`dan keyin MISSED bo‘ladi.
- [ ] Jonli ulanish: `ws/me/` `call.incoming|answered|declined|ended` ni yetkazadi va `call.signal` ni faqat bir jonli qo‘ng‘iroqdagi ikki odam orasida uzatadi.

## 2. Mobil/Veb integratsiya testi

- [ ] Ikki qurilmada jonli API bilan: shaxsiy ovozli, video va uch kishilik guruh qo‘ng‘irog‘i, to‘rtinchisini qo‘shish, rad etish, javob bermaslik, qayta qo‘ng‘iroq. Mock backendda (`AppConfig.useMockData`) qo‘ng‘iroq haqiqiy mediasiz faol holda ochiladi.
- [ ] Ekranni kichraytirish (orqaga chevron) tovushni to‘xtatmaydi; shu chatda trubka tugmasi qo‘ng‘iroqqa qaytaradi.

## 3. UI testi

- [ ] 3.7 shaxsiy taxtalar: chiquvchi “Chaqirilmoqda…”, kiruvchi (qizil rad etish / yashil qabul qilish, yumshoq qo‘sh halqa), faol (taymer `mm:ss`), video (to‘liq ekran tasvir, kichik o‘z tasviri, kamerani almashtirish), rad etilgan (“Qo‘ng‘iroq rad etildi”, qizil) va javob bermagan (“Javob bermadi”, amber) — surib qayta qo‘ng‘iroq qilish va yopish tugmasi bilan.
- [ ] 3.7 guruh taxtalari: plitkalar to‘ri (to‘rt kishigacha ikki ustun, undan ko‘pida uch ustun), ovozi o‘chiriqlarda qizil mikrofon, sarlavhada “N ishtirokchi · taymer”, “+” tugmasi qo‘ng‘iroqda bo‘lmagan odamlar bilan “Qo‘ng‘iroqqa qo‘shish” oynasini ochadi, “+N yana” / “orqaga” plitkalari to‘rni varaqlaydi, “X taklifni rad etdi” uch soniya ko‘rinadi, taklif ekrani guruh plitkasi, kim taklif qilgani va “N kishi suhbatda” ni ko‘rsatadi.
- [ ] Chat sarlavhasidagi trubka (shaxsiy va guruh chatlarida, vazifa chatida emas) qo‘ng‘iroq boshlaydi.
- [ ] 320 px va 768 px da to‘lib ketmaydi; uz, uz-Cyrl va ru da kalitlar yetishmaydi; fon yorug‘ va qorong‘i rejimda bir xil.

## 4. Mantiqiy/biznes testi

- [ ] WebRTC ulanishlarini faqat qo‘shilgan odam taklif qiladi, qo‘ng‘iroqdagi hammaga; chiqib ketgan odam boshqalarning to‘ridan olib tashlanadi.
- [ ] Tugagan qo‘ng‘iroq natijasini (rad etildi / javob bermadi) faqat boshlagan odam ko‘radi; qolganlar chatga qaytariladi.
- [ ] Kiruvchi qo‘ng‘iroq kirgan qobiqning istalgan ekranidan qo‘ng‘iroq ekranini ochadi; rad etish yoki qo‘ng‘iroq qilganning bekor qilishi uni yopadi.
