import { Link } from 'react-router-dom'
import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Edit, ImageIcon, Music, Plus, RefreshCw } from 'lucide-react'

import { getArtworks } from '@/api/artworks.api'
import { listArtistProfiles } from '@/api/artists.api'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { ROUTES } from '@/constants/routes'
import { useAuthStore } from '@/store/authStore'
import type { Artwork } from '@/types/auth'

type ArtworkLike = Artwork & {
  image?: string
  image_url?: string
  category?: string | { id?: number; name?: string; slug?: string }
  release_date?: string
  composer?: string
  genre?: string
  demo?: string
  artist?: Artwork['artist'] & {
    user_id?: string | number
    artistic_name?: string
    user?: { id?: string | number }
  }
}

function formatPrice(value?: number) {
  if (!value) return 'Sin precio'

  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(value)
}

function getArtworkImage(artwork: ArtworkLike) {
  return artwork.images?.[0]?.url || artwork.image_url || artwork.image || ''
}

function getCategoryName(category: ArtworkLike['category']) {
  if (!category) return 'Sin categoria'
  if (typeof category === 'string') return category
  return category.name || category.slug || 'Sin categoria'
}

function isMusicArtwork(artwork: ArtworkLike) {
  const category = getCategoryName(artwork.category)
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()

  return category.includes('music') || Boolean(artwork.demo || artwork.release_date || artwork.genre)
}

function statusLabel(status?: string) {
  const labels: Record<string, string> = {
    DISPONIBLE: 'Disponible',
    EN_SUBASTA: 'En subasta',
    VENDIDO: 'Vendido',
    PENDIENTE: 'Pendiente',
  }

  return labels[status ?? ''] ?? status ?? 'Publicada'
}

export default function ArtistArtworksPage() {
  const user = useAuthStore((state) => state.user)

  const artworksQuery = useQuery({
    queryKey: ['artist-artworks', user?.id],
    queryFn: () => getArtworks(),
    enabled: Boolean(user?.id),
  })

  const profilesQuery = useQuery({
    queryKey: ['artist-profile', 'me'],
    queryFn: listArtistProfiles,
    enabled: user?.role === 'artist',
  })

  const profile = useMemo(
    () => profilesQuery.data?.find((item) => item.user_id === String(user?.id)) ?? null,
    [profilesQuery.data, user?.id],
  )

  const artworks = useMemo(() => {
    const items = (artworksQuery.data ?? []) as ArtworkLike[]
    const hasArtistMetadata = items.some((artwork) => Boolean(artwork.artist))

    if (!hasArtistMetadata) return items

    return items.filter((artwork) => {
      const artist = artwork.artist
      if (!artist || !user) return false

      return (
        String(artist.user_id ?? '') === String(user.id) ||
        String(artist.user?.id ?? '') === String(user.id) ||
        Boolean(profile?.id && String(artist.id) === String(profile.id)) ||
        Boolean(profile?.slug && artist.slug === profile.slug) ||
        Boolean(profile?.artistic_name && artist.artistic_name === profile.artistic_name)
      )
    })
  }, [artworksQuery.data, profile, user])

  const isLoading = artworksQuery.isLoading || profilesQuery.isLoading

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">
              Mis obras
            </h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Gestion de obras publicadas y demos musicales.
            </p>
          </div>
          <Button asChild>
            <Link to={ROUTES.DASHBOARD.ARTWORKS_NEW} className="gap-2">
              <Plus size={16} />
              Anadir obra
            </Link>
          </Button>
        </section>

        {artworksQuery.isError ? (
          <Card>
            <CardContent className="flex flex-col gap-3 p-6">
              <p className="text-sm text-destructive">No fue posible cargar tus obras.</p>
              <Button
                type="button"
                variant="outline"
                className="w-fit gap-2"
                onClick={() => artworksQuery.refetch()}
              >
                <RefreshCw size={16} />
                Reintentar
              </Button>
            </CardContent>
          </Card>
        ) : null}

        {isLoading ? (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 3 }).map((_, index) => (
              <Card key={index}>
                <CardContent className="space-y-4 p-4">
                  <div className="aspect-[4/3] animate-pulse rounded-md bg-muted" />
                  <div className="h-4 w-2/3 animate-pulse rounded bg-muted" />
                  <div className="h-3 w-1/2 animate-pulse rounded bg-muted" />
                </CardContent>
              </Card>
            ))}
          </div>
        ) : null}

        {!isLoading && !artworksQuery.isError && artworks.length === 0 ? (
          <Card>
            <CardContent className="flex flex-col items-start gap-4 p-6">
              <div className="rounded-full bg-tierra-pale p-3 text-tierra">
                <ImageIcon size={22} />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-foreground">Aun no tienes obras registradas</h2>
                <p className="mt-1 max-w-xl text-sm text-muted-foreground">
                  Cuando guardes una obra o un demo musical, aparecera aqui para que puedas revisarlo.
                </p>
              </div>
              <Button asChild>
                <Link to={ROUTES.DASHBOARD.ARTWORKS_NEW}>Crear primera obra</Link>
              </Button>
            </CardContent>
          </Card>
        ) : null}

        {!isLoading && artworks.length > 0 ? (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {artworks.map((artwork) => {
              const image = getArtworkImage(artwork)
              const isMusic = isMusicArtwork(artwork)

              return (
                <Card key={artwork.id} className="overflow-hidden">
                  <div className="relative aspect-[4/3] bg-muted">
                    {image ? (
                      <img
                        src={image}
                        alt={artwork.title}
                        className="h-full w-full object-cover"
                        loading="lazy"
                      />
                    ) : (
                      <div className="flex h-full w-full items-center justify-center text-muted-foreground">
                        {isMusic ? <Music size={36} /> : <ImageIcon size={36} />}
                      </div>
                    )}
                    <div className="absolute left-3 top-3">
                      <Badge variant={isMusic ? 'indigo' : 'tierra'}>
                        {isMusic ? 'Musica' : getCategoryName(artwork.category)}
                      </Badge>
                    </div>
                  </div>

                  <CardContent className="space-y-3 p-4">
                    <div className="space-y-1">
                      <h2 className="line-clamp-1 text-base font-semibold text-foreground">
                        {artwork.title}
                      </h2>
                      <p className="line-clamp-2 min-h-10 text-sm text-muted-foreground">
                        {artwork.description}
                      </p>
                    </div>

                    <div className="flex items-center justify-between gap-3">
                      <div>
                        <p className="text-xs text-muted-foreground">
                          {isMusic ? artwork.genre || 'Demo musical' : artwork.technique || 'Tecnica no registrada'}
                        </p>
                        <p className="text-sm font-semibold text-tierra">
                          {isMusic ? artwork.release_date || 'Sin fecha' : formatPrice(artwork.price)}
                        </p>
                      </div>
                      <Badge variant={artwork.status === 'DISPONIBLE' ? 'selva' : 'oro'}>
                        {statusLabel(artwork.status)}
                      </Badge>
                    </div>

                    <div className="flex gap-2">
                      <Button asChild variant="outline" className="flex-1">
                        <Link to={ROUTES.ARTWORK_DETAIL(artwork.id)}>Ver</Link>
                      </Button>
                      <Button asChild variant="ghost" className="gap-2">
                        <Link to={ROUTES.DASHBOARD.ARTWORK_EDIT(artwork.id)}>
                          <Edit size={15} />
                          Editar
                        </Link>
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        ) : null}
      </main>
    </div>
  )
}
