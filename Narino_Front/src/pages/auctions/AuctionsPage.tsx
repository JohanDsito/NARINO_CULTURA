import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Gavel, Clock } from 'lucide-react'
import { formatDistanceToNow } from 'date-fns'
import { es } from 'date-fns/locale'
import { getAuctions } from '@/api/auctions.api'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { PageShell } from '@/components/layout/page-shell'
import { ROUTES } from '@/constants/routes'
import type { AuctionStatus } from '@/types/auth'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

const TABS: { label: string; value: AuctionStatus }[] = [
  { label: 'En curso', value: 'ACTIVA' },
  { label: 'Finalizadas', value: 'CERRADA' },
  { label: 'Canceladas', value: 'CANCELADA' },
]

export default function AuctionsPage() {
  const [activeTab, setActiveTab] = useState<AuctionStatus>('ACTIVA')

  const { data, isLoading } = useQuery({
    queryKey: ['auctions', activeTab],
    queryFn: () => getAuctions({ status: activeTab, page_size: 20 }),
    staleTime: 30 * 1000,
  })

  const auctions = Array.isArray(data) ? data : (data?.results ?? [])

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Subastas"
        subtitle="Compite en tiempo real por obras únicas de artistas nariñenses"
      />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {/* Tabs */}
        <div className="flex gap-2 mb-8 border-b border-border">
          {TABS.map((tab) => (
            <button
              key={tab.value}
              onClick={() => setActiveTab(tab.value)}
              className={`px-4 py-2 font-body text-sm font-medium transition-colors border-b-2 -mb-px ${
                activeTab === tab.value
                  ? 'border-oro text-oro'
                  : 'border-transparent text-text-muted hover:text-text-primary'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-64" />
            ))}
          </div>
        ) : auctions.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <Gavel size={40} className="opacity-30" />
            <p className="font-body text-sm">No hay subastas {activeTab === 'ACTIVA' ? 'activas' : activeTab === 'CERRADA' ? 'finalizadas' : 'canceladas'} en este momento.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {auctions.map((auction) => (
              <Link
                key={auction.id}
                to={ROUTES.AUCTION_DETAIL(auction.id)}
                className="no-underline"
              >
                <Card className="p-5 hover:shadow-card transition-shadow cursor-pointer group">
                  <div className="flex items-start justify-between mb-4">
                    <Badge
                      variant={
                        auction.status === 'ACTIVA'
                          ? 'selva'
                          : auction.status === 'CERRADA'
                            ? 'indigo'
                            : 'tierra'
                      }
                    >
                      {auction.status === 'ACTIVA'
                        ? 'En curso'
                        : auction.status === 'CERRADA'
                          ? 'Finalizada'
                          : 'Cancelada'}
                    </Badge>
                    <Gavel size={18} className="text-text-muted group-hover:text-oro transition-colors" />
                  </div>

                  <div className="mb-4">
                    <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-1">
                      Precio base
                    </p>
                    <p className="font-display font-bold text-text-primary text-[18px]">
                      {formatPrice(parseFloat(auction.base_price))}
                    </p>
                  </div>

                  <div className="mb-4">
                    <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-1">
                      Puja actual
                    </p>
                    <p className="font-display font-bold text-oro text-[22px]">
                      {formatPrice(parseFloat(auction.current_price))}
                    </p>
                  </div>

                  {auction.status === 'ACTIVA' && (
                    <div className="flex items-center gap-1.5 text-text-muted">
                      <Clock size={14} />
                      <span className="font-body text-[12px]">
                        Cierra{' '}
                        {formatDistanceToNow(new Date(auction.ends_at), {
                          addSuffix: true,
                          locale: es,
                        })}
                      </span>
                    </div>
                  )}
                </Card>
              </Link>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
