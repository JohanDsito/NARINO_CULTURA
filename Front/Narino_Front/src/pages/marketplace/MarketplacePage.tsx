import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { ShoppingBag, Gavel, Users } from 'lucide-react'
import { getArtworks } from '@/api/artworks.api'
import { getAuctions } from '@/api/auctions.api'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ROUTES } from '@/constants/routes'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

export default function MarketplacePage() {
  const { data: artworksData } = useQuery({
    queryKey: ['artworks', 'DISPONIBLE', 1],
    queryFn: () => getArtworks({ status: 'DISPONIBLE', page_size: 6 }),
    staleTime: 2 * 60 * 1000,
  })

  const { data: auctionsData } = useQuery({
    queryKey: ['auctions', 'ACTIVA'],
    queryFn: () => getAuctions({ status: 'ACTIVA', page_size: 3 }),
    staleTime: 30 * 1000,
  })

  const featuredArtworks = artworksData?.results ?? []
  const activeAuctions = Array.isArray(auctionsData)
    ? auctionsData
    : (auctionsData?.results ?? [])

  return (
    <div className="min-h-screen bg-bg pt-16">
      {/* Hero */}
      <section className="relative px-6 md:px-16 py-20 overflow-hidden" style={{ background: '#2D1B00' }}>
        <div
          className="pointer-events-none absolute -top-20 -right-20 w-96 h-96 rounded-full"
          style={{ background: 'radial-gradient(circle, rgba(201,146,26,0.12) 0%, transparent 70%)' }}
        />
        <div className="max-w-4xl mx-auto text-center relative z-10">
          <Badge variant="oro" className="mb-4">Marketplace Cultural</Badge>
          <h1 className="font-display font-black text-oro-light mb-4" style={{ fontSize: 'clamp(32px,7vw,60px)' }}>
            Arte Nariñense<br />para el Mundo
          </h1>
          <p className="font-body text-[16px] mb-8" style={{ color: 'rgba(245,239,229,0.75)' }}>
            Adquiere obras originales directamente de artistas locales o participa en subastas exclusivas.
          </p>
          <div className="flex flex-wrap gap-3 justify-center">
            <Link to={ROUTES.ARTWORKS}>
              <Button variant="gold" className="gap-2">
                <ShoppingBag size={18} /> Ver catálogo completo
              </Button>
            </Link>
            <Link to={ROUTES.AUCTIONS}>
              <Button variant="secondary" className="gap-2">
                <Gavel size={18} /> Subastas activas
              </Button>
            </Link>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="px-6 md:px-16 py-10 bg-surface border-b border-border">
        <div className="max-w-5xl mx-auto grid grid-cols-3 gap-6 text-center">
          <div>
            <p className="font-display font-bold text-oro text-[32px]">{artworksData?.count ?? '+'}</p>
            <p className="font-body text-text-muted text-sm">Obras disponibles</p>
          </div>
          <div>
            <p className="font-display font-bold text-oro text-[32px]">{activeAuctions.length}</p>
            <p className="font-body text-text-muted text-sm">Subastas activas</p>
          </div>
          <div>
            <Users size={32} className="mx-auto mb-1 text-oro" />
            <p className="font-body text-text-muted text-sm">Artistas locales</p>
          </div>
        </div>
      </section>

      {/* Obras destacadas */}
      {featuredArtworks.length > 0 && (
        <section className="px-6 md:px-16 py-12 max-w-6xl mx-auto">
          <div className="flex items-center justify-between mb-8">
            <h2 className="font-display font-bold text-text-primary text-[26px]">Obras Disponibles</h2>
            <Link to={ROUTES.ARTWORKS} className="font-body text-sm text-oro hover:underline">
              Ver todas →
            </Link>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {featuredArtworks.map((artwork) => {
              const mainImage =
                artwork.main_image_url ||
                artwork.images[0]?.image_url ||
                `https://placehold.co/400x300/2D1B00/F0C060?text=${encodeURIComponent(artwork.title)}`
              return (
                <Link key={artwork.id} to={ROUTES.ARTWORK_DETAIL(artwork.id)} className="no-underline">
                  <Card className="p-0 overflow-hidden group hover:shadow-card transition-shadow">
                    <div className="aspect-[4/3] overflow-hidden rounded-t-card">
                      <img src={mainImage} alt={artwork.title} loading="lazy"
                        className="w-full h-full object-cover transition-transform duration-350 group-hover:scale-105" />
                    </div>
                    <div className="p-4">
                      <h3 className="font-display font-bold text-text-primary text-[14px] line-clamp-1 group-hover:text-oro transition-colors">
                        {artwork.title}
                      </h3>
                      {artwork.category_detail && (
                        <p className="font-body text-text-muted text-[12px] mt-0.5">{artwork.category_detail.name}</p>
                      )}
                      <p className="font-display font-bold text-oro text-[16px] mt-2">
                        {formatPrice(parseFloat(artwork.price))}
                      </p>
                    </div>
                  </Card>
                </Link>
              )
            })}
          </div>
        </section>
      )}

      {/* Subastas activas */}
      {activeAuctions.length > 0 && (
        <section className="px-6 md:px-16 py-12 max-w-6xl mx-auto">
          <div className="flex items-center justify-between mb-8">
            <h2 className="font-display font-bold text-text-primary text-[26px]">Subastas en Curso</h2>
            <Link to={ROUTES.AUCTIONS} className="font-body text-sm text-oro hover:underline">
              Ver todas →
            </Link>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
            {activeAuctions.slice(0, 3).map((auction) => (
              <Link key={auction.id} to={ROUTES.AUCTION_DETAIL(auction.id)} className="no-underline">
                <Card className="p-5 hover:shadow-card transition-shadow group">
                  <div className="flex items-center justify-between mb-3">
                    <Badge variant="selva">En curso</Badge>
                    <Gavel size={18} className="text-text-muted group-hover:text-oro transition-colors" />
                  </div>
                  <p className="font-body text-text-muted text-[11px] uppercase tracking-widest mb-1">Puja actual</p>
                  <p className="font-display font-bold text-oro text-[22px]">
                    {formatPrice(parseFloat(auction.current_price))}
                  </p>
                </Card>
              </Link>
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
