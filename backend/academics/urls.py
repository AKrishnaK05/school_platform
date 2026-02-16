from django.urls import path
from .views import parent_students, student_attendance, student_marks

urlpatterns = [
    path("parent/<int:parent_id>/students/", parent_students),
    path("student/<int:student_id>/attendance/", student_attendance),
    path("student/<int:student_id>/marks/", student_marks),
]
