from django.contrib import admin
from .models import Announcement, ConversationGroup, ConversationThread, Message

admin.site.register(Announcement)
admin.site.register(ConversationThread)
admin.site.register(Message)
admin.site.register(ConversationGroup)
