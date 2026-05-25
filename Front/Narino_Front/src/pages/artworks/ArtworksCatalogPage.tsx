import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Search, Image } from 'lucide-react'
import { getArtworks, getArtworkCategories } from '@/api/artworks.api'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { PageShell } from '@/components/layout/page-shell'
import { ROUTES } from '@/constants/routes'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency', currency: 'COP', maximumFractionDigits: 0,
  }).format(n)
}

const STATUS_LABELS: Record<string, string> = {
  DISPONIBLE: 'Disponible',
  EN_SUBASTA: 'En subasta',
  VENDIDA: 'Vendida',
  INACTIVA: 'Inactiva',
}

export default function ArtworksCatalogPage() {
  const [search, setSearch] = useState('')
  const [categoryId, setCategoryId] = useState<string>('')
  const [page, setPage] = useState(1)

  const { data: categoriesData = [] } = useQuery({
    queryKey: ['artwork-categories'],
    queryFn: getArtworkCategories,
    staleTime: 60 * 60 * 1000,
  })

  const { data: paginatedArtworks, isLoading } = useQuery({
    queryKey: ['artworks', search, categoryId, page],
    queryFn: () =>
      getArtworks({
        search: search || undefined,
        category: categoryId || undefined,
        page,
        page_size: 12,
      }),
    staleTime: 2 * 60 * 1000,
  })

  const artworks = paginatedArtworks?.results ?? []
  const totalCount = paginatedArtworks?.count ?? 0
  const hasNext = Boolean(paginatedArtworks?.next)
  const hasPrev = Boolean(paginatedArtworks?.previous)

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Catálogo de Obras"
        subtitle="Arte nariñense disponible para adquirir o subastar"
      />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {/* Filtros */}
        <div className="flex flex-col sm:flex-row gap-4 mb-8">
          <div className="relative flex-1">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted pointer-events-none" />
            <input
              type="search"
              placeholder="Buscar obras…"
              value={search}
              onChange={(e) => { setSearch(e.target.value); setPage(1) }}
              className="w-full rounded-input border border-border bg-surface pl-9 pr-4 py-2.5 font-body text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-oro/50"
            />
          </div>
          <select
            value={categoryId}
            onChange={(e) => { setCategoryId(e.target.value); setPage(1) }}
            className="rounded-input border border-border bg-surface px-3 py-2.5 font-body text-sm text-text-primary focus:outline-none focus:ring-2 focus:ring-oro/50"
          >
            <option value="">Todas las categorías</option>
            {categoriesData.map((cat) => (
              <option key={cat.id} value={cat.id}>{cat.name}</option>
            ))}
          </select>
        </div>

        {/* Contador */}
        {!isLoading && (
          <p className="font-body text-sm text-text-muted mb-4">
            {totalCount} {totalCount === 1 ? 'obra encontrada' : 'obras encontradas'}
          </p>
        )}

        {/* Grid */}
        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse">
                <div className="aspect-[4/3] bg-muted rounded-t-card" />
                <div className="p-4 space-y-2">
                  <div className="h-4 bg-muted rounded w-3/4" />
                  <div className="h-3 bg-muted rounded w-1/2" />
                  <div className="h-5 bg-muted rounded w-1/3" />
                </div>
              </div>
            ))}
          </div>
        ) : artworks.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <Image size={40} className="opacity-30" />
            <p className="font-body text-sm">No se encontraron obras con esos filtros.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
            {artworks.map((artwork) => {
              const mainImage =
                artwork.main_image_url ||
                artwork.images[0]?.image_url ||
                `https://placehold.co/400x300/2D1B00/F0C060?text=${encodeURIComponent(artwork.title)}`

              return (
                <Link key={artwork.id} to={ROUTES.ARTWORK_DETAIL(artwork.id)} className="no-underline">
                  <Card className="p-0 overflow-hidden group hover:shadow-card transition-shadow cursor-pointer">
                    <div className="relative aspect-[4/3] overflow-hidden rounded-t-card">
                      <img
                        src={mainImage}
                        alt={artwork.title}
                        loading="lazy"
                        className="w-full h-full object-cover transition-transform duration-[350ms] group-hover:scale-105"
                      />
                      {artwork.status !== 'DISPONIBLE' && (
                        <div className="absolute top-2 right-2">
                          <Badge variant={artwork.status === 'EN_SUBASTA' ? 'indigo' : 'tierra'}>
                            {STATUS_LABELS[artwork.status] ?? artwork.status}
                          </Badge>
                        </div>
                      )}
                    </div>
                    <div className="p-4">
                      <h3 className="font-display font-bold text-text-primary text-[14px] mb-1 line-clamp-1 group-hover:text-oro transition-colors">
                        {artwork.title}
                      </h3>
                      {artwork.category && (
                        <p className="font-body text-text-muted text-[12px] mb-2">
                          {artwork.category.name}
                        </p>
                      )}
                      <p className="font-body font-bold text-oro text-[15px]">
                        {formatPrice(parseFloat(artwork.price))}
                      </p>
                    </div>
                  </Card>
                </Link>
              )
            })}
          </div>
        )}

        {/* Paginación */}
        {(hasNext || hasPrev) && (
          <div className="flex items-center justify-center gap-4 mt-8">
            <button
              onClick={() => setPage((p) => p - 1)}
              disabled={!hasPrev}
              className="rounded-btn border border-border px-4 py-2 font-body text-sm text-text-primary hover:bg-surface disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              ← Anterior
            </button>
            <span className="font-body text-sm text-text-muted">Página {page}</span>
            <button
              onClick={() => setPage((p) => p + 1)}
              disabled={!hasNext}
              className="rounded-btn border border-border px-4 py-2 font-body text-sm text-text-primary hover:bg-surface disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            >
              Siguiente →
            </button>
          </div>
        )}
      </main>
    </div>
  )
}
