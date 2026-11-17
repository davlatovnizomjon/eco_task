from django.urls import include, path

urlpatterns = [
    path("auth/", include("apps.accounts.auth_urls")),
    path("users/", include("apps.accounts.urls")),
    path("projects/", include("apps.projects.urls")),
    path("tasks/", include("apps.tasks.urls")),
    path("files/", include("apps.files.urls")),
    path("reports/", include("apps.reports.urls")),
    path("requests/", include("apps.client_requests.urls")),
    path("calls/", include("apps.chat.call_urls")),
    path("conversations/", include("apps.chat.urls")),
    path("notifications/", include("apps.notifications.urls")),
    path("audit/", include("apps.audit.urls")),
    path("app-version/", include("apps.releases.urls")),
    path("legal/", include("apps.legal.urls")),
    path("support/", include("apps.support.urls")),
]
