import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Search, Music } from 'lucide-react'
import { FaSpotify, FaYoutube } from 'react-icons/fa'
import { listMusicians } from '@/api/musicians.api'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { PageShell } from '@/components/layout/page-shell'
import { ROUTES, AGGREGATION_TYPE_LABELS } from '@/constants/routes'
import type { AggregationType } from '@/types/auth'

const AGGREGATION_OPTIONS: { value: AggregationType | ''; label: string }[] = [
  { value: '', label: 'Todos' },
  { value: 'SOLISTA', label: 'Solistas' },
  { value: 'BANDA', label: 'Bandas' },
  { value: 'DJ', label: 'DJs' },
  { value: 'COLECTIVO', label: 'Colectivos' },
  { value: 'DUO', label: 'Dúos' },
  { value: 'TRIO', label: 'Tríos' },
]

export default function MusicianDirectoryPage() {
  const [search, setSearch] = useState('')
  const [aggregationType, setAggregationType] = useState<AggregationType | ''>('')

  const { data, isLoading } = useQuery({
    queryKey: ['musicians', search, aggregationType],
    queryFn: () =>
      listMusicians({
        search: search || undefined,
        aggregation_type: aggregationType || undefined,
        page_size: 18,
      }),
    staleTime: 2 * 60 * 1000,
  })

  const musicians = data?.results ?? []

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Músicos de Nariño"
        subtitle="Artistas sonoros del departamento — solos, bandas, colectivos y más"
      />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {/* Filtros */}
        <div className="flex flex-col sm:flex-row gap-4 mb-8">
          <div className="relative flex-1">
            <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted pointer-events-none" />
            <input
              type="search"
              placeholder="Buscar por nombre artístico, género, ciudad…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full rounded-input border border-border bg-surface pl-9 pr-4 py-2.5 font-body text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-oro/50"
            />
          </div>
          <div className="flex gap-2 flex-wrap">
            {AGGREGATION_OPTIONS.map((opt) => (
              <button
                key={opt.value}
                onClick={() => setAggregationType(opt.value as AggregationType | '')}
                className={`rounded-btn px-3 py-1.5 font-body text-[13px] transition-colors ${
                  aggregationType === opt.value
                    ? 'bg-oro text-[#2D1B00] font-semibold'
                    : 'border border-border text-text-muted hover:text-text-primary hover:border-oro/50'
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        {/* Link a Music Discovery */}
        <div className="mb-8 rounded-card border border-oro/30 bg-oro/5 p-4 flex items-center justify-between flex-wrap gap-3">
          <div>
            <p className="font-body font-semibold text-text-primary text-sm">
              🎵 Búsqueda con IA
            </p>
            <p className="font-body text-text-muted text-[13px]">
              Describe en lenguaje natural qué tipo de música buscas y nuestra IA encontrará músicos para ti.
            </p>
          </div>
          <Link
            to={ROUTES.MUSIC_DISCOVERY}
            className="rounded-btn bg-oro text-[#2D1B00] font-body text-sm font-semibold px-4 py-2 no-underline hover:bg-oro-light transition-colors flex-none"
          >
            Probar →
          </Link>
        </div>

        {/* Grid */}
        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 9 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse h-52" />
            ))}
          </div>
        ) : musicians.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <Music size={40} className="opacity-30" />
            <p className="font-body text-sm">No se encontraron músicos con esos criterios.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {musicians.map((musician) => (
              <Link
                key={musician.id}
                to={ROUTES.MUSICIAN_DETAIL(musician.slug)}
                className="no-underline"
              >
                <Card className="p-5 hover:shadow-card transition-shadow cursor-pointer group">
                  {/* Avatar */}
                  <div className="w-14 h-14 rounded-full bg-oro/20 flex items-center justify-center mb-4">
                    {musician.profile_image_url ? (
                      <img src={musician.profile_image_url} alt="" className="w-14 h-14 rounded-full object-cover" />
                    ) : (
                      <span className="font-display font-bold text-oro text-2xl">
                        {musician.artistic_name.charAt(0)}
                      </span>
                    )}
                  </div>

                  <h3 className="font-display font-bold text-text-primary text-[16px] mb-1 group-hover:text-oro transition-colors line-clamp-1">
                    {musician.artistic_name}
                  </h3>

                  <div className="flex flex-wrap gap-1.5 mb-3">
                    <Badge variant="indigo" className="text-[10px]">
                      {AGGREGATION_TYPE_LABELS[musician.aggregation_type] ?? musician.aggregation_type}
                    </Badge>
                    {musician.is_verified && (
                      <Badge variant="selva" className="text-[10px]">Verificado</Badge>
                    )}
                  </div>

                  {musician.city && (
                    <p className="font-body text-text-muted text-[12px] mb-2">📍 {musician.city}</p>
                  )}

                  {musician.genres.length > 0 && (
                    <div className="flex flex-wrap gap-1 mb-3">
                      {musician.genres.slice(0, 3).map((genre) => (
                        <span
                          key={genre.id}
                          className="rounded-tag bg-surface border border-border px-2 py-0.5 font-body text-[10px] text-text-muted"
                        >
                          {genre.name}
                        </span>
                      ))}
                    </div>
                  )}

                  {/* Social icons */}
                  <div className="flex gap-3 mt-2">
                    {musician.spotify_url && (
                      <FaSpotify size={16} className="text-text-muted hover:text-selva transition-colors" />
                    )}
                    {musician.youtube_url && (
                      <FaYoutube size={16} className="text-text-muted hover:text-tierra transition-colors" />
                    )}
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
