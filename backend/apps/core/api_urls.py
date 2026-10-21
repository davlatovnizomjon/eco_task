from django.urls import include, path

urlpatterns = [
    path("auth/", include("apps.accounts.auth_urls")),
    path("users/", include("apps.accounts.urls")),
    path("projects/", include("apps.projects.urls")),
    path("tasks/", include("apps.tasks.urls")),
    path("requests/", include("apps.client_requests.urls")),
    path("conversations/", include("apps.chat.urls")),
    path("notifications/", include("apps.notifications.urls")),
    path("audit/", include("apps.audit.urls")),
]
