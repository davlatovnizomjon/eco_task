# Chat ma’lumoti (xodim)

AI bajarishi uchun reja; foydalanuvchi so‘ramaguncha bu yerda hech narsa ishga tushirilmaydi.

## 1. API Test

### `ChatRepository.getConversation` — GET `conversations/{id}`; `updateConversation` — PATCH; `removeMember` — DELETE `conversations/{id}/members/{me}/`

- [ ] Muvaffaqiyat: rollari bilan a’zolar, `muted`; PATCH `{muted}` faqat chaqiruvchining kalitini almashtiradi.
- [ ] Auth xatosi: 401 → `UnAuthorizedResponse`; begona id → 404.
- [ ] Guruhdan chiqish: 204; keyin guruh ro‘yxatdan yo‘qoladi va uning socketi bekor qilinadi.

## 2. Mobil/Web integratsiya testi

- [ ] `AppConfig.useMockData = true` bilan va jonli API bilan ishga tushiring; tortib yangilang; xatodan keyin qayta urining.

## 3. UI test

- [ ] 3.4 ma’lumot, 3.5 profil, 3.5 ovozsiz taxtalar: shaxsiy suhbat 96 px avatar, ism, “Xabar” va “Ovozsiz / Ovozni yoqish” tugmalari, telefon, rol va faol vazifalarni ko‘rsatadi; ovozsiz suhbatda “Bildirishnomalar o‘chirildi” chiqadi; guruh plitka, “N a’zo”, rol belgili a’zolar, qalam (faqat xodim uchun) va tasdiqlash dialogli qizil “Guruhdan chiqish” qatorini ko‘rsatadi.
- [ ] 320 px va 768 px da toshish yo‘q; yorug‘ va qorong‘i mavzular; uz, uz-Cyrl va ru yetishmayotgan kalitlarsiz.

## 4. Mantiqiy/biznes test

- [ ] Ovozsiz qilish shu suhbat yangi xabarlari uchun inbox bildirishnomalarini faqat chaqiruvchi uchun to‘xtatadi.
- [ ] Chiqqandan keyin router bosh sahifaga o‘tadi va guruh ro‘yxatda ko‘rinmaydi.
