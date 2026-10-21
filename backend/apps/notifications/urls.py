from django.urls import path

from . import views

urlpatterns = [
    path("", views.NotificationList.as_view()),
    path("unread-count/", views.UnreadCount.as_view()),
    path("read/", views.MarkRead.as_view()),
]
