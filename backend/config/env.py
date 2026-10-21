"""Tiny typed accessors for environment variables (no extra dependency)."""

import os

from django.core.exceptions import ImproperlyConfigured

_TRUE = {"1", "true", "yes", "on"}


def get(name: str, default: str | None = None) -> str:
    value = os.environ.get(name, default)
    if value is None:
        raise ImproperlyConfigured(f"Environment variable {name} is required.")
    return value


def boolean(name: str, default: bool = False) -> bool:
    return os.environ.get(name, str(default)).strip().lower() in _TRUE


def integer(name: str, default: int) -> int:
    return int(os.environ.get(name, default))


def csv(name: str, default: str = "") -> list[str]:
    return [item.strip() for item in os.environ.get(name, default).split(",") if item.strip()]
