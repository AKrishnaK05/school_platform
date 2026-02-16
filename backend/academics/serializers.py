from rest_framework import serializers
from .models import Attendance, Student, Marks


class AttendanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Attendance
        fields = ["date", "status", "reason"]


class MarksSerializer(serializers.ModelSerializer):
    subject = serializers.StringRelatedField()
    exam = serializers.StringRelatedField()

    class Meta:
        model = Marks
        fields = ["subject", "exam", "score"]
