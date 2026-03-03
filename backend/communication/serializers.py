from rest_framework import serializers
from .models import Announcement, ConversationThread, Message


class AnnouncementSerializer(serializers.ModelSerializer):
    created_by = serializers.StringRelatedField()
    target_class = serializers.StringRelatedField()

    class Meta:
        model = Announcement
        fields = [
            "id",
            "title",
            "body",
            "created_by",
            "target_class",
            "created_at",
        ]


class MessageSerializer(serializers.ModelSerializer):
    sender = serializers.StringRelatedField()

    class Meta:
        model = Message
        fields = ["id", "sender", "content", "timestamp"]


class ThreadSerializer(serializers.ModelSerializer):
    messages = MessageSerializer(many=True, read_only=True)

    class Meta:
        model = ConversationThread
        fields = ["id", "student", "messages"]


class ChatThreadSummarySerializer(serializers.Serializer):
    thread_id = serializers.IntegerField()
    student_id = serializers.IntegerField()
    student_name = serializers.CharField()
    teacher_id = serializers.IntegerField()
    teacher_name = serializers.CharField()
    last_message = serializers.CharField(allow_blank=True)
    last_message_at = serializers.DateTimeField(allow_null=True)


class ChatMessageSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    sender_id = serializers.IntegerField()
    sender_name = serializers.CharField()
    sender_role = serializers.CharField()
    content = serializers.CharField()
    timestamp = serializers.DateTimeField()
