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

    class Meta:
        unique_together = ("student", "parent", "teacher")

    def __str__(self):
        return f"{self.student.full_name} Thread"


class ConversationGroup(models.Model):
    teacher = models.ForeignKey(
        TeacherProfile,
        on_delete=models.CASCADE,
        related_name="conversation_groups",
    )
    name = models.CharField(max_length=100)
    threads = models.ManyToManyField(
        ConversationThread,
        related_name="conversation_groups",
        blank=True,
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["teacher", "name"],
                name="uniq_conversation_group_teacher_name",
            )
        ]

    def __str__(self):
        return f"{self.name} ({self.teacher.full_name})"


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


class ChatRoom(models.Model):
    name = models.CharField(max_length=200, blank=True)
    is_group = models.BooleanField(default=False)

    student = models.ForeignKey(
        Student,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    class_section = models.ForeignKey(
        ClassSection,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )
    direct_teacher = models.ForeignKey(
        TeacherProfile,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
    )

    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="created_chat_rooms",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["student", "direct_teacher", "is_group"],
                name="uniq_direct_room_student_teacher",
            ),
            models.UniqueConstraint(
                fields=["class_section", "name", "is_group"],
                name="uniq_group_room_class_name",
            ),
        ]

    def __str__(self):
        return self.name or f"Room {self.id}"


class ChatRoomMember(models.Model):
    room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name="memberships",
    )
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("room", "user")


class ChatRoomMessage(models.Model):
    room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name="messages",
    )
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.room_id} - {self.sender_id}"

