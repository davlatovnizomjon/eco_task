import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("notifications", "0002_notification_service_request"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="DeviceToken",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("token", models.CharField(max_length=512, unique=True)),
                (
                    "platform",
                    models.CharField(choices=[("ios", "ios"), ("android", "android"), ("web", "web")], max_length=8),
                ),
                ("language", models.CharField(blank=True, max_length=8)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("updated_at", models.DateTimeField(auto_now=True)),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="device_tokens",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                "indexes": [models.Index(fields=["user"], name="notificatio_user_id_5c1d0e_idx")],
                "constraints": [
                    models.CheckConstraint(
                        condition=models.Q(("platform__in", ["ios", "android", "web"])), name="device_platform_valid"
                    )
                ],
            },
        ),
    ]
