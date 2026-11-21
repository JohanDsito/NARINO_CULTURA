"""Panel de administración: búsqueda y filtros en /admin/users/ y fecha de registro."""

from rest_framework.test import APITestCase

from tests.factories import AdminUserFactory, ArtistUserFactory, UserFactory

URL = "/api/v1/admin/users/"


class AdminUserFilterTests(APITestCase):
    def setUp(self):
        self.admin = AdminUserFactory(email="admin@narino.test", first_name="Admin")
        self.ana = ArtistUserFactory(email="ana@narino.test", first_name="Ana", last_name="Pérez")
        self.luis = UserFactory(email="luis@correo.test", first_name="Luis", last_name="Guerrero", is_active=False)
        self.client.force_authenticate(user=self.admin)

    def emails(self, **params):
        r = self.client.get(URL, params)
        self.assertEqual(r.status_code, 200)
        return sorted(row["email"] for row in r.data)

    def test_sin_filtros_lista_todos(self):
        self.assertEqual(self.emails(), ["admin@narino.test", "ana@narino.test", "luis@correo.test"])

    def test_busca_por_correo_y_por_nombre(self):
        self.assertEqual(self.emails(search="correo.test"), ["luis@correo.test"])
        self.assertEqual(self.emails(search="pérez"), ["ana@narino.test"])
        self.assertEqual(self.emails(search="  Luis "), ["luis@correo.test"])

    def test_filtra_por_rol_sin_importar_mayusculas(self):
        self.assertEqual(self.emails(role="artista"), ["ana@narino.test"])

    def test_filtra_por_estado(self):
        self.assertEqual(self.emails(is_active="false"), ["luis@correo.test"])
        self.assertEqual(self.emails(is_active="true"), ["admin@narino.test", "ana@narino.test"])

    def test_un_valor_invalido_de_estado_se_ignora(self):
        self.assertEqual(len(self.emails(is_active="quizas")), 3)

    def test_filtra_por_verificacion(self):
        self.ana.is_verified = False
        self.ana.save(update_fields=["is_verified"])
        self.assertEqual(self.emails(is_verified="false"), ["ana@narino.test"])

    def test_cada_usuario_trae_su_fecha_de_registro_y_ultimo_ingreso(self):
        row = next(r for r in self.client.get(URL).data if r["email"] == "ana@narino.test")
        self.assertTrue(row["created_at"])
        self.assertIn("last_login", row)

    def test_la_fecha_de_registro_no_se_puede_editar(self):
        r = self.client.patch(f"{URL}{self.ana.id}/", {"created_at": "2000-01-01T00:00:00Z"}, format="json")
        self.assertEqual(r.status_code, 200)
        self.ana.refresh_from_db()
        self.assertNotEqual(self.ana.created_at.year, 2000)
