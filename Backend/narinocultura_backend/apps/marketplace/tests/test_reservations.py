"""Compras directas: la reserva de las obras vence si no se paga a tiempo; correo al artista y pago en la orden."""

import importlib
from datetime import timedelta
from decimal import Decimal
from unittest import mock

from django.apps import apps as django_apps
from django.conf import settings
from django.db import connection
from django.test import TestCase, override_settings
from django.test.utils import CaptureQueriesContext
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase

from apps.artworks.models import Artwork
from apps.marketplace.models import CartItem, Order, OrderItem
from apps.marketplace.tasks import expire_unpaid_direct_orders
from apps.notifications.models import Notification, NotificationLog
from apps.payments.models import Transaction
from services.marketplace_service import MarketplaceService
from services.notification_emails import build_notification_email
from services.notification_inbox import build_inbox_items
from tests.factories import ArtistProfileFactory, ArtworkFactory, UserFactory
from tests.wompi import signed_wompi_event


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class CheckoutReservationTests(APITestCase):
    def setUp(self):
        self.buyer = UserFactory()
        self.artwork = ArtworkFactory(status=Artwork.Status.DISPONIBLE, price=Decimal("200000.00"))
        CartItem.objects.create(cart=MarketplaceService.get_or_create_cart(user=self.buyer), artwork=self.artwork)

    def test_la_compra_directa_reserva_las_obras_por_un_plazo(self):
        antes = timezone.now()
        order = MarketplaceService.checkout(user=self.buyer, order_type=Order.Type.COMPRA_DIRECTA)
        self.assertEqual(Artwork.objects.get(pk=self.artwork.pk).status, Artwork.Status.INACTIVA)
        plazo = order.payment_due_at - antes
        self.assertGreaterEqual(plazo, timedelta(hours=settings.DIRECT_ORDER_PAYMENT_HOURS) - timedelta(seconds=5))
        self.assertLessEqual(plazo, timedelta(hours=settings.DIRECT_ORDER_PAYMENT_HOURS) + timedelta(seconds=5))

    @override_settings(DIRECT_ORDER_PAYMENT_HOURS=1)
    def test_el_plazo_se_configura(self):
        order = MarketplaceService.checkout(user=self.buyer, order_type=Order.Type.COMPRA_DIRECTA)
        self.assertLess(order.payment_due_at, timezone.now() + timedelta(hours=1, minutes=1))

    def test_despues_del_plazo_ya_no_se_puede_pagar(self):
        order = MarketplaceService.checkout(user=self.buyer, order_type=Order.Type.COMPRA_DIRECTA)
        Order.objects.filter(pk=order.pk).update(payment_due_at=timezone.now() - timedelta(minutes=1))
        self.client.force_authenticate(user=self.buyer)
        r = self.client.post("/api/v1/payments/initiate/", {"order_id": str(order.id)}, format="json")
        self.assertEqual(r.status_code, 400)
        self.assertIn("venció", r.data["detail"])


