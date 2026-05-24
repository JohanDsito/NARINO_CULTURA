import logging

from celery import shared_task
from django.utils import timezone

logger = logging.getLogger("apps.auctions")


@shared_task(bind=True, max_retries=3, default_retry_delay=30, ignore_result=True)
def close_expired_auctions(self):
    """Scans for auctions past their end time and closes them. Runs every 60s via Celery Beat."""
    from apps.auctions.models import Auction
    from services.auction_service import AuctionService

    expired_ids = list(
        Auction.objects.filter(
            status=Auction.Status.ACTIVA,
            ends_at__lte=timezone.now(),
        ).values_list("id", flat=True)
    )

    if not expired_ids:
        return

    logger.info("Closing %d expired auction(s): %s", len(expired_ids), expired_ids)

    for auction_id in expired_ids:
        try:
            AuctionService._close_if_ended(auction_id=auction_id)
        except Exception as exc:
            logger.error("Failed to close auction %s: %s", auction_id, exc)
            try:
                self.retry(exc=exc)
            except self.MaxRetriesExceededError:
                logger.error("Max retries exceeded for auction %s", auction_id)
