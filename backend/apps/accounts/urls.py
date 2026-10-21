from django.urls import path

from .views import UserDetail, UserListCreate

urlpatterns = [path("", UserListCreate.as_view()), path("<int:pk>/", UserDetail.as_view())]
