from django.db import migrations, models


def dedupe_conversation_threads(apps, schema_editor):
    ConversationThread = apps.get_model("communication", "ConversationThread")
    Message = apps.get_model("communication", "Message")

    kept_thread_by_key = {}

    for thread in ConversationThread.objects.all().order_by("id"):
        key = (thread.parent_id, thread.student_id, thread.teacher_id)
        kept_thread_id = kept_thread_by_key.get(key)

        if kept_thread_id is None:
            kept_thread_by_key[key] = thread.id
            continue

        Message.objects.filter(thread_id=thread.id).update(thread_id=kept_thread_id)
        thread.delete()


class Migration(migrations.Migration):

    dependencies = [
        ("communication", "0004_delete_notification"),
    ]

    operations = [
        migrations.RunPython(dedupe_conversation_threads, migrations.RunPython.noop),
        migrations.AddConstraint(
            model_name="conversationthread",
            constraint=models.UniqueConstraint(
                fields=("student", "parent", "teacher"),
                name="uniq_parent_student_teacher_thread",
            ),
        ),
    ]
