from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("reportcards", "0002_reportcard_status_fields"),
    ]

    operations = [
        migrations.AddField(
            model_name="reportcard",
            name="remarks",
            field=models.TextField(blank=True),
        ),
    ]
