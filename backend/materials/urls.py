from django.urls import path
from .views import study_materials, timetable_by_class

urlpatterns = [
    path("timetable/<int:class_id>/", timetable_by_class),
    path("materials/", study_materials),
]
