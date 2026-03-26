from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import (
    Announcement,
    ConversationThread,
    Message,
    ChatRoom,
    ChatRoomMember,
    ChatRoomMessage,
)
from academics.models import ParentStudentLink, TeacherAssignment, Student
from accounts.models import ParentProfile, TeacherProfile, User
from .serializers import (
    AnnouncementSerializer,
    ThreadSerializer,
    ChatThreadSummarySerializer,
    ChatMessageSerializer,
    ChatRoomSerializer,
    ChatRoomMessageSerializer,
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


def _display_name_for_user(user):
    teacher = TeacherProfile.objects.filter(user_id=user.id).first()
    if teacher:
        return teacher.full_name

    parent = ParentProfile.objects.filter(user_id=user.id).first()
    if parent:
        return parent.full_name

    return user.username


@api_view(["GET"])
def chat_rooms_v2(request):
    user_id = request.query_params.get("user_id")
    student_id = request.query_params.get("student_id")

    if not user_id:
        return Response(
            {"detail": "user_id is required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        user_id_int = int(user_id)
    except (TypeError, ValueError):
        return Response(
            {"detail": "user_id must be an integer"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = User.objects.filter(id=user_id_int).first()
    if not user:
        return Response({"detail": "User not found"}, status=status.HTTP_404_NOT_FOUND)

    parent_profile = ParentProfile.objects.filter(user_id=user.id).first()
    if parent_profile:
        links = ParentStudentLink.objects.filter(parent_id=parent_profile.id).select_related(
            "student", "student__class_section"
        )

        if student_id:
            try:
                student_id_int = int(student_id)
            except (TypeError, ValueError):
                return Response(
                    {"detail": "student_id must be an integer"},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            links = links.filter(student_id=student_id_int)

        for link in links:
            student = link.student
            class_section = student.class_section

            assignments = TeacherAssignment.objects.filter(
                class_section_id=class_section.id
            ).select_related("teacher")

            for assignment in assignments:
                teacher = assignment.teacher
                room, _ = ChatRoom.objects.get_or_create(
                    is_group=False,
                    student_id=student.id,
                    direct_teacher_id=teacher.id,
                    defaults={
                        "name": teacher.full_name,
                        "class_section_id": class_section.id,
                        "created_by_id": user.id,
                    },
                )

                ChatRoomMember.objects.get_or_create(room_id=room.id, user_id=user.id)
                ChatRoomMember.objects.get_or_create(
                    room_id=room.id,
                    user_id=teacher.user_id,
                )

            group_room, _ = ChatRoom.objects.get_or_create(
                is_group=True,
                class_section_id=class_section.id,
                name=f"{class_section} Group",
                defaults={
                    "created_by_id": user.id,
                    "student_id": student.id,
                },
            )

            class_parent_user_ids = ParentProfile.objects.filter(
                parentstudentlink__student__class_section_id=class_section.id
            ).values_list("user_id", flat=True).distinct()

            class_teacher_user_ids = TeacherProfile.objects.filter(
                teacherassignment__class_section_id=class_section.id
            ).values_list("user_id", flat=True).distinct()

            for member_user_id in set(class_parent_user_ids) | set(class_teacher_user_ids):
                ChatRoomMember.objects.get_or_create(
                    room_id=group_room.id,
                    user_id=member_user_id,
                )

    rooms_query = (
        ChatRoom.objects
        .filter(memberships__user_id=user.id)
        .select_related("student", "class_section")
        .prefetch_related("memberships__user", "messages")
        .distinct()
    )

    if student_id:
        try:
            selected_student = Student.objects.get(id=int(student_id))
            canonical_group_name = f"{selected_student.class_section} Group"
            rooms_query = rooms_query.filter(
                student_id=selected_student.id,
                class_section_id=selected_student.class_section_id,
            ) | rooms_query.filter(
                is_group=True,
                class_section_id=selected_student.class_section_id,
                name=canonical_group_name,
            )
            rooms_query = rooms_query.distinct()
        except (Student.DoesNotExist, ValueError, TypeError):
            pass

    rooms = rooms_query.order_by("-updated_at")

    payload = []
    for room in rooms:
        members = [membership.user for membership in room.memberships.all()]
        other_members = [member for member in members if member.id != user.id]
        member_names = [_display_name_for_user(member) for member in other_members]

        title = room.name
        if not room.is_group and other_members:
            title = _display_name_for_user(other_members[0])

        last_message = room.messages.order_by("-created_at").first()
        payload.append({
            "room_id": room.id,
            "name": title,
            "is_group": room.is_group,
            "student_id": room.student_id,
            "class_name": str(room.class_section) if room.class_section else "",
            "member_names": member_names,
            "last_message": last_message.content if last_message else "",
            "last_message_at": last_message.created_at if last_message else None,
        })

    serializer = ChatRoomSerializer(payload, many=True)
    return Response(serializer.data)


@api_view(["GET", "POST"])
def chat_room_messages_v2(request, room_id):
    user_id = request.query_params.get("user_id") if request.method == "GET" else request.data.get("user_id")
    if not user_id:
        return Response(
            {"detail": "user_id is required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        user_id_int = int(user_id)
    except (TypeError, ValueError):
        return Response(
            {"detail": "user_id must be an integer"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    room = ChatRoom.objects.filter(id=room_id).first()
    if not room:
        return Response({"detail": "Room not found"}, status=status.HTTP_404_NOT_FOUND)

    if not ChatRoomMember.objects.filter(room_id=room.id, user_id=user_id_int).exists():
        return Response(
            {"detail": "You are not a member of this room"},
            status=status.HTTP_403_FORBIDDEN,
        )

    if request.method == "GET":
        messages = room.messages.select_related("sender").order_by("created_at")
        payload = [
            {
                "id": msg.id,
                "room_id": room.id,
                "sender_id": msg.sender_id,
                "sender_name": _display_name_for_user(msg.sender),
                "content": msg.content,
                "created_at": msg.created_at,
            }
            for msg in messages
        ]
        serializer = ChatRoomMessageSerializer(payload, many=True)
        return Response(serializer.data)

    content = (request.data.get("content") or "").strip()
    if not content:
        return Response(
            {"detail": "content cannot be empty"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    message = ChatRoomMessage.objects.create(
        room_id=room.id,
        sender_id=user_id_int,
        content=content,
    )
    room.save(update_fields=["updated_at"])

    serializer = ChatRoomMessageSerializer(
        {
            "id": message.id,
            "room_id": room.id,
            "sender_id": message.sender_id,
            "sender_name": _display_name_for_user(message.sender),
            "content": message.content,
            "created_at": message.created_at,
        }
    )
    return Response(serializer.data, status=status.HTTP_201_CREATED)
