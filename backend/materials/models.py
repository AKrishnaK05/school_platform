from django.db import models
from academics.models import ClassSection, Subject
from accounts.models import TeacherProfile


class TimetableEntry(models.Model):
    class_section = models.ForeignKey(ClassSection, on_delete=models.CASCADE)

    day_of_week = models.CharField(
        max_length=10,
        choices=[
            ("MON", "Monday"),
            ("TUE", "Tuesday"),
            ("WED", "Wednesday"),
            ("THU", "Thursday"),
            ("FRI", "Friday"),
            ("SAT", "Saturday"),
        ]
    )

    period_number = models.IntegerField()

    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    teacher = models.ForeignKey(TeacherProfile, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.class_section} {self.day_of_week} P{self.period_number}"


class StudyMaterial(models.Model):
    title = models.CharField(max_length=200)
    file = models.FileField(upload_to="materials/")

    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    class_section = models.ForeignKey(ClassSection, on_delete=models.CASCADE)

    uploaded_by = models.ForeignKey(TeacherProfile, on_delete=models.CASCADE)
    uploaded_at = models.DateTimeField(auto_now_add=True)
