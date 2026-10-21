from django.urls import path

from . import views

urlpatterns = [
    path("", views.TaskList.as_view()),
    path("<uuid:pk>/", views.TaskDetail.as_view()),
    path("<uuid:pk>/transition/", views.TaskTransition.as_view()),
    path("<uuid:pk>/assignees/", views.TaskAssignees.as_view()),
    path("<uuid:pk>/history/", views.TaskHistoryList.as_view()),
    path("<uuid:pk>/comments/", views.TaskComments.as_view()),
]
