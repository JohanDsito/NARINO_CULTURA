"""Directorio de artistas: búsqueda con ?search= y orden con ?ordering=."""

from rest_framework.test import APITestCase

from tests.factories import ArtistProfileFactory, UserFactory

URL = "/api/v1/artists/"


def names(response):
    data = response.data["results"] if isinstance(response.data, dict) else response.data
    return [row["artistic_name"] for row in data]


class ArtistSearchTests(APITestCase):
    def setUp(self):
        self.pintora = ArtistProfileFactory(
            artistic_name="Ana Barniz", discipline="Pintor", city="Pasto", bio="Barniz de Pasto (mopa-mopa)"
        )
        self.escultor = ArtistProfileFactory(
            artistic_name="Taller del Volcán",
            discipline="Escultor",
            city="Ipiales",
            user=UserFactory(first_name="Luis", last_name="Guerrero"),
        )

    def search(self, term):
        return names(self.client.get(URL, {"search": term}))

    def test_busca_por_nombre_artistico_sin_importar_mayusculas(self):
        self.assertEqual(self.search("barniz"), ["Ana Barniz"])

    def test_busca_por_nombre_real_del_usuario(self):
        self.assertEqual(self.search("Guerrero"), ["Taller del Volcán"])

    def test_busca_por_disciplina_y_ciudad(self):
        self.assertEqual(self.search("escultor"), ["Taller del Volcán"])
        self.assertEqual(self.search("ipiales"), ["Taller del Volcán"])

    def test_busca_en_la_biografia(self):
        self.assertEqual(self.search("mopa"), ["Ana Barniz"])

    def test_sin_coincidencias_devuelve_vacio(self):
        self.assertEqual(self.search("zzzqqxx"), [])

    def test_sin_busqueda_lista_todos(self):
        self.assertEqual(sorted(names(self.client.get(URL))), ["Ana Barniz", "Taller del Volcán"])

    def test_ordena_por_nombre(self):
        self.assertEqual(names(self.client.get(URL, {"ordering": "-artistic_name"})), ["Taller del Volcán", "Ana Barniz"])

    def test_los_perfiles_privados_no_aparecen_en_la_busqueda(self):
        ArtistProfileFactory(artistic_name="Barniz Oculto", is_public=False)
        self.assertEqual(self.search("barniz"), ["Ana Barniz"])
