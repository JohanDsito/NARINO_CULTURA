from decimal import Decimal

from rest_framework.test import APITestCase

from apps.artists.models import ArtistProfile
from apps.artworks.models import Artwork
from apps.marketplace.models import Order
from apps.payments.models import Transaction
from apps.users.models import User


class PaymentWebhookTests(APITestCase):
    def setUp(self):
        self.artist_user = User.objects.create_user(
            email="artist2@example.com",
            password="StrongPass123!",
            role=User.Role.ARTISTA,
            is_verified=True,
        )
        self.buyer_user = User.objects.create_user(
            email="buyer2@example.com",
            password="StrongPass123!",
            role=User.Role.COMPRADOR,
            is_verified=True,
        )
        self.profile = ArtistProfile.objects.create(
            user=self.artist_user,
            slug="artista-2",
            artistic_name="Artista 2",
            followers_count=0,
            is_public=True,
        )
        self.artwork = Artwork.objects.create(
            artist=self.profile,
            title="Obra Pago",
            price=Decimal("50000.00"),
            status=Artwork.Status.DISPONIBLE,
        )

    def test_payment_webhook_approves_order_and_marks_artwork_sold(self):
        self.client.force_authenticate(user=self.buyer_user)
        r = self.client.post("/api/v1/marketplace/cart/items/", {"artwork_id": str(self.artwork.id)}, format="json")
        self.assertEqual(r.status_code, 201)

        r = self.client.post("/api/v1/marketplace/checkout/", {"order_type": "COMPRA_DIRECTA"}, format="json")
        self.assertEqual(r.status_code, 201)
        order_id = r.data["order_id"]

        r = self.client.post("/api/v1/payments/initiate/", {"order_id": order_id}, format="json")
        self.assertEqual(r.status_code, 201)

        self.client.force_authenticate(user=None)
        wompi_payload = {
            "data": {
                "transaction": {
                    "id": "wompi_tx_123",
                    "status": "APPROVED",
                    "reference": order_id,
                    "amount_in_cents": 5000000,
                    "currency": "COP",
                    "payment_method_type": "CARD",
                    "receipt_url": "https://example.com/receipt.pdf",
                }
            }
        }
        r = self.client.post("/api/v1/payments/wompi-webhook/", wompi_payload, format="json")
        self.assertEqual(r.status_code, 200)

        order = Order.objects.get(id=order_id)
        self.assertEqual(order.status, Order.Status.PAGADO)

        self.artwork.refresh_from_db()
        self.assertEqual(self.artwork.status, Artwork.Status.VENDIDA)

        tx = Transaction.objects.filter(order=order).latest("created_at")
        self.assertEqual(tx.status, Transaction.Status.APROBADO)

