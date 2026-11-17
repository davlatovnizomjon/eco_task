from django.db import migrations


def seed(apps, schema_editor):
    """Publishes the contacts the app used to ship as build constants, so the first deploy changes nothing visible."""
    apps.get_model("support", "SupportContact").objects.get_or_create(
        pk=1, defaults={"phone": "+998 71 200 00 00", "telegram": "@eco_tasks_bot"}
    )


class Migration(migrations.Migration):
    dependencies = [("support", "0001_initial")]
    operations = [migrations.RunPython(seed, migrations.RunPython.noop)]
