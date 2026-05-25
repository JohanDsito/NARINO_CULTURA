import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { CheckCircle, XCircle, Eye, Trash2, Layers } from 'lucide-react'
import { toast } from 'sonner'
import { getPendingArtworks, getAllArtworks, moderateArtwork, deleteAdminArtwork } from '@/api/admin.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { PageShell } from '@/components/layout/page-shell'
import type { Artwork } from '@/types/auth'

const STATUS_BADGE: Record<string, 'tierra' | 'selva' | 'secondary' | 'indigo'> = {
  PENDIENTE: 'tierra',
  DISPONIBLE: 'selva',
  INACTIVA: 'secondary',
  EN_SUBASTA: 'indigo',
}

const STATUS_LABEL: Record<string, string> = {
  PENDIENTE: 'Pendiente',
  DISPONIBLE: 'Disponible',
  INACTIVA: 'Inactiva',
  EN_SUBASTA: 'En subasta',
}

function ArtworkRow({
  artwork,
  onDelete,
  onApprove,
  onReject,
  isPending,
  showModerate,
}: {
  artwork: Artwork
  onDelete: (id: string, title: string) => void
  onApprove?: (id: string) => void
  onReject?: (id: string) => void
  isPending: boolean
  showModerate: boolean
}) {
  const mainImage = artwork.main_image_url || artwork.images?.[0]?.image_url || ''
  return (
    <div className="flex items-center gap-4 rounded-card border border-border bg-surface p-4">
      {mainImage && (
        <img src={mainImage} alt={artwork.title} className="w-16 h-16 rounded-md object-cover flex-none" />
      )}
      <div className="flex-1 min-w-0">
        <p className="font-body font-semibold text-text-primary text-sm">{artwork.title}</p>
        {artwork.category && (
          <p className="font-body text-text-muted text-[12px]">{artwork.category.name}</p>
        )}
        <Badge
          variant={STATUS_BADGE[artwork.status] ?? 'secondary'}
          className="mt-1 text-[10px]"
        >
          {STATUS_LABEL[artwork.status] ?? artwork.status}
        </Badge>
      </div>
      <div className="flex gap-2 flex-none flex-wrap">
        <Button
          variant="secondary"
          className="gap-1.5 text-[13px] px-3 py-1.5"
          onClick={() => window.open(`/artworks/${artwork.id}`, '_blank')}
        >
          <Eye size={14} />
          Ver
        </Button>
        {showModerate && onApprove && (
          <Button
            variant="primary"
            className="gap-1.5 text-[13px] px-3 py-1.5 bg-selva hover:bg-selva/90"
            disabled={isPending}
            onClick={() => onApprove(artwork.id)}
          >
            <CheckCircle size={14} />
            Aprobar
          </Button>
        )}
        {showModerate && onReject && (
          <Button
            variant="secondary"
            className="gap-1.5 text-[13px] px-3 py-1.5 text-error border-error/30 hover:bg-error/5"
            disabled={isPending}
            onClick={() => onReject(artwork.id)}
          >
            <XCircle size={14} />
            Rechazar
          </Button>
        )}
        <Button
          variant="secondary"
          className="gap-1.5 text-[13px] px-3 py-1.5 text-destructive border-destructive/30 hover:bg-destructive/5"
          disabled={isPending}
          onClick={() => onDelete(artwork.id, artwork.title)}
        >
          <Trash2 size={14} />
          Eliminar
        </Button>
      </div>
    </div>
  )
}

type Tab = 'pending' | 'all'

