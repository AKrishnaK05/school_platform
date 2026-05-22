from datetime import date, time, timedelta
from decimal import Decimal

from django.core.files.base import ContentFile
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
    FeePayment,
    FeePlan,
    Marks,
    Assignment,
    ParentStudentLink,
    Student,
    Subject,
    TeacherAssignment,
    Timetable,
)
from communication.models import (
    Announcement,
    ChatRoom,
    ChatRoomMember,
    ChatRoomMessage,
    ConversationThread,
    Message,
)
from materials.models import StudyMaterial
from reportcards.models import ReportCard
from schools.models import School


class Command(BaseCommand):
    help = "Seed mock/demo data for all parent-app pages"

    def add_arguments(self, parser):
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Delete previously created demo users and recreate data",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        if options.get("reset"):
            self._reset_demo_data()

        today = timezone.localdate()

        school, _ = School.objects.get_or_create(
            name="Green Valley Public School",
            defaults={"domain": "greenvalley.edu"},
        )

        class_8c, _ = ClassSection.objects.get_or_create(class_name="8", section="C")
        class_9a, _ = ClassSection.objects.get_or_create(class_name="9", section="A")

        father_user = self._ensure_user(
            username="demo.father",
            password="demo123",
            first_name="Dipu",
            last_name="Nair",
            phone="9000000001",
        )
        mother_user = self._ensure_user(
            username="demo.mother",
            password="demo123",
            first_name="Anju",
            last_name="Raj",
            phone="9000000002",
        )

        parent_father, _ = ParentProfile.objects.get_or_create(
            user=father_user,
            defaults={"full_name": "Dr Dipu K P"},
        )
        parent_mother, _ = ParentProfile.objects.get_or_create(
            user=mother_user,
            defaults={"full_name": "Dr Anju C Raj"},
        )

        teacher_specs = [
            ("demo.teacher.english", "Priya", "N", "9000000101", "Ms. Priya N"),
            ("demo.teacher.math", "Arjun", "Menon", "9000000102", "Mr. Arjun Menon"),
            ("demo.teacher.science", "Kavya", "R", "9000000103", "Ms. Kavya R"),
            ("demo.teacher.social", "Suresh", "P", "9000000104", "Mr. Suresh P"),
            ("demo.teacher.hindi", "Meera", "S", "9000000105", "Ms. Meera S"),
            ("demo.teacher.cs", "Kiran", "Das", "9000000106", "Mr. Kiran Das"),
        ]

        teachers = []
        for username, first, last, phone, full_name in teacher_specs:
            teacher_user = self._ensure_user(
                username=username,
                password="demo123",
                first_name=first,
                last_name=last,
                phone=phone,
            )
            teacher_profile, _ = TeacherProfile.objects.get_or_create(
                user=teacher_user,
                defaults={"full_name": full_name},
            )
            teachers.append(teacher_profile)

        subject_names = ["English", "Mathematics", "Science", "Social", "Hindi", "Computer"]
        subjects = {}
        for name in subject_names:
            subject, _ = Subject.objects.get_or_create(name=name)
            subjects[name] = subject

        teacher_subject_pairs = [
            (teachers[0], "English"),
            (teachers[1], "Mathematics"),
            (teachers[2], "Science"),
            (teachers[3], "Social"),
            (teachers[4], "Hindi"),
            (teachers[5], "Computer"),
        ]

        for teacher, subject_name in teacher_subject_pairs:
            TeacherAssignment.objects.get_or_create(
                teacher=teacher,
                subject=subjects[subject_name],
                class_section=class_8c,
            )

        TeacherAssignment.objects.get_or_create(
            teacher=teachers[1],
            subject=subjects["Mathematics"],
            class_section=class_9a,
        )

        ClassTeacher.objects.get_or_create(teacher=teachers[0], class_section=class_8c)
        ClassTeacher.objects.get_or_create(teacher=teachers[1], class_section=class_9a)

        student1, _ = Student.objects.get_or_create(
            full_name="Anika K P",
            roll_no="4943",
            class_section=class_8c,
        )
        student2, _ = Student.objects.get_or_create(
            full_name="Ayana Krishna P R",
            roll_no="5516",
            class_section=class_8c,
        )
        student3, _ = Student.objects.get_or_create(
            full_name="Vedhika Sai",
            roll_no="5556",
            class_section=class_9a,
        )

        for student in [student1, student2, student3]:
            ParentStudentLink.objects.get_or_create(
                parent=parent_father,
                student=student,
                defaults={"relationship": "FATHER"},
            )
            ParentStudentLink.objects.get_or_create(
                parent=parent_mother,
                student=student,
                defaults={"relationship": "MOTHER"},
            )

        self._seed_attendance(today, [student1, student2, student3])

        pa1, _ = Exam.objects.get_or_create(name="Periodic Assessment 1", academic_year="2026-2027")
        pa2, _ = Exam.objects.get_or_create(name="Periodic Assessment 2", academic_year="2026-2027")
        mid_term, _ = Exam.objects.get_or_create(name="Mid Term", academic_year="2026-2027")
        end_term, _ = Exam.objects.get_or_create(name="End Term", academic_year="2026-2027")

        demo_students = [student1, student2, student3]
        self._cleanup_legacy_exam_data(demo_students)
        exams = [pa1, pa2, mid_term, end_term]

        self._seed_marks(student1, exams, subjects, teachers)
        self._seed_marks(student2, exams, subjects, teachers)
        self._seed_marks(student3, exams, subjects, teachers)
        self._seed_assignments(student1, subjects)
        self._seed_assignments(student2, subjects)
        self._seed_assignments(student3, subjects)

        self._seed_timetable(class_8c, subjects, teachers)
        self._seed_timetable(class_9a, subjects, teachers)

        self._seed_materials(class_8c, subjects, teachers)
        self._seed_materials(class_9a, subjects, teachers)

        self._seed_reportcards(student1, exams)
        self._seed_reportcards(student2, exams)
        self._seed_reportcards(student3, exams)

        self._seed_announcements(father_user, class_8c, class_9a)

        self._seed_chats(
            parents=[parent_father, parent_mother],
            students=[student1, student2, student3],
            teachers=teachers,
            class_sections=[class_8c, class_9a],
        )

        self._seed_fee_data(
            today=today,
            class_8c=class_8c,
            class_9a=class_9a,
            students=[student1, student2, student3],
            parents=[parent_father, parent_mother],
        )

        self.stdout.write(self.style.SUCCESS("Demo data seeded successfully."))
        self.stdout.write(self.style.SUCCESS(f"School: {school.name}"))
        self.stdout.write(self.style.SUCCESS("Parent Login 1: demo.father / demo123"))
        self.stdout.write(self.style.SUCCESS("Parent Login 2: demo.mother / demo123"))

    def _ensure_user(self, username, password, first_name, last_name, phone):
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                "first_name": first_name,
                "last_name": last_name,
                "phone": phone,
                "is_active": True,
            },
        )
        if created:
            user.set_password(password)
            user.save(update_fields=["password"])
        else:
            changed = False
            if user.phone != phone:
                user.phone = phone
                changed = True
            if user.first_name != first_name:
                user.first_name = first_name
                changed = True
            if user.last_name != last_name:
                user.last_name = last_name
                changed = True
            if changed:
                user.save(update_fields=["phone", "first_name", "last_name"])
        return user

    def _seed_attendance(self, today, students):
        for idx, student in enumerate(students):
            for day_back in range(1, 16):
                entry_date = today - timedelta(days=day_back)
                if entry_date.weekday() == 6:
                    continue

                status = "PRESENT"
                reason = ""
                if (day_back + idx) % 7 == 0:
                    status = "ABSENT"
                    reason = "Sick leave"

                Attendance.objects.get_or_create(
                    student=student,
                    date=entry_date,
                    defaults={"status": status, "reason": reason},
                )

    def _cleanup_legacy_exam_data(self, students):
        legacy_exam_names = ["Term 1", "Term 2", "Demo Term", "Unit Test 1", "Unit Test 2"]
        Marks.objects.filter(student__in=students, exam__name__in=legacy_exam_names).delete()
        ReportCard.objects.filter(student__in=students, exam__name__in=legacy_exam_names).delete()

    def _seed_marks(self, student, exams, subjects, teachers):
        score_map = {
            "English": Decimal("84.0"),
            "Mathematics": Decimal("91.0"),
            "Science": Decimal("88.0"),
            "Social": Decimal("79.0"),
            "Hindi": Decimal("82.0"),
            "Computer": Decimal("94.0"),
        }
        teacher_by_subject = {
            "English": teachers[0],
            "Mathematics": teachers[1],
            "Science": teachers[2],
            "Social": teachers[3],
            "Hindi": teachers[4],
            "Computer": teachers[5],
        }

        for exam_index, exam in enumerate(exams):
            for subject_name, base_score in score_map.items():
                adjusted_score = base_score - Decimal(exam_index * 2)
                Marks.objects.get_or_create(
                    student=student,
                    subject=subjects[subject_name],
                    exam=exam,
                    defaults={
                        "score": adjusted_score,
                        "uploaded_by": teacher_by_subject[subject_name],
                    },
                )

    def _seed_assignments(self, student, subjects):
        today = timezone.localdate()
        assignment_specs = [
            {
                "title": "Water Cycle Model",
                "description": "Build a labeled model and submit with chart notes.",
                "subject": subjects["Science"],
                "due_date": today + timedelta(days=4),
                "status": Assignment.STATUS_PENDING,
            },
            {
                "title": "Algebra Worksheet 5B",
                "description": "Solve Q1-Q20 and show working steps.",
                "subject": subjects["Mathematics"],
                "due_date": today + timedelta(days=2),
                "status": Assignment.STATUS_SUBMITTED,
            },
            {
                "title": "Poem Recitation Practice",
                "description": "Record a 2-minute recitation and upload notes.",
                "subject": subjects["English"],
                "due_date": today + timedelta(days=7),
                "status": Assignment.STATUS_PENDING,
            },
        ]

        for spec in assignment_specs:
            Assignment.objects.get_or_create(
                student=student,
                title=spec["title"],
                due_date=spec["due_date"],
                defaults={
                    "description": spec["description"],
                    "subject": spec["subject"],
                    "status": spec["status"],
                },
            )

    def _seed_timetable(self, class_section, subjects, teachers):
        slots = [
            (1, time(8, 30), time(9, 15), "English", teachers[0]),
            (2, time(9, 15), time(10, 0), "Mathematics", teachers[1]),
            (3, time(10, 15), time(11, 0), "Science", teachers[2]),
            (4, time(11, 0), time(11, 45), "Social", teachers[3]),
            (5, time(12, 15), time(13, 0), "Hindi", teachers[4]),
            (6, time(13, 0), time(13, 45), "Computer", teachers[5]),
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

    def _seed_materials(self, class_section, subjects, teachers):
        material_specs = [
            ("English Reading Worksheet", "English", teachers[0]),
            ("Algebra Practice Set", "Mathematics", teachers[1]),
            ("Science Lab Notes", "Science", teachers[2]),
            ("Computer Revision Sheet", "Computer", teachers[5]),
        ]

        for title, subject_name, teacher in material_specs:
            material, _ = StudyMaterial.objects.get_or_create(
                title=f"{title} - {class_section}",
                class_section=class_section,
                subject=subjects[subject_name],
                uploaded_by=teacher,
            )
            if not material.file:
                file_name = f"demo_{class_section.class_name}{class_section.section}_{subject_name.lower()}.txt"
                file_content = (
                    f"Demo material for {subject_name} in class {class_section}.\n"
                    f"Title: {title}\n"
                    "Use this file to demonstrate material listing and downloads.\n"
                )
                material.file.save(file_name, ContentFile(file_content.encode("utf-8")), save=True)

    def _seed_reportcards(self, student, exams):
        for exam in exams:
            marks = Marks.objects.filter(student=student, exam=exam)
            if not marks.exists():
                continue

            total = sum((mark.score for mark in marks), Decimal("0"))
            percentage = (total / Decimal(len(marks))).quantize(Decimal("0.01"))
            if percentage >= Decimal("90"):
                grade = "A+"
            elif percentage >= Decimal("80"):
                grade = "A"
            elif percentage >= Decimal("70"):
                grade = "B+"
            else:
                grade = "B"

            ReportCard.objects.get_or_create(
                student=student,
                exam=exam,
                defaults={
                    "total": total,
                    "percentage": percentage,
                    "grade": grade,
                    "remarks": "Consistent progress. Keep up the good work.",
                    "is_published": True,
                    "published_on": timezone.now() - timedelta(days=3),
                },
            )

    def _seed_announcements(self, created_by, class_8c, class_9a):
        announcements = [
            (
                "PTA Meeting on Saturday",
                "Parents are requested to attend the PTA meeting at 10:00 AM this Saturday.",
                class_8c,
            ),
            (
                "Science Exhibition",
                "Students of Class 8 and 9 should submit project abstracts by Monday.",
                class_9a,
            ),
            (
                "Fee Reminder",
                "Kindly complete the monthly fee payment before the 10th of this month.",
                None,
            ),
        ]

        for title, body, target_class in announcements:
            Announcement.objects.get_or_create(
                title=title,
                body=body,
                created_by=created_by,
                target_class=target_class,
            )

    def _seed_chats(self, parents, students, teachers, class_sections):
        today_now = timezone.now()

        for student in students:
            for parent in parents:
                for teacher in teachers[:3]:
                    thread, _ = ConversationThread.objects.get_or_create(
                        student=student,
                        parent=parent,
                        teacher=teacher,
                    )
                    if not thread.messages.exists():
                        Message.objects.create(
                            thread=thread,
                            sender=teacher.user,
                            content=f"Hello {parent.full_name}, sharing an update about {student.full_name}.",
                        )
                        Message.objects.create(
                            thread=thread,
                            sender=parent.user,
                            content="Thank you. Please share any additional guidance.",
                        )

                    room, _ = ChatRoom.objects.get_or_create(
                        is_group=False,
                        student=student,
                        direct_teacher=teacher,
                        defaults={
                            "name": f"{teacher.full_name} - {student.full_name}",
                            "class_section": student.class_section,
                            "created_by": parent.user,
                        },
                    )
                    ChatRoomMember.objects.get_or_create(room=room, user=parent.user)
                    ChatRoomMember.objects.get_or_create(room=room, user=teacher.user)

                    if not room.messages.exists():
                        ChatRoomMessage.objects.create(
                            room=room,
                            sender=teacher.user,
                            content=f"Good evening. {student.full_name} did well in class today.",
                        )
                        ChatRoomMessage.objects.create(
                            room=room,
                            sender=parent.user,
                            content="Great to hear, thank you!",
                        )

        for class_section in class_sections:
            group_room, _ = ChatRoom.objects.get_or_create(
                is_group=True,
                class_section=class_section,
                name=f"{class_section} Group",
                defaults={
                    "created_by": parents[0].user,
                    "student": students[0],
                },
            )

            for parent in parents:
                ChatRoomMember.objects.get_or_create(room=group_room, user=parent.user)
            for teacher in teachers:
                if TeacherAssignment.objects.filter(
                    teacher=teacher,
                    class_section=class_section,
                ).exists():
                    ChatRoomMember.objects.get_or_create(room=group_room, user=teacher.user)

            if not group_room.messages.exists():
                ChatRoomMessage.objects.create(
                    room=group_room,
                    sender=teachers[0].user,
                    content=f"Welcome to {class_section} group. Weekly updates will be shared here.",
                )
                ChatRoomMessage.objects.create(
                    room=group_room,
                    sender=parents[0].user,
                    content="Thank you, looking forward to regular updates.",
                )

            group_room.updated_at = today_now
            group_room.save(update_fields=["updated_at"])

    def _seed_fee_data(self, today, class_8c, class_9a, students, parents):
        plan_8c, _ = FeePlan.objects.get_or_create(
            class_section=class_8c,
            title="Monthly Tuition",
            defaults={
                "monthly_amount": Decimal("2500.00"),
                "due_day": 10,
                "is_active": True,
            },
        )
        plan_9a, _ = FeePlan.objects.get_or_create(
            class_section=class_9a,
            title="Monthly Tuition",
            defaults={
                "monthly_amount": Decimal("2800.00"),
                "due_day": 10,
                "is_active": True,
            },
        )

        this_month = today.replace(day=1)
        prev_month = (this_month - timedelta(days=1)).replace(day=1)

        for student in students:
            plan = plan_8c if student.class_section_id == class_8c.id else plan_9a

            current_invoice, _ = FeeInvoice.objects.get_or_create(
                student=student,
                source_plan=plan,
                billing_month=this_month,
                title=f"{plan.title} - {this_month.strftime('%b %Y')}",
                defaults={
                    "due_date": this_month.replace(day=10),
                    "total_amount": plan.monthly_amount,
                    "paid_amount": Decimal("0.00"),
                    "status": FeeInvoice.STATUS_PENDING,
                },
            )

            overdue_invoice, _ = FeeInvoice.objects.get_or_create(
                student=student,
                source_plan=plan,
                billing_month=prev_month,
                title=f"{plan.title} - {prev_month.strftime('%b %Y')}",
                defaults={
                    "due_date": prev_month.replace(day=10),
                    "total_amount": plan.monthly_amount,
                    "paid_amount": Decimal("0.00"),
                    "status": FeeInvoice.STATUS_PENDING,
                },
            )

            if current_invoice.paid_amount == 0 and student == students[0]:
                current_invoice.paid_amount = Decimal("1000.00")
                current_invoice.status = FeeInvoice.STATUS_PARTIAL
                current_invoice.save(update_fields=["paid_amount", "status", "updated_at"])

                FeePayment.objects.get_or_create(
                    invoice=current_invoice,
                    reference_id=f"DEMO-PAY-{current_invoice.id}",
                    defaults={
                        "amount": Decimal("1000.00"),
                        "payment_method": "UPI",
                    },
                )

            for parent in parents:
                FeeNotification.objects.get_or_create(
                    parent=parent,
                    student=student,
                    invoice=overdue_invoice,
                    notification_type=FeeNotification.TYPE_OVERDUE,
                    notified_for_date=today,
                    defaults={
                        "title": f"Fee Overdue - {student.full_name}",
                        "body": f"{overdue_invoice.title}: Rs {(overdue_invoice.total_amount - overdue_invoice.paid_amount):.2f} due on {overdue_invoice.due_date}",
                        "is_read": False,
                    },
                )

                FeeNotification.objects.get_or_create(
                    parent=parent,
                    student=student,
                    invoice=current_invoice,
                    notification_type=FeeNotification.TYPE_DUE_SOON,
                    notified_for_date=today,
                    defaults={
                        "title": f"Fee Due Soon - {student.full_name}",
                        "body": f"{current_invoice.title}: Rs {(current_invoice.total_amount - current_invoice.paid_amount):.2f} due on {current_invoice.due_date}",
                        "is_read": False,
                    },
                )

    def _reset_demo_data(self):
        demo_usernames = [
            "demo.father",
            "demo.mother",
            "demo.teacher.english",
            "demo.teacher.math",
            "demo.teacher.science",
            "demo.teacher.social",
            "demo.teacher.hindi",
            "demo.teacher.cs",
        ]
        User.objects.filter(username__in=demo_usernames).delete()
