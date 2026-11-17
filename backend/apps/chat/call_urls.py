from django.urls import path

from . import call_views as v

urlpatterns = [
    path("<int:pk>/", v.CallDetail.as_view()),
    path("<int:pk>/answer/", v.CallAnswer.as_view()),
    path("<int:pk>/decline/", v.CallDecline.as_view()),
    path("<int:pk>/end/", v.CallEnd.as_view()),
    path("<int:pk>/invite/", v.CallInvite.as_view()),
]
