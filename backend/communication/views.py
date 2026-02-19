from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Announcement, ConversationThread, Message
from .serializers import AnnouncementSerializer, ThreadSerializer, MessageSerializer


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
