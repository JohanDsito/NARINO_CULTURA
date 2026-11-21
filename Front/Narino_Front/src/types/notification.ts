// Backend: GET /api/v1/notifications/ (apps/notifications/serializers.py)
export interface AppNotification {
  id: string
  type: string                            // p. ej. AUCTION_BID, PAYMENT_WEBHOOK, EVENT_REMINDER
  title: string
  body: string
  data: {
    url?: string                          // ruta de la web a la que lleva el aviso
    [key: string]: unknown
  }
  read: boolean
  read_at: string | null
  created_at: string
}
