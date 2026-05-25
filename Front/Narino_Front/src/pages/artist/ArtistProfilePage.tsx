import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { UserPlus, UserCheck, Globe, ExternalLink, ArrowLeft } from 'lucide-react'
import { FaInstagram, FaFacebook, FaTiktok } from 'react-icons/fa'
import { toast } from 'sonner'
import { getArtistBySlug, followArtist } from '@/api/artists.api'
import { getArtworks } from '@/api/artworks.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { PageLoader } from '@/components/layout/page-loader'
import { useAuthStore } from '@/store/authStore'
import { ROUTES } from '@/constants/routes'

function formatPrice(n: number) {
  return new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n)
}

export default function ArtistProfilePage() {
  const { slug } = useParams<{ slug: string }>()
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const queryClient = useQueryClient()
  const [isFollowing, setIsFollowing] = useState(false)

  const {
    data: artist,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ['artist', slug],
    queryFn: () => getArtistBySlug(slug!),
    enabled: Boolean(slug),
  })

  useEffect(() => {
    if (artist) setIsFollowing(artist.is_following ?? false)
  }, [artist])

  const { data: artworksData } = useQuery({
    queryKey: ['artworks', 'artist', slug],
    queryFn: () => getArtworks({ artist: slug, page_size: 9 }),
    enabled: Boolean(slug),
  })

  const followMutation = useMutation({
    mutationFn: () => followArtist(slug!),
    onSuccess: (res) => {
      const nowFollowing = res.detail?.toLowerCase().includes('siguiendo') || !isFollowing
      setIsFollowing(nowFollowing)
      toast.success(res.detail)
      void queryClient.invalidateQueries({ queryKey: ['artist', slug] })
    },
    onError: () => {
      toast.error('No se pudo actualizar el seguimiento.')
    },
  })

  if (isLoading) return <PageLoader label="Cargando perfil…" />

  if (isError || !artist) {
    return (
      <div className="min-h-screen bg-bg pt-24 flex flex-col items-center gap-4">
        <p className="text-text-muted font-body">No se encontró este perfil de artista.</p>
        <Link to={ROUTES.ARTISTS} className="text-oro hover:underline font-body text-sm">
          ← Volver al directorio
        </Link>
      </div>
    )
  }

  const artworks = artworksData?.results ?? []

  return (
    <div className="min-h-screen bg-bg pt-16">

      {/* ── Breadcrumb ── */}
      <div className="px-6 md:px-16 pt-6">
        <Link
          to={ROUTES.ARTISTS}
          className="inline-flex items-center gap-1.5 text-text-muted hover:text-oro font-body text-sm no-underline transition-colors"
        >
          <ArrowLeft size={14} /> Artistas
        </Link>
      </div>

      {/* ── SECCIÓN SUPERIOR ── */}
      <section className="relative overflow-hidden px-6 md:px-16 py-16 md:py-24" style={{ background: '#2D1B00' }}>
        <div
          className="pointer-events-none absolute -top-20 -right-20 w-80 h-80 rounded-full"
          style={{ background: 'radial-gradient(circle, rgba(201,146,26,0.15) 0%, transparent 70%)' }}
        />
        <div className="max-w-5xl mx-auto grid md:grid-cols-2 gap-12 items-center relative z-10">

          {/* Texto */}
          <div>
            {artist.is_public && (
              <Badge variant="indigo" className="mb-4">Perfil Público</Badge>
            )}
            <h1
              className="font-display font-black text-oro-light leading-tight mb-1"
              style={{ fontSize: 'clamp(30px,6vw,50px)' }}
            >
              {artist.artistic_name}
            </h1>
            {artist.discipline && (
              <p className="font-accent italic text-tierra-light text-[22px] mb-6">
                {artist.discipline}
              </p>
            )}
            {artist.city && (
              <p className="font-body text-[13px] text-text-muted mb-4">📍 {artist.city}</p>
            )}
            {artist.bio && (
              <p className="font-body text-[15px] leading-[1.65] mb-4" style={{ color: 'rgba(245,239,229,0.75)' }}>
                {artist.bio}
              </p>
            )}
            {artist.trajectory && (
              <p className="font-body text-[15px] leading-[1.65] mb-8" style={{ color: 'rgba(245,239,229,0.75)' }}>
                {artist.trajectory}
              </p>
            )}

            {/* Redes sociales */}
            <div className="flex flex-col gap-3 mb-8">
              <p className="font-body font-bold text-[11px] tracking-widest uppercase text-text-muted">
                Contacto
              </p>
              <div className="flex gap-5 flex-wrap">
                {artist.instagram_url && (
                  <a href={artist.instagram_url} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-oro transition-colors">
                    <FaInstagram size={16} /> Instagram
                  </a>
                )}
                {artist.facebook_url && (
                  <a href={artist.facebook_url} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-oro transition-colors">
                    <FaFacebook size={16} /> Facebook
                  </a>
                )}
                {artist.tiktok_url && (
                  <a href={artist.tiktok_url} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-oro transition-colors">
                    <FaTiktok size={16} /> TikTok
                  </a>
                )}
                {artist.website_url && (
                  <a href={artist.website_url} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-oro transition-colors">
                    <Globe size={16} /> Sitio web <ExternalLink size={12} />
                  </a>
                )}
              </div>
            </div>

            {/* Botón seguir */}
            {isAuthenticated && (
              <Button
                variant={isFollowing ? 'secondary' : 'primary'}
                onClick={() => followMutation.mutate()}
                disabled={followMutation.isPending}
                className="gap-2"
              >
                {isFollowing
                  ? <><UserCheck size={16} /> Siguiendo</>
                  : <><UserPlus size={16} /> Seguir artista</>}
              </Button>
            )}
          </div>

          {/* Foto */}
          <div className="flex justify-center md:justify-end">
            <div className="relative">
              <div
                className="absolute inset-0 rounded-[20px]"
                style={{ border: '3px solid var(--oro)', transform: 'translate(8px, 8px)' }}
              />
              <div
                className="relative w-[280px] md:w-[340px] aspect-[4/5] object-cover rounded-[20px] z-10 bg-volcan/40 flex items-center justify-center"
              >
                <span className="font-display text-oro text-6xl font-bold">
                  {artist.artistic_name.charAt(0)}
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── ESTADÍSTICAS ── */}
      <section className="px-6 md:px-16 py-10">
        <div className="max-w-5xl mx-auto rounded-[24px] p-8 md:p-10" style={{ background: '#4A3320' }}>
          <div className="grid grid-cols-2 md:grid-cols-2 gap-6">
            <div className="text-center">
              <p className="font-display font-bold text-oro" style={{ fontSize: '28px' }}>
                {artist.followers_count}
              </p>
              <p className="font-body font-medium text-[12px] text-text-muted mt-1">Seguidores</p>
            </div>
            <div className="text-center">
              <p className="font-display font-bold text-oro" style={{ fontSize: '28px' }}>
                {artworksData?.count ?? 0}
              </p>
              <p className="font-body font-medium text-[12px] text-text-muted mt-1">Obras publicadas</p>
            </div>
          </div>
        </div>
      </section>

      {/* ── PORTAFOLIO ── */}
      <section className="px-6 md:px-16 py-10 max-w-5xl mx-auto">
        <div className="flex items-center gap-4 mb-8">
          <h2 className="font-display font-bold text-text-primary" style={{ fontSize: '28px', whiteSpace: 'nowrap' }}>
            Sus Obras
          </h2>
          <div className="flex-1 h-[2px]" style={{ background: 'var(--oro)' }} />
        </div>

        {artworks.length === 0 ? (
          <p className="text-text-muted font-body text-center py-12">
            Este artista aún no ha publicado obras.
          </p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {artworks.map((artwork) => {
              const mainImage =
                artwork.main_image_url ||
                artwork.images.find((img) => img.order === 0)?.image_url ||
                artwork.images[0]?.image_url ||
                `https://placehold.co/400x300/2D1B00/F0C060?text=${encodeURIComponent(artwork.title)}`

              return (
                <Link
                  key={artwork.id}
                  to={ROUTES.ARTWORK_DETAIL(artwork.id)}
                  className="no-underline"
                >
                  <Card className="p-0 overflow-hidden group cursor-pointer hover:shadow-card transition-shadow">
                    <div className="relative aspect-[4/3] overflow-hidden rounded-t-card">
                      <img
                        src={mainImage}
                        alt={artwork.title}
                        loading="lazy"
                        className="w-full h-full object-cover transition-transform duration-[350ms] ease-smooth group-hover:scale-105"
                      />
                      <div className="absolute inset-0 bg-volcan/80 opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center">
                        <Button variant="gold" className="text-xs">Ver obra</Button>
                      </div>
                    </div>
                    <div className="p-4">
                      <h3 className="font-display font-bold text-text-primary text-[15px] mb-1">
                        {artwork.title}
                      </h3>
                      <p className="font-body text-text-muted text-[12px] mb-2">
                        {artist.artistic_name}
                      </p>
                      <div className="flex items-center justify-between">
                        <p className="font-body font-bold text-oro text-[15px]">
                          {formatPrice(parseFloat(artwork.price))}
                        </p>
                        <Badge variant={artwork.status === 'DISPONIBLE' ? 'selva' : artwork.status === 'EN_SUBASTA' ? 'indigo' : 'tierra'}>
                          {artwork.status === 'DISPONIBLE'
                            ? 'Disponible'
                            : artwork.status === 'EN_SUBASTA'
                              ? 'En subasta'
                              : artwork.status === 'VENDIDA'
                                ? 'Vendida'
                                : 'Inactiva'}
                        </Badge>
                      </div>
                    </div>
                  </Card>
                </Link>
              )
            })}
          </div>
        )}
      </section>
    </div>
  )
}
