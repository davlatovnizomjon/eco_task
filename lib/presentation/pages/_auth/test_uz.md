# Auth (kirish) — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `SupportRepository.getContact` — GET `support/`

- [ ] Muvaffaqiyat: `{phone, telegram}` → `SupportContact`; Telegram nomi `@` bilan qoladi.
- [ ] Kiritilmagan: 404 `support_not_found` → `SupportContact.none` (xato emas, bo‘sh holat).
- [ ] Xato: ulanish yo‘q / 5xx → turlangan `ScreenResponse` ko‘tariladi va oyna qayta urinish panelini ko‘rsatadi.
- [ ] Mock/live mosligi: `MockDioClient` `support/` ga `AppConfig.supportPhone` / `AppConfig.telegramBot` bilan javob beradi; `BackendDioClient` uni to‘g‘ridan-to‘g‘ri o‘tkazadi.

### `LegalRepository.get` — GET `legal/terms/` va `legal/privacy/`

- [ ] Muvaffaqiyat: `{title, message, updated_at}` → `LegalDocument` (`updated_at` matn oxiridagi sana qatoriga aylanadi); `message` bo‘sh qator bo‘yicha bo‘limlarga bo‘linadi (`1. Sarlavha` + matn, sarlavhadan raqam olib tashlanadi), bir qatorli qism sarlavhasiz matn bo‘ladi.
- [ ] Til: so‘rov `Accept-Language` (`uz`, `uz-Cyrl`, `ru`) yuboradi; matni e’lon qilinmagan til uchun o‘zbekcha javob keladi.
- [ ] E’lon qilinmagan: 404 `legal_document_not_found` → `null` (xato emas, bo‘sh holat).
- [ ] Xato: ulanish yo‘q / 5xx → turlangan `ScreenResponse` ko‘tariladi va oyna qayta urinish panelini ko‘rsatadi.
- [ ] Kesh: olingan matn shu til uchun xotiradan beriladi (ikkinchi so‘rov yo‘q); 404 yoki xato eslab qolinmaydi; til o‘zgarsa matn qayta olinadi.
- [ ] Mock/live mosligi: `MockDioClient` ikkala yo‘lga bir xil shaklda javob beradi (o‘zbekcha matn, har birida oltita bo‘lim); `BackendDioClient` `legal/…` ni to‘g‘ridan-to‘g‘ri o‘tkazadi.

### `SessionRepository.login` — POST `auth/login`

- [ ] Muvaffaqiyat: har bir demo hisobning (`jamshid`, `malika`, `boris`, `gulnora`, parol `1234`) `{login, password}` → 200, `{token, user}` va mos `role` bilan; tahlil qilingan model javobga mos keladi.
- [ ] Noto‘g‘ri ma’lumot: noma’lum login yoki noto‘g‘ri parol → 401 → `MessageErrorResponse(statusCode: 401)` (`UnAuthorizedResponse` emas); sessiya tozalanmaydi.
- [ ] Cheklov: jonli APIning `429` javobi oxirgi noto‘g‘ri urinish sifatida qabul qilinadi va formani bloklaydi.
- [ ] Parametr xatosi: bo‘sh `login` yoki `password` hech qanday so‘rovsiz mahalliy rad etiladi (amber toast, qizil maydonlar).
- [ ] Qiymatlar: `user.role` bosh ekranni belgilaydi: owner (admin) → pastki tabli admin shell, assistant (menejer) / worker → o‘z chap menyu shelllari, client → Telegram-bot xabari.
- [ ] Mock/jonli tenglik: bir xil chaqiruvlar `MockDioClient` va jonli API (`AppConfig.useMockData`) bilan o‘tadi; modellar va xato shakllari bir xil.

## 2. Mobil/Web integratsiya testi

- [ ] To‘rtala rol sifatida kiring, to‘g‘ri bosh ekranga tushing va ilova qayta ochilganda sessiya saqlanib qolsin (xavfsiz xotira).
- [ ] Profildan chiqing, so‘ng boshqa rol bilan eskirgan ma’lumotsiz kiring (keshlar tozalangan).
- [ ] Sarlavhada faqat brend va til tugmasi bor (yordam tugmasi yo‘q). Dispetcher oynasiga kirish ekranidan endi o‘tib bo‘lmaydi: u texnik ishlar ekranidagi «Dispetcher bilan bog‘lanish» tugmasidan ochiladi (`public/update_gate`); kontaktlar `GET support/` dan yuklanadi (avval spinner, javob tez kelsa ham kamida 0,6 soniya ko‘rinadi), qo‘ng‘iroq qatori raqamni terishni (`tel:`), Telegram qatori `https://t.me/<nom>` ni ochadi; qurilma ocholmasa qiymat nusxalanadi va qator ikki soniya «Nusxalandi» ni ko‘rsatadi. Oyna `2.4 Dispetcher` maketiga mos: yuqori o‘ngda yopish tugmasi, yumaloq quloqchin belgisi, sarlavha va ish vaqti gapi, chevronli 56 px qatorlar. Kontakt kiritilmagan bo‘lsa (404 yoki ikkala qiymat bo‘sh) — bo‘sh holat paneli; tarmoq/server xatosida — «Yuklab bo‘lmadi» va ishlaydigan «Qayta urinish»; kontaktlar ilova ishlagan davrda bir marta yuklanadi: oyna qayta ochilganda ular darhol, spinner va so‘rovsiz ko‘rinadi; bo‘sh javob yoki xato eslab qolinmaydi, keyingi ochilishda yana so‘raladi. Til tugmasi popupni ochadi; tilni tanlash ilovani darhol almashtiradi: kirish ekranidagi barcha matnlar (sarlavha, izoh, maydon yorliqlari va maslahatlari, tugma, shartlar satri) ekrandan chiqmasdan yangi tilda qayta o‘qiladi va tugma uning bayrog‘i hamda kodini ko‘rsatadi.
- [ ] Pastdagi foydalanish shartlari va maxfiylik havolalari balandroq huquqiy oynalarni ochadi; oyna ekran tepasidan 96 px pastgacha ko‘tariladi, pastda tugma yo‘q, yopish tugmasi (yoki pastga tortish) uni yopadi. Sarlavha va bo‘limlar backenddan keladi, matn tagidagi oxirgi qator esa «Oxirgi yangilanish: <sana>» (backendning `updated_at` qiymati, ilova tilida va telefon vaqt mintaqasida) (Django admin → Legal documents orqali tahrirlanadi), ilova tilida; birinchi ochilishda spinner, e’lon qilinmagan matn uchun «Hujjat hali e’lon qilinmagan», so‘rov xatosida «Yuklab bo‘lmadi» va ishlaydigan «Qayta urinish», qayta ochilganda esa eslab qolingan matn darhol ko‘rinadi. Raqamlangan sarlavhalar va matn `3.2` / `3.3` maketlariga mos.
- [ ] Haqiqiy yoki emulyatsiya qilingan Android/iOS qurilmada `AppConfig.useMockData = true` bilan va yana jonli API bilan ishga tushiring.

