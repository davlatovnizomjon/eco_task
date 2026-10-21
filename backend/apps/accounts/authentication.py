from django.utils import timezone
from rest_framework import authentication, exceptions

from .models import AuthToken, hash_token

# Same message for every failure so responses never reveal why a token was refused.
_INVALID = "Invalid or expired credentials."


def user_for_raw_token(raw: str):
    """Resolve a raw bearer token to an active user, or None. Shared by HTTP and WebSocket auth."""
    token = AuthToken.objects.select_related("user").filter(key_hash=hash_token(raw)).first()
    if token is None or not token.is_valid or not token.user.is_active:
        return None
    AuthToken.objects.filter(pk=token.pk).update(last_used_at=timezone.now())
    return token.user


class BearerTokenAuthentication(authentication.BaseAuthentication):
    keyword = "Bearer"

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).split()
        if not header or header[0].lower() != self.keyword.lower().encode():
            return None
        if len(header) != 2:
            raise exceptions.AuthenticationFailed(_INVALID)
        user = user_for_raw_token(header[1].decode(errors="ignore"))
        if user is None:
            raise exceptions.AuthenticationFailed(_INVALID)
        return user, None

    def authenticate_header(self, request):
        return self.keyword
