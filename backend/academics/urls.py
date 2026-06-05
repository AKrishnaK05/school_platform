from django.urls import path
from .views import (
    parent_students,
    student_attendance,
    student_marks,
    student_assignments,
    student_profile,
    student_fees,
    pay_student_fee,
    student_fee_summary,
    parent_fee_reminders,
    fee_payment_receipt,
    fee_plans,
    generate_monthly_invoices,
    generate_fee_due_notifications,
    parent_fee_notifications,
    parent_fee_notification_unread_count,
    mark_parent_fee_notifications_read,
)

urlpatterns = [
    path("parent/<int:parent_id>/students/", parent_students),
    path("parent/<int:parent_id>/fee-notifications/", parent_fee_notifications),
    path(
        "parent/<int:parent_id>/fee-notifications/unread-count/",
        parent_fee_notification_unread_count,
    ),
    path(
        "parent/<int:parent_id>/fee-notifications/mark-read/",
        mark_parent_fee_notifications_read,
    ),
    path("fees/plans/", fee_plans),
    path("fees/generate-monthly-invoices/", generate_monthly_invoices),
    path("fees/generate-due-notifications/", generate_fee_due_notifications),
    path("student/<int:student_id>/attendance/", student_attendance),
    path("student/<int:student_id>/marks/", student_marks),
    path("student/<int:student_id>/assignments/", student_assignments),
    path("student/<int:student_id>/profile/", student_profile),
    path("student/<int:student_id>/fees/", student_fees),
    path("student/<int:student_id>/fees/summary/", student_fee_summary),
    path("student/<int:student_id>/fees/<int:invoice_id>/pay/", pay_student_fee),
    path("student/<int:student_id>/fees/payments/<int:payment_id>/receipt/", fee_payment_receipt),
    path("parent/<int:parent_id>/fees/reminders/", parent_fee_reminders),
]
