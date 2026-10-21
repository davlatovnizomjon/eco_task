from django.conf import settings
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.core.views import HealthView, ReadinessView

urlpatterns = [
    path("health/", HealthView.as_view()),
    path("ready/", ReadinessView.as_view()),
    path("api/v1/", include("apps.core.api_urls")),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema")),
    path(settings.ADMIN_URL, admin.site.urls),
]
