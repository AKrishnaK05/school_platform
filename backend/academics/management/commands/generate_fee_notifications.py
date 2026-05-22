from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db.models import Q
from django.utils import timezone

from academics.models import FeeInvoice, FeeNotification, ParentStudentLink


class Command(BaseCommand):
    help = "Generate private parent fee notifications for due-soon and overdue invoices"

    def add_arguments(self, parser):
        parser.add_argument(
            "--days-ahead",
            type=int,
            default=7,
            help="Notify for invoices due within this many days",
        )

    def handle(self, *args, **options):
        days_ahead = options.get("days_ahead", 7)
        if days_ahead < 0:
            self.stderr.write(self.style.ERROR("days-ahead must be >= 0"))
            return

        today = timezone.localdate()
        due_soon_cutoff = today + timedelta(days=days_ahead)

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
                    defaults={"title": title, "body": body},
                )
                if created:
                    created_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Created fee notifications: {created_count} (date: {today})"
            )
        )
