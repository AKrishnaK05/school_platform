from datetime import date
from decimal import Decimal, InvalidOperation
from io import BytesIO

from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.core.files.base import ContentFile
from django.db import IntegrityError, transaction
from django.db.models import Count, Prefetch, Q
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone
from django.utils.text import slugify

from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from academics.models import Attendance, ClassSection, ClassTeacher, Exam, Marks, ParentStudentLink, Student, TeacherAssignment, Timetable
from accounts.models import TeacherProfile
from communication.models import Announcement, ChatRoom, ChatRoomMember, ChatRoomMessage, ConversationThread, Message
from materials.models import StudyMaterial
from reportcards.models import ReportCard
from schools.models import School


def _get_logged_in_teacher(request):
    return TeacherProfile.objects.filter(user=request.user).first()


def _calculate_grade(percentage):
    p = Decimal(percentage)
    if p >= Decimal("90"):
        return "A+"
    if p >= Decimal("80"):
        return "A"
    if p >= Decimal("70"):
        return "B"
    if p >= Decimal("60"):
        return "C"
    if p >= Decimal("50"):
        return "D"
    return "F"


def _report_preview_for(class_id, exam_id):
    students = Student.objects.filter(class_section_id=class_id).order_by("full_name")
    preview = []

    for student in students:
        marks_qs = Marks.objects.filter(student=student, exam_id=exam_id)
        subject_count = marks_qs.count()
        total = sum((m.score for m in marks_qs), Decimal("0"))
        percentage = Decimal("0") if subject_count == 0 else (total / Decimal(subject_count)).quantize(Decimal("0.01"))
        grade = _calculate_grade(percentage)

        existing = ReportCard.objects.filter(student=student, exam_id=exam_id).first()

        preview.append(
            {
                "student": student,
                "subject_count": subject_count,
                "total": total,
                "percentage": percentage,
                "grade": grade,
                "is_generated": existing is not None,
                "is_published": existing.is_published if existing else False,
                "remarks": existing.remarks if existing else "",
            }
        )

    return preview


def _render_report_card_pdf(report_card):
    student = report_card.student
    exam = report_card.exam
    marks = Marks.objects.filter(student=student, exam=exam).select_related("subject")
    school = School.objects.first()

    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=A4)
    w, h = A4

    y = h - 50
    p.setFont("Helvetica-Bold", 16)
    p.drawString(50, y, school.name if school else "School Report Card")

    y -= 25
    p.setFont("Helvetica", 11)
    p.drawString(50, y, f"Student: {student.full_name}")
    y -= 18
    p.drawString(50, y, f"Class: {student.class_section}")
    y -= 18
    p.drawString(50, y, f"Exam: {exam.name} ({exam.academic_year})")

    y -= 28
    p.setFont("Helvetica-Bold", 11)
    p.drawString(50, y, "Subject")
    p.drawString(350, y, "Score")

    y -= 14
    p.line(50, y, w - 50, y)

    p.setFont("Helvetica", 11)
    for m in marks:
        y -= 18
        if y < 120:
            p.showPage()
            y = h - 50
        p.drawString(50, y, m.subject.name)
        p.drawRightString(w - 60, y, str(m.score))

    y -= 26
    p.setFont("Helvetica-Bold", 11)
    p.drawString(50, y, f"Total: {report_card.total}")
    y -= 18
    p.drawString(50, y, f"Percentage: {report_card.percentage}%")
    y -= 18
    p.drawString(50, y, f"Grade: {report_card.grade}")

    if report_card.remarks:
        y -= 22
        p.setFont("Helvetica-Bold", 11)
        p.drawString(50, y, "Remarks:")
        y -= 16
        p.setFont("Helvetica", 10)
        p.drawString(50, y, report_card.remarks[:1000])

    p.showPage()
    p.save()
    buffer.seek(0)
    return buffer


def _sync_thread_message_to_direct_room(thread, sender_user, content):
    room, _ = ChatRoom.objects.get_or_create(
        is_group=False,
        student_id=thread.student_id,
        direct_teacher_id=thread.teacher_id,
        defaults={
            "name": thread.teacher.full_name,
            "class_section_id": thread.student.class_section_id,
            "created_by_id": sender_user.id,
        },
    )

    ChatRoomMember.objects.get_or_create(room_id=room.id, user_id=thread.parent.user_id)
    ChatRoomMember.objects.get_or_create(room_id=room.id, user_id=thread.teacher.user_id)

    latest = room.messages.order_by("-created_at").first()
    if latest and latest.sender_id == sender_user.id and latest.content == content:
        return

    ChatRoomMessage.objects.create(room_id=room.id, sender_id=sender_user.id, content=content)


