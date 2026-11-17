from django.urls import path

from . import call_views, views

urlpatterns = [
    path("contacts/", views.ContactList.as_view()),
    path("", views.ConversationList.as_view()),
    path("<uuid:pk>/", views.ConversationDetail.as_view()),
    path("<uuid:pk>/members/", views.ConversationMembers.as_view()),
    path("<uuid:pk>/members/<int:user_id>/", views.ConversationMember.as_view()),
    path("<uuid:pk>/calls/", call_views.ConversationCalls.as_view()),
    path("<uuid:pk>/pin/", views.ConversationPin.as_view()),
    path("<uuid:pk>/messages/", views.MessageList.as_view()),
    path("<uuid:pk>/messages/<int:message_id>/", views.MessageDetail.as_view()),
    path("<uuid:pk>/messages/<int:message_id>/reaction/", views.MessageReactionView.as_view()),
    path("<uuid:pk>/read/", views.ConversationRead.as_view()),
]
