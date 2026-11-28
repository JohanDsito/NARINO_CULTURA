import { useState } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ShoppingCart, Gavel, Eye, ArrowLeft, Sparkles } from 'lucide-react'
import { toast } from 'sonner'
import { getArtworkById, aiEnhanceArtwork } from '@/api/artworks.api'
import { addCartItem } from '@/api/marketplace.api'
import { ArtworkImage } from '@/components/artworks/artwork-image'
import { FavoriteButton } from '@/components/artworks/favorite-button'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { PageLoader } from '@/components/layout/page-loader'
import { useAuthStore } from '@/store/authStore'
import { useCartStore } from '@/store/cartStore'
import { ROUTES } from '@/constants/routes'
import { formatCurrency } from '@/utils'
import { getApiErrorMessage } from '@/utils/apiError'
import { artworkStatus } from '@/constants/labels'

export default function ArtworkDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const addLocalItem = useCartStore((s) => s.addItem)
  const queryClient = useQueryClient()
  const [selectedImage, setSelectedImage] = useState(0)

  const { data: artwork, isLoading, isError } = useQuery({
    queryKey: ['artwork', id],
    queryFn: () => getArtworkById(id!),
    enabled: Boolean(id),
  })

  const addToServerCartMutation = useMutation({
    mutationFn: () => addCartItem(id!),
    onSuccess: () => {
      toast.success('Obra agregada al carrito')
      void queryClient.invalidateQueries({ queryKey: ['server-cart'] })
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const aiEnhanceMutation = useMutation({
    mutationFn: () => aiEnhanceArtwork(id!),
    onSuccess: () => {
      toast.success('Descripción mejorada con IA')
      void queryClient.invalidateQueries({ queryKey: ['artwork', id] })
    },
    onError: () => {
      toast.error('El servicio de IA no está disponible.')
    },
  })

  if (isLoading) return <PageLoader fullPage label="Cargando obra…" />

  if (isError || !artwork) {
    return (
      <div className="min-h-screen pt-24 flex flex-col items-center gap-4">
        <p className="text-text-muted font-body">No se encontró esta obra.</p>
        <Link to={ROUTES.ARTWORKS} className="text-magenta hover:underline font-body text-sm">
          ← Volver al catálogo
        </Link>
      </div>
    )
  }

  const handleAddToCart = () => {
    if (isAuthenticated) {
      addToServerCartMutation.mutate()
    } else {
      const mainImage =
        artwork.main_image_url ||
        artwork.images?.[0]?.image_url ||
        ''
      addLocalItem({
        id: artwork.id,
        artwork_id: artwork.id,
        title: artwork.title,
        artist_name: artwork.artist_slug ?? '',
        price: parseFloat(artwork.price),
        image: mainImage,
      })
      toast.success('Obra agregada al carrito')
    }
  }

  const images = [
    ...(artwork.main_image_url ? [artwork.main_image_url] : []),
    // copia antes de ordenar: sort() mutaría los datos en caché de React Query
    ...[...(artwork.images ?? [])].sort((a, b) => a.order - b.order).map((img) => img.image_url),
  ].filter(Boolean)

  const status = artworkStatus(artwork.status)

  return (
    <div className="min-h-screen pt-16">
      <div className="mx-auto max-w-6xl px-6 py-8">
        {/* Breadcrumb */}
        <Link
          to={ROUTES.ARTWORKS}
          className="inline-flex items-center gap-1.5 text-text-muted hover:text-magenta font-body text-sm no-underline transition-colors mb-8"
        >
          <ArrowLeft size={14} /> Catálogo
        </Link>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Galería */}
          <div className="space-y-3">
            <div className="aspect-[4/3] overflow-hidden rounded-card bg-bg-card">
              <ArtworkImage src={images[selectedImage]} alt={artwork.title} accent="magenta" iconSize={56} />
            </div>
            {images.length > 1 && (
              <div className="flex gap-2 overflow-x-auto pb-1">
                {images.map((img, i) => (
                  <button
                    key={i}
                    onClick={() => setSelectedImage(i)}
                    className={`flex-none w-16 h-16 rounded-md overflow-hidden border-2 transition-colors ${
                      selectedImage === i ? 'border-magenta' : 'border-transparent'
                    }`}
                  >
                    <img src={img} alt="" className="w-full h-full object-cover" />
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Información */}
          <div className="space-y-6">
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Badge variant={status.variant}>{status.label}</Badge>
                {artwork.views_count > 0 && (
                  <span className="flex items-center gap-1 font-body text-[12px] text-text-muted">
                    <Eye size={12} /> {artwork.views_count} vistas
                  </span>
                )}
              </div>
              <h1 className="font-display font-bold text-text-primary text-[32px] leading-tight mb-2">
                {artwork.title}
              </h1>
              {artwork.category_detail && (
                <p className="font-body text-text-muted text-sm mb-1">{artwork.category_detail.name}</p>
              )}
            </div>

            {/* Precio */}
            <p className="font-display font-extrabold text-naranja text-[36px]">
              {formatCurrency(parseFloat(artwork.price))}
            </p>

            {/* Descripción */}
            {(artwork.ai_description || artwork.description) && (
              <div>
                <p className="font-body text-text-primary text-[15px] leading-relaxed">
                  {artwork.ai_description || artwork.description}
                </p>
              </div>
            )}

            {/* Detalles técnicos */}
            <div className="grid grid-cols-2 gap-4 py-4 border-t border-border">
              {artwork.technique && (
                <div>
                  <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-1">Técnica</p>
                  <p className="font-body text-sm text-text-primary">{artwork.technique}</p>
                </div>
              )}
              {artwork.dimensions && (
                <div>
                  <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-1">Dimensiones</p>
                  <p className="font-body text-sm text-text-primary">{artwork.dimensions}</p>
                </div>
              )}
              {artwork.material && (
                <div>
                  <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-1">Material</p>
                  <p className="font-body text-sm text-text-primary">{artwork.material}</p>
                </div>
              )}
            </div>

            {/* Acciones */}
            <div className="flex flex-col gap-3">
              {artwork.status === 'DISPONIBLE' && (
                <Button
                  variant="primary"
                  className="gap-2 w-full"
                  onClick={handleAddToCart}
                  disabled={addToServerCartMutation.isPending}
                >
                  <ShoppingCart size={18} />
                  Agregar al carrito
                </Button>
              )}
              {artwork.status === 'EN_SUBASTA' && (
                <Button
                  variant="gold"
                  className="gap-2 w-full"
                  onClick={() => navigate(ROUTES.AUCTIONS)}
                >
                  <Gavel size={18} />
                  Ver subastas activas
                </Button>
              )}
              <FavoriteButton artworkId={artwork.id} />
              {isAuthenticated && artwork.status === 'DISPONIBLE' && (
                <Button
                  variant="secondary"
                  className="gap-2 w-full"
                  onClick={() => aiEnhanceMutation.mutate()}
                  disabled={aiEnhanceMutation.isPending}
                >
                  <Sparkles size={16} />
                  {aiEnhanceMutation.isPending ? 'Mejorando con IA…' : 'Mejorar descripción con IA'}
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
