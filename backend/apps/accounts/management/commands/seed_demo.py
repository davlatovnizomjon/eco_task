"""Create the four demo accounts the Flutter app's docs talk about. Development only; never runs with DEBUG off."""

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from apps.accounts.models import User
from apps.core.policies import Role

DEMO_PASSWORD = "Demo-Passphrase-2026"  # noqa: S105 (documented dev-only credential)
ACCOUNTS = [
    ("jamshid", "Jamshid Aliyev", Role.OWNER),
    ("malika", "Malika Tosheva", Role.ASSISTANT),
    ("boris", "Boris Ivanov", Role.WORKER),
    ("gulnora", "Gulnora Karimova", Role.CLIENT),
]


class Command(BaseCommand):
    help = "Create demo accounts (jamshid/malika/boris/gulnora) for local development. Idempotent."

    def handle(self, *args, **options):
        if not settings.DEBUG:
            raise CommandError("seed_demo refuses to run with DEBUG off (it creates well-known credentials).")
        for username, full_name, role in ACCOUNTS:
            user, created = User.objects.get_or_create(
                username=username, defaults={"full_name": full_name, "role": role.value}
            )
            if created:
                user.set_password(DEMO_PASSWORD)
                user.save()
            self.stdout.write(f"{'created' if created else 'exists '} {username} ({role.value})")
        self.stdout.write(self.style.SUCCESS(f"Demo password for new accounts: {DEMO_PASSWORD}"))
