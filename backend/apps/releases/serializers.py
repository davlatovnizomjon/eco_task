from rest_framework import serializers

from .models import AppRelease, Platform


class AppVersionQuerySerializer(serializers.Serializer):
    platform = serializers.ChoiceField(choices=Platform.choices)


class AppVersionSerializer(serializers.ModelSerializer):
    """What the app needs to decide between "nothing", "dialog" and "blocking screen"."""

    class Meta:
        model = AppRelease
        fields = ["platform", "latest_version", "force_update", "is_maintenance", "store_url", "title", "subtitle"]
        read_only_fields = fields
