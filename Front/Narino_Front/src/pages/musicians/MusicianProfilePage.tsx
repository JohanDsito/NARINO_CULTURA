import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { UserPlus, UserCheck, Globe, ArrowLeft, ExternalLink, Music2 } from 'lucide-react'
import { FaSpotify, FaYoutube, FaSoundcloud, FaInstagram } from 'react-icons/fa'
import { toast } from 'sonner'
import { getMusicianBySlug, getMusicianWorks, followMusician } from '@/api/musicians.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { PageLoader } from '@/components/layout/page-loader'
import { useAuthStore } from '@/store/authStore'
import { ROUTES, AGGREGATION_TYPE_LABELS, MUSICAL_WORK_TYPE_LABELS } from '@/constants/routes'

export default function MusicianProfilePage() {
  const { slug } = useParams<{ slug: string }>()
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)
  const queryClient = useQueryClient()
  const [isFollowing, setIsFollowing] = useState(false)

  const { data: musician, isLoading, isError } = useQuery({
    queryKey: ['musician', slug],
    queryFn: () => getMusicianBySlug(slug!),
    enabled: Boolean(slug),
  })

  const { data: works = [] } = useQuery({
    queryKey: ['musician-works', slug],
    queryFn: () => getMusicianWorks(slug!),
    enabled: Boolean(slug),
  })

  const followMutation = useMutation({
    mutationFn: () => followMusician(slug!),
    onSuccess: (res) => {
      setIsFollowing((v) => !v)
      toast.success(res.detail)
      void queryClient.invalidateQueries({ queryKey: ['musician', slug] })
    },
    onError: () => toast.error('No se pudo actualizar el seguimiento.'),
  })

  if (isLoading) return <PageLoader label="Cargando perfil del músico…" />

  if (isError || !musician) {
    return (
      <div className="min-h-screen bg-bg pt-24 flex flex-col items-center gap-4">
        <p className="text-text-muted font-body">No se encontró este perfil.</p>
        <Link to={ROUTES.MUSICIANS} className="text-oro hover:underline font-body text-sm">
          ← Volver a músicos
        </Link>
      </div>
    )
  }

  const youtubeWorks = works.filter((w) => w.youtube_url && w.work_type === 'VIDEO')
  const audioWorks = works.filter((w) => w.work_type !== 'VIDEO')
  const hasWorks = works.length > 0

  const socialLinks = [
    musician.spotify_url && {
      href: musician.spotify_url,
      label: 'Spotify',
      icon: <FaSpotify size={15} />,
      hover: 'hover:text-[#1DB954]',
    },
    musician.youtube_url && {
      href: musician.youtube_url,
      label: 'YouTube',
      icon: <FaYoutube size={15} />,
      hover: 'hover:text-[#FF0000]',
    },
    musician.soundcloud_url && {
      href: musician.soundcloud_url,
      label: 'SoundCloud',
      icon: <FaSoundcloud size={15} />,
      hover: 'hover:text-orange-400',
    },
    musician.instagram_handle && {
      href: `https://instagram.com/${musician.instagram_handle.replace(/^@/, '')}`,
      label: `@${musician.instagram_handle.replace(/^@/, '')}`,
      icon: <FaInstagram size={15} />,
      hover: 'hover:text-oro',
    },
    musician.website_url && {
      href: musician.website_url,
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
      {/* Breadcrumb */}
      <div className="px-6 md:px-16 pt-6" style={{ background: '#2D1B00' }}>
        <Link
          to={ROUTES.MUSICIANS}
          className="inline-flex items-center gap-1.5 text-oro/60 hover:text-oro font-body text-sm no-underline transition-colors pb-4"
        >
          <ArrowLeft size={14} /> Músicos
        </Link>
      </div>

      {/* Hero */}
      <section className="relative overflow-hidden px-6 md:px-16 pb-14 pt-8" style={{ background: '#2D1B00' }}>
        {/* Decorative glow */}
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
              {musician.profile_image ? (
                <img src={musician.profile_image} alt={musician.artistic_name} className="w-full h-full object-cover" />
              ) : (
                <span className="font-display font-bold text-oro text-5xl">
                  {musician.artistic_name.charAt(0)}
                </span>
              )}
            </div>
          </div>

          {/* Info */}
          <div className="flex-1 min-w-0">
            {/* Badges */}
            <div className="flex flex-wrap gap-2 mb-3">
              <Badge variant="indigo">
                {AGGREGATION_TYPE_LABELS[musician.aggregation_type] ?? musician.aggregation_type}
              </Badge>
              {musician.is_verified && <Badge variant="selva">Verificado</Badge>}
            </div>

            {/* Name */}
            <h1
              className="font-display font-black text-oro-light leading-tight mb-2"
              style={{ fontSize: 'clamp(28px, 5vw, 44px)' }}
            >
              {musician.artistic_name}
            </h1>

            {/* Location */}
            <p className="font-body text-text-muted text-sm mb-4">
              📍 {musician.city}, {musician.region}
              {musician.founding_year && ` · Desde ${musician.founding_year}`}
            </p>

            {/* Genres */}
            {musician.genres.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mb-5">
                {musician.genres.map((g) => (
                  <span
                    key={g.id}
                    className="rounded-tag bg-white/10 text-oro-light font-body text-[12px] px-2.5 py-0.5"
                  >
                    {g.icon} {g.name}
                  </span>
                ))}
              </div>
            )}

            {/* Bio */}
            {musician.bio && (
              <p
                className="font-body text-[14px] leading-[1.7] mb-6 max-w-2xl"
                style={{ color: 'rgba(245,239,229,0.78)' }}
              >
                {musician.bio}
              </p>
            )}

            {/* Social links */}
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

            {/* Actions */}
            {isAuthenticated && (
              <Button
                variant={isFollowing ? 'secondary' : 'primary'}
                onClick={() => followMutation.mutate()}
                disabled={followMutation.isPending}
                className="gap-2"
              >
                {isFollowing
                  ? <><UserCheck size={16} /> Siguiendo</>
                  : <><UserPlus size={16} /> Seguir</>}
              </Button>
            )}
          </div>

          {/* Stats column */}
          <div className="flex md:flex-col gap-6 md:gap-4 md:text-right text-center flex-none">
            <div>
              <p className="font-display font-bold text-oro leading-none" style={{ fontSize: '2rem' }}>
                {musician.followers_count}
              </p>
              <p className="font-body text-text-muted text-[11px] mt-0.5 uppercase tracking-wide">
                Seguidores
              </p>
            </div>
            {hasWorks && (
              <div>
                <p className="font-display font-bold text-oro leading-none" style={{ fontSize: '2rem' }}>
                  {works.length}
                </p>
                <p className="font-body text-text-muted text-[11px] mt-0.5 uppercase tracking-wide">
                  Obras
                </p>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Gold separator */}
      <div className="h-[3px] w-full" style={{ background: 'linear-gradient(90deg, #2D1B00 0%, var(--oro) 40%, var(--oro) 60%, #2D1B00 100%)' }} />

      {/* Content */}
      <div className="max-w-5xl mx-auto px-6 md:px-16 py-12">
        {!hasWorks ? (
          /* Empty state */
          <div className="flex flex-col items-center gap-5 py-16 text-center">
            <div
              className="w-20 h-20 rounded-full flex items-center justify-center"
              style={{ background: 'rgba(201,146,26,0.08)' }}
            >
              <Music2 size={32} style={{ color: 'rgba(201,146,26,0.4)' }} />
            </div>
            <div className="space-y-1.5">
              <p className="font-display font-semibold text-text-primary text-lg">
                Aún no hay obras publicadas
              </p>
              <p className="font-body text-text-muted text-sm max-w-sm">
                Cuando este músico suba canciones, videos o podcasts, aparecerán aquí.
              </p>
            </div>
            <Link
              to={ROUTES.MUSICIANS}
              className="font-body text-sm text-oro hover:underline no-underline"
            >
              ← Explorar más músicos
            </Link>
          </div>
        ) : (
          <div className="space-y-14">
            {/* Videos */}
            {youtubeWorks.length > 0 && (
              <section>
                <div className="flex items-center gap-4 mb-8">
                  <h2 className="font-display font-bold text-text-primary text-[22px] whitespace-nowrap">
                    Videos
                  </h2>
                  <div className="flex-1 h-[2px]" style={{ background: 'var(--oro)' }} />
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {youtubeWorks.slice(0, 4).map((work) => {
                    const youtubeId = work.youtube_url.match(
                      /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|v\/))([^&?/]+)/,
                    )?.[1]
                    return (
                      <Card key={work.id} className="p-0 overflow-hidden">
                        {youtubeId ? (
                          <iframe
                            src={`https://www.youtube-nocookie.com/embed/${youtubeId}`}
                            title={work.title}
                            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                            allowFullScreen
                            className="w-full aspect-video"
                          />
                        ) : (
                          <a
                            href={work.youtube_url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-2 p-4 text-oro hover:underline font-body text-sm"
                          >
                            <FaYoutube size={18} /> {work.title}
                          </a>
                        )}
                        <div className="p-3">
                          <p className="font-body font-semibold text-text-primary text-sm">{work.title}</p>
                          <p className="font-body text-text-muted text-[12px]">
                            {MUSICAL_WORK_TYPE_LABELS[work.work_type] ?? work.work_type}
                          </p>
                        </div>
                      </Card>
                    )
                  })}
                </div>
              </section>
            )}

            {/* Audio / other works */}
            {audioWorks.length > 0 && (
              <section>
                <div className="flex items-center gap-4 mb-6">
                  <h2 className="font-display font-bold text-text-primary text-[22px] whitespace-nowrap">
                    Música
                  </h2>
                  <div className="flex-1 h-[2px]" style={{ background: 'var(--oro)' }} />
                </div>
                <div className="grid gap-4 sm:grid-cols-2">
                  {audioWorks.map((work) => {
                    const soundcloudUrl = work.soundcloud_embed?.startsWith('http')
                      ? work.soundcloud_embed
                      : null
                    const workLinks = [
                      work.spotify_track_url && {
                        href: work.spotify_track_url,
                        icon: <FaSpotify size={13} />,
                        label: 'Spotify',
                        color: 'hover:text-[#1DB954]',
                      },
                      soundcloudUrl && {
                        href: soundcloudUrl,
                        icon: <FaSoundcloud size={13} />,
                        label: 'SoundCloud',
                        color: 'hover:text-orange-400',
                      },
                      work.youtube_url && {
                        href: work.youtube_url,
                        icon: <FaYoutube size={13} />,
                        label: 'YouTube',
                        color: 'hover:text-[#FF0000]',
                      },
                    ].filter(Boolean) as {
                      href: string
                      icon: React.ReactNode
                      label: string
                      color: string
                    }[]

                    const formatDuration = (secs: number) => {
                      const m = Math.floor(secs / 60)
                      const s = String(secs % 60).padStart(2, '0')
                      return `${m}:${s}`
                    }

                    return (
                      <div
                        key={work.id}
                        className="rounded-card border border-border bg-surface overflow-hidden"
                      >
                        <div className="flex gap-4 p-4">
                          {/* Thumbnail o ícono */}
                          <div className="w-16 h-16 flex-none rounded-lg overflow-hidden bg-oro/10 flex items-center justify-center">
                            {work.thumbnail ? (
                              <img
                                src={work.thumbnail}
                                alt={work.title}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <FaSpotify size={22} className="text-oro/40" />
                            )}
                          </div>

                          {/* Contenido */}
                          <div className="flex-1 min-w-0 space-y-1">
                            <div className="flex items-start justify-between gap-2">
                              <p className="font-body font-semibold text-text-primary text-sm leading-tight line-clamp-2">
                                {work.title}
                              </p>
                              {work.is_featured && (
                                <span className="flex-none text-[10px] bg-oro/10 text-oro px-2 py-0.5 rounded-full font-medium">
                                  Destacada
                                </span>
                              )}
                            </div>

                            <p className="font-body text-text-muted text-[11px]">
                              {MUSICAL_WORK_TYPE_LABELS[work.work_type] ?? work.work_type}
                              {work.release_date && ` · ${work.release_date.slice(0, 4)}`}
                              {work.duration_seconds
                                ? ` · ${formatDuration(work.duration_seconds)}`
                                : null}
                            </p>

                            {work.description && (
                              <p className="font-body text-text-muted text-[12px] leading-snug line-clamp-2 pt-0.5">
                                {work.description}
                              </p>
                            )}

                            {workLinks.length > 0 && (
                              <div className="flex flex-wrap gap-3 pt-1">
                                {workLinks.map((link) => (
                                  <a
                                    key={link.href}
                                    href={link.href}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className={`flex items-center gap-1 font-body text-[12px] text-text-muted no-underline transition-colors ${link.color}`}
                                  >
                                    {link.icon}
                                    {link.label}
                                  </a>
                                ))}
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </section>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
