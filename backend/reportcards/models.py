from django.db import models
from academics.models import Student, Exam


class ReportCard(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    exam = models.ForeignKey(Exam, on_delete=models.CASCADE)

    pdf_file = models.FileField(upload_to="reportcards/", blank=True, null=True)

    generated_on = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.student.full_name} - {self.exam.name}"

