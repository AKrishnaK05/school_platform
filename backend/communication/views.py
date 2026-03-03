from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Announcement, ConversationThread, Message
from academics.models import ParentStudentLink, TeacherAssignment
from .serializers import (
    AnnouncementSerializer,
    ThreadSerializer,
    ChatThreadSummarySerializer,
    ChatMessageSerializer,
)


@api_view(["GET"])
def announcements(request):
    data = Announcement.objects.all().order_by("-created_at")
    serializer = AnnouncementSerializer(data, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def get_threads(request, parent_id):
    threads = ConversationThread.objects.filter(parent_id=parent_id)
    serializer = ThreadSerializer(threads, many=True)
    return Response(serializer.data)


@api_view(["POST"])
def send_message(request):
    thread_id = request.data.get("thread_id")
    sender_id = request.data.get("sender_id")
    content = request.data.get("content")

    message = Message.objects.create(
        thread_id=thread_id,
        sender_id=sender_id,
        content=content
    )

    return Response({"status": "Message sent"})


@api_view(["GET"])
def parent_chat_threads(request, parent_id):
    student_filter = request.query_params.get("student_id")

    student_ids = list(
        ParentStudentLink.objects.filter(parent_id=parent_id)
        .values_list("student_id", flat=True)
    )

    if student_filter is not None:
        try:
            selected_student_id = int(student_filter)
        except (TypeError, ValueError):
            return Response(
                {"detail": "student_id must be an integer"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if selected_student_id not in student_ids:
            return Response([], status=status.HTTP_200_OK)

        student_ids = [selected_student_id]

    teacher_assignments = (
        TeacherAssignment.objects
        .filter(class_section_id__in=(
            ParentStudentLink.objects.filter(
                parent_id=parent_id,
                student_id__in=student_ids,
            )
            .values_list("student__class_section_id", flat=True)
        ))
        .select_related("teacher")
    )

    student_class_map = {
        link.student_id: link.student.class_section_id
        for link in ParentStudentLink.objects
        .filter(parent_id=parent_id, student_id__in=student_ids)
        .select_related("student")
    }

    class_teacher_map = {}
    for assignment in teacher_assignments:
        class_teacher_map.setdefault(assignment.class_section_id, set()).add(
            assignment.teacher_id
        )

    for student_id in student_ids:
        class_id = student_class_map.get(student_id)
        teacher_ids = class_teacher_map.get(class_id, set())
        for teacher_id in teacher_ids:
            ConversationThread.objects.get_or_create(
                parent_id=parent_id,
                student_id=student_id,
                teacher_id=teacher_id,
            )

    threads = (
        ConversationThread.objects
        .filter(parent_id=parent_id, student_id__in=student_ids)
        .select_related("student", "teacher")
        .prefetch_related("messages__sender")
        .order_by("-created_at")
    )

    payload = []
    for thread in threads:
        last_message = thread.messages.order_by("-timestamp").first()
        payload.append({
            "thread_id": thread.id,
            "student_id": thread.student_id,
            "student_name": thread.student.full_name,
            "teacher_id": thread.teacher_id,
            "teacher_name": thread.teacher.full_name,
            "last_message": last_message.content if last_message else "",
            "last_message_at": last_message.timestamp if last_message else None,
        })

    serializer = ChatThreadSummarySerializer(payload, many=True)
    return Response(serializer.data)


@api_view(["GET"])
def thread_messages(request, thread_id):
    thread = ConversationThread.objects.filter(id=thread_id).first()
    if not thread:
        return Response({"detail": "Thread not found"}, status=status.HTTP_404_NOT_FOUND)

    messages = (
        Message.objects
        .filter(thread_id=thread_id)
        .select_related("sender")
        .order_by("timestamp")
    )

    payload = []
    for msg in messages:
        role = "PARENT" if thread.parent.user_id == msg.sender_id else "TEACHER"
        payload.append({
            "id": msg.id,
            "sender_id": msg.sender_id,
            "sender_name": msg.sender.username,
            "sender_role": role,
            "content": msg.content,
            "timestamp": msg.timestamp,
        })

    serializer = ChatMessageSerializer(payload, many=True)
    return Response(serializer.data)


@api_view(["POST"])
def send_parent_message(request, thread_id):
    parent_id = request.data.get("parent_id")
    content = (request.data.get("content") or "").strip()

    if not parent_id:
        return Response(
            {"detail": "parent_id is required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if not content:
        return Response(
            {"detail": "content cannot be empty"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    thread = ConversationThread.objects.filter(id=thread_id, parent_id=parent_id).first()
    if not thread:
        return Response(
            {"detail": "Thread not found for this parent"},
            status=status.HTTP_404_NOT_FOUND,
        )

    message = Message.objects.create(
        thread_id=thread.id,
        sender_id=thread.parent.user_id,
        content=content,
    )

    response_payload = {
        "id": message.id,
        "sender_id": message.sender_id,
        "sender_name": message.sender.username,
        "sender_role": "PARENT",
        "content": message.content,
        "timestamp": message.timestamp,
    }
    serializer = ChatMessageSerializer(response_payload)
    return Response(serializer.data, status=status.HTTP_201_CREATED)
