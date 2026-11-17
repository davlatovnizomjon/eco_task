from django.urls import path

from . import views

urlpatterns = [
    path("stats/", views.StatsView.as_view()),
    path("export/", views.ExportView.as_view()),
    path("dashboard/", views.DashboardView.as_view()),
]