## 3. UI test

- [ ] Kichik telefon (320 px) va planshet (768 px) kengligida toshib ketish yoki kesilish yo‘q; uzun nomlar va tarjima qilingan matnlar ko‘p nuqta bilan qisqartiriladi.
- [ ] Yorug‘ va qorong‘i mavzular to‘g‘ri o‘qiladi; profilda mavzuni almashtirish bu ekranni holatini yo‘qotmasdan qayta chizadi.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari yetishmayotgan kalitlarsiz va maket buzilishisiz ko‘rinadi.
- [ ] Dizayn bu ekranning `Eco Tasks — mobile app` taxtasiga yorug‘ va qorong‘i mavzuda 1:1 mos keladi (o‘lchamlar, ranglar, radiuslar, ikonkalar).
- [ ] Birinchi yuborishdan oldin hech narsa qizil emas; bo‘sh maydon bilan yuborish amber «Login va parolni kiriting / Kirish uchun ikkala maydonni to‘ldiring.» toastini chiqaradi va har bir bo‘sh maydonni qizil qiladi (maydonlar tagida matn yo‘q, `2.1` maketidagidek); maydonni tuzatish qizillikni darhol olib tashlaydi. Qizil chegara/belgi asta paydo bo‘ladi va tozalanganda silliq qaytadi; fokusda yashil chegara va halo asta paydo bo‘ladi va so‘nadi. Sarlavha «Kirish», uning tagida «Sizga berilgan login va parolni kiriting».
- [ ] Noto‘g‘ri ma’lumot qizil toastni qolgan urinishlar bilan (4 → 3 → 2 → 1) va ikkala maydon qizil holda ko‘rsatadi; keyingi tahrir qizil maydonlarni tozalaydi.
- [ ] Kirish davomida tugma spinner va «Kirilmoqda…» ni ko‘rsatadi; toastlar umumiy `showTopToast` orqali ko‘rsatiladi (`public/toast/test_uz.md` ga qarang).
- [ ] Parol ko‘zi yashirishni almashtiradi; mock rejimida demo-hisob chiplari login va parolni to‘ldiradi; shartlar qatori klaviatura yopiqda pastda turadi, ochiqda esa siljiydi.

## 4. Mantiqiy/biznes test

- [ ] Beshinchi noto‘g‘ri urinish kirishni 5 daqiqaga bloklaydi (backend `LOGIN_MAX_ATTEMPTS` / `LOGIN_LOCK_SECONDS` bilan bir xil): toast ham, alohida ekran ham yo‘q — forma qoladi va `2.3` maketidagidek parol maydoni ostida qulf belgili amber banner chiqadi («Siz vaqtincha bloklangansiz. mm:ss dan keyin qayta urinib ko‘ring.», vaqt qalin va jonli sanaydi), «Kirish» tugmasi o‘chirilgan bo‘ladi; maydonlarni tahrirlash mumkin. Sanoq tugagach banner yo‘qoladi, tugma ishlaydi va urinishlar 5 ga qaytadi.
- [ ] Blok ilovani yopganda ham saqlanadi: kirishni bloklang, masalan 3:00 qolganda ilovani yoping, 1 daqiqadan keyin qayta oching → banner taxminan 2:00 ni ko‘rsatadi va sanashda davom etadi; vaqti tugagandan keyin ochilsa — banner yo‘q va kirish ishlaydi. Saqlangan tugash vaqti o‘tgach o‘chiriladi. (Blok qurilma bo‘yicha saqlanadi, login bo‘yicha emas.)
- [ ] Urinishlar hisoblagichi 0 dan pastga tushmaydi va ekran qayta ochilganda tiklanadi (blok faqat xotirada saqlanadi).
- [ ] Login katta-kichik harfga sezgir emas va bo‘shliqlardan tozalanadi; parol sezgir.
