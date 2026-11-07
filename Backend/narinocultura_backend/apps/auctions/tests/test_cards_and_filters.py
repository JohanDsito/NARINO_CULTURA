from datetime import timedelta
from decimal import Decimal

from django.db import connection
from django.test.utils import CaptureQueriesContext
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.auctions.models import Auction
from services.auction_service import AuctionService
from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory, UserFactory

URL = "/api/v1/auctions/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) and "results" in response.data else response.data


class AuctionAppDataTests(APITestCase):
    """Datos de la tarjeta, historial de pujas y filtros por usuario (pedido de la app móvil)."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller, artistic_name="Ana Pintora")
        self.ana = UserFactory(first_name="Ana", last_name="Pérez")
        self.luis = UserFactory(first_name="Luis", last_name="Gómez")
        self.auction = self._auction("Danza del Carnaval")
        self.other = self._auction("Volcán Galeras")

    def _auction(self, title, status=Auction.Status.ACTIVA, seller_profile=None):
        profile = seller_profile or self.profile
        now = timezone.now()
        return Auction.objects.create(
            artwork=ArtworkFactory(artist=profile, title=title, status="EN_SUBASTA", main_image_url=f"https://img.test/{title}.jpg"),
            seller=profile.user,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now - timedelta(hours=1),
            ends_at=now + timedelta(hours=1),
            status=status,
        )

    def bid(self, user, amount, auction=None):
        AuctionService.place_bid(auction=auction or self.auction, bidder=user, amount=Decimal(amount))

    def ids(self, response):
        return {a["id"] for a in results(response)}

    # --- tarjeta ---------------------------------------------------------------------

    def test_card_fields(self):
        self.bid(self.ana, "110000")
        self.bid(self.luis, "120000")
        data = self.client.get(f"{URL}{self.auction.id}/").data
        self.assertEqual(data["artwork_title"], "Danza del Carnaval")
        self.assertEqual(data["artwork_image_url"], "https://img.test/Danza del Carnaval.jpg")
        self.assertEqual(data["artist_name"], "Ana Pintora")
        self.assertEqual(data["bids_count"], 2)

    def test_list_query_count_does_not_grow_with_auctions(self):
        self.bid(self.ana, "110000")
        with CaptureQueriesContext(connection) as few:
            self.client.get(URL)
        for i in range(4):
            extra = self._auction(f"Obra {i}", seller_profile=ArtistProfileFactory())
            self.bid(self.luis, "150000", auction=extra)
        with CaptureQueriesContext(connection) as many:
            r = self.client.get(URL)
        self.assertEqual(len(results(r)), 6)
        self.assertEqual(len(many), len(few))

    # --- historial de pujas --------------------------------------------------------

    def test_bid_history_newest_first_with_public_names(self):
        self.bid(self.ana, "110000")
        self.bid(self.luis, "120000")
        self.client.force_authenticate(user=self.ana)
        history = results(self.client.get(f"{URL}{self.auction.id}/bids/"))
        self.assertEqual([h["amount"] for h in history], ["120000.00", "110000.00"])
        self.assertEqual([h["bidder_name"] for h in history], ["Luis G.", "Ana P."])
        self.assertEqual([h["is_mine"] for h in history], [False, True])
        self.assertNotIn("bidder", history[0])  # sin ids ni correos de otros usuarios

    def test_bid_history_is_public_but_hides_pending_auctions(self):
        self.bid(self.ana, "110000")
        self.assertEqual(self.client.get(f"{URL}{self.auction.id}/bids/").status_code, 200)
        pending = self._auction("Pendiente", status=Auction.Status.PENDIENTE)
        self.assertEqual(self.client.get(f"{URL}{pending.id}/bids/").status_code, 404)

    # --- filtros -----------------------------------------------------------------------

    def test_mine_returns_auctions_i_sell(self):
        mine = self._auction("Mía", seller_profile=ArtistProfileFactory(user=self.ana))
        self.client.force_authenticate(user=self.ana)
        self.assertEqual(self.ids(self.client.get(URL, {"mine": "true"})), {str(mine.id)})

    def test_participating_includes_auctions_i_lost(self):
        self.bid(self.ana, "110000")
        self.bid(self.luis, "120000")  # Ana va perdiendo, pero participó
        AuctionService.close_auction(auction=self.auction, actor=self.seller)
        self.client.force_authenticate(user=self.ana)
        self.assertEqual(self.ids(self.client.get(URL, {"participating": "true"})), {str(self.auction.id)})

    def test_participating_counts_each_auction_once(self):
        self.bid(self.ana, "110000")
        self.bid(self.ana, "130000")
        self.client.force_authenticate(user=self.ana)
        self.assertEqual(len(results(self.client.get(URL, {"participating": "true"}))), 1)

    def test_user_filters_require_session(self):
        self.bid(self.ana, "110000")
        self.assertEqual(results(self.client.get(URL, {"participating": "true"})), [])
        self.assertEqual(results(self.client.get(URL, {"mine": "true"})), [])

    def test_without_filters_everything_visible_is_listed(self):
        self.assertEqual(self.ids(self.client.get(URL)), {str(self.auction.id), str(self.other.id)})
