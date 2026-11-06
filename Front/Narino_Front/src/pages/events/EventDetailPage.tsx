import { useParams, Link } from 'react-router-dom'
import { useQuery, useMutation } from '@tanstack/react-query'
import { Calendar, MapPin, ArrowLeft, UserPlus } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { toast } from 'sonner'
import { eventsApi } from '@/api/events.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { PageLoader } from '@/components/layout/page-loader'
import { useAuthStore } from '@/store/authStore'
import { ROUTES } from '@/constants/routes'

const EVENT_TYPE_LABELS: Record<string, string> = {
  CONCIERTO: 'Concierto',
  EXPOSICION: 'Exposición',
  TALLER: 'Taller',
  FERIA: 'Feria',
  ESPECTACULO: 'Espectáculo',
  OTRO: 'Otro',
}

export default function EventDetailPage() {
  const { id } = useParams<{ id: string }>()
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)

  const { data: event, isLoading, isError } = useQuery({
    queryKey: ['event', id],
    queryFn: async () => {
      const res = await eventsApi.getEventById(id!)
      return res.data
    },
    enabled: Boolean(id),
  })

  const registerMutation = useMutation({
    mutationFn: async () => eventsApi.registerToEvent(id!),
    onSuccess: () => toast.success('Te has registrado en el evento'),
    onError: () => toast.error('No se pudo completar el registro'),
  })

  if (isLoading) return <PageLoader label="Cargando evento…" />

  if (isError || !event) {
    return (
      <div className="min-h-screen bg-bg pt-24 flex flex-col items-center gap-4">
        <p className="text-text-muted font-body">No se encontró este evento.</p>
        <Link to={ROUTES.EVENTS} className="text-oro hover:underline font-body text-sm">
          ← Volver a eventos
        </Link>
      </div>
    )
  }

  const startDate = new Date(event.start_date)
  const endDate = new Date(event.end_date)
  const typeLabel = EVENT_TYPE_LABELS[event.event_type] ?? event.event_type

  return (
    <div className="min-h-screen bg-bg pt-16">
      <div className="mx-auto max-w-4xl px-6 py-8">
        {/* Breadcrumb */}
        <Link
          to={ROUTES.EVENTS}
          className="inline-flex items-center gap-1.5 text-text-muted hover:text-oro font-body text-sm no-underline transition-colors mb-8"
        >
          <ArrowLeft size={14} /> Eventos
        </Link>

        {/* Imagen */}
        {event.image_url && (
          <div className="w-full aspect-[16/7] rounded-card overflow-hidden mb-8">
            <img src={event.image_url} alt={event.title} className="w-full h-full object-cover" />
          </div>
        )}

        {/* Header */}
        <div className="flex flex-wrap items-start gap-3 mb-4">
          <Badge variant="indigo">{typeLabel}</Badge>
          {!event.is_published && <Badge variant="tierra">Borrador</Badge>}
        </div>
        <h1 className="font-display font-bold text-text-primary text-[36px] leading-tight mb-6">
          {event.title}
        </h1>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Descripción */}
          <div className="md:col-span-2 space-y-6">
            {event.description && (
              <p className="font-body text-text-primary leading-relaxed">{event.description}</p>
            )}

            {isAuthenticated && event.is_published && (
              <Button
                variant="primary"
                className="gap-2"
                onClick={() => registerMutation.mutate()}
                disabled={registerMutation.isPending}
              >
                <UserPlus size={16} />
                {registerMutation.isPending ? 'Registrando…' : 'Registrarme en este evento'}
              </Button>
            )}
          </div>

          {/* Detalles */}
          <div className="space-y-4">
            <div className="rounded-card border border-border bg-surface p-5 space-y-4">
              <div className="flex items-start gap-3">
                <Calendar size={18} className="text-oro flex-none mt-0.5" />
                <div>
                  <p className="font-body font-semibold text-text-primary text-sm">
                    {format(startDate, "d 'de' MMMM yyyy", { locale: es })}
                  </p>
                  <p className="font-body text-text-muted text-xs">
                    {format(startDate, 'HH:mm')} – {format(endDate, 'HH:mm')}
                  </p>
                </div>
              </div>

              {event.location && (
                <div className="flex items-start gap-3">
                  <MapPin size={18} className="text-oro flex-none mt-0.5" />
                  <div>
                    <p className="font-body text-text-primary text-sm">{event.location}</p>
                    {event.latitude && event.longitude && (
                      <a
                        href={`https://www.google.com/maps?q=${event.latitude},${event.longitude}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-body text-xs text-oro hover:underline"
                      >
                        Ver en el mapa →
                      </a>
                    )}
                  </div>
                </div>
              )}

              {event.organizer && (
                <div className="border-t border-border pt-4">
                  <p className="font-body text-[11px] uppercase tracking-widest text-text-muted mb-1">
                    Organizador
                  </p>
                  <p className="font-body text-sm text-text-primary">
                    {event.organizer.first_name} {event.organizer.last_name}
                  </p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
