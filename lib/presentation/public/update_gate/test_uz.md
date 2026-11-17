# Ilovani yangilash darvozasi — Test rejasi

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha hech narsa ishga tushirilmaydi.

## 1. API testi

### `AppUpdateRepository.check` — GET `app-version/?platform=android|ios`

- [ ] Muvaffaqiyat: o‘rnatilgan versiya `latest_version` dan past, `force_update` false → `UpdateNeed.optional`; `title` va `subtitle` natijaga o‘tadi (yo‘q bo‘lsa bo‘sh qator).
- [ ] Muvaffaqiyat: o‘rnatilgan versiya past, `force_update` true → `UpdateNeed.required`.
- [ ] Qiymatlar: o‘rnatilgan versiya `latest_version` ga teng yoki undan yuqori → `UpdateNeed.none`, `force_update` true bo‘lsa ham.
- [ ] Qiymatlar: `1.2` va `1.2.0` teng; `1.10.0` `1.9.9` dan yangi (matn emas, raqam bo‘yicha solishtirish).
- [ ] Platforma: web va desktop build so‘rov yubormaydi va `UpdateNeed.none` qaytaradi.
- [ ] Topilmadi: backend 404 (`release_not_found`) qaytarsa → tekshiruv jimgina tugaydi, ilova bloklanmaydi.
- [ ] Oflayn / taym-aut / 4xx: tekshiruv jimgina tugaydi, oldingi natija saqlanadi, ilova bloklanmaydi.
- [ ] Texnik ishlar belgisi: javobda `is_maintenance: true` bo‘lsa, texnik ishlar ekrani chiqadi (5xx kabi); `false` (yoki maydon yo‘q) bo‘lsa ekran yo‘qoladi va ilova ko‘rinadi; ekran turganda yangilanish dialoglari taklif qilinmaydi, keyin hamon kerak bo‘lsa qaytadi va ostida ochiq turgan dialogning ikkinchi nusxasi to‘planib qolmaydi.
- [ ] Server xatosi: 5xx javob (`ServerErrorResponse`) `maintenance` ni yoqadi va texnik ishlar ekranini chiqaradi; keyingi muvaffaqiyatli javob uni qayta olib tashlaydi.
- [ ] Tokensiz: so‘rovda bearer token yo‘q va u kirishdan oldin ham ishlaydi; eskirgan token refresh yoki logoutni ishga tushirmaydi.
- [ ] Mock/live mosligi: `AppConfig.useMockData` da mock har qanday build’dan eski versiya qaytaradi, shuning uchun taklif chiqmaydi.

## 2. Mobil/Web integratsiya testi

- [ ] Backend `title` / `subtitle` bergan bo‘lsa, dialogda aynan shu matn chiqadi; bo‘sh bo‘lsa ilovaning o‘z matni (“Yangi versiya mavjud” va versiyalar) chiqadi.
- [ ] Ixtiyoriy yangilanish bilan ishga tushirish: birinchi kadrdan keyin “Yangi versiya mavjud” dialogi ikkala versiyani ko‘rsatadi; “Yangilash” do‘kon havolasini ochadi, “Keyinroq” yopadi.
- [ ] “Keyinroq” dan keyin xuddi shu versiya uchun dialog qaytib chiqmaydi; yangiroq versiya e’lon qilinsa yana chiqadi.
- [ ] Majburiy yangilanish bilan ishga tushirish (`force_update` true): o‘sha platformaga mos dialog faqat «Yangilash» tugmasi bilan chiqadi («Keyinroq» yo‘q); «Yangilash» do‘konni ochadi va dialog ochiq qoladi; Android «orqaga» tugmasi va tashqariga bosish uni yopmaydi. `force_update` false bo‘lsa dialogda ikkala tugma bor.
- [ ] Fondan qaytganda backend `force_update` ni yoqsa: majburiy dialog qayta ishga tushirmasdan chiqadi.
- [ ] `store_url` bo‘sh bo‘lsa dialog chiqadi, lekin yangilash tugmasi hech narsa qilmaydi.
- [ ] Build e’lon qilingan versiyaga yangilansa: dialog chiqmaydi.
- [ ] `GET app-version/` ishga tushishda yoki fondan qaytganda 5xx javob bersa: texnik ishlar ekrani («Texnik ishlar olib borilmoqda») barcha ekranlarni yopadi — kirish ekrani, har bir rolning ekranlari, ochilgan sahifalar, sheet va dialoglar. «Dispetcher bilan bog‘lanish» dispetcher sheet'ini ekran USTIDA ochadi (ekranning o‘z navigatori bor, shuning uchun sheet ko‘rinadi), uni yopish tugmasi / pastga tortish yopadi. «Qayta urinish» qayta so‘ralayotganda spinner ko‘rsatadi; endpoint normal javob bersa ekran yo‘qoladi va ostidagi ilova avvalgidek turadi.
- [ ] Ekran ochiq paytda qayta urinish yana 5xx bersa ekran qoladi; oflayn xato bersa ham qoladi (xato bilan ekran hech qachon yopilmaydi).

## 3. UI testi

- [ ] 320 px (kichik telefon) va 768 px (planshet) kenglikda toshib ketish yoki kesilish yo‘q; uzun versiya satrlari va tarjima qilingan matn ko‘p nuqta bilan qisqaradi.
- [ ] Dialog yorug‘ va qorong‘i mavzuda to‘g‘ri ko‘rinadi.
- [ ] Texnik ishlar ekrani `4.1 Texnik ishlar olib borilmoqda` maketiga mos: 84 px yashil yumaloq-kvadrat ortida 168 px ikki qatlamli yashil halo, kalit belgisi, 22 px sarlavha, 15 px matn (eng ko‘pi 300 px) va pastdan 36 px yuqorida, bir-biridan 8 px masofada ikkita to‘liq enli tugma: yashil «Qayta urinish» va chegarali «Dispetcher bilan bog‘lanish» (quloqchin belgisi), yorug‘ va qorong‘i mavzuda.
- [ ] O‘zbek lotin, o‘zbek kirill va rus tillari kalitlarsiz, maket buzilmasdan chiqadi.
- [ ] Ixtiyoriy yangilanish dialogi `showUpdateDialog` (`lib/helpers/update_dialog.dart`) va platformaga mos ko‘rinadi: iOS da xira shaffof alert (markazdagi sarlavha va matn, “Keyinroq” / “Yangilash” yonma-yon, ingichka chiziq bilan ajratilgan, “Yangilash” qalin); Android da Material 3 dialog (yashil yangilash belgisi, 24 px markazdagi sarlavha, chapga tekislangan matn, o‘ngdagi matnli tugmalar). Ikkalasi ham ekran eniga chap va o‘ngdan 24 px bo‘sh joy qoldirib cho‘ziladi va `Update dialog` maketiga yorug‘ va qorong‘i mavzuda mos; “Keyinroq” yoki “Yangilash” bosilganda ikkala platformada ham standart ink splash/highlight (Material ning o‘z rangi, yashil emas) ko‘rinadi; uzun matn toshmaydi, aylantiriladi. `force_update` true bo‘lsa faqat «Yangilash» ko‘rsatiladi: iOS da tugmalar qatorini to‘liq egallaydi, Android da o‘ngda yolg‘iz turadi.
