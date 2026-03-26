from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0002_hash_teacher_passwords"),
        ("communication", "0006_chatroom_chatroommember_chatroommessage"),
    ]

    operations = [
        migrations.CreateModel(
            name="ConversationGroup",
            fields=[
                ("id", models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name="ID")),
                ("name", models.CharField(max_length=100)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                (
                    "teacher",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="conversation_groups",
                        to="accounts.teacherprofile",
                    ),
                ),
                (
                    "threads",
                    models.ManyToManyField(blank=True, related_name="conversation_groups", to="communication.conversationthread"),
                ),
            ],
            options={
                "constraints": [
                    models.UniqueConstraint(
                        fields=("teacher", "name"),
                        name="uniq_conversation_group_teacher_name",
                    )
                ],
            },
        ),
    ]
