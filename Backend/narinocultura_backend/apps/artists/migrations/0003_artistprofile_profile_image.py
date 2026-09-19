from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("artists", "0002_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="artistprofile",
            name="profile_image",
            field=models.FileField(blank=True, upload_to="artists/profiles/"),
        ),
    ]
