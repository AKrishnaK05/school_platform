from django.urls import path

from .views import teacher_login, teacher_dashboard

urlpatterns = [
    path("login/", teacher_login, name="teacher_login"),
    path("dashboard/", teacher_dashboard, name="teacher_dashboard"),
]
