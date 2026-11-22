import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Edit, ImageIcon, Plus, Trash2 } from 'lucide-react'
import { toast } from 'sonner'

import { deleteArtwork, getArtworks } from '@/api/artworks.api'
import { getMyArtistProfile } from '@/api/artists.api'
import { Badge } from '@/components/ui/badge'
import { ArtworkImage } from '@/components/artworks/artwork-image'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { ROUTES } from '@/constants/routes'
import { useAuthStore } from '@/store/authStore'
import type { Artwork } from '@/types'
import { formatCurrency } from '@/utils'
import { artworkStatus } from '@/constants/labels'

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
  const categoryName = artwork.category_detail?.name ?? 'Sin categoría'

  return (
    <Card className="overflow-hidden">
      <div className="relative aspect-[4/3] bg-bg-subtle">
        <ArtworkImage src={image} alt={artwork.title} accent="magenta" />
        <div className="absolute left-3 top-3">
          <Badge variant="magenta">{categoryName}</Badge>
        </div>
        <div className="absolute right-3 top-3">
          <Badge variant={artworkStatus(artwork.status).variant}>
            {artworkStatus(artwork.status).label}
          </Badge>
        </div>
      </div>

      <CardContent className="space-y-3 p-4">
        <div className="space-y-0.5">
          <h2 className="line-clamp-1 text-base font-semibold text-text-primary">
            {artwork.title}
          </h2>
          <p className="line-clamp-2 min-h-10 text-sm text-text-secondary">
            {artwork.description}
          </p>
        </div>

        <div className="flex items-center justify-between gap-3">
          <p className="text-sm font-semibold text-naranja">{formatCurrency(artwork.price, 'Sin precio')}</p>
          <p className="text-xs text-text-secondary">{artwork.technique || 'Sin técnica'}</p>
        </div>

        <div className="flex gap-2">
          <Button asChild variant="outline" size="sm" className="flex-1">
            <Link to={ROUTES.ARTWORK_DETAIL(artwork.id)}>Ver</Link>
          </Button>
          <Button
            asChild
            variant="ghost"
            size="sm"
            className="gap-1.5 text-text-primary"
          >
            <Link to={ROUTES.DASHBOARD.ARTWORK_EDIT(artwork.id)}>
              <Edit size={14} />
              Editar
            </Link>
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="gap-1.5 text-error hover:bg-error/10 hover:text-error"
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
    queryFn: () => getMyArtistProfile(),
    enabled: user?.role === 'artist',
  })
  const profile = profilesQuery.data ?? null

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
    <div className="min-h-screen pt-16">
      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-8 md:px-10">
        <section className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-sm font-medium text-text-secondary">Panel de artista</p>
            <h1 className="text-3xl font-semibold tracking-tight text-text-primary">Mis obras</h1>
            {!isLoading && artworks.length > 0 && (
              <p className="mt-1 text-sm text-text-secondary">
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
              <p className="text-sm text-error">No fue posible cargar tus obras.</p>
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
                  <div className="aspect-[4/3] animate-pulse rounded-md bg-bg-subtle" />
                  <div className="h-4 w-2/3 animate-pulse rounded bg-bg-subtle" />
                  <div className="h-3 w-1/2 animate-pulse rounded bg-bg-subtle" />
                </CardContent>
              </Card>
            ))}
          </div>
        )}

        {!isLoading && !artworksQuery.isError && artworks.length === 0 && (
          <Card>
            <CardContent className="flex flex-col items-start gap-4 p-6">
              <div className="rounded-full bg-magenta-tint p-3 text-magenta">
                <ImageIcon size={22} />
              </div>
              <div>
                <h2 className="text-lg font-semibold text-text-primary">
                  Aún no tienes obras registradas
                </h2>
                <p className="mt-1 max-w-xl text-sm text-text-secondary">
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
