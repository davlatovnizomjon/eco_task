"""The UI language a client asks for in the `Accept-Language` header."""

UZ, UZ_CYRL, RU = "uz", "uz-Cyrl", "ru"


def requested_language(request) -> str:
    """`uz`, `uz-Cyrl` or `ru` from the header (`ru-RU,ru;q=0.9`, `uz_cyrl`...); Uzbek when absent or unknown."""
    first = request.headers.get("Accept-Language", "").split(",")[0].split(";")[0].strip().lower().replace("_", "-")
    if first.startswith("uz") and "cyrl" in first:
        return UZ_CYRL
    if first.startswith("ru"):
        return RU
    return UZ
