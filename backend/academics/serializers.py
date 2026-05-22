from rest_framework import serializers
from .models import (
    Attendance,
    Student,
    Marks,
    FeeInvoice,
    FeePayment,
    FeePlan,
    FeeNotification,
    Assignment,
)


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


class FeePaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeePayment
        fields = ["id", "amount", "payment_method", "reference_id", "paid_at"]


class FeeInvoiceSerializer(serializers.ModelSerializer):
    balance_amount = serializers.SerializerMethodField()
    payments = FeePaymentSerializer(many=True, read_only=True)

    class Meta:
        model = FeeInvoice
        fields = [
            "id",
            "title",
            "due_date",
            "total_amount",
            "paid_amount",
            "balance_amount",
            "status",
            "payments",
        ]

    def get_balance_amount(self, obj):
        balance = obj.total_amount - obj.paid_amount
        if balance < 0:
            return 0
        return balance


class FeePlanSerializer(serializers.ModelSerializer):
    class_name = serializers.StringRelatedField(source="class_section", read_only=True)

    class Meta:
        model = FeePlan
        fields = [
            "id",
            "class_section",
            "class_name",
            "title",
            "monthly_amount",
            "due_day",
            "is_active",
        ]


class FeeNotificationSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source="student.full_name", read_only=True)

    class Meta:
        model = FeeNotification
        fields = [
            "id",
            "invoice",
            "student",
            "student_name",
            "notification_type",
            "title",
            "body",
            "notified_for_date",
            "is_read",
            "created_at",
        ]


class AssignmentSerializer(serializers.ModelSerializer):
    subject = serializers.StringRelatedField()

    class Meta:
        model = Assignment
        fields = [
            "id",
            "title",
            "description",
            "subject",
            "due_date",
            "status",
        ]
