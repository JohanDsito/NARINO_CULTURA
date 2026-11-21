"""El historial de ventas se conserva cuando el comprador elimina su cuenta.

La orden queda sin usuario (Order.buyer = NULL) pero guarda una copia del nombre y el correo del comprador,
que es el soporte del pago y lo que ve el artista en "Mis ventas".
"""

import importlib
from datetime import timedelta
from decimal import Decimal

from django.apps import apps as django_apps
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase

from apps.artworks.models import Artwork
from apps.marketplace.models import Order, OrderItem
from apps.notifications.models import Notification, NotificationLog
from apps.payments.models import Transaction
from services.auction_service import AuctionService
from services.notification_emails import build_notification_email
from tests.factories import AdminUserFactory, ArtistProfileFactory, ArtworkFactory, UserFactory
from tests.wompi import signed_wompi_event

PASSWORD = "Test1234!"  # contraseña de UserFactory
DELETE_ACCOUNT_URL = "/api/v1/auth/delete-account/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class BuyerSnapshotTests(TestCase):
    def test_la_orden_guarda_nombre_y_correo_del_comprador_al_crearse(self):
        buyer = UserFactory(first_name="Ana", last_name="Pérez", email="ana@narino.test")
        order = Order.objects.create(buyer=buyer, total_amount=Decimal("100000.00"))
        self.assertEqual((order.buyer_name, order.buyer_email), ("Ana Pérez", "ana@narino.test"))

    def test_sin_nombre_usa_el_correo(self):
        buyer = UserFactory(first_name="", last_name="", email="anonimo@narino.test")
        order = Order.objects.create(buyer=buyer, total_amount=Decimal("1.00"))
        self.assertEqual(order.buyer_name, "anonimo@narino.test")

    def test_la_copia_no_cambia_si_el_comprador_edita_su_perfil(self):
        buyer = UserFactory(first_name="Ana", last_name="Pérez")
        order = Order.objects.create(buyer=buyer, total_amount=Decimal("1.00"))
        buyer.first_name = "Otra"
        buyer.save()
        order.status = Order.Status.PAGADO
        order.save(update_fields=["status"])
        order.refresh_from_db()
        self.assertEqual(order.buyer_name, "Ana Pérez")

    def test_un_guardado_parcial_completa_la_copia_si_faltaba(self):
        buyer = UserFactory(email="tarde@narino.test")
        order = Order.objects.create(buyer=buyer, total_amount=Decimal("1.00"))
        Order.objects.filter(pk=order.pk).update(buyer_name="", buyer_email="")
        order.refresh_from_db()
        order.status = Order.Status.PAGADO
        order.save(update_fields=["status"])
        order.refresh_from_db()
        self.assertEqual(order.buyer_email, "tarde@narino.test")

    def test_la_orden_del_ganador_de_una_subasta_tambien_guarda_la_copia(self):
        winner = UserFactory(first_name="Luis", last_name="Gómez", email="luis@narino.test")
        artwork = ArtworkFactory()
        auction = type("SubastaCerrada", (), {"winner_id": winner.id, "current_price": Decimal("90000.00"), "artwork": artwork})
        order = AuctionService._create_winner_order(auction)
        self.assertEqual((order.buyer_name, order.buyer_email), ("Luis Gómez", "luis@narino.test"))

    def test_la_migracion_llena_la_copia_de_las_ordenes_existentes(self):
        buyer = UserFactory(first_name="Ana", last_name="", email="vieja@narino.test")
        order = Order.objects.create(buyer=buyer, total_amount=Decimal("1.00"))
        Order.objects.filter(pk=order.pk).update(buyer_name="", buyer_email="")
        migracion = importlib.import_module("apps.marketplace.migrations.0004_conservar_ordenes_sin_comprador")
        migracion.copiar_comprador(django_apps, None)
        order.refresh_from_db()
        self.assertEqual((order.buyer_name, order.buyer_email), ("Ana", "vieja@narino.test"))


