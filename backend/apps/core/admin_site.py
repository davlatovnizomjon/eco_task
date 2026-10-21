"""Django admin wired to the central role/capability policy instead of `is_staff` / model permissions."""

from django.contrib import admin
from django.contrib.admin.forms import AdminAuthenticationForm
from django.core.exceptions import ValidationError
from django.http import HttpRequest

from apps.audit.services import record

from .policies import Cap, can


class OwnerLoginForm(AdminAuthenticationForm):
    """Admin sign-in for accounts whose role grants `MANAGE_USERS` (the OWNER); everyone else gets the generic error."""

    def confirm_login_allowed(self, user) -> None:
        super(AdminAuthenticationForm, self).confirm_login_allowed(user)  # active-account check only
        if not can(user, Cap.MANAGE_USERS):
            raise ValidationError(self.error_messages["invalid_login"], code="invalid_login", params={"username": ""})


class EcoAdminSite(admin.AdminSite):
    site_header = "Eco Tasks"
    site_title = "Eco Tasks admin"
    index_title = "Administration"
    login_form = OwnerLoginForm

    def has_permission(self, request: HttpRequest) -> bool:
        return can(request.user, Cap.MANAGE_USERS)


class PolicyAdmin(admin.ModelAdmin):
    """Base of every model admin: access comes from `can(user, cap)`, and every change is written to the audit log."""

    cap: Cap = Cap.MANAGE_USERS
    allow_add = True
    allow_change = True
    allow_delete = False  # history must survive; deactivate instead of deleting

    def has_module_permission(self, request) -> bool:
        return can(request.user, self.cap)

    def has_view_permission(self, request, obj=None) -> bool:
        return can(request.user, self.cap)

    def has_add_permission(self, request) -> bool:
        return self.allow_add and can(request.user, self.cap)

    def has_change_permission(self, request, obj=None) -> bool:
        return self.allow_change and can(request.user, self.cap)

    def has_delete_permission(self, request, obj=None) -> bool:
        return self.allow_delete and can(request.user, self.cap)

    def save_model(self, request, obj, form, change) -> None:
        super().save_model(request, obj, form, change)
        # Field names only: values may be secrets (password hashes) or personal data.
        fields = sorted(form.changed_data) if change else []
        record(request.user, f"admin.{obj._meta.model_name}.{'changed' if change else 'created'}", obj, fields=fields)

    def delete_model(self, request, obj) -> None:
        record(request.user, f"admin.{obj._meta.model_name}.deleted", obj)
        super().delete_model(request, obj)


class ReadOnlyAdmin(PolicyAdmin):
    """Browse-only: rows are written by services (or are append-only), never by hand."""

    allow_add = False
    allow_change = False


class ReadOnlyInline(admin.TabularInline):
    """Child rows shown on a parent's page without being editable."""

    extra = 0
    can_delete = False

    def has_add_permission(self, request, obj=None) -> bool:
        return False

    def has_change_permission(self, request, obj=None) -> bool:
        return False

    def has_delete_permission(self, request, obj=None) -> bool:
        return False
