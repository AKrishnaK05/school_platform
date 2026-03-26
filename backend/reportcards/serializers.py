from rest_framework import serializers

from .models import ReportCard


class ReportCardSerializer(serializers.ModelSerializer):
    exam = serializers.StringRelatedField()

    class Meta:
        model = ReportCard
        fields = [
            "id",
            "exam",
            "total",
            "percentage",
            "grade",
            "remarks",
            "is_published",
            "published_on",
            "pdf_file",
            "generated_on",
        ]
