from django.urls import path

from .views import reportcard_pdf, student_reportcards

urlpatterns = [
    path("student/<int:student_id>/reportcards/", student_reportcards),
    path("reportcards/<int:reportcard_id>/pdf/", reportcard_pdf),
]
