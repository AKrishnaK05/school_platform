from django.db import models
from academics.models import Student, Exam


class ReportCard(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    exam = models.ForeignKey(Exam, on_delete=models.CASCADE)

    total = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    percentage = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    grade = models.CharField(max_length=5, blank=True)
    remarks = models.TextField(blank=True)
    is_published = models.BooleanField(default=False)
    published_on = models.DateTimeField(blank=True, null=True)

    pdf_file = models.FileField(upload_to="reportcards/", blank=True, null=True)

    generated_on = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.student.full_name} - {self.exam.name}"

