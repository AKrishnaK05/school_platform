from django.contrib import admin
from .models import User, Role, UserRole, TeacherProfile, ParentProfile

admin.site.register(User)
admin.site.register(Role)
admin.site.register(UserRole)
admin.site.register(TeacherProfile)
admin.site.register(ParentProfile)

