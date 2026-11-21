// Matches backend apps.auctions.models.Auction exactly.
export type AuctionStatus = 'PENDIENTE' | 'ACTIVA' | 'CERRADA' | 'CANCELADA'

export interface Auction {
  id: string
  artwork: string                         // Artwork UUID FK
  seller: string                          // User UUID FK
  base_price: string                      // DecimalField → string
  current_price: string
  highest_bidder: string | null           // User UUID FK
  status: AuctionStatus
  starts_at: string
  ends_at: string
  winner: string | null                   // User UUID FK
  artwork_title?: string
  artwork_image_url?: string
  artist_name?: string
  bids_count?: number
  payment_order_id?: string | null
  created_at: string
  updated_at: string
}

export interface Bid {
  id: string
  auction: string                         // Auction UUID FK
  bidder: string                          // User UUID FK
  amount: string                          // DecimalField → string
  created_at: string
}