def _persist_report_card_pdf(report_card):
    pdf_buffer = _render_report_card_pdf(report_card)
    student_slug = slugify(report_card.student.full_name) or f"student-{report_card.student_id}"
    exam_slug = slugify(report_card.exam.name) or f"exam-{report_card.exam_id}"
    file_name = f"report_card_{student_slug}_{exam_slug}.pdf"

    report_card.pdf_file.save(file_name, ContentFile(pdf_buffer.getvalue()), save=False)
    report_card.save(update_fields=["pdf_file"])


def teacher_login(request):
    teacher = _get_logged_in_teacher(request)
    if request.user.is_authenticated and teacher:
        return redirect("teacher_dashboard")

    if request.method == "POST":
        username = request.POST.get("username", "").strip()
        password = request.POST.get("password", "")

        user = authenticate(request, username=username, password=password)
        if user and TeacherProfile.objects.filter(user=user).exists():
            login(request, user)
            messages.success(request, "Logged in successfully.")
            return redirect("teacher_dashboard")

        if user:
            messages.error(request, "This account is not linked to a teacher profile.")
        else:
            messages.error(request, "Invalid username or password.")

    return render(request, "teacher/login.html")


@login_required(login_url="teacher_login")
def teacher_dashboard(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    assignments = TeacherAssignment.objects.filter(teacher=teacher).select_related("class_section", "subject")
    
    # Check if teacher is a class teacher
    try:
        class_teacher_record = ClassTeacher.objects.get(teacher=teacher)
        is_class_teacher = True
        class_teacher_class = class_teacher_record.class_section
    except ClassTeacher.DoesNotExist:
        is_class_teacher = False
        class_teacher_class = None
    
    return render(request, "teacher/dashboard.html", {
        "teacher": teacher,
        "assignments": assignments,
        "is_class_teacher": is_class_teacher,
        "class_teacher_class": class_teacher_class,
    })


@login_required(login_url="teacher_login")
def mark_attendance(request, class_id):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    # Check if teacher is the class teacher
    class_section = get_object_or_404(ClassSection, id=class_id)
    try:
        class_teacher = ClassTeacher.objects.get(class_section=class_section)
        if class_teacher.teacher != teacher:
            messages.error(request, "You are not the class teacher for this class and cannot mark attendance.")
            return redirect("teacher_dashboard")
    except ClassTeacher.DoesNotExist:
        messages.error(request, "No class teacher assigned for this class.")
        return redirect("teacher_dashboard")

    students = Student.objects.filter(class_section=class_section).order_by("full_name")

    if request.method == "POST":
        for student in students:
            status = "PRESENT" if f"student_{student.id}" in request.POST else "ABSENT"
            Attendance.objects.update_or_create(student=student, date=date.today(), defaults={"status": status})

        messages.success(request, f"Attendance saved for {class_section}.")
        return redirect("teacher_dashboard")

    return render(request, "teacher/attendance.html", {"students": students, "class_section": class_section})


@login_required(login_url="teacher_login")
def manage_timetable(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    # Get classes where this teacher is the class teacher
    try:
        class_teacher_record = ClassTeacher.objects.get(teacher=teacher)
        class_section = class_teacher_record.class_section
    except ClassTeacher.DoesNotExist:
        messages.error(request, "You are not assigned as a class teacher for any class.")
        return redirect("teacher_dashboard")

    timetables = Timetable.objects.filter(class_section=class_section).order_by("day", "period")

    if request.method == "POST":
        # Handle timetable updates
        for timetable in timetables:
            day = request.POST.get(f"day_{timetable.id}")
            period = request.POST.get(f"period_{timetable.id}")
            subject_id = request.POST.get(f"subject_{timetable.id}")
            start_time = request.POST.get(f"start_time_{timetable.id}")
            end_time = request.POST.get(f"end_time_{timetable.id}")

            if day and period and start_time and end_time:
                timetable.day = day
                timetable.period = int(period)
                timetable.subject_id = subject_id if subject_id else None
                timetable.start_time = start_time
                timetable.end_time = end_time
                timetable.save()

        messages.success(request, "Timetable updated successfully.")
        return redirect("manage_timetable")

    from academics.models import Subject
    subjects = Subject.objects.all()
    days = Timetable.DAYS_OF_WEEK

    return render(request, "teacher/timetable.html", {
        "class_section": class_section,
        "timetables": timetables,
        "subjects": subjects,
        "days": days,
    })


@login_required(login_url="teacher_login")
def upload_material(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    assignments = TeacherAssignment.objects.filter(teacher=teacher).select_related("class_section", "subject")
    allowed_class_ids = set(assignments.values_list("class_section_id", flat=True))
    allowed_subject_ids = set(assignments.values_list("subject_id", flat=True))

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        file_obj = request.FILES.get("file")

        try:
            class_id = int(request.POST.get("class", 0))
            subject_id = int(request.POST.get("subject", 0))
        except (TypeError, ValueError):
            class_id = 0
            subject_id = 0

        if title and file_obj and class_id in allowed_class_ids and subject_id in allowed_subject_ids:
            StudyMaterial.objects.create(
                title=title,
                file=file_obj,
                subject_id=subject_id,
                class_section_id=class_id,
                uploaded_by=teacher,
            )
            messages.success(request, "Study material uploaded successfully.")
            return redirect("teacher_dashboard")

        messages.error(request, "Upload failed. Check title, file, class, and subject.")

    return render(request, "teacher/upload_material.html", {"assignments": assignments})


@login_required(login_url="teacher_login")
def post_announcement(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    assignments = TeacherAssignment.objects.filter(teacher=teacher).select_related("class_section", "subject")
    allowed_class_ids = set(assignments.values_list("class_section_id", flat=True))

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        body = request.POST.get("body", "").strip()

        try:
            class_id = int(request.POST.get("class", 0))
        except (TypeError, ValueError):
            class_id = 0

        if title and body and class_id in allowed_class_ids:
            Announcement.objects.create(
                title=title,
                body=body,
                created_by=request.user,
                target_class_id=class_id,
            )
            messages.success(request, "Announcement posted successfully.")
            return redirect("teacher_dashboard")

        messages.error(request, "Post failed. Check title, body, and class.")

    return render(request, "teacher/post_announcement.html", {"assignments": assignments})


@login_required(login_url="teacher_login")
def teacher_messages(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    base_threads = ConversationThread.objects.filter(teacher=teacher).annotate(
        message_count=Count("messages")
    ).filter(
        message_count__gt=0
    ).select_related(
        "student", "parent", "teacher", "parent__user"
    ).prefetch_related(
        Prefetch("messages", queryset=Message.objects.select_related("sender").order_by("timestamp"))
    ).order_by("-created_at")

    assigned_classes = ClassSection.objects.filter(
        id__in=TeacherAssignment.objects.filter(teacher=teacher).values_list("class_section_id", flat=True)
    ).distinct()

    # Automatically provision one group chat per assigned class.
    for class_section in assigned_classes:
        room_name = f"{class_section} Parents"
        class_rooms = list(
            ChatRoom.objects.filter(is_group=True, class_section=class_section).order_by("id")
        )

        if class_rooms:
            # Prefer an existing correctly named room to avoid unique-key conflicts when normalizing names.
            room = next((existing_room for existing_room in class_rooms if existing_room.name == room_name), class_rooms[0])

            # Merge any accidental duplicate class group rooms into the primary room.
            for duplicate_room in class_rooms:
                if duplicate_room.id == room.id:
                    continue
                with transaction.atomic():
                    for membership in ChatRoomMember.objects.filter(room=duplicate_room):
                        ChatRoomMember.objects.get_or_create(room=room, user_id=membership.user_id)
                    ChatRoomMessage.objects.filter(room=duplicate_room).update(room=room)
                    duplicate_room.delete()

            update_fields = []
            if room.name != room_name:
                room.name = room_name
                update_fields.append("name")
            if room.direct_teacher_id is None:
                room.direct_teacher = teacher
                update_fields.append("direct_teacher")
            if update_fields:
                update_fields.append("updated_at")
                room.save(update_fields=update_fields)
        else:
            room = ChatRoom.objects.create(
                is_group=True,
                class_section=class_section,
                name=room_name,
                direct_teacher=teacher,
                student=None,
                created_by=request.user,
            )

        parent_users = ParentStudentLink.objects.filter(
            student__class_section=class_section
        ).select_related("parent__user").values_list("parent__user", flat=True).distinct()
        class_teacher_users = TeacherAssignment.objects.filter(
            class_section=class_section
        ).values_list("teacher__user", flat=True).distinct()

        with transaction.atomic():
            ChatRoomMember.objects.get_or_create(room=room, user=request.user)
            for parent_user_id in parent_users:
                ChatRoomMember.objects.get_or_create(room=room, user_id=parent_user_id)
            for teacher_user_id in class_teacher_users:
                ChatRoomMember.objects.get_or_create(room=room, user_id=teacher_user_id)

    group_rooms = ChatRoom.objects.filter(
        is_group=True,
        class_section__in=assigned_classes,
    ).prefetch_related(
        Prefetch("messages", queryset=ChatRoomMessage.objects.select_related("sender").order_by("created_at")),
        "memberships__user",
    ).order_by("class_section__class_name", "class_section__section", "name")

    search_query = request.GET.get("q", "").strip()

    threads = base_threads
    rooms = group_rooms
    if search_query:
        threads = threads.filter(
            Q(student__full_name__icontains=search_query)
            | Q(parent__full_name__icontains=search_query)
            | Q(parent__user__username__icontains=search_query)
        )
        rooms = rooms.filter(
            Q(name__icontains=search_query)
            | Q(memberships__user__first_name__icontains=search_query)
            | Q(memberships__user__last_name__icontains=search_query)
            | Q(memberships__user__username__icontains=search_query)
        ).distinct()

    try:
        active_room_id = int(request.GET.get("room", 0))
    except (TypeError, ValueError):
        active_room_id = 0

    try:
        active_thread_id = int(request.GET.get("thread", 0))
    except (TypeError, ValueError):
        active_thread_id = 0

    active_room = rooms.filter(id=active_room_id).first() if active_room_id else None
    active_room_messages = active_room.messages.all() if active_room else []

    active_thread = None
    active_messages = []
    if not active_room:
        active_thread = threads.filter(id=active_thread_id).first() if active_thread_id else threads.first()
        active_messages = active_thread.messages.all() if active_thread else []

    return render(
        request,
        "teacher/messages.html",
        {
            "threads": threads,
            "all_threads": base_threads,
            "group_rooms": rooms,
            "active_room": active_room,
            "active_room_messages": active_room_messages,
            "active_thread": active_thread,
            "active_messages": active_messages,
            "search_query": search_query,
        },
    )


@login_required(login_url="teacher_login")
def reply_message(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    thread_id = 0
    if request.method == "POST":
        content = request.POST.get("content", "").strip()

        try:
            room_id = int(request.POST.get("room_id", 0))
        except (TypeError, ValueError):
            room_id = 0

        try:
            thread_id = int(request.POST.get("thread_id", 0))
        except (TypeError, ValueError):
            thread_id = 0

        if room_id:
            allowed_class_ids = TeacherAssignment.objects.filter(teacher=teacher).values_list("class_section_id", flat=True)
            room = ChatRoom.objects.filter(
                id=room_id,
                is_group=True,
                class_section_id__in=allowed_class_ids,
            ).first()
            if room and content:
                ChatRoomMessage.objects.create(room=room, sender=request.user, content=content)
                messages.success(request, "Group message sent.")
            else:
                messages.error(request, "Message failed. Invalid group or empty message.")
            return redirect(f"{reverse('teacher_messages')}?room={room_id}")

        thread = ConversationThread.objects.filter(id=thread_id, teacher=teacher).first()
        if thread and content:
            Message.objects.create(thread=thread, sender=request.user, content=content)
            _sync_thread_message_to_direct_room(thread, request.user, content)
            messages.success(request, "Reply sent.")
        else:
            messages.error(request, "Reply failed. Invalid thread or empty message.")

    if thread_id:
        return redirect(f"{reverse('teacher_messages')}?thread={thread_id}")
    return redirect("teacher_messages")


def teacher_logout(request):
    logout(request)
    messages.success(request, "Logged out successfully.")
    return redirect("teacher_login")


@login_required(login_url="teacher_login")
def enter_marks(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    assignments = TeacherAssignment.objects.filter(teacher=teacher).select_related("class_section", "subject")
    exams = Exam.objects.all().order_by("-academic_year", "name")

    allowed_pairs = {(a.class_section_id, a.subject_id) for a in assignments}

    source = request.POST if request.method == "POST" else request.GET
    try:
        class_id = int(source.get("class", 0))
        subject_id = int(source.get("subject", 0))
        exam_id = int(source.get("exam", 0))
    except (TypeError, ValueError):
        class_id = 0
        subject_id = 0
        exam_id = 0

    students = Student.objects.none()
    student_rows = []
    selection_is_valid = (class_id, subject_id) in allowed_pairs and exam_id > 0

    if selection_is_valid:
        students = Student.objects.filter(class_section_id=class_id).order_by("full_name")
        existing_marks = {
            m.student_id: m.score
            for m in Marks.objects.filter(
                subject_id=subject_id,
                exam_id=exam_id,
                student_id__in=students.values_list("id", flat=True),
            )
        }
        student_rows = [{"student": s, "score": existing_marks.get(s.id, "")} for s in students]

    if request.method == "POST" and request.POST.get("action") == "save":
        if not selection_is_valid:
            messages.error(request, "Select a valid class, subject, and exam.")
            return redirect("enter_marks")

        for student in students:
            raw_score = request.POST.get(f"mark_{student.id}", "").strip()
            if raw_score == "":
                continue

            try:
                score = Decimal(raw_score)
            except (InvalidOperation, TypeError):
                messages.error(request, f"Invalid score for {student.full_name}.")
                return redirect(f"{reverse('enter_marks')}?class={class_id}&subject={subject_id}&exam={exam_id}")

            if score < 0 or score > 100:
                messages.error(request, f"Score for {student.full_name} must be between 0 and 100.")
                return redirect(f"{reverse('enter_marks')}?class={class_id}&subject={subject_id}&exam={exam_id}")

            Marks.objects.update_or_create(
                student=student,
                subject_id=subject_id,
                exam_id=exam_id,
                defaults={"score": score, "uploaded_by": teacher},
            )

        messages.success(request, "Marks saved successfully.")
        return redirect(f"{reverse('enter_marks')}?class={class_id}&subject={subject_id}&exam={exam_id}")

    return render(
        request,
        "teacher/enter_marks.html",
        {
            "assignments": assignments,
            "exams": exams,
            "students": students,
            "student_rows": student_rows,
            "selected_class": class_id,
            "selected_subject": subject_id,
            "selected_exam": exam_id,
        },
    )


@login_required(login_url="teacher_login")
def generate_report_cards(request):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        messages.error(request, "Please sign in with a teacher account.")
        return redirect("teacher_login")

    assignments = TeacherAssignment.objects.filter(teacher=teacher).select_related("class_section", "subject")
    exams = Exam.objects.all().order_by("-academic_year", "name")

    allowed_class_ids = set(assignments.values_list("class_section_id", flat=True))

    source = request.POST if request.method == "POST" else request.GET
    try:
        class_id = int(source.get("class", 0))
        exam_id = int(source.get("exam", 0))
    except (TypeError, ValueError):
        class_id = 0
        exam_id = 0

    report_preview = []
    if class_id in allowed_class_ids and exam_id > 0:
        report_preview = _report_preview_for(class_id, exam_id)

    if request.method == "POST" and class_id in allowed_class_ids and exam_id > 0:
        action = request.POST.get("action")
        students = Student.objects.filter(class_section_id=class_id)

        if action == "generate":
            failed_pdf_count = 0
            for student in students:
                marks_qs = Marks.objects.filter(student=student, exam_id=exam_id)
                subject_count = marks_qs.count()
                total = sum((m.score for m in marks_qs), Decimal("0"))
                percentage = Decimal("0") if subject_count == 0 else (total / Decimal(subject_count)).quantize(Decimal("0.01"))
                grade = _calculate_grade(percentage)
                remarks = request.POST.get(f"remark_{student.id}", "").strip()

                report_card, _ = ReportCard.objects.update_or_create(
                    student=student,
                    exam_id=exam_id,
                    defaults={
                        "total": total,
                        "percentage": percentage,
                        "grade": grade,
                        "remarks": remarks,
                    },
                )

                try:
                    _persist_report_card_pdf(report_card)
                except Exception:
                    failed_pdf_count += 1

            if failed_pdf_count == 0:
                messages.success(request, "Report cards generated.")
            else:
                messages.warning(
                    request,
                    f"Report cards generated, but {failed_pdf_count} PDF file(s) could not be saved.",
                )
            return redirect(f"{reverse('generate_report_cards')}?class={class_id}&exam={exam_id}")

        if action == "publish":
            updated = ReportCard.objects.filter(student__class_section_id=class_id, exam_id=exam_id).update(
                is_published=True,
                published_on=timezone.now(),
            )
            messages.success(request, f"Published {updated} report cards.")
            return redirect(f"{reverse('generate_report_cards')}?class={class_id}&exam={exam_id}")

        if action == "unpublish":
            updated = ReportCard.objects.filter(student__class_section_id=class_id, exam_id=exam_id).update(
                is_published=False,
                published_on=None,
            )
            messages.success(request, f"Unpublished {updated} report cards.")
            return redirect(f"{reverse('generate_report_cards')}?class={class_id}&exam={exam_id}")

    return render(
        request,
        "teacher/report_cards.html",
        {
            "assignments": assignments,
            "exams": exams,
            "selected_class": class_id,
            "selected_exam": exam_id,
            "report_preview": report_preview,
        },
    )


@login_required(login_url="teacher_login")
def download_report_card_pdf(request, student_id, exam_id):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        return redirect("teacher_login")

    allowed_class_ids = set(
        TeacherAssignment.objects.filter(teacher=teacher).values_list("class_section_id", flat=True)
    )

    report_card = get_object_or_404(
        ReportCard,
        student_id=student_id,
        exam_id=exam_id,
        student__class_section_id__in=allowed_class_ids,
    )

    pdf_buffer = _render_report_card_pdf(report_card)
    filename = f"report_card_{report_card.student.full_name.replace(' ', '_')}_{report_card.exam.name}.pdf"

    response = HttpResponse(pdf_buffer.getvalue(), content_type="application/pdf")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    return response


@login_required(login_url="teacher_login")
def download_class_report_cards_pdf(request, class_id, exam_id):
    teacher = _get_logged_in_teacher(request)
    if teacher is None:
        return redirect("teacher_login")

    allowed_class_ids = set(
        TeacherAssignment.objects.filter(teacher=teacher).values_list("class_section_id", flat=True)
    )
    if class_id not in allowed_class_ids:
        messages.error(request, "You are not assigned to this class.")
        return redirect("generate_report_cards")

    report_cards = ReportCard.objects.filter(student__class_section_id=class_id, exam_id=exam_id).select_related(
        "student", "exam"
    )
    if not report_cards.exists():
        messages.error(request, "No report cards found for selected class/exam.")
        return redirect(f"{reverse('generate_report_cards')}?class={class_id}&exam={exam_id}")

    buffer = BytesIO()
    p = canvas.Canvas(buffer, pagesize=A4)
    w, h = A4

    exam = report_cards.first().exam
    y = h - 50
    p.setFont("Helvetica-Bold", 15)
    p.drawString(50, y, f"Class Report Cards - {exam.name} ({exam.academic_year})")

    y -= 28
    p.setFont("Helvetica-Bold", 10)
    p.drawString(50, y, "Student")
    p.drawString(290, y, "Total")
    p.drawString(360, y, "Percent")
    p.drawString(440, y, "Grade")

    y -= 10
    p.line(50, y, w - 50, y)

    p.setFont("Helvetica", 10)
    for rc in report_cards.order_by("student__full_name"):
        y -= 18
        if y < 50:
            p.showPage()
            y = h - 50
            p.setFont("Helvetica", 10)
        p.drawString(50, y, rc.student.full_name)
        p.drawRightString(340, y, str(rc.total))
        p.drawRightString(420, y, f"{rc.percentage}%")
        p.drawString(440, y, rc.grade)

    p.showPage()
    p.save()
    buffer.seek(0)

    response = HttpResponse(buffer.getvalue(), content_type="application/pdf")
    response["Content-Disposition"] = 'attachment; filename="class_report_cards.pdf"'
    return response
