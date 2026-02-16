from django.db import models

class School(models.Model):
    name = models.CharField(max_length=200)
    domain = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return self.name

