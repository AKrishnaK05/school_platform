from datetime import timedelta, time
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from accounts.models import ParentProfile, TeacherProfile, User
from academics.models import (
    Attendance,
    ClassSection,
    ClassTeacher,
    Exam,
    FeeInvoice,
    FeeNotification,
    FeePlan,
    Marks,
    Assignment,
    ParentStudentLink,
    Student,
    Subject,
    TeacherAssignment,
    Timetable,
)
from communication.models import Announcement


class Command(BaseCommand):
    help = "Seed larger mock datasets for demonstrations and load testing"

    def add_arguments(self, parser):
        parser.add_argument(
            "--classes",
            type=str,
            default="6A,7A,8A,9A,10A",
            help="Comma-separated class-section tokens (e.g. 8A,8B,9A)",
        )
        parser.add_argument(
            "--students-per-class",
            type=int,
            default=30,
            help="Number of demo students per class-section",
        )
        parser.add_argument(
            "--attendance-days",
            type=int,
            default=30,
            help="Attendance days to seed per student",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        classes_arg = options["classes"]
        students_per_class = options["students_per_class"]
        attendance_days = options["attendance_days"]

        if students_per_class < 1:
            self.stderr.write(self.style.ERROR("students-per-class must be >= 1"))
            return

        if attendance_days < 1:
            self.stderr.write(self.style.ERROR("attendance-days must be >= 1"))
            return

        class_tokens = [token.strip().upper() for token in classes_arg.split(",") if token.strip()]
        if not class_tokens:
            self.stderr.write(self.style.ERROR("No valid classes provided"))
            return

        today = timezone.localdate()

        subjects = self._ensure_subjects()
        teachers = self._ensure_teachers(subjects)
        exams = [
            Exam.objects.get_or_create(name="Periodic Assessment 1", academic_year="2026-2027")[0],
            Exam.objects.get_or_create(name="Periodic Assessment 2", academic_year="2026-2027")[0],
            Exam.objects.get_or_create(name="Mid Term", academic_year="2026-2027")[0],
            Exam.objects.get_or_create(name="End Term", academic_year="2026-2027")[0],
        ]

        created_students = 0
        created_parents = 0
        created_attendance = 0
        created_marks = 0
        created_assignments = 0
        created_fees = 0

        for token in class_tokens:
            class_name, section = token[:-1], token[-1]
            class_section, _ = ClassSection.objects.get_or_create(
                class_name=class_name,
                section=section,
            )

            self._ensure_class_links(class_section, subjects, teachers)
            self._ensure_timetable(class_section, subjects, teachers)
            self._ensure_fee_plan(class_section)

            for idx in range(1, students_per_class + 1):
                student, student_created = self._ensure_student(class_section, idx)
                if student_created:
                    created_students += 1

                parents_created = self._ensure_parents_for_student(student, class_section, idx)
                created_parents += parents_created

                self._cleanup_legacy_exam_marks(student)
                created_attendance += self._seed_attendance(student, attendance_days, today)
                for exam in exams:
                    created_marks += self._seed_marks(student, subjects, teachers, exam)
                created_assignments += self._seed_assignments(student, subjects, today)
                created_fees += self._seed_fees(student, today)

        self._ensure_announcements(class_tokens)

        self.stdout.write(self.style.SUCCESS("Scaled demo data seeding completed."))
        self.stdout.write(self.style.SUCCESS(f"Students created: {created_students}"))
        self.stdout.write(self.style.SUCCESS(f"Parent profiles created: {created_parents}"))
        self.stdout.write(self.style.SUCCESS(f"Attendance records created: {created_attendance}"))
        self.stdout.write(self.style.SUCCESS(f"Marks records created: {created_marks}"))
        self.stdout.write(self.style.SUCCESS(f"Assignments created: {created_assignments}"))
        self.stdout.write(self.style.SUCCESS(f"Fee invoices created: {created_fees}"))
        self.stdout.write(
            self.style.SUCCESS(
                "Sample credentials pattern: scale.parent.father.<class><section>.<n> / demo123"
            )
        )

    def _ensure_subjects(self):
        names = ["English", "Mathematics", "Science", "Social", "Hindi", "Computer"]
        subjects = {}
        for name in names:
            subjects[name] = Subject.objects.get_or_create(name=name)[0]
        return subjects

    def _ensure_teachers(self, subjects):
        specs = [
            ("english", "English", "Ms. Priya Demo"),
            ("math", "Mathematics", "Mr. Arjun Demo"),
            ("science", "Science", "Ms. Kavya Demo"),
            ("social", "Social", "Mr. Suresh Demo"),
            ("hindi", "Hindi", "Ms. Meera Demo"),
            ("computer", "Computer", "Mr. Kiran Demo"),
        ]

        teachers = {}
        for key, _, full_name in specs:
            username = f"scale.teacher.{key}"
            user, created = User.objects.get_or_create(
                username=username,
                defaults={"first_name": full_name.split()[0], "last_name": "Scale", "phone": None},
            )
            if created:
                user.set_password("demo123")
                user.save(update_fields=["password"])

            teacher, _ = TeacherProfile.objects.get_or_create(
                user=user,
                defaults={"full_name": full_name},
            )
            teachers[key] = teacher

        return teachers

    def _ensure_class_links(self, class_section, subjects, teachers):
        assignment_map = {
            "English": teachers["english"],
            "Mathematics": teachers["math"],
            "Science": teachers["science"],
            "Social": teachers["social"],
            "Hindi": teachers["hindi"],
            "Computer": teachers["computer"],
        }

        for subject_name, teacher in assignment_map.items():
            TeacherAssignment.objects.get_or_create(
                teacher=teacher,
                subject=subjects[subject_name],
                class_section=class_section,
            )

        ClassTeacher.objects.get_or_create(
            class_section=class_section,
            defaults={"teacher": teachers["english"]},
        )

    def _ensure_timetable(self, class_section, subjects, teachers):
        slots = [
            (1, time(8, 30), time(9, 15), "English", teachers["english"]),
            (2, time(9, 15), time(10, 0), "Mathematics", teachers["math"]),
            (3, time(10, 15), time(11, 0), "Science", teachers["science"]),
            (4, time(11, 0), time(11, 45), "Social", teachers["social"]),
            (5, time(12, 15), time(13, 0), "Hindi", teachers["hindi"]),
            (6, time(13, 0), time(13, 45), "Computer", teachers["computer"]),
        ]

        for day_key, _ in Timetable.DAYS_OF_WEEK:
            for period, start_at, end_at, subject_name, teacher in slots:
                Timetable.objects.get_or_create(
                    class_section=class_section,
                    day=day_key,
                    period=period,
                    defaults={
                        "subject": subjects[subject_name],
                        "teacher": teacher,
                        "start_time": start_at,
                        "end_time": end_at,
                    },
                )

    def _ensure_fee_plan(self, class_section):
        FeePlan.objects.get_or_create(
            class_section=class_section,
            title="Monthly Tuition",
            defaults={
                "monthly_amount": Decimal("2500.00"),
                "due_day": 10,
                "is_active": True,
            },
        )

    def _ensure_student(self, class_section, index):
        roll_no = f"{class_section.class_name}{class_section.section}{index:03d}"
        full_name = f"Scale Student {class_section.class_name}{class_section.section}-{index:03d}"
        student, created = Student.objects.get_or_create(
            roll_no=roll_no,
            defaults={
                "full_name": full_name,
                "class_section": class_section,
            },
        )
        if not created and student.class_section_id != class_section.id:
            student.class_section = class_section
            student.save(update_fields=["class_section"])
        return student, created

    def _ensure_parents_for_student(self, student, class_section, index):
        created_count = 0

        father_username = f"scale.parent.father.{class_section.class_name}{class_section.section}.{index:03d}".lower()
        mother_username = f"scale.parent.mother.{class_section.class_name}{class_section.section}.{index:03d}".lower()

        father_user, created = User.objects.get_or_create(
            username=father_username,
            defaults={"first_name": "Father", "last_name": student.roll_no, "phone": None},
        )
        if created:
            father_user.set_password("demo123")
            father_user.save(update_fields=["password"])

        mother_user, created = User.objects.get_or_create(
            username=mother_username,
            defaults={"first_name": "Mother", "last_name": student.roll_no, "phone": None},
        )
        if created:
            mother_user.set_password("demo123")
            mother_user.save(update_fields=["password"])

        father_profile, father_created = ParentProfile.objects.get_or_create(
            user=father_user,
            defaults={"full_name": f"Father of {student.full_name}"},
        )
        mother_profile, mother_created = ParentProfile.objects.get_or_create(
            user=mother_user,
            defaults={"full_name": f"Mother of {student.full_name}"},
        )

        created_count += 1 if father_created else 0
        created_count += 1 if mother_created else 0

        ParentStudentLink.objects.get_or_create(
            parent=father_profile,
            student=student,
            defaults={"relationship": "FATHER"},
        )
        ParentStudentLink.objects.get_or_create(
            parent=mother_profile,
            student=student,
            defaults={"relationship": "MOTHER"},
        )

        return created_count

    def _seed_attendance(self, student, attendance_days, today):
        created_count = 0
        for day_back in range(1, attendance_days + 1):
            entry_date = today - timedelta(days=day_back)
            if entry_date.weekday() == 6:
                continue

            status = "ABSENT" if day_back % 9 == 0 else "PRESENT"
            reason = "Sick leave" if status == "ABSENT" else ""

            _, created = Attendance.objects.get_or_create(
                student=student,
                date=entry_date,
                defaults={"status": status, "reason": reason},
            )
            if created:
                created_count += 1
        return created_count

    def _seed_marks(self, student, subjects, teachers, exam):
        base_scores = {
            "English": Decimal("80.0"),
            "Mathematics": Decimal("88.0"),
            "Science": Decimal("84.0"),
            "Social": Decimal("79.0"),
            "Hindi": Decimal("82.0"),
            "Computer": Decimal("91.0"),
        }
        teacher_map = {
            "English": teachers["english"],
            "Mathematics": teachers["math"],
            "Science": teachers["science"],
            "Social": teachers["social"],
            "Hindi": teachers["hindi"],
            "Computer": teachers["computer"],
        }

        created_count = 0
        mod = int(student.roll_no[-2:]) % 7
        for subject_name, score in base_scores.items():
            _, created = Marks.objects.get_or_create(
                student=student,
                subject=subjects[subject_name],
                exam=exam,
                defaults={
                    "score": score - Decimal(mod),
                    "uploaded_by": teacher_map[subject_name],
                },
            )
            if created:
                created_count += 1
        return created_count

    def _cleanup_legacy_exam_marks(self, student):
        legacy_exam_names = ["Term 1", "Term 2", "Demo Term", "Unit Test 1", "Unit Test 2"]
        Marks.objects.filter(student=student, exam__name__in=legacy_exam_names).delete()

    def _seed_assignments(self, student, subjects, today):
        created_count = 0
        offset = int(student.roll_no[-2:]) % 5
        specs = [
            ("Worksheet Practice", "English", 2 + offset, Assignment.STATUS_PENDING),
            ("Project Submission", "Science", 4 + offset, Assignment.STATUS_PENDING),
            ("Lab Record Update", "Computer", 1 + offset, Assignment.STATUS_SUBMITTED),
        ]

        for title, subject_name, due_in_days, status in specs:
            _, created = Assignment.objects.get_or_create(
                student=student,
                title=f"{subject_name} - {title}",
                due_date=today + timedelta(days=due_in_days),
                defaults={
                    "description": f"{title} for {subject_name}.",
                    "subject": subjects[subject_name],
                    "status": status,
                },
            )
            if created:
                created_count += 1

        return created_count

    def _seed_fees(self, student, today):
        this_month = today.replace(day=1)
        prev_month = (this_month - timedelta(days=1)).replace(day=1)

        current_title = f"Monthly Tuition - {this_month.strftime('%b %Y')}"
        overdue_title = f"Monthly Tuition - {prev_month.strftime('%b %Y')}"

        current_invoice, created_current = FeeInvoice.objects.get_or_create(
            student=student,
            title=current_title,
            billing_month=this_month,
            defaults={
                "due_date": this_month.replace(day=10),
                "total_amount": Decimal("2500.00"),
                "paid_amount": Decimal("500.00"),
                "status": FeeInvoice.STATUS_PARTIAL,
            },
        )

        overdue_invoice, created_overdue = FeeInvoice.objects.get_or_create(
            student=student,
            title=overdue_title,
            billing_month=prev_month,
            defaults={
                "due_date": prev_month.replace(day=10),
                "total_amount": Decimal("2500.00"),
                "paid_amount": Decimal("0.00"),
                "status": FeeInvoice.STATUS_PENDING,
            },
        )

        parent_links = ParentStudentLink.objects.filter(student=student).select_related("parent")
        for link in parent_links:
            FeeNotification.objects.get_or_create(
                parent=link.parent,
                student=student,
                invoice=overdue_invoice,
                notification_type=FeeNotification.TYPE_OVERDUE,
                notified_for_date=today,
                defaults={
                    "title": f"Fee Overdue - {student.full_name}",
                    "body": f"{overdue_invoice.title}: Rs 2500.00 due on {overdue_invoice.due_date}",
                    "is_read": False,
                },
            )
            FeeNotification.objects.get_or_create(
                parent=link.parent,
                student=student,
                invoice=current_invoice,
                notification_type=FeeNotification.TYPE_DUE_SOON,
                notified_for_date=today,
                defaults={
                    "title": f"Fee Due Soon - {student.full_name}",
                    "body": f"{current_invoice.title}: pending balance due on {current_invoice.due_date}",
                    "is_read": False,
                },
            )

        return (1 if created_current else 0) + (1 if created_overdue else 0)

    def _ensure_announcements(self, class_tokens):
        creator = User.objects.filter(username="scale.teacher.english").first()
        if creator is None:
            return

        for token in class_tokens:
            class_name, section = token[:-1], token[-1]
            class_section = ClassSection.objects.filter(class_name=class_name, section=section).first()
            if class_section is None:
                continue

            Announcement.objects.get_or_create(
                title=f"Demo Announcement for {class_section}",
                body=f"This is demonstration content for class {class_section}.",
                created_by=creator,
                target_class=class_section,
            )
