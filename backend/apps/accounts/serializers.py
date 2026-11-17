from rest_framework import serializers

from apps.core.policies import Role

from .models import AVATAR_URL_VALIDATOR, User


def _avatar_field():
    return serializers.URLField(max_length=500, required=False, allow_blank=True, validators=[AVATAR_URL_VALIDATOR])


class UserSerializer(serializers.ModelSerializer):
    """Full view for the owner and for the user themselves. Password hash is never exposed."""

    class Meta:
        model = User
        fields = [
            "id", "username", "full_name", "phone", "address", "is_org", "contact_person", "note", "avatar_url",
            "role", "is_active", "created_at",
        ]  # fmt: skip
        read_only_fields = fields


class LoginUserSerializer(serializers.ModelSerializer):
    """The account in the sign-in answer: just enough to open the right home screen and greet the person."""

    class Meta:
        model = User
        fields = ["id", "full_name", "role"]
        read_only_fields = fields


class UserBriefSerializer(serializers.ModelSerializer):
    """What an assistant (or a conversation member) may see of another person."""

    class Meta:
        model = User
        fields = ["id", "username", "full_name", "avatar_url", "role"]
        read_only_fields = fields


class UserCreateSerializer(serializers.Serializer):
    username = serializers.RegexField(r"^[\w.@+-]+$", max_length=150)
    password = serializers.CharField(write_only=True, trim_whitespace=False)
    role = serializers.ChoiceField(choices=[r.value for r in Role])
    full_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    phone = serializers.CharField(max_length=32, required=False, allow_blank=True)
    address = serializers.CharField(max_length=300, required=False, allow_blank=True)
    is_org = serializers.BooleanField(required=False)
    contact_person = serializers.CharField(max_length=150, required=False, allow_blank=True)
    note = serializers.CharField(max_length=300, required=False, allow_blank=True)
    avatar_url = _avatar_field()

    def validate_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value


class UserUpdateSerializer(serializers.Serializer):
    """Explicit writable fields only (no mass assignment)."""

    full_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    phone = serializers.CharField(max_length=32, required=False, allow_blank=True)
    address = serializers.CharField(max_length=300, required=False, allow_blank=True)
    is_org = serializers.BooleanField(required=False)
    contact_person = serializers.CharField(max_length=150, required=False, allow_blank=True)
    note = serializers.CharField(max_length=300, required=False, allow_blank=True)
    avatar_url = _avatar_field()
    role = serializers.ChoiceField(choices=[r.value for r in Role], required=False)
    is_active = serializers.BooleanField(required=False)


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(trim_whitespace=False, max_length=256)


class PasswordChangeSerializer(serializers.Serializer):
    old_password = serializers.CharField(trim_whitespace=False, max_length=256)
    new_password = serializers.CharField(trim_whitespace=False, max_length=256)


class RefreshSerializer(serializers.Serializer):
    refresh = serializers.CharField(max_length=256, trim_whitespace=False)


class TokenPairSerializer(serializers.Serializer):
    token = serializers.CharField(help_text="Short-lived access token; send as `Authorization: Bearer <token>`.")
    refresh = serializers.CharField(help_text="Long-lived, single-use token for `POST /auth/refresh/`.")


class LoginResponseSerializer(TokenPairSerializer):
    user = LoginUserSerializer()
