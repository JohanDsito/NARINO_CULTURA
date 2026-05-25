import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Search, Users } from 'lucide-react'
import { listArtistProfiles } from '@/api/artists.api'
import { listMusicians } from '@/api/musicians.api'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { PageShell } from '@/components/layout/page-shell'
import { ROUTES } from '@/constants/routes'

export default function ArtistsPage() {
  const [search, setSearch] = useState('')

  const { data: artists = [], isLoading } = useQuery({
    queryKey: ['artists', search],
    queryFn: () => listArtistProfiles({ search: search || undefined }),
    staleTime: 2 * 60 * 1000,
  })

  const { data: musiciansData } = useQuery({
    queryKey: ['musicians-user-ids'],
    queryFn: () => listMusicians({ page_size: 500 }),
    staleTime: 5 * 60 * 1000,
  })

  const musicianUserIds = useMemo(() => {
    const ids = new Set<string>()
    musiciansData?.results.forEach((m) => ids.add(m.user_id))
    return ids
  }, [musiciansData])

  const visualArtists = useMemo(
    () => artists.filter((a) => !musicianUserIds.has(a.user_id)),
    [artists, musicianUserIds],
  )

  return (
    <div className="min-h-screen bg-bg pt-16">
      <PageShell
        title="Artistas de Nariño"
        subtitle="Descubre los creadores visuales del departamento"
      />

      <main className="mx-auto max-w-6xl px-6 py-8">
        {/* Buscador */}
        <div className="relative mb-8 max-w-md">
          <Search
            size={16}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted pointer-events-none"
          />
          <input
            type="search"
            placeholder="Buscar por nombre artístico o disciplina…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full rounded-input border border-border bg-surface pl-9 pr-4 py-2.5 font-body text-sm text-text-primary placeholder:text-text-muted focus:outline-none focus:ring-2 focus:ring-oro/50"
          />
        </div>

        {/* Grid */}
        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="rounded-card border border-border bg-surface animate-pulse">
                <div className="h-40 bg-muted rounded-t-card" />
                <div className="p-5 space-y-2">
                  <div className="h-4 bg-muted rounded w-3/4" />
                  <div className="h-3 bg-muted rounded w-1/2" />
                </div>
              </div>
            ))}
          </div>
        ) : visualArtists.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <Users size={40} className="opacity-30" />
            <p className="font-body text-sm">
              {search ? 'Sin resultados para tu búsqueda.' : 'No hay artistas disponibles.'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 items-stretch">
            {visualArtists.map((artist) => (
              <Link
                key={artist.id}
                to={ROUTES.ARTIST_DETAIL(artist.slug)}
                className="no-underline h-full"
              >
                <Card className="p-0 overflow-hidden group cursor-pointer hover:shadow-card transition-shadow h-full flex flex-col">
                  {/* Avatar */}
                  <div
                    className="h-44 flex-none flex items-center justify-center"
                    style={{ background: '#2D1B00' }}
                  >
                    <span className="font-display text-oro font-bold text-5xl">
                      {artist.artistic_name.charAt(0)}
                    </span>
                  </div>

                  {/* Contenido — flex-1 para que todas las cards estiren igual */}
                  <div className="flex flex-1 flex-col justify-between p-5">
                    <div className="space-y-1.5">
                      <h2 className="font-display font-bold text-text-primary text-[17px] group-hover:text-oro transition-colors line-clamp-1">
                        {artist.artistic_name}
                      </h2>
                      {/* Disciplina — siempre ocupa la misma línea */}
                      <p className="font-body text-text-muted text-[13px] line-clamp-1 min-h-[18px]">
                        {artist.discipline || ''}
                      </p>
                      {/* Ciudad — siempre ocupa la misma línea */}
                      <p className="font-body text-text-muted text-[12px] min-h-[18px]">
                        {artist.city ? `📍 ${artist.city}` : ''}
                      </p>
                    </div>

                    <div className="flex items-center justify-between pt-3 mt-2 border-t border-border">
                      <span className="font-body text-[12px] text-text-muted">
                        {artist.followers_count}{' '}
                        {artist.followers_count === 1 ? 'seguidor' : 'seguidores'}
                      </span>
                      {artist.is_public && (
                        <Badge variant="selva" className="text-[10px]">Público</Badge>
                      )}
                    </div>
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
