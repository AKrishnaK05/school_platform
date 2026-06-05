from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from django.db.models import Q
from decimal import Decimal, InvalidOperation
from django.utils import timezone
from datetime import timedelta
from io import BytesIO
from django.http import HttpResponse
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from .models import (
    Student,
    Attendance,
    Marks,
    ParentStudentLink,
    ClassTeacher,
    FeeInvoice,
    FeePayment,
    FeePlan,
    FeeNotification,
    Assignment,
)
from .serializers import (
    AttendanceSerializer,
    MarksSerializer,
    FeeInvoiceSerializer,
    FeePlanSerializer,
    FeeNotificationSerializer,
    AssignmentSerializer,
)


@api_view(["GET"])
def parent_students(request, parent_id):
    links = ParentStudentLink.objects.filter(parent_id=parent_id)
    students = [link.student for link in links]

    data = [_student_payload(s, parent_id=parent_id) for s in students]
    return Response(data)


def _student_payload(student, parent_id=None):
    parent_link = None
    if parent_id is not None:
        parent_link = ParentStudentLink.objects.filter(parent_id=parent_id, student=student).select_related("parent").first()
    else:
        parent_link = ParentStudentLink.objects.filter(student=student).select_related("parent").first()

    class_teacher = ClassTeacher.objects.filter(class_section=student.class_section).select_related("teacher").first()
    parent_profile = parent_link.parent if parent_link else None
    user_phone = parent_profile.user.phone if parent_profile and parent_profile.user.phone else ""
    emergency_name = student.emergency_contact_name or (parent_profile.full_name if parent_profile else "")
    emergency_phone = student.emergency_contact_phone or user_phone

    return {
        "id": student.id,
        "name": student.full_name,
        "class_id": student.class_section.id,
        "class_name": str(student.class_section),
        "roll_no": student.roll_no,
        "admission_no": student.admission_no,
        "date_of_birth": student.date_of_birth.isoformat() if student.date_of_birth else None,
        "blood_group": student.blood_group,
        "gender": student.gender,
        "address": student.address,
        "image": student.photo.url if student.photo else None,
        "teacher_name": class_teacher.teacher.full_name if class_teacher else "",
        "teacher_photo": class_teacher.teacher.photo.url if class_teacher and class_teacher.teacher.photo else None,
        "parent_name": parent_profile.full_name if parent_profile else "",
        "parent_username": parent_profile.user.username if parent_profile else "",
        "parent_phone": parent_profile.user.phone if parent_profile and parent_profile.user.phone else "",
        "relationship": parent_link.relationship if parent_link else "",
        "emergency_contact_name": emergency_name,
        "emergency_contact_phone": emergency_phone,
        "emergency_contact": " • ".join([part for part in [emergency_name, emergency_phone] if part]),
    }


@api_view(["GET"])
def student_profile(request, student_id):
    student = Student.objects.select_related("class_section").filter(id=student_id).first()
    if student is None:
        return Response({"detail": "Student not found"}, status=status.HTTP_404_NOT_FOUND)

    return Response(_student_payload(student))


