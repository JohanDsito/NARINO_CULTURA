from datetime import timedelta
from decimal import Decimal
from unittest.mock import patch

from celery.exceptions import Retry
from django.test import TestCase
from django.utils import timezone

from apps.artworks.models import Artwork
from apps.auctions.models import Auction
from apps.auctions.tasks import close_expired_auctions, expire_unpaid_auction_orders
from tests.factories import ArtistProfileFactory, ArtistUserFactory, ArtworkFactory


class CloseExpiredAuctionsTaskTests(TestCase):
    """Tarea periódica de Celery Beat que cierra las subastas vencidas."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller)

    def _auction(self, *, ends):
        now = timezone.now()
        return Auction.objects.create(
            artwork=ArtworkFactory(artist=self.profile, status=Artwork.Status.EN_SUBASTA),
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now - timedelta(days=1),
            ends_at=now + timedelta(hours=ends),
            status=Auction.Status.ACTIVA,
        )

    @patch("services.auction_service.AuctionService._close_if_ended")
    def test_does_nothing_without_expired_auctions(self, close):
        self._auction(ends=2)
        close_expired_auctions()
        close.assert_not_called()

    def test_failure_on_one_auction_is_retried(self):
        self._auction(ends=-1)
        with (
            patch("services.auction_service.AuctionService._close_if_ended", side_effect=RuntimeError("db caída")),
            patch.object(close_expired_auctions, "retry", side_effect=Retry()) as retry,
        ):
            with self.assertRaises(Retry):
                close_expired_auctions()
        self.assertIsInstance(retry.call_args.kwargs["exc"], RuntimeError)

    def test_max_retries_exceeded_does_not_crash_the_task(self):
        first = self._auction(ends=-1)
        second = self._auction(ends=-2)
        with (
            patch(
                "services.auction_service.AuctionService._close_if_ended", side_effect=RuntimeError("db caída")
            ) as close,
            patch.object(
                close_expired_auctions, "retry", side_effect=close_expired_auctions.MaxRetriesExceededError()
            ),
            self.assertLogs("apps.auctions", level="ERROR") as logs,
        ):
            close_expired_auctions()
        # Se intenta cerrar cada subasta aunque la anterior haya fallado
        self.assertEqual({c.kwargs["auction_id"] for c in close.call_args_list}, {first.id, second.id})
        self.assertTrue(any("Max retries" in line for line in logs.output))


class ExpireUnpaidOrdersTaskTests(TestCase):
    @patch("services.auction_service.AuctionService.expire_unpaid_orders", return_value=0)
    def test_no_log_when_nothing_expires(self, expire):
        with self.assertNoLogs("apps.auctions", level="INFO"):
            expire_unpaid_auction_orders()
        expire.assert_called_once()

    @patch("services.auction_service.AuctionService.expire_unpaid_orders", return_value=2)
    def test_logs_expired_orders(self, _expire):
        with self.assertLogs("apps.auctions", level="INFO") as logs:
            expire_unpaid_auction_orders()
        self.assertTrue(any("Expired 2" in line for line in logs.output))
