import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { UserPlus, UserCheck, Globe, ArrowLeft, ExternalLink } from 'lucide-react'
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
      const nowFollowing = !isFollowing
      setIsFollowing(nowFollowing)
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

  return (
    <div className="min-h-screen bg-bg pt-16">
      {/* Breadcrumb */}
      <div className="px-6 md:px-16 pt-6">
        <Link
          to={ROUTES.MUSICIANS}
          className="inline-flex items-center gap-1.5 text-text-muted hover:text-oro font-body text-sm no-underline transition-colors"
        >
          <ArrowLeft size={14} /> Músicos
        </Link>
      </div>

      {/* Header */}
      <section className="relative overflow-hidden px-6 md:px-16 py-16" style={{ background: '#2D1B00' }}>
        <div
          className="pointer-events-none absolute -top-20 -right-20 w-80 h-80 rounded-full"
          style={{ background: 'radial-gradient(circle, rgba(201,146,26,0.15) 0%, transparent 70%)' }}
        />
        <div className="max-w-5xl mx-auto flex flex-col md:flex-row gap-10 items-start relative z-10">
          {/* Avatar */}
          <div className="w-32 h-32 rounded-full bg-oro/20 flex items-center justify-center flex-none">
            {musician.profile_image ? (
              <img src={musician.profile_image} alt="" className="w-32 h-32 rounded-full object-cover" />
            ) : (
              <span className="font-display font-bold text-oro text-5xl">
                {musician.artistic_name.charAt(0)}
              </span>
            )}
          </div>

          {/* Info */}
          <div className="flex-1">
            <div className="flex flex-wrap gap-2 mb-3">
              <Badge variant="indigo">
                {AGGREGATION_TYPE_LABELS[musician.aggregation_type] ?? musician.aggregation_type}
              </Badge>
              {musician.is_verified && <Badge variant="selva">Verificado</Badge>}
            </div>
            <h1 className="font-display font-black text-oro-light leading-tight mb-2" style={{ fontSize: 'clamp(28px,5vw,44px)' }}>
              {musician.artistic_name}
            </h1>
            <p className="font-body text-text-muted text-sm mb-3">
              📍 {musician.city}, {musician.region}
              {musician.founding_year && ` · Desde ${musician.founding_year}`}
            </p>

            {musician.genres.length > 0 && (
              <div className="flex flex-wrap gap-1.5 mb-4">
                {musician.genres.map((g) => (
                  <span
                    key={g.id}
                    className="rounded-tag bg-white/10 text-oro-light font-body text-[12px] px-2.5 py-1"
                  >
                    {g.icon} {g.name}
                  </span>
                ))}
              </div>
            )}

            {musician.bio && (
              <p className="font-body text-[15px] leading-[1.65] mb-6" style={{ color: 'rgba(245,239,229,0.75)' }}>
                {musician.bio}
              </p>
            )}

            {/* Social links */}
            <div className="flex flex-wrap gap-4 mb-6">
              {musician.spotify_url && (
                <a href={musician.spotify_url} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-[#1DB954] transition-colors">
                  <FaSpotify size={16} /> Spotify
                </a>
              )}
              {musician.youtube_url && (
                <a href={musician.youtube_url} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-[#FF0000] transition-colors">
                  <FaYoutube size={16} /> YouTube
                </a>
              )}
              {musician.soundcloud_url && (
                <a href={musician.soundcloud_url} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-orange-400 transition-colors">
                  <FaSoundcloud size={16} /> SoundCloud
                </a>
              )}
              {musician.instagram_handle && (
                <a href={`https://instagram.com/${musician.instagram_handle.replace(/^@/, '')}`} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-oro transition-colors">
                  <FaInstagram size={16} /> @{musician.instagram_handle.replace(/^@/, '')}
                </a>
              )}
              {musician.website_url && (
                <a href={musician.website_url} target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-1.5 no-underline text-oro-light font-body text-[13px] hover:text-oro transition-colors">
                  <Globe size={16} /> Sitio web <ExternalLink size={12} />
                </a>
              )}
            </div>

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

          {/* Stat */}
          <div className="text-center">
            <p className="font-display font-bold text-oro text-[32px]">{musician.followers_count}</p>
            <p className="font-body text-text-muted text-[12px]">Seguidores</p>
          </div>
        </div>
      </section>

      {/* Obras musicales */}
      {youtubeWorks.length > 0 && (
        <section className="px-6 md:px-16 py-12 max-w-5xl mx-auto">
          <div className="flex items-center gap-4 mb-8">
            <h2 className="font-display font-bold text-text-primary text-[24px] whitespace-nowrap">Videos</h2>
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
                    <a href={work.youtube_url} target="_blank" rel="noopener noreferrer"
                      className="flex items-center gap-2 p-4 text-oro hover:underline font-body text-sm">
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

      {/* Otras obras */}
      {audioWorks.length > 0 && (
        <section className="px-6 md:px-16 py-8 max-w-5xl mx-auto">
          <div className="flex items-center gap-4 mb-6">
            <h2 className="font-display font-bold text-text-primary text-[22px] whitespace-nowrap">Música</h2>
            <div className="flex-1 h-[2px]" style={{ background: 'var(--oro)' }} />
          </div>
          <div className="space-y-3">
            {audioWorks.map((work) => (
              <div key={work.id} className="flex items-center gap-4 rounded-card border border-border bg-surface p-4">
                <div className="w-10 h-10 rounded-md bg-oro/20 flex items-center justify-center flex-none">
                  <FaSpotify size={18} className="text-oro" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-body font-semibold text-text-primary text-sm line-clamp-1">{work.title}</p>
                  <p className="font-body text-text-muted text-[12px]">
                    {MUSICAL_WORK_TYPE_LABELS[work.work_type] ?? work.work_type}
                    {work.release_date && ` · ${work.release_date.slice(0, 4)}`}
                  </p>
                </div>
                {work.spotify_track_url && (
                  <a href={work.spotify_track_url} target="_blank" rel="noopener noreferrer"
                    className="text-text-muted hover:text-[#1DB954] transition-colors flex-none">
                    <ExternalLink size={16} />
                  </a>
                )}
              </div>
            ))}
          </div>
        </section>
      )}
    </div>
  )
}
