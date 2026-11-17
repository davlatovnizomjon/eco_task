from django.urls import path

from .views import AppVersionView

urlpatterns = [path("", AppVersionView.as_view())]