class ExpireDirectOrdersTests(TestCase):
    def setUp(self):
        self.buyer = UserFactory()
        self.artwork = ArtworkFactory(status=Artwork.Status.INACTIVA, price=Decimal("150000.00"))

    def _order(self, minutes_left=-5, order_type=Order.Type.COMPRA_DIRECTA, status=Order.Status.PENDIENTE):
        order = Order.objects.create(
            buyer=self.buyer,
            total_amount=Decimal("150000.00"),
            order_type=order_type,
            status=status,
            payment_due_at=timezone.now() + timedelta(minutes=minutes_left),
        )
        OrderItem.objects.create(order=order, artwork=self.artwork, price=Decimal("150000.00"))
        return order

    def _artwork_status(self):
        return Artwork.objects.get(pk=self.artwork.pk).status

    def test_vencida_se_cancela_y_la_obra_vuelve_al_catalogo(self):
        order = self._order()
        self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 1)
        order.refresh_from_db()
        self.assertEqual(order.status, Order.Status.CANCELADO)
        self.assertEqual(self._artwork_status(), Artwork.Status.DISPONIBLE)
        aviso = Notification.objects.get(notification_type="ORDER_RESERVATION_EXPIRED")
        self.assertEqual((aviso.recipient_id, aviso.title, aviso.data["url"]), (self.buyer.id, "Tu reserva venció", "/orders"))

    def test_dentro_del_plazo_no_se_toca(self):
        self._order(minutes_left=30)
        self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 0)
        self.assertEqual(self._artwork_status(), Artwork.Status.INACTIVA)

    def test_no_vence_si_el_pago_ya_esta_en_curso_en_wompi(self):
        order = self._order()
        Transaction.objects.create(
            order=order, amount=order.total_amount, currency="COP", status="PENDIENTE", wompi_transaction_id="pse-123"
        )
        self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 0)
        self.assertEqual(Order.objects.get(pk=order.pk).status, Order.Status.PENDIENTE)

    def test_vence_si_solo_se_abrio_el_pago_sin_iniciarlo_en_wompi(self):
        order = self._order()
        Transaction.objects.create(order=order, amount=order.total_amount, currency="COP", status="PENDIENTE")
        self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 1)

    def test_no_toca_ordenes_pagadas_ni_de_subasta(self):
        self._order(status=Order.Status.PAGADO)
        self._order(order_type=Order.Type.SUBASTA)
        self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 0)

    def test_una_obra_que_ya_no_esta_reservada_no_se_cambia(self):
        self._order()
        Artwork.objects.filter(pk=self.artwork.pk).update(status=Artwork.Status.VENDIDA)
        MarketplaceService.expire_unpaid_direct_orders()
        self.assertEqual(self._artwork_status(), Artwork.Status.VENDIDA)

    def test_si_el_comprador_ya_no_existe_no_queda_aviso_huerfano(self):
        self._order()
        self.buyer.delete()
        self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 1)
        self.assertFalse(Notification.objects.filter(recipient__isnull=True).exists())

    def test_si_otro_proceso_la_pago_mientras_tanto_no_se_cancela(self):
        order = self._order()
        original = Order.objects.select_for_update

        def pagada_antes_del_bloqueo(*args, **kwargs):
            Order.objects.filter(pk=order.pk).update(status=Order.Status.PAGADO)
            return original(*args, **kwargs)

        with mock.patch.object(Order.objects, "select_for_update", pagada_antes_del_bloqueo):
            self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 0)
        self.assertEqual(Order.objects.get(pk=order.pk).status, Order.Status.PAGADO)

    def test_el_aviso_de_una_orden_que_ya_no_existe_se_omite(self):
        payload = {"order_id": "00000000-0000-0000-0000-000000000000"}
        self.assertEqual(build_inbox_items("ORDER_RESERVATION_EXPIRED", payload), [])

    def test_la_tarea_de_celery_y_su_agenda(self):
        self._order()
        self.assertEqual(expire_unpaid_direct_orders(), 1)
        tarea = settings.CELERY_BEAT_SCHEDULE["expire-unpaid-direct-orders"]
        self.assertEqual((tarea["task"], tarea["schedule"]), ("apps.marketplace.tasks.expire_unpaid_direct_orders", 300.0))

    def test_la_migracion_pone_plazo_a_las_pendientes_que_ya_existian(self):
        order = self._order()
        hace_un_dia = timezone.now() - timedelta(days=1)
        Order.objects.filter(pk=order.pk).update(payment_due_at=None, created_at=hace_un_dia)
        migracion = importlib.import_module("apps.marketplace.migrations.0005_plazo_de_compras_directas_pendientes")
        migracion.poner_plazo(django_apps, None)
        order.refresh_from_db()
        self.assertEqual(order.payment_due_at, hace_un_dia + timedelta(hours=migracion.HORAS_DE_PLAZO))
        self.assertEqual(MarketplaceService.expire_unpaid_direct_orders(), 1)


