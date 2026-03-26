from django.db import models
from django.contrib.auth.models import AbstractUser
from django.contrib.auth.hashers import identify_hasher, make_password
from django.core.exceptions import ValidationError


class User(AbstractUser):
    phone = models.CharField(max_length=15, unique=True, null=True, blank=True)

    def save(self, *args, **kwargs):
        if self.password:
            try:
                identify_hasher(self.password)
            except (ValueError, ValidationError):
                self.password = make_password(self.password)

        super().save(*args, **kwargs)

    def __str__(self):
        return self.username


class Role(models.Model):
    name = models.CharField(max_length=50, unique=True)

    def __str__(self):
        return self.name


class UserRole(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    role = models.ForeignKey(Role, on_delete=models.CASCADE)

    class Meta:
        unique_together = ("user", "role")

class TeacherProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=200)
    photo = models.ImageField(upload_to="teachers/", blank=True, null=True)

    def __str__(self):
        return self.full_name


class ParentProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    full_name = models.CharField(max_length=200)

    def __str__(self):
        return self.full_name

