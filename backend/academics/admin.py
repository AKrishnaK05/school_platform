from django.contrib import admin
from .models import (
    ClassSection, Student, Attendance,
    Subject, TeacherAssignment,
    Exam, Marks,
    ParentStudentLink, ClassTeacher, Timetable,
    FeeInvoice, FeePayment, FeePlan, FeeNotification,
    Assignment
)

admin.site.register(ClassSection)
admin.site.register(Student)
admin.site.register(Attendance)
admin.site.register(Subject)
admin.site.register(TeacherAssignment)
admin.site.register(Exam)
admin.site.register(Marks)
admin.site.register(ParentStudentLink)
admin.site.register(ClassTeacher)
admin.site.register(Timetable)
admin.site.register(FeeInvoice)
admin.site.register(FeePayment)
admin.site.register(FeePlan)
admin.site.register(FeeNotification)
admin.site.register(Assignment)