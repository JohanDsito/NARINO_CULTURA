import { Link } from 'react-router-dom'
import { Heart, ImageOff } from 'lucide-react'

import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { artworkStatus } from '@/constants/labels'
import { ROUTES } from '@/constants/routes'
import { useFavorites } from '@/hooks/useFavorites'
import { formatCurrency } from '@/utils'

export default function FavoritesPage() {
  const { favorites, isLoading, isError, refetch, toggle, pendingId } = useFavorites()
  // Las filas "pendiente-…" son el agregado optimista: todavía no tienen datos de la obra
  const saved = favorites.filter((f) => !f.id.startsWith('pendiente-'))

  return (
    <div className="min-h-screen pt-16">
      <PageShell title="Mis favoritos" subtitle="Las obras que guardaste para ver después" />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {isLoading ? (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3" aria-hidden>
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="h-72 animate-pulse rounded-card border border-border bg-bg-card" />
            ))}
          </div>
        ) : isError ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <p className="font-body text-sm">No pudimos cargar tus favoritos.</p>
            <Button variant="secondary" size="sm" onClick={() => refetch()}>
              Reintentar
            </Button>
          </div>
        ) : saved.length === 0 ? (
          <div className="flex flex-col items-center gap-4 py-24 text-text-muted">
            <Heart size={48} className="opacity-30" />
            <p className="font-body text-center text-sm">
              Todavía no tienes obras favoritas. Toca «Guardar en favoritos» en cualquier obra.
            </p>
            <Button asChild variant="primary" size="sm">
              <Link to={ROUTES.ARTWORKS} className="no-underline">
                Explorar el catálogo
              </Link>
            </Button>
          </div>
        ) : (
          <ul className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {saved.map((favorite) => (
              <li
                key={favorite.id}
                className="flex flex-col overflow-hidden rounded-card border border-border bg-bg-card"
              >
                {/* La imagen repite el enlace del título: solo visual, para no anunciar la obra dos veces */}
                <Link
                  to={ROUTES.ARTWORK_DETAIL(favorite.artwork_id)}
                  className="no-underline"
                  tabIndex={-1}
                  aria-hidden
                >
                  {favorite.artwork_image_url ? (
                    <img
                      src={favorite.artwork_image_url}
                      alt=""
                      className="h-48 w-full object-cover"
                      loading="lazy"
                    />
                  ) : (
                    <div className="flex h-48 items-center justify-center bg-bg-subtle text-text-muted">
                      <ImageOff size={32} className="opacity-40" />
                    </div>
                  )}
                </Link>
                <div className="flex flex-1 flex-col gap-1 p-4">
                  <Link
                    to={ROUTES.ARTWORK_DETAIL(favorite.artwork_id)}
                    className="font-display text-[17px] font-bold text-text-primary no-underline hover:text-oro"
                  >
                    {favorite.title}
                  </Link>
                  {favorite.artist_name && (
                    <p className="font-body text-[13px] text-text-muted">{favorite.artist_name}</p>
                  )}
                  <div className="mt-auto flex items-center justify-between pt-3">
                    <span className="font-body text-sm font-semibold text-text-primary">
                      {formatCurrency(favorite.artwork_price)}
                    </span>
                    {favorite.artwork_status && favorite.artwork_status !== 'DISPONIBLE' && (
                      <Badge variant={artworkStatus(favorite.artwork_status).variant} className="text-[10px]">
                        {artworkStatus(favorite.artwork_status).label}
                      </Badge>
                    )}
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="mt-2 self-start"
                    onClick={() => toggle(favorite.artwork_id)}
                    disabled={pendingId === favorite.artwork_id}
                    aria-label={`Quitar «${favorite.title}» de favoritos`}
                  >
                    <Heart size={14} className="fill-current" />
                    Quitar
                  </Button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </main>
    </div>
  )
}
