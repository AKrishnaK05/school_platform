from django.urls import path
from .views import (
    announcements,
    get_threads,
    send_message,
    parent_chat_threads,
    thread_messages,
    send_parent_message,
    chat_rooms_v2,
    chat_room_messages_v2,
)

urlpatterns = [
    path("announcements/", announcements),
    path("threads/<int:parent_id>/", get_threads),
    path("send-message/", send_message),
    path("chats/<int:parent_id>/", parent_chat_threads),
    path("chats/thread/<int:thread_id>/messages/", thread_messages),
    path("chats/thread/<int:thread_id>/send/", send_parent_message),
    path("chats/v2/", chat_rooms_v2),
    path("chats/v2/rooms/<int:room_id>/messages/", chat_room_messages_v2),
]
