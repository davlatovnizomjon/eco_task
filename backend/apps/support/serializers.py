from rest_framework import serializers

from .models import SupportContact


class SupportContactSerializer(serializers.ModelSerializer):
    """Dispatcher phone and Telegram username, exactly as the admin entered the phone."""

    telegram = serializers.SerializerMethodField()

    class Meta:
        model = SupportContact
        fields = ["phone", "telegram"]
        read_only_fields = fields

    def get_telegram(self, obj: SupportContact) -> str:
        return "@" + obj.telegram.lstrip("@")
