from django.urls import path

from . import views

urlpatterns = [
    path("", views.RequestList.as_view()),
    path("<int:pk>/", views.RequestDetail.as_view()),
    path("<int:pk>/messages/", views.RequestMessages.as_view()),
]
