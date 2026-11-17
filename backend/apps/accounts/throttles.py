import hashlib

from rest_framework.throttling import SimpleRateThrottle


class LoginThrottle(SimpleRateThrottle):
    """Limits attempts per (client address, username) so one attacker cannot lock a victim out for everyone.

    The address comes from REMOTE_ADDR only; `X-Forwarded-For` is not trusted unless the proxy layer rewrites it.
    """

    scope = "login"

    def get_cache_key(self, request, view):
        username = str(request.data.get("username", "")).lower()[:150]
        ident = hashlib.sha256(f"{self.get_ident(request)}|{username}".encode()).hexdigest()
        return self.cache_format % {"scope": self.scope, "ident": ident}


class RefreshThrottle(SimpleRateThrottle):
    """Limits refresh attempts per client address so refresh tokens cannot be guessed at speed."""

    scope = "refresh"

    def get_cache_key(self, request, view):
        return self.cache_format % {"scope": self.scope, "ident": self.get_ident(request)}
