"""Title and description of the common API errors in the three UI languages, looked up by the error `code`.

Codes that are not listed keep the English sentence the code raised (and have no title). `{minutes}` is filled from
`retry_after`.
"""

Texts = dict[str, tuple[str, str]]  # language -> (title, message)

MESSAGES: dict[str, Texts] = {
    "invalid_credentials": {
        "uz": ("Login yoki parol noto‘g‘ri", "Kiritgan login va parolingizni tekshirib, qayta urinib ko‘ring."),
        "uz-Cyrl": ("Логин ёки парол нотўғри", "Киритган логин ва паролингизни текшириб, қайта уриниб кўринг."),
        "ru": ("Неверный логин или пароль", "Проверьте введённые логин и пароль и попробуйте ещё раз."),
    },
    "login_locked": {
        "uz": (
            "Kirish vaqtincha bloklandi",
            "Juda ko‘p noto‘g‘ri urinish bo‘ldi. {minutes} daqiqadan keyin qayta urinib ko‘ring.",
        ),
        "uz-Cyrl": (
            "Кириш вақтинча блокланди",
            "Жуда кўп нотўғри уриниш бўлди. {minutes} дақиқадан кейин қайта уриниб кўринг.",
        ),
        "ru": ("Вход временно заблокирован", "Слишком много неудачных попыток. Повторите через {minutes} мин."),
    },
    "account_blocked": {
        "uz": ("Hisob bloklangan", "Hisobingiz bloklangan. Dispetcher bilan bog‘laning."),
        "uz-Cyrl": ("Ҳисоб блокланган", "Ҳисобингиз блокланган. Диспетчер билан боғланинг."),
        "ru": ("Аккаунт заблокирован", "Ваш аккаунт заблокирован. Свяжитесь с диспетчером."),
    },
    "invalid_refresh_token": {
        "uz": ("Seans tugagan", "Davom etish uchun qayta kiring."),
        "uz-Cyrl": ("Сеанс тугаган", "Давом этиш учун қайта киринг."),
        "ru": ("Сессия истекла", "Войдите снова, чтобы продолжить."),
    },
    "not_authenticated": {
        "uz": ("Tizimga kirmagansiz", "Davom etish uchun login va parol bilan kiring."),
        "uz-Cyrl": ("Тизимга кирмагансиз", "Давом этиш учун логин ва парол билан киринг."),
        "ru": ("Вы не вошли в систему", "Чтобы продолжить, войдите по логину и паролю."),
    },
    "authentication_failed": {
        "uz": ("Seans tugagan", "Xavfsizlik uchun qayta kiring."),
        "uz-Cyrl": ("Сеанс тугаган", "Хавфсизлик учун қайта киринг."),
        "ru": ("Сессия завершена", "В целях безопасности войдите снова."),
    },
    "permission_denied": {
        "uz": ("Ruxsat yo‘q", "Bu amalni bajarish huquqingiz yo‘q."),
        "uz-Cyrl": ("Рухсат йўқ", "Бу амални бажариш ҳуқуқингиз йўқ."),
        "ru": ("Нет доступа", "У вас нет прав для этого действия."),
    },
    "not_found": {
        "uz": ("Topilmadi", "So‘ralgan ma’lumot mavjud emas yoki o‘chirilgan."),
        "uz-Cyrl": ("Топилмади", "Сўралган маълумот мавжуд эмас ёки ўчирилган."),
        "ru": ("Не найдено", "Запрошенные данные не существуют или удалены."),
    },
    "throttled": {
        "uz": ("So‘rovlar juda ko‘p", "Birozdan keyin qayta urinib ko‘ring."),
        "uz-Cyrl": ("Сўровлар жуда кўп", "Бироздан кейин қайта уриниб кўринг."),
        "ru": ("Слишком много запросов", "Повторите попытку чуть позже."),
    },
}


def localized(code: str, language: str, retry_after: int | None = None) -> tuple[str, str] | None:
    """`(title, message)` of [code] in [language], or None when the code has no translation."""
    texts = MESSAGES.get(code, {}).get(language)
    if texts is None:
        return None
    title, message = texts
    return title, message.format(minutes=-(-(retry_after or 0) // 60))