@api_view(["GET"])
def student_attendance(request, student_id):
    records = Attendance.objects.filter(student_id=student_id)
    serializer = AttendanceSerializer(records, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def student_marks(request, student_id):
    records = Marks.objects.filter(student_id=student_id)
    serializer = MarksSerializer(records, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def student_assignments(request, student_id):
    records = Assignment.objects.filter(student_id=student_id)
    serializer = AssignmentSerializer(records, many=True)
    return Response(serializer.data)


@api_view(["GET", "POST"])
def fee_plans(request):
    if request.method == "GET":
        plans = FeePlan.objects.select_related("class_section").all()
        serializer = FeePlanSerializer(plans, many=True)
        return Response(serializer.data)

    serializer = FeePlanSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    due_day = serializer.validated_data.get("due_day", 10)
    if due_day < 1 or due_day > 28:
        return Response(
            {"detail": "due_day must be between 1 and 28"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    plan = serializer.save()
    return Response(FeePlanSerializer(plan).data, status=status.HTTP_201_CREATED)


@api_view(["POST"])
def generate_monthly_invoices(request):
    month = request.data.get("month")
    year = request.data.get("year")

    today = timezone.localdate()
    target_month = int(month) if month else today.month
    target_year = int(year) if year else today.year

    if target_month < 1 or target_month > 12:
        return Response(
            {"detail": "month must be between 1 and 12"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    generated = 0
    skipped = 0
    billing_month = today.replace(day=1, month=target_month, year=target_year)

    plans = FeePlan.objects.filter(is_active=True).select_related("class_section")
    for plan in plans:
        students = Student.objects.filter(class_section_id=plan.class_section_id)
        due_date = billing_month.replace(day=plan.due_day)

        for student in students:
            title = f"{plan.title} - {billing_month.strftime('%b %Y')}"

            existing = FeeInvoice.objects.filter(
                student_id=student.id,
                source_plan_id=plan.id,
                billing_month=billing_month,
            ).exists()
            if existing:
                skipped += 1
                continue

            FeeInvoice.objects.create(
                student=student,
                source_plan=plan,
                title=title,
                billing_month=billing_month,
                due_date=due_date,
                total_amount=plan.monthly_amount,
            )
            generated += 1

    return Response(
        {
            "billing_month": billing_month,
            "generated_invoices": generated,
            "skipped_existing": skipped,
        }
    )


@api_view(["POST"])
def generate_fee_due_notifications(request):
    days_ahead = request.data.get("days_ahead")
    days_window = int(days_ahead) if days_ahead is not None else 7
    if days_window < 0:
        return Response(
            {"detail": "days_ahead must be >= 0"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    today = timezone.localdate()
    due_soon_cutoff = today + timedelta(days=days_window)

    candidates = FeeInvoice.objects.filter(
        Q(status=FeeInvoice.STATUS_PENDING) | Q(status=FeeInvoice.STATUS_PARTIAL)
    ).select_related("student")

    created_count = 0
    for invoice in candidates:
        balance = invoice.total_amount - invoice.paid_amount
        if balance <= 0:
            continue

        notification_type = None
        if invoice.due_date < today:
            notification_type = FeeNotification.TYPE_OVERDUE
        elif invoice.due_date <= due_soon_cutoff:
            notification_type = FeeNotification.TYPE_DUE_SOON

        if not notification_type:
            continue

        links = ParentStudentLink.objects.filter(student_id=invoice.student_id).select_related("parent")
        for link in links:
            title = (
                f"Fee Overdue - {invoice.student.full_name}"
                if notification_type == FeeNotification.TYPE_OVERDUE
                else f"Fee Due Soon - {invoice.student.full_name}"
            )
            body = f"{invoice.title}: Rs {balance:.2f} due on {invoice.due_date}"

            _, created = FeeNotification.objects.get_or_create(
                parent_id=link.parent_id,
                student_id=invoice.student_id,
                invoice_id=invoice.id,
                notification_type=notification_type,
                notified_for_date=today,
                defaults={
                    "title": title,
                    "body": body,
                },
            )
            if created:
                created_count += 1

    return Response(
        {
            "notification_date": today,
            "created_notifications": created_count,
        }
    )


@api_view(["GET"])
def parent_fee_notifications(request, parent_id):
    records = FeeNotification.objects.filter(parent_id=parent_id).select_related("student", "invoice")
    serializer = FeeNotificationSerializer(records, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def parent_fee_notification_unread_count(request, parent_id):
    unread_count = FeeNotification.objects.filter(parent_id=parent_id, is_read=False).count()
    return Response({"unread_count": unread_count})


@api_view(["POST"])
def mark_parent_fee_notifications_read(request, parent_id):
    notification_id = request.data.get("notification_id")
    queryset = FeeNotification.objects.filter(parent_id=parent_id, is_read=False)

    if notification_id is not None:
        try:
            notification_id = int(notification_id)
        except (TypeError, ValueError):
            return Response(
                {"detail": "notification_id must be an integer"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        queryset = queryset.filter(id=notification_id)

    updated_count = queryset.update(is_read=True)
    return Response({"marked_read": updated_count})


@api_view(["GET"])
def student_fees(request, student_id):
    invoices = FeeInvoice.objects.filter(student_id=student_id).prefetch_related("payments")
    serializer = FeeInvoiceSerializer(invoices, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def student_fee_summary(request, student_id):
    invoices = FeeInvoice.objects.filter(student_id=student_id)

    pending_total = Decimal("0")
    overdue_count = 0
    due_soon_count = 0
    today = timezone.localdate()
    due_soon_cutoff = today + timedelta(days=7)

    for invoice in invoices:
        balance = invoice.total_amount - invoice.paid_amount
        if balance <= 0:
            continue

        pending_total += balance

        if invoice.due_date < today:
            overdue_count += 1
        elif invoice.due_date <= due_soon_cutoff:
            due_soon_count += 1

    return Response(
        {
            "student_id": student_id,
            "pending_total": f"{pending_total:.2f}",
            "overdue_count": overdue_count,
            "due_soon_count": due_soon_count,
        }
    )


@api_view(["GET"])
def parent_fee_reminders(request, parent_id):
    student_ids = ParentStudentLink.objects.filter(parent_id=parent_id).values_list(
        "student_id", flat=True
    )

    invoices = (
        FeeInvoice.objects
        .filter(student_id__in=student_ids)
        .select_related("student")
        .order_by("due_date")
    )

    today = timezone.localdate()
    due_soon_cutoff = today + timedelta(days=7)
    reminders = []

    for invoice in invoices:
        balance = invoice.total_amount - invoice.paid_amount
        if balance <= 0:
            continue

        reminder_type = None
        if invoice.due_date < today:
            reminder_type = "OVERDUE"
        elif invoice.due_date <= due_soon_cutoff:
            reminder_type = "DUE_SOON"

        if not reminder_type:
            continue

        reminders.append(
            {
                "invoice_id": invoice.id,
                "student_id": invoice.student_id,
                "student_name": invoice.student.full_name,
                "title": f"Fee {reminder_type.replace('_', ' ').title()} - {invoice.student.full_name}",
                "body": f"{invoice.title}: Rs {balance:.2f} due on {invoice.due_date}",
                "due_date": invoice.due_date,
                "reminder_type": reminder_type,
                "pending_amount": f"{balance:.2f}",
            }
        )

    return Response(reminders)


@api_view(["POST"])
def pay_student_fee(request, student_id, invoice_id):
    invoice = FeeInvoice.objects.filter(id=invoice_id, student_id=student_id).first()
    if not invoice:
        return Response({"detail": "Invoice not found"}, status=status.HTTP_404_NOT_FOUND)

    amount_raw = request.data.get("amount")
    method = (request.data.get("payment_method") or "UPI").strip() or "UPI"

    if amount_raw is None:
        amount = invoice.total_amount - invoice.paid_amount
    else:
        try:
            amount = Decimal(str(amount_raw))
        except (InvalidOperation, TypeError, ValueError):
            return Response(
                {"detail": "amount must be a valid decimal"},
                status=status.HTTP_400_BAD_REQUEST,
            )

    if amount <= 0:
        return Response(
            {"detail": "amount must be greater than 0"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    balance = invoice.total_amount - invoice.paid_amount
    if amount > balance:
        return Response(
            {"detail": "amount cannot exceed pending balance"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    with transaction.atomic():
        reference = f"FP-{invoice.id}-{timezone.now().strftime('%Y%m%d%H%M%S%f')}"
        FeePayment.objects.create(
            invoice=invoice,
            amount=amount,
            payment_method=method,
            reference_id=reference,
        )

        invoice.paid_amount = invoice.paid_amount + amount
        if invoice.paid_amount >= invoice.total_amount:
            invoice.status = FeeInvoice.STATUS_PAID
        elif invoice.paid_amount > 0:
            invoice.status = FeeInvoice.STATUS_PARTIAL
        else:
            invoice.status = FeeInvoice.STATUS_PENDING
        invoice.save(update_fields=["paid_amount", "status", "updated_at"])

    serializer = FeeInvoiceSerializer(invoice)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(["GET"])
def fee_payment_receipt(request, student_id, payment_id):
    payment = (
        FeePayment.objects
        .filter(id=payment_id, invoice__student_id=student_id)
        .select_related("invoice", "invoice__student")
        .first()
    )
    if not payment:
        return Response({"detail": "Payment not found"}, status=status.HTTP_404_NOT_FOUND)

    invoice = payment.invoice
    student = invoice.student
    balance = invoice.total_amount - invoice.paid_amount

    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    y = height - 50
    pdf.setFont("Helvetica-Bold", 16)
    pdf.drawString(50, y, "School Platform - Fee Receipt")

    y -= 26
    pdf.setFont("Helvetica", 11)
    pdf.drawString(50, y, f"Receipt Ref: {payment.reference_id}")
    y -= 18
    pdf.drawString(50, y, f"Payment Date: {payment.paid_at.strftime('%Y-%m-%d %H:%M')}")

    y -= 28
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(50, y, "Student Details")
    y -= 18
    pdf.setFont("Helvetica", 11)
    pdf.drawString(50, y, f"Name: {student.full_name}")
    y -= 18
    pdf.drawString(50, y, f"Roll No: {student.roll_no}")
    y -= 18
    pdf.drawString(50, y, f"Class: {student.class_section}")

    y -= 28
    pdf.setFont("Helvetica-Bold", 12)
    pdf.drawString(50, y, "Invoice Details")
    y -= 18
    pdf.setFont("Helvetica", 11)
    pdf.drawString(50, y, f"Invoice: {invoice.title}")
    y -= 18
    pdf.drawString(50, y, f"Due Date: {invoice.due_date}")
    y -= 18
    pdf.drawString(50, y, f"Invoice Total: Rs {invoice.total_amount:.2f}")
    y -= 18
    pdf.drawString(50, y, f"Amount Paid: Rs {payment.amount:.2f}")
    y -= 18
    pdf.drawString(50, y, f"Paid So Far: Rs {invoice.paid_amount:.2f}")
    y -= 18
    pdf.drawString(50, y, f"Balance: Rs {balance:.2f}")

    y -= 28
    pdf.setFont("Helvetica", 10)
    pdf.drawString(50, y, "This is a system-generated receipt.")

    pdf.showPage()
    pdf.save()
    buffer.seek(0)

    response = HttpResponse(buffer.getvalue(), content_type="application/pdf")
    response["Content-Disposition"] = f'inline; filename="fee_receipt_{payment.id}.pdf"'
    return response

