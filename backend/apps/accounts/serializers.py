from rest_framework import serializers

from apps.core.policies import Role

from .models import User


class UserSerializer(serializers.ModelSerializer):
    """Full view for the owner and for the user themselves. Password hash is never exposed."""

    class Meta:
        model = User
        fields = ["id", "username", "full_name", "phone", "role", "is_active", "created_at"]
        read_only_fields = fields


class UserBriefSerializer(serializers.ModelSerializer):
    """What an assistant (or a conversation member) may see of another person."""

    class Meta:
        model = User
        fields = ["id", "username", "full_name", "role"]
        read_only_fields = fields


class UserCreateSerializer(serializers.Serializer):
    username = serializers.RegexField(r"^[\w.@+-]+$", max_length=150)
    password = serializers.CharField(write_only=True, trim_whitespace=False)
    role = serializers.ChoiceField(choices=[r.value for r in Role])
    full_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    phone = serializers.CharField(max_length=32, required=False, allow_blank=True)

    def validate_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("A user with this username already exists.")
        return value


class UserUpdateSerializer(serializers.Serializer):
    """Explicit writable fields only (no mass assignment)."""

    full_name = serializers.CharField(max_length=150, required=False, allow_blank=True)
    phone = serializers.CharField(max_length=32, required=False, allow_blank=True)
    role = serializers.ChoiceField(choices=[r.value for r in Role], required=False)
    is_active = serializers.BooleanField(required=False)


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=150)
    password = serializers.CharField(trim_whitespace=False, max_length=256)


class PasswordChangeSerializer(serializers.Serializer):
    old_password = serializers.CharField(trim_whitespace=False, max_length=256)
    new_password = serializers.CharField(trim_whitespace=False, max_length=256)


class LoginResponseSerializer(serializers.Serializer):
    token = serializers.CharField()
    user = UserSerializer()


class TokenSerializer(serializers.Serializer):
    token = serializers.CharField()
