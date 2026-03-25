from django.contrib.auth.hashers import identify_hasher, make_password
from django.core.exceptions import ValidationError
from django.db import migrations


def hash_teacher_passwords(apps, schema_editor):
    TeacherProfile = apps.get_model("accounts", "TeacherProfile")

    for teacher_profile in TeacherProfile.objects.select_related("user").all():
        user = teacher_profile.user
        if not user or not user.password:
            continue

        try:
            identify_hasher(user.password)
        except (ValueError, ValidationError):
            user.password = make_password(user.password)
            user.save(update_fields=["password"])


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(hash_teacher_passwords, migrations.RunPython.noop),
    ]
