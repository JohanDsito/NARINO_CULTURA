import { useState, useEffect, useCallback } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { Gavel, Clock, ArrowLeft, TrendingUp } from 'lucide-react'
import { formatDistanceToNow, format } from 'date-fns'
import { es } from 'date-fns/locale'
import { toast } from 'sonner'
import { getAuctionById, placeBid } from '@/api/auctions.api'
import { useAuctionSocket } from '@/services/auctionSocket'
import type { AuctionSocketEvent } from '@/services/auctionSocket'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { PageLoader } from '@/components/layout/page-loader'
import { useAuthStore } from '@/store/authStore'
import { ROUTES } from '@/constants/routes'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

export default function AuctionRoomPage() {
  const { id } = useParams<{ id: string }>()
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)

  const [currentPrice, setCurrentPrice] = useState<number | null>(null)
  const [bidAmount, setBidAmount] = useState('')
  const [wsConnected, setWsConnected] = useState(false)
  const [bidHistory, setBidHistory] = useState<
    { amount: number; time: string; bidder?: string }[]
  >([])

  const { data: auction, isLoading, isError } = useQuery({
    queryKey: ['auction', id],
    queryFn: () => getAuctionById(id!),
    enabled: Boolean(id),
  })

  useEffect(() => {
    if (auction && currentPrice === null) {
      setCurrentPrice(parseFloat(auction.current_price))
    }
  }, [auction, currentPrice])

  const handleSocketEvent = useCallback((event: AuctionSocketEvent) => {
    switch (event.type) {
      case 'connected':
        setWsConnected(true)
        break
      case 'snapshot':
        setCurrentPrice(parseFloat(event.current_price))
        break
      case 'bid_placed':
        setCurrentPrice(parseFloat(event.current_price))
        setBidHistory((prev) => [
          { amount: parseFloat(event.amount), time: new Date().toISOString(), bidder: event.bidder_name },
          ...prev.slice(0, 19),
        ])
        toast.success(`Nueva puja: ${formatPrice(parseFloat(event.amount))}`)
        break
      case 'auction_closed':
        toast.info('La subasta ha finalizado.')
        break
    }
  }, [])

  useAuctionSocket(
    id,
    handleSocketEvent,
    auction?.status === 'ACTIVA',
  )

  const bidMutation = useMutation({
    mutationFn: () => placeBid(id!, parseFloat(bidAmount)),
    onSuccess: () => {
      toast.success('Puja registrada exitosamente')
      setBidAmount('')
    },
    onError: () => {
      toast.error('No se pudo registrar la puja. Verifica el monto.')
    },
  })

  const minBid = currentPrice ? currentPrice + 1 : 0

  if (isLoading) return <PageLoader label="Entrando a la sala de subasta…" />

  if (isError || !auction) {
    return (
      <div className="min-h-screen bg-bg pt-24 flex flex-col items-center gap-4">
        <p className="text-text-muted font-body">No se encontró esta subasta.</p>
        <Link to={ROUTES.AUCTIONS} className="text-oro hover:underline font-body text-sm">
          ← Volver a subastas
        </Link>
      </div>
    )
  }

  const displayPrice = currentPrice ?? parseFloat(auction.current_price)
  const isActive = auction.status === 'ACTIVA'

  return (
    <div className="min-h-screen bg-bg pt-16">
      <div className="mx-auto max-w-5xl px-6 py-8">
        {/* Breadcrumb */}
        <Link
          to={ROUTES.AUCTIONS}
          className="inline-flex items-center gap-1.5 text-text-muted hover:text-oro font-body text-sm no-underline transition-colors mb-6"
        >
          <ArrowLeft size={14} /> Subastas
        </Link>

        {/* Header */}
        <div className="flex flex-wrap items-center gap-3 mb-6">
          <Badge variant={isActive ? 'selva' : 'indigo'}>
            {isActive ? 'En curso' : auction.status === 'CERRADA' ? 'Finalizada' : 'Cancelada'}
          </Badge>
          {wsConnected && isActive && (
            <span className="flex items-center gap-1.5 font-body text-[12px] text-selva">
              <span className="w-2 h-2 rounded-full bg-selva animate-pulse" />
              En tiempo real
            </span>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Panel principal */}
          <div className="lg:col-span-2 space-y-6">

            {/* Precio actual */}
            <div className="rounded-card border border-border bg-surface p-8 text-center">
              <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-2">
                Puja actual
              </p>
              <p className="font-display font-black text-oro" style={{ fontSize: '48px' }}>
                {formatPrice(displayPrice)}
              </p>
              <p className="font-body text-text-muted text-sm mt-1">
                Precio base: {formatPrice(parseFloat(auction.base_price))}
              </p>
            </div>

            {/* Formulario de puja */}
            {isActive && isAuthenticated && (
              <div className="rounded-card border border-border bg-surface p-6 space-y-4">
                <h3 className="font-display font-bold text-text-primary text-[18px]">
                  Hacer una puja
                </h3>
                <p className="font-body text-text-muted text-sm">
                  Mínimo: {formatPrice(minBid)}
                </p>
                <div className="flex gap-3">
                  <input
                    type="number"
                    min={minBid}
                    step={1000}
                    value={bidAmount}
                    onChange={(e) => setBidAmount(e.target.value)}
                    placeholder={`Ej: ${formatPrice(minBid + 50000)}`}
                    className="flex-1 rounded-input border border-border bg-bg px-4 py-2.5 font-body text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-oro/50"
                  />
                  <Button
                    variant="gold"
                    onClick={() => bidMutation.mutate()}
                    disabled={
                      bidMutation.isPending ||
                      !bidAmount ||
                      parseFloat(bidAmount) <= displayPrice
                    }
                    className="gap-2"
                  >
                    <Gavel size={16} />
                    Pujar
                  </Button>
                </div>
              </div>
            )}

            {isActive && !isAuthenticated && (
              <div className="rounded-card border border-border bg-surface p-6 text-center">
                <p className="font-body text-text-muted text-sm mb-3">
                  Debes iniciar sesión para hacer una puja.
                </p>
                <Link to={ROUTES.LOGIN}>
                  <Button variant="primary">Iniciar sesión</Button>
                </Link>
              </div>
            )}

            {/* Historial de pujas */}
            {bidHistory.length > 0 && (
              <div className="rounded-card border border-border bg-surface p-6">
                <h3 className="font-display font-bold text-text-primary text-[16px] mb-4 flex items-center gap-2">
                  <TrendingUp size={18} className="text-oro" />
                  Pujas recientes
                </h3>
                <div className="space-y-2">
                  {bidHistory.map((bid, i) => (
                    <div
                      key={i}
                      className={`flex items-center justify-between py-2 border-b border-border last:border-0 ${i === 0 ? 'text-oro' : 'text-text-muted'}`}
                    >
                      <span className="font-body text-sm font-semibold">
                        {formatPrice(bid.amount)}
                      </span>
                      <span className="font-body text-[12px]">
                        {format(new Date(bid.time), 'HH:mm:ss')}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Panel lateral */}
          <div className="space-y-4">
            {isActive && (
              <div className="rounded-card border border-border bg-surface p-5">
                <div className="flex items-center gap-2 mb-2">
                  <Clock size={16} className="text-oro" />
                  <p className="font-body font-semibold text-text-primary text-sm">
                    Tiempo restante
                  </p>
                </div>
                <p className="font-body text-text-muted text-sm">
                  Cierra{' '}
                  {formatDistanceToNow(new Date(auction.ends_at), {
                    addSuffix: true,
                    locale: es,
                  })}
                </p>
                <p className="font-body text-[11px] text-text-muted mt-1">
                  {format(new Date(auction.ends_at), "d MMM yyyy, HH:mm", { locale: es })}
                </p>
              </div>
            )}

            <div className="rounded-card border border-border bg-surface p-5 space-y-3">
              <p className="font-body font-semibold text-text-primary text-sm">Detalles</p>
              <div>
                <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-0.5">Inicio</p>
                <p className="font-body text-sm text-text-primary">
                  {format(new Date(auction.starts_at), "d MMM yyyy, HH:mm", { locale: es })}
                </p>
              </div>
              <div>
                <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-0.5">Fin</p>
                <p className="font-body text-sm text-text-primary">
                  {format(new Date(auction.ends_at), "d MMM yyyy, HH:mm", { locale: es })}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
