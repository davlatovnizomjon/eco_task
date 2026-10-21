from django.urls import path

from . import views

urlpatterns = [
    path("contacts/", views.ContactList.as_view()),
    path("", views.ConversationList.as_view()),
    path("<uuid:pk>/", views.ConversationDetail.as_view()),
    path("<uuid:pk>/members/", views.ConversationMembers.as_view()),
    path("<uuid:pk>/members/<int:user_id>/", views.ConversationMember.as_view()),
    path("<uuid:pk>/messages/", views.MessageList.as_view()),
    path("<uuid:pk>/read/", views.ConversationRead.as_view()),
]
