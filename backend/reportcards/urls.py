from django.urls import path

from .views import student_reportcards

urlpatterns = [
    path("student/<int:student_id>/reportcards/", student_reportcards),
]
