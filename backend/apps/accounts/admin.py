from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from apps.core.admin_site import PolicyAdmin, ReadOnlyAdmin

from .models import AuthToken, User


@admin.register(User)
class UserAdmin(PolicyAdmin, BaseUserAdmin):
    list_display = ("username", "full_name", "role", "phone", "is_active", "last_login")
    list_filter = ("role", "is_active")
    search_fields = ("username", "full_name", "email", "phone")
    ordering = ("username",)
    filter_horizontal = ()
    fieldsets = (
        (None, {"fields": ("username", "password")}),
        ("Profile", {"fields": ("full_name", "email", "phone")}),
        ("Access", {"fields": ("role", "is_active")}),
        ("Dates", {"fields": ("last_login", "date_joined", "created_at")}),
    )
    add_fieldsets = (
        (
            None,
            {"classes": ("wide",), "fields": ("username", "role", "full_name", "email", "phone", "password1", "password2")},
        ),
    )
    readonly_fields = ("last_login", "date_joined", "created_at")

    def get_readonly_fields(self, request, obj=None):
        fields = super().get_readonly_fields(request, obj)
        # Nobody can demote or lock out their own account by accident.
        if obj is not None and obj.pk == request.user.pk:
            return (*fields, "role", "is_active")
        return fields


@admin.register(AuthToken)
class AuthTokenAdmin(ReadOnlyAdmin):
    list_display = ("id", "user", "created_at", "expires_at", "revoked_at", "last_used_at")
    list_filter = ("revoked_at",)
    search_fields = ("user__username",)
    exclude = ("key_hash",)  # only a digest is stored, but there is no reason to display it
