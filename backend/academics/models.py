from django.db import models

class ClassSection(models.Model):
    class_name = models.CharField(max_length=10)
    section = models.CharField(max_length=5)

    def __str__(self):
        return f"{self.class_name}{self.section}"


class Student(models.Model):
    full_name = models.CharField(max_length=200)
    roll_no = models.CharField(max_length=20)
    class_section = models.ForeignKey(ClassSection, on_delete=models.CASCADE)

    def __str__(self):
        return self.full_name


class Attendance(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    date = models.DateField()
    status = models.CharField(max_length=10, choices=[
        ("PRESENT", "Present"),
        ("ABSENT", "Absent")
    ])
    reason = models.CharField(max_length=200, blank=True)

    class Meta:
        unique_together = ("student", "date")


class ParentStudentLink(models.Model):
    parent = models.ForeignKey(
        "accounts.ParentProfile",
        on_delete=models.CASCADE
    )
    student = models.ForeignKey(Student, on_delete=models.CASCADE)

    relationship = models.CharField(
        max_length=20,
        choices=[
            ("FATHER", "Father"),
            ("MOTHER", "Mother"),
            ("GUARDIAN", "Guardian"),
        ]
    )

    class Meta:
        unique_together = ("parent", "student")


class Subject(models.Model):
    name = models.CharField(max_length=100)

    def __str__(self):
        return self.name


class TeacherAssignment(models.Model):
    teacher = models.ForeignKey(
        "accounts.TeacherProfile",
        on_delete=models.CASCADE
    )
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    class_section = models.ForeignKey(ClassSection, on_delete=models.CASCADE)

    class Meta:
        unique_together = ("teacher", "subject", "class_section")


class Exam(models.Model):
    name = models.CharField(max_length=100)
    academic_year = models.CharField(max_length=20)

    def __str__(self):
        return f"{self.name} ({self.academic_year})"


class Marks(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    exam = models.ForeignKey(Exam, on_delete=models.CASCADE)

    score = models.DecimalField(max_digits=5, decimal_places=2)

    uploaded_by = models.ForeignKey(
        "accounts.TeacherProfile",
        on_delete=models.SET_NULL,
        null=True
    )

    class Meta:
        unique_together = ("student", "subject", "exam")
