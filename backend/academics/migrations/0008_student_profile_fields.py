from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("academics", "0007_assignment"),
    ]

    operations = [
        migrations.AddField(
            model_name="student",
            name="admission_no",
            field=models.CharField(blank=True, default="", max_length=30),
        ),
        migrations.AddField(
            model_name="student",
            name="address",
            field=models.TextField(blank=True, default=""),
        ),
        migrations.AddField(
            model_name="student",
            name="blood_group",
            field=models.CharField(blank=True, default="", max_length=5),
        ),
        migrations.AddField(
            model_name="student",
            name="date_of_birth",
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="student",
            name="emergency_contact_name",
            field=models.CharField(blank=True, default="", max_length=200),
        ),
        migrations.AddField(
            model_name="student",
            name="emergency_contact_phone",
            field=models.CharField(blank=True, default="", max_length=20),
        ),
        migrations.AddField(
            model_name="student",
            name="gender",
            field=models.CharField(blank=True, default="", max_length=20),
        ),
    ]