@override_settings(WOMPI_EVENTS_SECRET="test_events_secret")
class ArtistSaleEmailTests(TestCase):
    def setUp(self):
        self.ana = ArtistProfileFactory(user=UserFactory(first_name="Ana", last_name="", email="ana@narino.test"))
        self.luis = ArtistProfileFactory(user=UserFactory(email="luis@narino.test"))
        self.order = Order.objects.create(buyer=UserFactory(), total_amount=Decimal("350000.00"))
        for artist, title, price in ((self.ana, "Volcán", "100000"), (self.ana, "Laguna", "50000"), (self.luis, "Carnaval", "200000")):
            artwork = ArtworkFactory(artist=artist, title=title, status=Artwork.Status.INACTIVA)
            OrderItem.objects.create(order=self.order, artwork=artwork, price=Decimal(price))
        Transaction.objects.create(order=self.order, amount=self.order.total_amount, currency="COP", status="PENDIENTE")

    def _webhook(self, status):
        event = signed_wompi_event({
            "id": "wompi-1",
            "status": status,
            "reference": str(self.order.id),
            "amount_in_cents": 35000000,
            "currency": "COP",
            "payment_method_type": "CARD",
        })
        return APIClient().post("/api/v1/payments/wompi-webhook/", event, format="json")

    def test_cada_artista_recibe_un_correo_con_sus_obras_y_su_parte(self):
        self.assertEqual(self._webhook("APPROVED").status_code, 200)
        correos = {
            email.to: email for email in map(build_notification_email, NotificationLog.objects.filter(notification_type="ARTWORK_SOLD"))
        }
        self.assertEqual(set(correos), {"ana@narino.test", "luis@narino.test"})
        ana = correos["ana@narino.test"]
        self.assertEqual(ana.context["artworks"], "Laguna, Volcán")
        self.assertIn(("Te corresponde", "$150.000 COP"), [(k, v.replace("\xa0", "")) for k, v in ana.context["details"]])
        self.assertTrue(ana.context["sales_url"].endswith("/dashboard/sales"))

    def test_un_pago_rechazado_no_avisa_a_los_artistas(self):
        self._webhook("DECLINED")
        self.assertFalse(NotificationLog.objects.filter(notification_type="ARTWORK_SOLD").exists())


class OrderPaymentFieldTests(APITestCase):
    def setUp(self):
        self.buyer = UserFactory()
        self.client.force_authenticate(user=self.buyer)

    def _order(self):
        order = Order.objects.create(buyer=self.buyer, total_amount=Decimal("100000.00"))
        OrderItem.objects.create(order=order, artwork=ArtworkFactory(), price=Decimal("100000.00"))
        return order

    def test_sin_intentos_de_pago_el_campo_es_nulo(self):
        order = self._order()
        self.assertIsNone(self.client.get(f"/api/v1/marketplace/orders/{order.id}/").data["payment"])

    def test_muestra_el_ultimo_intento_con_su_comprobante(self):
        order = self._order()
        Transaction.objects.create(order=order, amount=order.total_amount, currency="COP", status="RECHAZADO")
        aprobada = Transaction.objects.create(
            order=order, amount=order.total_amount, currency="COP", status="APROBADO",
            payment_method="CARD", receipt_url="https://comprobantes.wompi.test/r/1",
        )
        Transaction.objects.filter(pk=aprobada.pk).update(created_at=timezone.now() + timedelta(seconds=1))
        payment = self.client.get(f"/api/v1/marketplace/orders/{order.id}/").data["payment"]
        self.assertEqual(payment["transaction_id"], str(aprobada.id))
        self.assertEqual(payment["status"], "APROBADO")
        self.assertEqual(payment["receipt_url"], "https://comprobantes.wompi.test/r/1")

    def test_listar_ordenes_no_hace_una_consulta_por_orden(self):
        for _ in range(2):
            order = self._order()
            Transaction.objects.create(order=order, amount=order.total_amount, currency="COP", status="APROBADO")
        with CaptureQueriesContext(connection) as dos:
            self.assertEqual(len(results(self.client.get("/api/v1/marketplace/orders/"))), 2)
        for _ in range(3):
            order = self._order()
            Transaction.objects.create(order=order, amount=order.total_amount, currency="COP", status="APROBADO")
        with CaptureQueriesContext(connection) as cinco:
            self.assertEqual(len(results(self.client.get("/api/v1/marketplace/orders/"))), 5)
        self.assertEqual(len(dos.captured_queries), len(cinco.captured_queries))
