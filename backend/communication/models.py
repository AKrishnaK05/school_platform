from django.db import models
from accounts.models import User
from academics.models import ClassSection


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

