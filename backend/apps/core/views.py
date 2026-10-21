from django.db import connection
from django.http import JsonResponse
from django.views import View


class HealthView(View):
    """Liveness: the process answers. Reveals nothing."""

    def get(self, request):
        return JsonResponse({"status": "ok"})


class ReadinessView(View):
    """Readiness: database (and Redis when configured) reachable. Only a boolean is exposed."""

    def get(self, request):
        from django.conf import settings

        ok = True
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
        except Exception:
            ok = False
        if ok and settings.REDIS_URL:
            try:
                from django.core.cache import cache

                cache.set("ready-probe", "1", 5)
                ok = cache.get("ready-probe") == "1"
            except Exception:
                ok = False
        return JsonResponse({"status": "ready" if ok else "unavailable"}, status=200 if ok else 503)
