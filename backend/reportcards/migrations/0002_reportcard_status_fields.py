from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("reportcards", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="reportcard",
            name="grade",
            field=models.CharField(blank=True, max_length=5),
        ),
        migrations.AddField(
            model_name="reportcard",
            name="is_published",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="reportcard",
            name="percentage",
            field=models.DecimalField(decimal_places=2, default=0, max_digits=6),
        ),
        migrations.AddField(
            model_name="reportcard",
            name="published_on",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name="reportcard",
            name="total",
            field=models.DecimalField(decimal_places=2, default=0, max_digits=8),
        ),
    ]
