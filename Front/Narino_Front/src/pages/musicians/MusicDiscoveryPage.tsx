import { useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Search, Sparkles } from 'lucide-react'
import { musicDiscovery } from '@/api/musicians.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card } from '@/components/ui/card'
import { ROUTES } from '@/constants/routes'
import { AGGREGATION_TYPE_LABELS } from '@/constants/labels'
import type { MusicDiscoveryResult } from '@/types'

const EXAMPLES = [
  'Banda de rock alternativo en Pasto',
  'DJ para eventos culturales en Nariño',
  'Solista de música andina tradicional',
  'Colectivo de jazz contemporáneo',
]

export default function MusicDiscoveryPage() {
  const [query, setQuery] = useState('')
  const [result, setResult] = useState<MusicDiscoveryResult | null>(null)

  const discoveryMutation = useMutation({
    mutationFn: () => musicDiscovery(query),
    onSuccess: (data) => setResult(data),
  })

  const handleSearch = (q?: string) => {
    const searchQuery = q ?? query
    if (!searchQuery.trim()) return
    if (q) setQuery(q)
    discoveryMutation.mutate()
  }

  const filtersApplied = result?.filters_applied
    ? Object.entries(result.filters_applied).filter(([, v]) => v)
    : []

  return (
    <div className="min-h-screen pt-16">
      {/* Hero */}
      <section className="relative overflow-hidden px-6 py-16 text-center">
        <div className="relative z-10 max-w-2xl mx-auto">
          <div className="flex items-center justify-center gap-2 mb-4">
            <Sparkles size={22} className="text-azul" />
            <Badge variant="azul">Búsqueda con IA</Badge>
          </div>
          <h1 className="font-display font-extrabold text-text-primary text-[36px] md:text-[48px] leading-tight mb-3">
            Music Discovery
          </h1>
          <p className="font-body text-[16px] mb-8 text-text-secondary">
            Describe en lenguaje natural qué tipo de músico buscas.<br />
            Nuestra IA analiza tu búsqueda y encuentra los artistas más relevantes.
          </p>

          {/* Buscador */}
          <div className="flex gap-2 max-w-lg mx-auto">
            <div className="relative flex-1">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted pointer-events-none" />
              <input
                type="text"
                placeholder="Ej: Banda de cumbia experimental en Pasto…"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                className="w-full rounded-input border border-border-strong bg-bg-card pl-9 pr-4 py-3 font-body text-[15px] text-text-primary placeholder:text-text-muted focus:outline-none focus:border-azul focus:ring-2 focus:ring-azul/25"
              />
            </div>
            <Button
              variant="primary"
              onClick={() => handleSearch()}
              disabled={discoveryMutation.isPending || !query.trim()}
              className="gap-2 flex-none"
            >
              <Sparkles size={16} />
              {discoveryMutation.isPending ? 'Buscando…' : 'Buscar'}
            </Button>
          </div>

          {/* Ejemplos */}
          <div className="flex flex-wrap gap-2 justify-center mt-4">
            {EXAMPLES.map((ex) => (
              <button
                key={ex}
                onClick={() => handleSearch(ex)}
                className="rounded-tag border border-border-strong text-text-secondary hover:text-azul hover:border-azul font-body text-[12px] px-3 py-1 transition-colors"
              >
                {ex}
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* Resultados */}
      <main className="mx-auto max-w-6xl px-6 py-10">
        {discoveryMutation.isPending && (
          <div className="flex items-center justify-center gap-3 py-16 text-text-muted">
            <Sparkles size={20} className="motion-safe:animate-pulse text-azul" />
            <p className="font-body">Analizando tu búsqueda con IA…</p>
          </div>
        )}

        {result && !discoveryMutation.isPending && (
          <>
            {/* Filtros detectados */}
            {filtersApplied.length > 0 && (
              <div className="mb-6 flex flex-wrap items-center gap-2">
                <span className="font-body text-[12px] text-text-muted uppercase tracking-widest">
                  Filtros detectados:
                </span>
                {filtersApplied.map(([key, value]) => (
                  <Badge key={key} variant="azul" className="text-[11px]">
                    {key}: {String(value)}
                  </Badge>
                ))}
              </div>
            )}

            <p className="font-body text-text-muted text-sm mb-6">
              {result.count === 0
                ? 'No se encontraron músicos para esa búsqueda.'
                : `${result.count} músico${result.count === 1 ? '' : 's'} encontrado${result.count === 1 ? '' : 's'} para "${result.query}"`}
            </p>

            {result.results.length > 0 && (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {result.results.map((musician) => (
                  <Link
                    key={musician.id}
                    to={ROUTES.MUSICIAN_DETAIL(musician.slug)}
                    className="no-underline"
                  >
                    <Card className="p-5 hover:shadow-card transition-shadow cursor-pointer group">
                      <div className="w-12 h-12 rounded-full bg-azul-tint flex items-center justify-center mb-3">
                        {musician.profile_image_url ? (
                          <img src={musician.profile_image_url} alt="" className="w-12 h-12 rounded-full object-cover" />
                        ) : (
                          <span className="font-display font-bold text-azul text-xl">
                            {musician.artistic_name.charAt(0)}
                          </span>
                        )}
                      </div>
                      <h3 className="font-display font-bold text-text-primary text-[16px] mb-1 group-hover:text-azul transition-colors">
                        {musician.artistic_name}
                      </h3>
                      <Badge variant="azul" className="text-[10px] mb-2">
                        {AGGREGATION_TYPE_LABELS[musician.aggregation_type] ?? musician.aggregation_type}
                      </Badge>
                      {musician.city && (
                        <p className="font-body text-text-muted text-[12px]">📍 {musician.city}</p>
                      )}
                      {musician.genres.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-2">
                          {musician.genres.slice(0, 3).map((g) => (
                            <span
                              key={g.id}
                              className="rounded-tag bg-bg-card border border-border px-2 py-0.5 font-body text-[10px] text-text-muted"
                            >
                              {g.name}
                            </span>
                          ))}
                        </div>
                      )}
                    </Card>
                  </Link>
                ))}
              </div>
            )}
          </>
        )}

        {!result && !discoveryMutation.isPending && (
          <div className="text-center py-20 text-text-muted">
            <Sparkles size={48} className="mx-auto mb-4 opacity-20" />
            <p className="font-body text-sm">
              Escribe tu búsqueda arriba para descubrir músicos con IA
            </p>
          </div>
        )}
      </main>
    </div>
  )
}
