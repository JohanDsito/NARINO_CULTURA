from celery import shared_task


@shared_task(ignore_result=True)
def expire_unpaid_direct_orders():
    """Libera las obras de las compras directas no pagadas a tiempo. Se ejecuta cada 5 min vía Celery Beat."""
    from services.marketplace_service import MarketplaceService

    return MarketplaceService.expire_unpaid_direct_orders()
