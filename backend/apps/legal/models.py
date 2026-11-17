from django.db import models


class DocumentKind(models.TextChoices):
    TERMS = "terms"
    PRIVACY = "privacy"


class Language(models.TextChoices):
    UZ = "uz"
    UZ_CYRL = "uz-Cyrl"
    RU = "ru"


class LegalDocument(models.Model):
    """One published legal text (terms of use or privacy policy) in one language, edited in the admin."""

    kind = models.CharField(max_length=16, choices=DocumentKind.choices)
    language = models.CharField(max_length=8, choices=Language.choices, default=Language.UZ)
    title = models.CharField(max_length=200)
    message = models.TextField()
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["kind", "language"], name="legal_document_kind_language_unique"),
            models.CheckConstraint(condition=models.Q(kind__in=DocumentKind.values), name="legal_kind_valid"),
            models.CheckConstraint(condition=models.Q(language__in=Language.values), name="legal_language_valid"),
        ]

    def __str__(self) -> str:
        return f"{self.kind} ({self.language})"
