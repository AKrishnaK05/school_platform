from django.core.management.base import BaseCommand
from django.utils import timezone

from academics.models import FeePlan, FeeInvoice, Student


class Command(BaseCommand):
    help = "Generate monthly fee invoices from active fee plans"

    def add_arguments(self, parser):
        parser.add_argument("--month", type=int, help="Billing month (1-12)")
        parser.add_argument("--year", type=int, help="Billing year (e.g. 2026)")

    def handle(self, *args, **options):
        today = timezone.localdate()
        month = options.get("month") or today.month
        year = options.get("year") or today.year

        if month < 1 or month > 12:
            self.stderr.write(self.style.ERROR("month must be between 1 and 12"))
            return

        billing_month = today.replace(day=1, month=month, year=year)
        generated = 0
        skipped = 0

        plans = FeePlan.objects.filter(is_active=True).select_related("class_section")
        for plan in plans:
            due_date = billing_month.replace(day=plan.due_day)
            students = Student.objects.filter(class_section_id=plan.class_section_id)

            for student in students:
                exists = FeeInvoice.objects.filter(
                    student_id=student.id,
                    source_plan_id=plan.id,
                    billing_month=billing_month,
                ).exists()
                if exists:
                    skipped += 1
                    continue

                title = f"{plan.title} - {billing_month.strftime('%b %Y')}"
                FeeInvoice.objects.create(
                    student=student,
                    source_plan=plan,
                    title=title,
                    billing_month=billing_month,
                    due_date=due_date,
                    total_amount=plan.monthly_amount,
                )
                generated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Generated invoices: {generated}, skipped existing: {skipped}, billing month: {billing_month}"
            )
        )
