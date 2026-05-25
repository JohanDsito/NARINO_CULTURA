import { Link } from 'react-router-dom'
import { useMemo } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Edit, ImageIcon, Plus, Trash2 } from 'lucide-react'
import { toast } from 'sonner'

import { deleteArtwork, getArtworks } from '@/api/artworks.api'
import { listArtistProfiles } from '@/api/artists.api'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { ROUTES } from '@/constants/routes'
import { useAuthStore } from '@/store/authStore'
import type { Artwork, ArtworkStatus } from '@/types/auth'

function formatPrice(value: string | undefined) {
  if (!value) return 'Sin precio'
  const n = parseFloat(value)
  if (isNaN(n)) return 'Sin precio'
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n)
}

const STATUS_LABELS: Record<ArtworkStatus, string> = {
  DISPONIBLE: 'Disponible',
  EN_SUBASTA: 'En subasta',
  VENDIDA: 'Vendida',
  INACTIVA: 'Inactiva',
}

const STATUS_VARIANT: Record<ArtworkStatus, 'selva' | 'oro' | 'secondary' | 'indigo'> = {
  DISPONIBLE: 'selva',
  EN_SUBASTA: 'indigo',
  VENDIDA: 'secondary',
  INACTIVA: 'secondary',
}

function ArtworkCard({
  artwork,
  onDelete,
  isDeleting,
}: {
  artwork: Artwork
  onDelete: (id: string, title: string) => void
  isDeleting: boolean
}) {
  const image = artwork.main_image_url || artwork.images?.[0]?.image_url || ''
  const categoryName = artwork.category?.name ?? 'Sin categoría'

  return (
    <Card className="overflow-hidden">
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
            <ImageIcon size={36} />
          </div>
        )}
        <div className="absolute left-3 top-3">
          <Badge variant="tierra">{categoryName}</Badge>
        </div>
        <div className="absolute right-3 top-3">
          <Badge variant={STATUS_VARIANT[artwork.status] ?? 'secondary'}>
            {STATUS_LABELS[artwork.status] ?? artwork.status}
          </Badge>
        </div>
      </div>

      <CardContent className="space-y-3 p-4">
        <div className="space-y-0.5">
          <h2 className="line-clamp-1 text-base font-semibold text-foreground">
            {artwork.title}
          </h2>
          <p className="line-clamp-2 min-h-10 text-sm text-muted-foreground">
            {artwork.description}
          </p>
        </div>

        <div className="flex items-center justify-between gap-3">
          <p className="text-sm font-semibold text-tierra">{formatPrice(artwork.price)}</p>
          <p className="text-xs text-muted-foreground">{artwork.technique || 'Sin técnica'}</p>
        </div>

        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm" className="flex-1">
            <Link to={ROUTES.ARTWORK_DETAIL(artwork.id)}>Ver</Link>
          </Button>
          <Button
            asChild
            variant="ghost"
            size="sm"
            className="gap-1.5 text-foreground"
          >
            <Link to={ROUTES.DASHBOARD.ARTWORK_EDIT(artwork.id)}>
              <Edit size={14} />
              Editar
            </Link>
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="gap-1.5 text-destructive hover:bg-destructive/10 hover:text-destructive"
            disabled={isDeleting}
            onClick={() => onDelete(artwork.id, artwork.title)}
          >
            <Trash2 size={14} />
            Eliminar
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

export default function ArtistArtworksPage() {
  const user = useAuthStore((state) => state.user)
  const queryClient = useQueryClient()

  const profilesQuery = useQuery({
    queryKey: ['artist-profile', 'me'],
    queryFn: () => listArtistProfiles(),
    enabled: user?.role === 'artist',
  })

  const profile = useMemo(
    () => profilesQuery.data?.find((item) => item.user_id === String(user?.id)) ?? null,
    [profilesQuery.data, user?.id],
  )

  const artworksQuery = useQuery({
    queryKey: ['artist-artworks', profile?.slug],
    queryFn: () => getArtworks({ artist: profile!.slug }),
    enabled: Boolean(profile?.slug),
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteArtwork(id),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['artist-artworks', profile?.slug] })
      toast.success('Obra eliminada correctamente.')
    },
    onError: () => toast.error('No se pudo eliminar la obra.'),
  })

  const handleDelete = (id: string, title: string) => {
    if (!window.confirm(`¿Eliminar permanentemente "${title}"?\nEsta acción no se puede deshacer.`))
      return
    deleteMutation.mutate(id)
  }

  const artworks = artworksQuery.data?.results ?? []
  const isLoading = artworksQuery.isLoading || profilesQuery.isLoading

  return (
    <div className="min-h-screen bg-background pt-16">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-muted-foreground">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-foreground">Mis obras</h1>
            {!isLoading && artworks.length > 0 && (
              <p className="mt-1 text-sm text-muted-foreground">
                {artworks.length} obra{artworks.length === 1 ? '' : 's'} registrada{artworks.length === 1 ? '' : 's'}
              </p>
            )}
          </div>
          <Button asChild>
            <Link to={ROUTES.DASHBOARD.ARTWORKS_NEW} className="gap-2">
              <Plus size={16} />
              Añadir obra
            </Link>
          </Button>
        </section>

        {artworksQuery.isError && (
          <Card>
            <CardContent className="p-6">
              <p className="text-sm text-destructive">No fue posible cargar tus obras.</p>
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="mt-3 gap-2"
                onClick={() => artworksQuery.refetch()}
              >
                Reintentar
              </Button>
            </CardContent>
          </Card>
        )}

        {isLoading && (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <Card key={i}>
                <CardContent className="space-y-4 p-4">
                  <div className="aspect-[4/3] animate-pulse rounded-md bg-muted" />
                  <div className="h-4 w-2/3 animate-pulse rounded bg-muted" />
                  <div className="h-3 w-1/2 animate-pulse rounded bg-muted" />
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {!isLoading && !artworksQuery.isError && artworks.length === 0 && (
          <Card>
            <CardContent className="flex flex-col items-start gap-4 p-6">
              <div className="rounded-full bg-tierra-pale p-3 text-tierra">
                <ImageIcon size={22} />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-foreground">
                  Aún no tienes obras registradas
                </h2>
                <p className="mt-1 max-w-xl text-sm text-muted-foreground">
                  Cuando guardes una obra, aparecerá aquí para que puedas revisarla, editarla o eliminarla.
                </p>
              </div>
              <Button asChild>
                <Link to={ROUTES.DASHBOARD.ARTWORKS_NEW}>Crear primera obra</Link>
              </Button>
            </CardContent>
          </Card>
        )}

        {!isLoading && artworks.length > 0 && (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {artworks.map((artwork) => (
              <ArtworkCard
                key={artwork.id}
                artwork={artwork}
                onDelete={handleDelete}
                isDeleting={deleteMutation.isPending}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
