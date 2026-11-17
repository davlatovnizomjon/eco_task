from django.urls import path

from .views import SupportContactView

urlpatterns = [path("", SupportContactView.as_view())]
