import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { UserPlus, UserCheck, Globe, ExternalLink, ArrowLeft, Palette } from 'lucide-react'
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

  const { data: artist, isLoading, isError } = useQuery({
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
    onError: () => toast.error('No se pudo actualizar el seguimiento.'),
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
  const artworksCount = artworksData?.count ?? 0

  const socialLinks = [
    artist.instagram_url && {
      href: artist.instagram_url,
      label: 'Instagram',
      icon: <FaInstagram size={15} />,
      hover: 'hover:text-[#E1306C]',
    },
    artist.facebook_url && {
      href: artist.facebook_url,
      label: 'Facebook',
      icon: <FaFacebook size={15} />,
      hover: 'hover:text-[#1877F2]',
    },
    artist.tiktok_url && {
      href: artist.tiktok_url,
      label: 'TikTok',
      icon: <FaTiktok size={15} />,
      hover: 'hover:text-white',
    },
    artist.website_url && {
      href: artist.website_url,
      label: 'Sitio web',
      icon: <Globe size={15} />,
      hover: 'hover:text-oro',
      extra: <ExternalLink size={11} className="opacity-60" />,
    },
  ].filter(Boolean) as {
    href: string
    label: string
    icon: React.ReactNode
    hover: string
    extra?: React.ReactNode
  }[]

  return (
    <div className="min-h-screen bg-bg pt-16">
      {/* Breadcrumb integrado en el fondo oscuro */}
      <div className="px-6 md:px-16 pt-6" style={{ background: '#2D1B00' }}>
        <Link
          to={ROUTES.ARTISTS}
          className="inline-flex items-center gap-1.5 text-oro/60 hover:text-oro font-body text-sm no-underline transition-colors pb-4"
        >
          <ArrowLeft size={14} /> Artistas
        </Link>
      </div>

      {/* Hero */}
      <section
        className="relative overflow-hidden px-6 md:px-16 pb-14 pt-8"
        style={{ background: '#2D1B00' }}
      >
        {/* Decoraciones */}
        <div
          className="pointer-events-none absolute -top-20 -right-20 w-96 h-96 rounded-full opacity-60"
          style={{ background: 'radial-gradient(circle, rgba(201,146,26,0.18) 0%, transparent 70%)' }}
        />
        <div
          className="pointer-events-none absolute bottom-0 left-0 right-0 h-20"
          style={{ background: 'linear-gradient(to bottom, transparent, rgba(0,0,0,0.25))' }}
        />

        <div className="max-w-5xl mx-auto flex flex-col md:flex-row gap-10 items-start relative z-10">
          {/* Avatar */}
          <div className="flex-none">
            <div className="w-28 h-28 md:w-36 md:h-36 rounded-full ring-2 ring-oro/30 overflow-hidden bg-oro/20 flex items-center justify-center shadow-xl">
              {artist.profile_image_url ? (
                <img
                  src={artist.profile_image_url}
                  alt={artist.artistic_name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <span className="font-display font-bold text-oro text-5xl">
                  {artist.artistic_name.charAt(0)}
                </span>
              )}
            </div>
          </div>

          {/* Info */}
          <div className="flex-1 min-w-0">
            {/* Badge */}
            <div className="flex flex-wrap gap-2 mb-3">
              {artist.is_public && <Badge variant="indigo">Perfil público</Badge>}
            </div>

            {/* Nombre */}
            <h1
              className="font-display font-black text-oro-light leading-tight mb-1"
              style={{ fontSize: 'clamp(28px, 5vw, 44px)' }}
            >
              {artist.artistic_name}
            </h1>

            {/* Disciplina */}
            {artist.discipline && (
              <p className="font-accent italic text-tierra-light text-[20px] mb-4">
                {artist.discipline}
              </p>
            )}

            {/* Ciudad */}
            {artist.city && (
              <p className="font-body text-text-muted text-sm mb-4">📍 {artist.city}</p>
            )}

            {/* Biografía */}
            {artist.bio && (
              <p
                className="font-body text-[14px] leading-[1.7] mb-3 max-w-2xl"
                style={{ color: 'rgba(245,239,229,0.78)' }}
              >
                {artist.bio}
              </p>
            )}

            {/* Trayectoria */}
            {artist.trajectory && (
              <p
                className="font-body text-[14px] leading-[1.7] mb-6 max-w-2xl"
                style={{ color: 'rgba(245,239,229,0.65)' }}
              >
                {artist.trajectory}
              </p>
            )}

            {/* Redes sociales */}
            {socialLinks.length > 0 && (
              <div className="flex flex-wrap gap-x-5 gap-y-2.5 mb-6">
                {socialLinks.map((link) => (
                  <a
                    key={link.href}
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className={`flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] transition-colors ${link.hover}`}
                  >
                    {link.icon}
                    {link.label}
                    {link.extra}
                  </a>
                ))}
              </div>
            )}

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

          {/* Stats */}
          <div className="flex md:flex-col gap-6 md:gap-4 md:text-right text-center flex-none">
            <div>
              <p className="font-display font-bold text-oro leading-none" style={{ fontSize: '2rem' }}>
                {artist.followers_count}
              </p>
              <p className="font-body text-text-muted text-[11px] mt-0.5 uppercase tracking-wide">
                Seguidores
              </p>
            </div>
            {artworksCount > 0 && (
              <div>
                <p className="font-display font-bold text-oro leading-none" style={{ fontSize: '2rem' }}>
                  {artworksCount}
                </p>
                <p className="font-body text-text-muted text-[11px] mt-0.5 uppercase tracking-wide">
                  Obras
                </p>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Separador dorado */}
      <div
        className="h-[3px] w-full"
        style={{ background: 'linear-gradient(90deg, #2D1B00 0%, var(--oro) 40%, var(--oro) 60%, #2D1B00 100%)' }}
      />

      {/* Contenido */}
      <div className="max-w-5xl mx-auto px-6 md:px-16 py-12">
        {artworks.length === 0 ? (
          /* Empty state */
          <div className="flex flex-col items-center gap-5 py-16 text-center">
            <div
              className="w-20 h-20 rounded-full flex items-center justify-center"
              style={{ background: 'rgba(201,146,26,0.08)' }}
            >
              <Palette size={32} style={{ color: 'rgba(201,146,26,0.4)' }} />
            </div>
            <div className="space-y-1.5">
              <p className="font-display font-semibold text-text-primary text-lg">
                Aún no hay obras publicadas
              </p>
              <p className="font-body text-text-muted text-sm max-w-sm">
                Cuando este artista suba su portafolio, las obras aparecerán aquí.
              </p>
            </div>
            <Link
              to={ROUTES.ARTISTS}
              className="font-body text-sm text-oro hover:underline no-underline"
            >
              ← Explorar más artistas
            </Link>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-4 mb-8">
              <h2
                className="font-display font-bold text-text-primary whitespace-nowrap"
                style={{ fontSize: '22px' }}
              >
                Portafolio
              </h2>
              <div className="flex-1 h-[2px]" style={{ background: 'var(--oro)' }} />
            </div>

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
                        <h3 className="font-display font-bold text-text-primary text-[15px] mb-1 line-clamp-1">
                          {artwork.title}
                        </h3>
                        <p className="font-body text-text-muted text-[12px] mb-2">
                          {artist.artistic_name}
                        </p>
                        <div className="flex items-center justify-between">
                          <p className="font-body font-bold text-oro text-[15px]">
                            {formatPrice(parseFloat(artwork.price))}
                          </p>
                          <Badge
                            variant={
                              artwork.status === 'DISPONIBLE'
                                ? 'selva'
                                : artwork.status === 'EN_SUBASTA'
                                  ? 'indigo'
                                  : 'tierra'
                            }
                          >
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
          </>
        )}
      </div>
    </div>
  )
}
