from django.contrib.admin.apps import AdminConfig


class EcoAdminConfig(AdminConfig):
    """Replaces `django.contrib.admin` so `admin.site` is our policy-gated site."""

    default_site = "apps.core.admin_site.EcoAdminSite"
