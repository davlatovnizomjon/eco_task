from django.urls import path

from .views import PrivacyView, TermsView

urlpatterns = [
    path("terms/", TermsView.as_view()),
    path("privacy/", PrivacyView.as_view()),
]
