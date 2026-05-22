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
    photo = models.ImageField(upload_to="students/", blank=True, null=True)

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


class ClassTeacher(models.Model):
    """Designates a teacher as the class teacher for a class section."""
    teacher = models.ForeignKey(
        "accounts.TeacherProfile",
        on_delete=models.CASCADE
    )
    class_section = models.OneToOneField(ClassSection, on_delete=models.CASCADE, related_name="class_teacher")

    def __str__(self):
        return f"{self.teacher} - Class Teacher of {self.class_section}"


class Timetable(models.Model):
    """Stores class timetable information."""
    DAYS_OF_WEEK = [
        ("MONDAY", "Monday"),
        ("TUESDAY", "Tuesday"),
        ("WEDNESDAY", "Wednesday"),
        ("THURSDAY", "Thursday"),
        ("FRIDAY", "Friday"),
        ("SATURDAY", "Saturday"),
    ]

    class_section = models.ForeignKey(ClassSection, on_delete=models.CASCADE, related_name="timetables")
    day = models.CharField(max_length=10, choices=DAYS_OF_WEEK)
    period = models.IntegerField(help_text="Period number (1, 2, 3, etc.)")
    subject = models.ForeignKey(Subject, on_delete=models.SET_NULL, null=True, blank=True)
    teacher = models.ForeignKey(
        "accounts.TeacherProfile",
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    start_time = models.TimeField()
    end_time = models.TimeField()

    class Meta:
        unique_together = ("class_section", "day", "period")
        ordering = ("day", "period")

    def __str__(self):
        return f"{self.class_section} - {self.day} Period {self.period}"


class FeeInvoice(models.Model):
    STATUS_PENDING = "PENDING"
    STATUS_PARTIAL = "PARTIAL"
    STATUS_PAID = "PAID"

    STATUS_CHOICES = [
        (STATUS_PENDING, "Pending"),
        (STATUS_PARTIAL, "Partial"),
        (STATUS_PAID, "Paid"),
    ]

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="fee_invoices")
    source_plan = models.ForeignKey(
        "FeePlan",
        on_delete=models.SET_NULL,
        related_name="generated_invoices",
        null=True,
        blank=True,
    )
    title = models.CharField(max_length=150)
    billing_month = models.DateField(null=True, blank=True)
    due_date = models.DateField()
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    paid_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_PENDING)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("due_date", "-id")

    def __str__(self):
        return f"{self.student.full_name} - {self.title}"


class FeePayment(models.Model):
    invoice = models.ForeignKey(FeeInvoice, on_delete=models.CASCADE, related_name="payments")
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment_method = models.CharField(max_length=40, default="UPI")
    reference_id = models.CharField(max_length=80, unique=True)
    paid_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-paid_at",)

    def __str__(self):
        return f"{self.reference_id} - {self.amount}"


class FeePlan(models.Model):
    class_section = models.ForeignKey(ClassSection, on_delete=models.CASCADE, related_name="fee_plans")
    title = models.CharField(max_length=150)
    monthly_amount = models.DecimalField(max_digits=10, decimal_places=2)
    due_day = models.PositiveSmallIntegerField(default=10)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("class_section", "title")
        ordering = ("class_section", "title")

    def __str__(self):
        return f"{self.class_section} - {self.title}"


class FeeNotification(models.Model):
    TYPE_DUE_SOON = "DUE_SOON"
    TYPE_OVERDUE = "OVERDUE"

    TYPE_CHOICES = [
        (TYPE_DUE_SOON, "Due Soon"),
        (TYPE_OVERDUE, "Overdue"),
    ]

    parent = models.ForeignKey("accounts.ParentProfile", on_delete=models.CASCADE, related_name="fee_notifications")
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="fee_notifications")
    invoice = models.ForeignKey(FeeInvoice, on_delete=models.CASCADE, related_name="notifications")
    notification_type = models.CharField(max_length=12, choices=TYPE_CHOICES)
    title = models.CharField(max_length=200)
    body = models.TextField()
    notified_for_date = models.DateField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("parent", "invoice", "notification_type", "notified_for_date")
        ordering = ("-created_at",)

    def __str__(self):
        return f"{self.parent.full_name} - {self.title}"


class Assignment(models.Model):
    STATUS_PENDING = "PENDING"
    STATUS_SUBMITTED = "SUBMITTED"
    STATUS_OVERDUE = "OVERDUE"

    STATUS_CHOICES = [
        (STATUS_PENDING, "Pending"),
        (STATUS_SUBMITTED, "Submitted"),
        (STATUS_OVERDUE, "Overdue"),
    ]

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name="assignments")
    subject = models.ForeignKey(Subject, on_delete=models.SET_NULL, null=True, blank=True)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    due_date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default=STATUS_PENDING)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("due_date", "-id")

    def __str__(self):
        return f"{self.student.full_name} - {self.title}"
