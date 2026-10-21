"""Create the very first OWNER from environment variables. Explicit, idempotent, never resets passwords."""

import hashlib
import os

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.management.base import BaseCommand, CommandError
from django.db import connection, transaction

from apps.accounts.models import User
from apps.audit.services import record
from apps.core.policies import Role

# Values copied verbatim from documentation/.env.example must never become a real credential.
UNSAFE_PASSWORDS = {"change-me", "changeme", "password", "admin", "owner", "change-me-to-a-long-random-passphrase"}
LOCK_KEY = int.from_bytes(hashlib.sha256(b"bootstrap_owner").digest()[:7], "big")


class Command(BaseCommand):
    help = "Create the initial OWNER from INITIAL_OWNER_* environment variables (only when no owner exists)."

    def handle(self, *args, **options):
        username = os.environ.get("INITIAL_OWNER_USERNAME", "").strip()
        email = os.environ.get("INITIAL_OWNER_EMAIL", "").strip()
        password = os.environ.get("INITIAL_OWNER_PASSWORD", "")
        missing = [n for n, v in (("INITIAL_OWNER_USERNAME", username), ("INITIAL_OWNER_PASSWORD", password)) if not v]
        if missing:
            raise CommandError(f"Missing environment variable(s): {', '.join(missing)}.")
        if password.lower() in UNSAFE_PASSWORDS:
            raise CommandError("INITIAL_OWNER_PASSWORD is a known unsafe placeholder. Choose a strong passphrase.")
        candidate = User(username=username, email=email, role=Role.OWNER)
        try:
            validate_password(password, candidate)
        except ValidationError as exc:
            raise CommandError("INITIAL_OWNER_PASSWORD is too weak: " + " ".join(exc.messages)) from None

        with transaction.atomic():
            # Serialise concurrent bootstrap runs (PostgreSQL); SQLite serialises writers by itself.
            if connection.vendor == "postgresql":
                with connection.cursor() as cursor:
                    cursor.execute("SELECT pg_advisory_xact_lock(%s)", [LOCK_KEY])
            if User.objects.filter(role=Role.OWNER).exists():
                self.stdout.write(
                    "An owner already exists; nothing changed. To rotate or recover owner access use "
                    "'python manage.py changepassword <username>' (see docs/SECURITY.md)."
                )
                return
            if User.objects.filter(username__iexact=username).exists():
                raise CommandError("That username is taken by a non-owner account. Choose another username.")
            owner = User(username=username, email=email, role=Role.OWNER, is_active=True)
            owner.set_password(password)
            owner.save()
            record(None, "owner.bootstrapped", owner)
        self.stdout.write(
            self.style.SUCCESS(f"Owner '{username}' created. Remove INITIAL_OWNER_PASSWORD from the environment.")
        )
