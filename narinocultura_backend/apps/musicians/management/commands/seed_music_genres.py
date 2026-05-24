from django.core.management.base import BaseCommand
from django.utils.text import slugify

from apps.musicians.models import MusicGenre

GENRES = [
    ("Rock", "Música de rock en todas sus variantes", "🎸"),
    ("Rock Alternativo", "Rock alternativo e independiente", "🎸"),
    ("Metal", "Metal y sus subgéneros", "🤘"),
    ("Pop", "Música pop contemporánea", "🎤"),
    ("Salsa", "Salsa colombiana y afrocaribeña", "🎺"),
    ("Cumbia", "Cumbia colombiana tradicional y fusión", "🥁"),
    ("Cumbia Nariñense", "Cumbia propia de la región de Nariño", "🥁"),
    ("Vallenato", "Vallenato tradicional colombiano", "🪗"),
    ("Hip Hop", "Hip hop y cultura urbana", "🎧"),
    ("Rap", "Rap y spoken word", "🎤"),
    ("Jazz", "Jazz y sus fusiones", "🎷"),
    ("Blues", "Blues americano y fusiones latinas", "🎸"),
    ("Electrónica", "Música electrónica y dance", "🎛️"),
    ("Reggaetón", "Reggaetón y música urbana latina", "🎶"),
    ("Reggae", "Reggae jamaicano y fusión latina", "🎵"),
    ("Música Andina", "Música andina colombiana tradicional", "🪘"),
    ("Folclore", "Música folclórica de Nariño y Colombia", "🎼"),
    ("Chirimía", "Chirimía del Pacífico nariñense", "🎺"),
    ("Bambuco", "Bambuco, aire típico colombiano", "🪗"),
    ("Pasillo", "Pasillo colombiano", "🎻"),
    ("Marimba", "Música de marimba del Pacífico", "🪘"),
    ("Indie", "Música indie y alternativa", "🎸"),
    ("Bolero", "Bolero romántico latinoamericano", "🎤"),
    ("Tropical", "Música tropical y caribeña", "🎶"),
    ("Funk", "Funk y soul", "🎸"),
    ("R&B", "Rhythm and Blues contemporáneo", "🎤"),
    ("Gospel", "Gospel y música cristiana", "🎼"),
    ("Experimental", "Música experimental y vanguardia", "🎛️"),
    ("Fusión", "Fusión de géneros y propuestas híbridas", "🎵"),
    ("Trova", "Trova y canción de autor", "🎸"),
]


class Command(BaseCommand):
    help = "Seed initial music genres for the musicians module"

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Delete all existing genres before seeding",
        )

    def handle(self, *args, **options):
        if options["clear"]:
            deleted, _ = MusicGenre.objects.all().delete()
            self.stdout.write(self.style.WARNING(f"Deleted {deleted} existing genres."))

        created_count = 0
        updated_count = 0

        for name, description, icon in GENRES:
            slug = slugify(name)
            genre, created = MusicGenre.objects.update_or_create(
                slug=slug,
                defaults={"name": name, "description": description, "icon": icon},
            )
            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Done: {created_count} genres created, {updated_count} updated."
            )
        )
