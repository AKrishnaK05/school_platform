from django.db import models
from django.conf import settings
from accounts.models import User
from academics.models import ClassSection
from accounts.models import TeacherProfile, ParentProfile
from academics.models import Student


class Announcement(models.Model):
    title = models.CharField(max_length=200)
    body = models.TextField()

    created_by = models.ForeignKey(User, on_delete=models.CASCADE)

    target_class = models.ForeignKey(
        ClassSection,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title


class ConversationThread(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    parent = models.ForeignKey(ParentProfile, on_delete=models.CASCADE)
    teacher = models.ForeignKey(TeacherProfile, on_delete=models.CASCADE)

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.student.full_name} Thread"


class Message(models.Model):
    thread = models.ForeignKey(
        ConversationThread,
        on_delete=models.CASCADE,
        related_name="messages"
    )

    sender = models.ForeignKey(settings.AUTH_USER_MODEL,
                               on_delete=models.CASCADE)

    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Message by {self.sender}"

