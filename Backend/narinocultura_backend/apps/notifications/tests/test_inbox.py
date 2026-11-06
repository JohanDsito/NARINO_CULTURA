from datetime import timedelta
from decimal import Decimal
from unittest.mock import patch

from django.db import transaction
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase

from apps.auctions.models import Auction
from apps.events.models import Event
from apps.marketplace.models import Order, OrderItem
from apps.notifications.models import Notification
from services.auction_service import AuctionService
from services.notification_service import NotificationService
from tests.factories import (
    AdminUserFactory,
    ArtistProfileFactory,
    ArtistUserFactory,
    ArtworkFactory,
    CulturalManagerFactory,
    UserFactory,
)

URL = "/api/v1/notifications/"


def results(response):
    return response.data["results"] if isinstance(response.data, dict) else response.data


class NotificationApiTests(APITestCase):
    """HU-B09: bandeja de notificaciones del usuario autenticado."""

    def setUp(self):
        self.user = UserFactory()
        self.other = UserFactory()
        self.old = Notification.objects.create(recipient=self.user, notification_type="X", title="Vieja")
        self.new = Notification.objects.create(recipient=self.user, notification_type="X", title="Nueva", data={"url": "/orders"})
        self.read = Notification.objects.create(recipient=self.user, notification_type="X", title="Leída", read_at=timezone.now())
        self.foreign = Notification.objects.create(recipient=self.other, notification_type="X", title="Ajena")
        now = timezone.now()
        for minutes, notification in ((30, self.old), (20, self.new), (10, self.read)):
            Notification.objects.filter(id=notification.id).update(created_at=now - timedelta(minutes=minutes))
        self.client.force_authenticate(user=self.user)

    def test_lists_only_own_notifications_newest_first(self):
        titles = [n["title"] for n in results(self.client.get(URL))]
        self.assertEqual(titles, ["Leída", "Nueva", "Vieja"])

    def test_response_shape(self):
        item = next(n for n in results(self.client.get(URL)) if n["title"] == "Nueva")
        self.assertEqual(item["id"], str(self.new.id))
        self.assertEqual(item["type"], "X")
        self.assertEqual(item["data"], {"url": "/orders"})
        self.assertFalse(item["read"])
        self.assertIn("created_at", item)

    def test_unread_filter_accepts_both_param_names(self):
        for params in ({"unread": "true"}, {"no_leidas": "true"}):
            titles = {n["title"] for n in results(self.client.get(URL, params))}
            self.assertEqual(titles, {"Nueva", "Vieja"})

    def test_unread_count(self):
        self.assertEqual(self.client.get(f"{URL}unread-count/").data, {"unread": 2})

    def test_mark_read_with_post_and_patch(self):
        r = self.client.post(f"{URL}{self.new.id}/read/")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["read"])
        r = self.client.patch(f"{URL}{self.old.id}/read/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(self.client.get(f"{URL}unread-count/").data, {"unread": 0})

    def test_cannot_mark_someone_elses_notification(self):
        self.assertEqual(self.client.post(f"{URL}{self.foreign.id}/read/").status_code, 404)
        self.foreign.refresh_from_db()
        self.assertIsNone(self.foreign.read_at)

    def test_read_all_only_touches_own(self):
        r = self.client.post(f"{URL}read-all/")
        self.assertEqual(r.data, {"updated": 2})
        self.foreign.refresh_from_db()
        self.assertIsNone(self.foreign.read_at)

    def test_anonymous_gets_401(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get(URL).status_code, 401)
        self.assertEqual(self.client.post(f"{URL}read-all/").status_code, 401)


class InboxRecipientsTests(TestCase):
    """Cada evento de negocio llega a la bandeja de quien debe enterarse, no de quien lo provocó."""

    def setUp(self):
        self.seller = ArtistUserFactory()
        self.profile = ArtistProfileFactory(user=self.seller)
        self.admin = AdminUserFactory()
        now = timezone.now()
        self.artwork = ArtworkFactory(artist=self.profile, title="Carnaval", status="EN_SUBASTA")
        self.auction = Auction.objects.create(
            artwork=self.artwork,
            seller=self.seller,
            base_price=Decimal("100000.00"),
            current_price=Decimal("100000.00"),
            starts_at=now - timedelta(hours=1),
            ends_at=now + timedelta(hours=1),
            status=Auction.Status.ACTIVA,
        )

    def inbox(self, user):
        return list(Notification.objects.filter(recipient=user).values_list("title", flat=True))

    def test_new_auction_notifies_admins(self):
        artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")
        now = timezone.now()
        AuctionService.create_auction(
            seller=self.seller, artwork=artwork, base_price=Decimal("1000.00"),
            starts_at=now, ends_at=now + timedelta(days=1),
        )
        self.assertEqual(self.inbox(self.admin), ["Subasta pendiente de aprobación"])
        self.assertEqual(self.inbox(self.seller), [])

    def test_approval_notifies_seller_not_admin(self):
        artwork = ArtworkFactory(artist=self.profile, status="DISPONIBLE")
        now = timezone.now()
        pending = AuctionService.create_auction(
            seller=self.seller, artwork=artwork, base_price=Decimal("1000.00"),
            starts_at=now, ends_at=now + timedelta(days=1),
        )
        AuctionService.approve_auction(auction=pending, actor=self.admin)
        self.assertIn("Tu subasta fue aprobada", self.inbox(self.seller))
        self.assertNotIn("Tu subasta fue aprobada", self.inbox(self.admin))

    def test_bids_notify_seller_and_outbid_bidder(self):
        ana, luis = UserFactory(), UserFactory()
        AuctionService.place_bid(auction=self.auction, bidder=ana, amount=Decimal("110000.00"))
        self.assertEqual(self.inbox(ana), [])
        AuctionService.place_bid(auction=self.auction, bidder=luis, amount=Decimal("120000.00"))
        self.assertEqual(self.inbox(ana), ["Te superaron en una subasta"])
        self.assertEqual(self.inbox(luis), [])
        self.assertEqual(self.inbox(self.seller).count("Nueva puja en tu subasta"), 2)
        outbid = Notification.objects.get(recipient=ana)
        self.assertIn("$120.000 COP", outbid.body)
        self.assertEqual(outbid.data["url"], f"/auctions/{self.auction.id}")

    def test_raising_own_bid_does_not_notify_yourself(self):
        ana = UserFactory()
        AuctionService.place_bid(auction=self.auction, bidder=ana, amount=Decimal("110000.00"))
        AuctionService.place_bid(auction=self.auction, bidder=ana, amount=Decimal("130000.00"))
        self.assertEqual(self.inbox(ana), [])

    def test_close_notifies_winner_and_seller(self):
        winner = UserFactory()
        AuctionService.place_bid(auction=self.auction, bidder=winner, amount=Decimal("150000.00"))
        AuctionService.close_auction(auction=self.auction, actor=self.seller)
        self.assertEqual(self.inbox(winner), ["¡Ganaste la subasta!"])
        self.assertIn("Tu subasta cerró", self.inbox(self.seller))
        self.assertIn("$150.000 COP", Notification.objects.get(recipient=winner).body)

    def test_close_without_bids_notifies_seller(self):
        AuctionService.close_auction(auction=self.auction, actor=self.seller)
        self.assertEqual(self.inbox(self.seller), ["Tu subasta cerró sin pujas"])

    def test_approved_payment_notifies_buyer_and_artist(self):
        buyer = UserFactory()
        artwork = ArtworkFactory(artist=self.profile, title="Retrato")
        order = Order.objects.create(buyer=buyer, total_amount=Decimal("80000.00"), status=Order.Status.PAGADO)
        OrderItem.objects.create(order=order, artwork=artwork, price=Decimal("80000.00"))
        NotificationService.send("PAYMENT_WEBHOOK", {"order_id": str(order.id), "status": "APROBADO"})
        self.assertEqual(self.inbox(buyer), ["Pago confirmado"])
        self.assertEqual(self.inbox(self.seller), ["¡Vendiste una obra!"])

    def test_rejected_payment_notifies_nobody(self):
        order = Order.objects.create(buyer=UserFactory(), total_amount=Decimal("80000.00"))
        NotificationService.send("PAYMENT_WEBHOOK", {"order_id": str(order.id), "status": "RECHAZADO"})
        self.assertFalse(Notification.objects.exists())

    def test_event_registration_and_publication(self):
        attendee = UserFactory()
        start = timezone.now() + timedelta(days=7)
        event = Event.objects.create(
            organizer=CulturalManagerFactory(), title="Noche andina", event_type="CONCIERTO",
            start_date=start, end_date=start + timedelta(hours=2), is_published=True,
        )
        NotificationService.send("EVENT_REGISTRATION", {"event_id": str(event.id), "user_email": attendee.email})
        NotificationService.send("EVENT_PUBLISHED", {"event_id": str(event.id)})
        self.assertEqual(self.inbox(attendee), ["Inscripción confirmada"])
        self.assertEqual(self.inbox(event.organizer), ["Tu evento fue publicado"])

    def test_rolled_back_operation_leaves_no_inbox_items(self):
        try:
            with transaction.atomic():
                AuctionService.place_bid(auction=self.auction, bidder=UserFactory(), amount=Decimal("110000.00"))
                raise RuntimeError("falló después")
        except RuntimeError:
            pass
        self.assertFalse(Notification.objects.exists())

    def test_inbox_error_does_not_break_the_bid(self):
        with patch.dict("services.notification_inbox.BUILDERS", {"AUCTION_BID": lambda payload: 1 / 0}):
            AuctionService.place_bid(auction=self.auction, bidder=UserFactory(), amount=Decimal("110000.00"))
        self.auction.refresh_from_db()
        self.assertEqual(self.auction.current_price, Decimal("110000.00"))
        self.assertFalse(Notification.objects.exists())
