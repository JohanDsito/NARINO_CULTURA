// Matches backend apps.marketplace.models.Order/OrderItem exactly.
export type OrderStatus = 'PENDIENTE' | 'PAGADO' | 'CANCELADO' | 'REEMBOLSADO'
export type OrderType = 'COMPRA_DIRECTA' | 'SUBASTA'

export interface OrderItem {
  id: string
  artwork: string                         // Artwork UUID FK
  artwork_title?: string
  artwork_image_url?: string
  artist_name?: string
  artist_slug?: string
  price: string                           // DecimalField → string
  // No quantity — backend enforces one unit per artwork in an order
}

/** Último intento de pago de la orden (backend: OrderSerializer.payment). */
export interface OrderPayment {
  transaction_id: string
  status: TransactionStatus
  payment_method: string
  receipt_url: string                     // comprobante de Wompi; vacío hasta que Wompi lo envía
  updated_at: string
}

export interface Order {
  id: string
  buyer: string | null                    // User UUID FK; null si el comprador eliminó su cuenta
  total_amount: string                    // DecimalField → string
  status: OrderStatus
  order_type: OrderType
  payment_due_at?: string | null          // plazo para pagar (compra directa: la reserva vence; subasta: 48 h)
  items: OrderItem[]
  payment?: OrderPayment | null
  created_at: string
}

/** Venta vista por el artista: solo sus obras de la orden y su parte (`seller_amount`). */
export interface Sale extends Order {
  seller_amount: string
}

export type TransactionStatus = 'PENDIENTE' | 'APROBADO' | 'RECHAZADO' | 'REEMBOLSADO'

export interface Transaction {
  id: string
  order: string
  wompi_transaction_id: string
  amount: string
  currency: string
  status: TransactionStatus
  payment_method: string
  receipt_url: string
  created_at: string
  updated_at: string
}
