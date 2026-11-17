from django.urls import path

from . import views

urlpatterns = [
    path("", views.FileUpload.as_view()),
    path("<int:pk>/", views.FileDownload.as_view()),
]
