from django.db import migrations


DEFAULT_CATEGORIES = [
    {
        "name": "Pintura",
        "slug": "pintura",
        "description": "Obras pictoricas en diferentes tecnicas y soportes.",
    },
    {
        "name": "Escultura",
        "slug": "escultura",
        "description": "Piezas tridimensionales elaboradas en diversos materiales.",
    },
    {
        "name": "Fotografia",
        "slug": "fotografia",
        "description": "Obras fotograficas artisticas, documentales o experimentales.",
    },
    {
        "name": "Artesania",
        "slug": "artesania",
        "description": "Creaciones artesanales vinculadas a saberes y oficios tradicionales.",
    },
    {
        "name": "Textil",
        "slug": "textil",
        "description": "Obras y piezas artisticas desarrolladas sobre fibras y tejidos.",
    },
    {
        "name": "Ceramica",
        "slug": "ceramica",
        "description": "Piezas artisticas elaboradas en arcilla, barro o materiales afines.",
    },
    {
        "name": "Grabado",
        "slug": "grabado",
        "description": "Obras graficas obtenidas por tecnicas de impresion artistica.",
    },
    {
        "name": "Digital",
        "slug": "digital",
        "description": "Creaciones artisticas desarrolladas mediante herramientas digitales.",
    },
    {
        "name": "Mixta",
        "slug": "mixta",
        "description": "Obras que combinan tecnicas, materiales o lenguajes diversos.",
    },
]


def seed_categories(apps, schema_editor):
    Category = apps.get_model("artworks", "Category")

    for category in DEFAULT_CATEGORIES:
        Category.objects.update_or_create(
            slug=category["slug"],
            defaults={
                "name": category["name"],
                "description": category["description"],
            },
        )


def unseed_categories(apps, schema_editor):
    Category = apps.get_model("artworks", "Category")
    Category.objects.filter(slug__in=[category["slug"] for category in DEFAULT_CATEGORIES]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("artworks", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(seed_categories, unseed_categories),
    ]
