import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { renderHook } from '@testing-library/react'

import { AuctionSocket, useAuctionSocket, type AuctionSocketEvent } from '@/services/auctionSocket'

class FakeWebSocket {
  static OPEN = 1
  static instances: FakeWebSocket[] = []
  url: string
  readyState = 0
  onopen: (() => void) | null = null
  onmessage: ((e: { data: string }) => void) | null = null
  onclose: (() => void) | null = null
  onerror: ((e: Event) => void) | null = null
  close = vi.fn()
  constructor(url: string) {
    this.url = url
    FakeWebSocket.instances.push(this)
  }
}

describe('AuctionSocket', () => {
  beforeEach(() => {
    FakeWebSocket.instances = []
    vi.stubGlobal('WebSocket', FakeWebSocket)
  })
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('se conecta por wss a la sala de la subasta y avisa al abrir', () => {
    const onMessage = vi.fn()
    const socket = new AuctionSocket().connect('42', onMessage)
    const ws = FakeWebSocket.instances[0]
    expect(ws.url).toBe('wss://narinocultura-production.up.railway.app/ws/auctions/42/')
    ws.onopen!()
    expect(onMessage).toHaveBeenCalledWith({ type: 'connected', auction_id: '42' })
    expect(socket.isConnected).toBe(false)
    ws.readyState = FakeWebSocket.OPEN
    expect(socket.isConnected).toBe(true)
  })

  it('entrega los mensajes JSON y descarta los mal formados', () => {
    const onMessage = vi.fn()
    new AuctionSocket().connect('1', onMessage)
    const ws = FakeWebSocket.instances[0]
    ws.onmessage!({ data: JSON.stringify({ type: 'auction_closed', winner_id: null }) })
    ws.onmessage!({ data: 'no es json' })
    expect(onMessage).toHaveBeenCalledTimes(1)
    expect(onMessage).toHaveBeenCalledWith({ type: 'auction_closed', winner_id: null })
  })

  it('propaga cierre y error si hay callbacks, y tolera que no los haya', () => {
    const onClose = vi.fn()
    const onError = vi.fn()
    new AuctionSocket().connect('1', vi.fn(), onClose, onError)
    const ws = FakeWebSocket.instances[0]
    ws.onclose!()
    const err = new Event('error')
    ws.onerror!(err)
    expect(onClose).toHaveBeenCalledTimes(1)
    expect(onError).toHaveBeenCalledWith(err)

    new AuctionSocket().connect('2', vi.fn())
    const ws2 = FakeWebSocket.instances[1]
    expect(() => {
      ws2.onclose!()
      ws2.onerror!(err)
    }).not.toThrow()
  })

  it('reconectar cierra el socket anterior sin disparar su onClose; disconnect sin socket no falla', () => {
    const onClose = vi.fn()
    const socket = new AuctionSocket()
    socket.connect('1', vi.fn(), onClose)
    const first = FakeWebSocket.instances[0]
    socket.connect('2', vi.fn())
    expect(first.close).toHaveBeenCalled()
    expect(first.onclose).toBeNull()
    expect(FakeWebSocket.instances).toHaveLength(2)
    socket.disconnect()
    expect(() => socket.disconnect()).not.toThrow()
    expect(socket.isConnected).toBe(false)
  })

  describe('useAuctionSocket', () => {
    it('conecta, entrega eventos al último callback y desconecta al desmontar', () => {
      const first = vi.fn()
      const second = vi.fn()
      const { rerender, unmount } = renderHook(
        ({ cb }: { cb: (e: AuctionSocketEvent) => void }) => useAuctionSocket('7', cb),
        { initialProps: { cb: first } },
      )
      const ws = FakeWebSocket.instances[0]
      expect(ws.url).toContain('/ws/auctions/7/')
      rerender({ cb: second })
      ws.onmessage!({ data: JSON.stringify({ type: 'error', message: 'x' }) })
      expect(second).toHaveBeenCalledWith({ type: 'error', message: 'x' })
      expect(first).not.toHaveBeenCalled()
      ws.onclose!()
      unmount()
      expect(ws.close).toHaveBeenCalled()
    })

    it('no conecta sin id o si está deshabilitado', () => {
      renderHook(() => useAuctionSocket(undefined, vi.fn()))
      renderHook(() => useAuctionSocket('7', vi.fn(), false))
      expect(FakeWebSocket.instances).toHaveLength(0)
    })
  })
})
