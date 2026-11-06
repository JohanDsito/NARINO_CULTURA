import { API_BASE_URL } from '@/config/env'

// Convert http(s) to ws(s) for the WebSocket URL
const WS_BASE = API_BASE_URL.replace(/^https?/, (p) => (p === 'https' ? 'wss' : 'ws')).replace(
  /\/api\/v1\/?$/,
  '',
)

// ─── Event Types ──────────────────────────────────────────────────────────────
// These match the Django Channels AuctionConsumer message types.
export type AuctionSocketEvent =
  | {
      type: 'snapshot'
      current_price: string
      highest_bidder_id: string | null
      status: string
      ends_at: string
    }
  | {
      type: 'bid_placed'
      current_price: string
      highest_bidder_id: string
      amount: string
      bidder_name?: string
    }
  | { type: 'auction_closed'; winner_id: string | null }
  | { type: 'connected'; auction_id: string }
  | { type: 'error'; message: string }

export type AuctionSocketCallback = (event: AuctionSocketEvent) => void

// ─── AuctionSocket ────────────────────────────────────────────────────────────
// Uses native WebSocket (not socket.io-client) because Django Channels uses
// the standard WebSocket protocol, not the Socket.IO protocol.
export class AuctionSocket {
  private ws: WebSocket | null = null

  get isConnected(): boolean {
    return this.ws?.readyState === WebSocket.OPEN
  }

  connect(
    auctionId: string,
    onMessage: AuctionSocketCallback,
    onClose?: () => void,
    onError?: (e: Event) => void,
  ): this {
    if (this.ws) this.disconnect()

    const url = `${WS_BASE}/ws/auctions/${auctionId}/`

    this.ws = new WebSocket(url)

    this.ws.onopen = () => {
      onMessage({ type: 'connected', auction_id: auctionId })
    }

    this.ws.onmessage = (event: MessageEvent) => {
      try {
        const parsed = JSON.parse(event.data as string) as AuctionSocketEvent
        onMessage(parsed)
      } catch {
        // Ignore malformed messages
      }
    }

    this.ws.onclose = () => {
      onClose?.()
    }

    this.ws.onerror = (e: Event) => {
      onError?.(e)
    }

    return this
  }

  disconnect(): void {
    if (this.ws) {
      this.ws.onclose = null // Prevent onClose callback on intentional disconnect
      this.ws.close()
      this.ws = null
    }
  }
}

// ─── React Hook ───────────────────────────────────────────────────────────────
import { useEffect, useRef } from 'react'

export function useAuctionSocket(
  auctionId: string | undefined,
  onMessage: AuctionSocketCallback,
  enabled = true,
) {
  const socketRef = useRef<AuctionSocket | null>(null)
  const onMessageRef = useRef(onMessage)

  useEffect(() => {
    onMessageRef.current = onMessage
  }, [onMessage])

  useEffect(() => {
    if (!auctionId || !enabled) return

    const socket = new AuctionSocket()
    socketRef.current = socket

    socket.connect(
      auctionId,
      (event) => onMessageRef.current(event),
      () => {
        // Connection closed — could add reconnect logic here
      },
    )

    return () => {
      socket.disconnect()
      socketRef.current = null
    }
  }, [auctionId, enabled])

  return socketRef
}
