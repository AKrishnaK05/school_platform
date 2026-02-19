from django.contrib import admin
from .models import Announcement, ConversationThread, Message

admin.site.register(Announcement)
admin.site.register(ConversationThread)
admin.site.register(Message)