export default function AdminArtworksPage() {
  const queryClient = useQueryClient()
  const [tab, setTab] = useState<Tab>('pending')

  const { data: pendingArtworks = [], isLoading: isLoadingPending } = useQuery({
    queryKey: ['admin-pending-artworks'],
    queryFn: getPendingArtworks,
    staleTime: 60 * 1000,
  })

  const { data: allArtworks = [], isLoading: isLoadingAll } = useQuery({
    queryKey: ['admin-all-artworks'],
    queryFn: getAllArtworks,
    staleTime: 60 * 1000,
  })

  const deleteMutation = useMutation({
    mutationFn: deleteAdminArtwork,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['admin-pending-artworks'] })
      await queryClient.invalidateQueries({ queryKey: ['admin-all-artworks'] })
      await queryClient.invalidateQueries({ queryKey: ['admin-metrics'] })
      toast.success('Obra eliminada.')
    },
    onError: () => toast.error('No se pudo eliminar la obra.'),
  })

  const handleDelete = (id: string, title: string) => {
    if (!window.confirm(`¿Eliminar permanentemente "${title}"? Esta acción no se puede deshacer.`))
      return
    deleteMutation.mutate(id)
  }

  const moderateMutation = useMutation({
    mutationFn: ({ id, status, reason }: { id: string; status: 'DISPONIBLE' | 'INACTIVA'; reason?: string }) =>
      moderateArtwork(id, { status, reason }),
    onSuccess: (_, { status }) => {
      toast.success(status === 'DISPONIBLE' ? 'Obra aprobada' : 'Obra rechazada')
      void queryClient.invalidateQueries({ queryKey: ['admin-pending-artworks'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-all-artworks'] })
    },
    onError: () => toast.error('No se pudo procesar la acción'),
  })

  const isActionPending = moderateMutation.isPending || deleteMutation.isPending

  const artworks = tab === 'pending' ? pendingArtworks : allArtworks
  const isLoading = tab === 'pending' ? isLoadingPending : isLoadingAll

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Gestión de Obras"
        subtitle={
          tab === 'pending'
            ? `${pendingArtworks.length} obra${pendingArtworks.length === 1 ? '' : 's'} pendiente${pendingArtworks.length === 1 ? '' : 's'} de revisión`
            : `${allArtworks.length} obra${allArtworks.length === 1 ? '' : 's'} en la plataforma`
        }
      />

      <main className="mx-auto max-w-5xl px-6 py-8 space-y-6">
        {/* Tabs */}
        <div className="flex gap-2 border-b border-border">
          <button
            className={`pb-2 px-3 text-sm font-medium transition-colors border-b-2 -mb-px ${
              tab === 'pending'
                ? 'border-primary text-primary'
                : 'border-transparent text-text-muted hover:text-text-primary'
            }`}
            onClick={() => setTab('pending')}
          >
            Pendientes de moderación
            {pendingArtworks.length > 0 && (
              <span className="ml-2 inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-amber-500 px-1 text-[10px] font-bold text-white">
                {pendingArtworks.length}
              </span>
            )}
          </button>
          <button
            className={`pb-2 px-3 text-sm font-medium transition-colors border-b-2 -mb-px flex items-center gap-1.5 ${
              tab === 'all'
                ? 'border-primary text-primary'
                : 'border-transparent text-text-muted hover:text-text-primary'
            }`}
            onClick={() => setTab('all')}
          >
            <Layers size={13} />
            Todas las obras
          </button>
        </div>

        {isLoading ? (
          <div className="space-y-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-24" />
            ))}
          </div>
        ) : artworks.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <CheckCircle size={40} className="opacity-30" />
            <p className="font-body text-sm">
              {tab === 'pending' ? 'No hay obras pendientes de moderación.' : 'No hay obras registradas.'}
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {artworks.map((artwork) => (
              <ArtworkRow
                key={artwork.id}
                artwork={artwork}
                onDelete={handleDelete}
                onApprove={tab === 'pending' ? (id) => moderateMutation.mutate({ id, status: 'DISPONIBLE' }) : undefined}
                onReject={tab === 'pending' ? (id) => moderateMutation.mutate({ id, status: 'INACTIVA', reason: 'No cumple los requisitos' }) : undefined}
                isPending={isActionPending}
                showModerate={tab === 'pending'}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
