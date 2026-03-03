from rest_framework import serializers
from .models import StudyMaterial, TimetableEntry


class TimetableSerializer(serializers.ModelSerializer):
    day_of_week = serializers.CharField(source="get_day_of_week_display", read_only=True)
    subject = serializers.StringRelatedField()
    teacher = serializers.StringRelatedField()
    class_section = serializers.StringRelatedField()

    class Meta:
        model = TimetableEntry
        fields = [
            "day_of_week",
            "period_number",
            "subject",
            "teacher",
            "class_section",
        ]


class StudyMaterialSerializer(serializers.ModelSerializer):
    subject = serializers.StringRelatedField()
    class_section = serializers.StringRelatedField()
    uploaded_by = serializers.StringRelatedField()

    class Meta:
        model = StudyMaterial
        fields = [
            "id",
            "title",
            "file",
            "subject",
            "class_section",
            "uploaded_by",
            "uploaded_at",
        ]
