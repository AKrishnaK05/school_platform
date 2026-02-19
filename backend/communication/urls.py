from django.urls import path
from .views import announcements, get_threads, send_message

urlpatterns = [
    path("announcements/", announcements),
    path("threads/<int:parent_id>/", get_threads),
    path("send-message/", send_message),
]
