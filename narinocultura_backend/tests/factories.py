"""
Shared test factories using factory_boy.
Import these in any test module instead of manually building objects.
"""
import factory
from factory.django import DjangoModelFactory

from apps.users.models import User


class UserFactory(DjangoModelFactory):
    class Meta:
        model = User

    email = factory.Sequence(lambda n: f"user{n}@test.com")
    first_name = "Test"
    last_name = "User"
    role = User.Role.COMPRADOR
    is_active = True
    is_verified = True
    password = factory.PostGenerationMethodCall("set_password", "Test1234!")


class ArtistUserFactory(UserFactory):
    role = User.Role.ARTISTA
    email = factory.Sequence(lambda n: f"artista{n}@test.com")


class AdminUserFactory(UserFactory):
    role = User.Role.ADMINISTRADOR
    is_staff = True
    email = factory.Sequence(lambda n: f"admin{n}@test.com")


class CulturalManagerFactory(UserFactory):
    role = User.Role.GESTOR_CULTURAL
    email = factory.Sequence(lambda n: f"gestor{n}@test.com")


class ArtistProfileFactory(DjangoModelFactory):
    class Meta:
        model = "artists.ArtistProfile"

    user = factory.SubFactory(ArtistUserFactory)
    slug = factory.Sequence(lambda n: f"artista-{n}")
    artistic_name = factory.Sequence(lambda n: f"Artista {n}")
    is_public = True


class CategoryFactory(DjangoModelFactory):
    class Meta:
        model = "artworks.Category"

    name = factory.Sequence(lambda n: f"Categoria {n}")
    slug = factory.Sequence(lambda n: f"categoria-{n}")


class ArtworkFactory(DjangoModelFactory):
    class Meta:
        model = "artworks.Artwork"

    artist = factory.SubFactory(ArtistProfileFactory)
    title = factory.Sequence(lambda n: f"Obra {n}")
    price = "150000.00"
    status = "DISPONIBLE"
    description = "Descripcion de prueba"


class MusicianUserFactory(UserFactory):
    role = User.Role.ARTISTA
    email = factory.Sequence(lambda n: f"musico{n}@test.com")


class MusicGenreFactory(DjangoModelFactory):
    class Meta:
        model = "musicians.MusicGenre"
        django_get_or_create = ("slug",)

    name = factory.Sequence(lambda n: f"Genero {n}")
    slug = factory.Sequence(lambda n: f"genero-{n}")
    description = "Genero de prueba"
    icon = "🎵"


class MusicianProfileFactory(DjangoModelFactory):
    class Meta:
        model = "musicians.MusicianProfile"

    user = factory.SubFactory(MusicianUserFactory)
    artistic_name = factory.Sequence(lambda n: f"Musico {n}")
    slug = factory.Sequence(lambda n: f"musico-{n}")
    aggregation_type = "SOLISTA"
    city = "Pasto"
    region = "Narino"
    contact_email = factory.LazyAttribute(lambda o: o.user.email)
    is_active = True


class MusicalWorkFactory(DjangoModelFactory):
    class Meta:
        model = "musicians.MusicalWork"

    musician = factory.SubFactory(MusicianProfileFactory)
    title = factory.Sequence(lambda n: f"Obra Musical {n}")
    work_type = "VIDEO"
    youtube_url = "https://youtube.com/watch?v=test"
