from django.contrib import admin
from .models import (
    ClassSection, Student, Attendance,
    Subject, TeacherAssignment,
    Exam, Marks,
    ParentStudentLink
)

admin.site.register(ClassSection)
admin.site.register(Student)
admin.site.register(Attendance)
admin.site.register(Subject)
admin.site.register(TeacherAssignment)
admin.site.register(Exam)
admin.site.register(Marks)
admin.site.register(ParentStudentLink)