class BuyerDeletesAccountTests(APITestCase):
    def setUp(self):
        self.buyer = UserFactory(first_name="Ana", last_name="Pérez", email="ana@narino.test")
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, status=Artwork.Status.VENDIDA)
        self.order = Order.objects.create(buyer=self.buyer, total_amount=Decimal("150000.00"), status=Order.Status.PAGADO)
        OrderItem.objects.create(order=self.order, artwork=self.artwork, price=Decimal("150000.00"))
        self.tx = Transaction.objects.create(
            order=self.order, amount=Decimal("150000.00"), currency="COP", status="APROBADO"
        )

    def _delete_buyer_account(self):
        self.client.force_authenticate(user=self.buyer)
        return self.client.delete(DELETE_ACCOUNT_URL, {"password": PASSWORD}, format="json")

    def test_la_cuenta_se_elimina_y_la_orden_y_su_pago_se_conservan(self):
        r = self._delete_buyer_account()
        self.assertEqual(r.status_code, 204)
        self.assertIn("se conservan", r.data["message"])
        self.order.refresh_from_db()
        self.assertIsNone(self.order.buyer_id)
        self.assertEqual((self.order.buyer_name, self.order.buyer_email), ("Ana Pérez", "ana@narino.test"))
        self.assertTrue(OrderItem.objects.filter(order=self.order).exists())
        self.assertTrue(Transaction.objects.filter(id=self.tx.id).exists())

    def test_el_artista_sigue_viendo_la_venta(self):
        self._delete_buyer_account()
        self.client.force_authenticate(user=self.profile.user)
        sales = results(self.client.get("/api/v1/marketplace/sales/"))
        self.assertEqual([s["id"] for s in sales], [str(self.order.id)])
        self.assertIsNone(sales[0]["buyer"])

    def test_el_admin_ve_el_correo_del_comprador_en_las_transacciones(self):
        self._delete_buyer_account()
        self.client.force_authenticate(user=AdminUserFactory())
        (row,) = self.client.get("/api/v1/admin/transactions/").data
        self.assertEqual(row["buyer_email"], "ana@narino.test")

    def test_la_orden_conservada_no_aparece_a_otro_usuario(self):
        self._delete_buyer_account()
        self.client.force_authenticate(user=UserFactory())
        self.assertEqual(results(self.client.get("/api/v1/marketplace/orders/")), [])
        self.assertEqual(self.client.get(f"/api/v1/marketplace/orders/{self.order.id}/").status_code, 404)


@override_settings(WOMPI_EVENTS_SECRET="test_events_secret")
class OrdersWithoutBuyerNotificationsTests(TestCase):
    """Pagos y vencimientos que llegan después de que el comprador eliminó su cuenta."""

    def setUp(self):
        self.buyer = UserFactory(first_name="Ana", email="ana@narino.test")
        self.profile = ArtistProfileFactory()
        self.artwork = ArtworkFactory(artist=self.profile, status=Artwork.Status.INACTIVA)

    def _order(self, **extra):
        order = Order.objects.create(buyer=self.buyer, total_amount=Decimal("200000.00"), **extra)
        OrderItem.objects.create(order=order, artwork=self.artwork, price=Decimal("200000.00"))
        return order

    @staticmethod
    def _log(order):
        return NotificationLog(notification_type="PAYMENT_WEBHOOK", payload={"status": "APROBADO", "order_id": str(order.id)})

    def test_el_pago_aprobado_avisa_al_artista_aunque_ya_no_exista_el_comprador(self):
        order = self._order()
        Transaction.objects.create(order=order, amount=Decimal("200000.00"), currency="COP", status="PENDIENTE")
        self.buyer.delete()
        event = signed_wompi_event(
            {
                "id": "wompi-sin-comprador",
                "status": "APPROVED",
                "reference": str(order.id),
                "amount_in_cents": 20000000,
                "currency": "COP",
                "payment_method_type": "CARD",
            }
        )
        r = APIClient().post("/api/v1/payments/wompi-webhook/", event, format="json")
        self.assertEqual(r.status_code, 200)
        order.refresh_from_db()
        self.assertEqual(order.status, Order.Status.PAGADO)
        destinatarios = set(Notification.objects.values_list("recipient_id", flat=True))
        self.assertEqual(destinatarios, {self.profile.user_id})

    def test_el_correo_de_pago_usa_la_copia_del_comprador(self):
        order = self._order()
        self.buyer.delete()
        email = build_notification_email(self._log(order))
        self.assertEqual(email.to, "ana@narino.test")
        order.refresh_from_db()
        self.assertEqual(email.context["name"], order.buyer_name)

    def test_sin_correo_guardado_no_se_envia_el_correo_de_pago(self):
        order = self._order()
        Order.objects.filter(pk=order.pk).update(buyer=None, buyer_email="")
        self.assertIsNone(build_notification_email(self._log(order)))

    def test_vence_la_orden_de_subasta_de_un_comprador_que_ya_no_existe(self):
        order = self._order(order_type=Order.Type.SUBASTA, payment_due_at=timezone.now() - timedelta(hours=1))
        self.buyer.delete()
        self.assertEqual(AuctionService.expire_unpaid_orders(), 1)
        order.refresh_from_db()
        self.artwork.refresh_from_db()
        self.assertEqual(order.status, Order.Status.CANCELADO)
        self.assertEqual(self.artwork.status, Artwork.Status.DISPONIBLE)
        self.assertFalse(Notification.objects.filter(recipient__isnull=True).exists())
