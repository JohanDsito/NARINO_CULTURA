from datetime import timedelta
from decimal import Decimal

from django.utils import timezone
from rest_framework.test import APITestCase

from apps.artists.models import ArtistProfile
from apps.artworks.models import Artwork
from apps.users.models import User


class AuctionBidTests(APITestCase):
    def setUp(self):
        self.artist_user = User.objects.create_user(
            email="artist@example.com",
            password="StrongPass123!",
            role=User.Role.ARTISTA,
            is_verified=True,
        )
        self.buyer_user = User.objects.create_user(
            email="buyer@example.com",
            password="StrongPass123!",
            role=User.Role.COMPRADOR,
            is_verified=True,
        )
        self.profile = ArtistProfile.objects.create(
            user=self.artist_user,
            slug="artista",
            artistic_name="Artista",
            bio="",
            trajectory="",
            discipline="",
            city="",
            followers_count=0,
            is_public=True,
        )
        self.artwork = Artwork.objects.create(
            artist=self.profile,
            title="Obra",
            description="",
            technique="",
            dimensions="",
            material="",
            price=Decimal("100000.00"),
            status=Artwork.Status.DISPONIBLE,
        )

    def test_bid_must_be_greater_than_current(self):
        self.client.force_authenticate(user=self.artist_user)
        now = timezone.now()
        r = self.client.post(
            "/api/v1/auctions/",
            {
                "artwork": str(self.artwork.id),
                "base_price": "1000.00",
                "starts_at": (now - timedelta(seconds=1)).isoformat(),
                "ends_at": (now + timedelta(minutes=10)).isoformat(),
            },
            format="json",
        )
        self.assertEqual(r.status_code, 201)
        auction_id = r.data["id"]

        self.client.force_authenticate(user=self.buyer_user)
        r = self.client.post(f"/api/v1/auctions/{auction_id}/bid/", {"amount": "1000.00"}, format="json")
        self.assertEqual(r.status_code, 400)
