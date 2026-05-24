import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, XCircle, Eye } from 'lucide-react'
import { toast } from 'sonner'
import { getPendingArtworks, moderateArtwork } from '@/api/admin.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { PageShell } from '@/components/layout/page-shell'

export default function AdminArtworksPage() {
  const queryClient = useQueryClient()

  const { data: artworks = [], isLoading } = useQuery({
    queryKey: ['admin-pending-artworks'],
    queryFn: getPendingArtworks,
    staleTime: 60 * 1000,
  })

  const moderateMutation = useMutation({
    mutationFn: ({ id, status, reason }: { id: string; status: 'DISPONIBLE' | 'INACTIVA'; reason?: string }) =>
      moderateArtwork(id, { status, reason }),
    onSuccess: (_, { status }) => {
      toast.success(status === 'DISPONIBLE' ? 'Obra aprobada' : 'Obra rechazada')
      void queryClient.invalidateQueries({ queryKey: ['admin-pending-artworks'] })
    },
    onError: () => toast.error('No se pudo procesar la acción'),
  })

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Moderación de Obras"
        subtitle={`${artworks.length} obra${artworks.length === 1 ? '' : 's'} pendiente${artworks.length === 1 ? '' : 's'} de revisión`}
      />

      <main className="mx-auto max-w-5xl px-6 py-8">
        {isLoading ? (
          <div className="space-y-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-24" />
            ))}
          </div>
        ) : artworks.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <CheckCircle size={40} className="opacity-30" />
            <p className="font-body text-sm">No hay obras pendientes de moderación.</p>
          </div>
        ) : (
          <div className="space-y-4">
            {artworks.map((artwork) => {
              const mainImage =
                artwork.main_image_url ||
                artwork.images[0]?.image_url ||
                ''

              return (
                <div
                  key={artwork.id}
                  className="flex items-center gap-4 rounded-card border border-border bg-surface p-4"
                >
                  {mainImage && (
                    <img
                      src={mainImage}
                      alt={artwork.title}
                      className="w-16 h-16 rounded-md object-cover flex-none"
                    />
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-body font-semibold text-text-primary text-sm">{artwork.title}</p>
                    {artwork.category && (
                      <p className="font-body text-text-muted text-[12px]">{artwork.category.name}</p>
                    )}
                    <Badge variant="tierra" className="mt-1 text-[10px]">{artwork.status}</Badge>
                  </div>
                  <div className="flex gap-2 flex-none">
                    <Button
                      variant="secondary"
                      className="gap-1.5 text-[13px] px-3 py-1.5"
                      onClick={() => window.open(`/artworks/${artwork.id}`, '_blank')}
                    >
                      <Eye size={14} />
                      Ver
                    </Button>
                    <Button
                      variant="primary"
                      className="gap-1.5 text-[13px] px-3 py-1.5 bg-selva hover:bg-selva/90"
                      disabled={moderateMutation.isPending}
                      onClick={() => moderateMutation.mutate({ id: artwork.id, status: 'DISPONIBLE' })}
                    >
                      <CheckCircle size={14} />
                      Aprobar
                    </Button>
                    <Button
                      variant="secondary"
                      className="gap-1.5 text-[13px] px-3 py-1.5 text-error border-error/30 hover:bg-error/5"
                      disabled={moderateMutation.isPending}
                      onClick={() => moderateMutation.mutate({ id: artwork.id, status: 'INACTIVA', reason: 'No cumple los requisitos' })}
                    >
                      <XCircle size={14} />
                      Rechazar
                    </Button>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </main>
    </div>
  )
}
