import { useState } from 'react'
import { useParams, Link, useLocation } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Calendar, MapPin, ArrowLeft, UserPlus, CalendarCheck, UserMinus } from 'lucide-react'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { toast } from 'sonner'
import { eventsApi } from '@/api/events.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { PageLoader } from '@/components/layout/page-loader'
import { useAuthStore } from '@/store/authStore'
import { ROUTES } from '@/constants/routes'
import { getApiErrorMessage } from '@/utils/apiError'

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
  const location = useLocation()
  const queryClient = useQueryClient()
  const [now] = useState(() => Date.now())

  const { data: event, isLoading, isError } = useQuery({
    queryKey: ['event', id],
    queryFn: async () => {
      const res = await eventsApi.getEventById(id!)
      return res.data
    },
    enabled: Boolean(id),
  })

  // Tras inscribirse o cancelar se vuelve a pedir el evento: is_registered lo decide el servidor
  const refreshEvent = () => queryClient.invalidateQueries({ queryKey: ['event', id] })

  const registerMutation = useMutation({
    mutationFn: async () => eventsApi.registerToEvent(id!),
    onSuccess: () => {
      toast.success('¡Listo! Te inscribiste. Te recordaremos el evento un día antes.')
      return refreshEvent()
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  const unregisterMutation = useMutation({
    mutationFn: async () => eventsApi.unregisterFromEvent(id!),
    onSuccess: () => {
      toast.success('Cancelaste tu inscripción')
      return refreshEvent()
    },
    onError: (error) => toast.error(getApiErrorMessage(error)),
  })

  if (isLoading) return <PageLoader label="Cargando evento…" />

  if (isError || !event) {
    return (
      <div className="min-h-screen pt-24 flex flex-col items-center gap-4">
        <p className="text-text-muted font-body">No se encontró este evento.</p>
        <Link to={ROUTES.EVENTS} className="text-tomate hover:underline font-body text-sm">
          ← Volver a eventos
        </Link>
      </div>
    )
  }

  const startDate = new Date(event.start_date)
  const endDate = new Date(event.end_date)
  const typeLabel = EVENT_TYPE_LABELS[event.event_type] ?? event.event_type
  const hasEnded = endDate.getTime() < now
  const busy = registerMutation.isPending || unregisterMutation.isPending

  return (
    <div className="min-h-screen pt-16">
      <div className="mx-auto max-w-4xl px-6 py-8">
        {/* Breadcrumb */}
        <Link
          to={ROUTES.EVENTS}
          className="inline-flex items-center gap-1.5 text-text-muted hover:text-tomate font-body text-sm no-underline transition-colors mb-8"
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
          <Badge variant="tomate">{typeLabel}</Badge>
          {!event.is_published && <Badge variant="secondary">Borrador</Badge>}
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

            {event.is_published &&
              (hasEnded ? (
                <p className="font-body text-sm text-text-muted">Este evento ya terminó.</p>
              ) : !isAuthenticated ? (
                <Button asChild variant="primary" className="gap-2">
                  <Link to={ROUTES.LOGIN} state={{ from: location.pathname }} className="no-underline">
                    <UserPlus size={16} />
                    Inicia sesión para inscribirte
                  </Link>
                </Button>
              ) : event.is_registered ? (
                <div className="flex flex-wrap items-center gap-3">
                  <p className="inline-flex items-center gap-2 rounded-tag bg-selva-pale px-3 py-1.5 font-body text-sm font-semibold text-selva">
                    <CalendarCheck size={16} />
                    Ya estás inscrito
                  </p>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="gap-1.5"
                    onClick={() => unregisterMutation.mutate()}
                    disabled={busy}
                  >
                    <UserMinus size={14} />
                    {unregisterMutation.isPending ? 'Cancelando…' : 'Cancelar inscripción'}
                  </Button>
                </div>
              ) : (
                <Button
                  variant="primary"
                  className="gap-2"
                  onClick={() => registerMutation.mutate()}
                  disabled={busy}
                >
                  <UserPlus size={16} />
                  {registerMutation.isPending ? 'Inscribiendo…' : 'Inscribirme en este evento'}
                </Button>
              ))}
          </div>

          {/* Detalles */}
          <div className="space-y-4">
            <div className="rounded-card border border-border bg-bg-card p-5 space-y-4">
              <div className="flex items-start gap-3">
                <Calendar size={18} className="text-tomate flex-none mt-0.5" />
                <div>
                  <p className="font-body font-semibold text-text-primary text-sm">
                    {format(startDate, "d 'de' MMMM yyyy", { locale: es })}
                  </p>
                  <p className="font-body text-naranja font-semibold text-xs">
                    {format(startDate, 'HH:mm')} – {format(endDate, 'HH:mm')}
                  </p>
                </div>
              </div>

              {event.location && (
                <div className="flex items-start gap-3">
                  <MapPin size={18} className="text-tomate flex-none mt-0.5" />
                  <div>
                    <p className="font-body text-text-primary text-sm">{event.location}</p>
                    {event.latitude && event.longitude && (
                      <a
                        href={`https://www.google.com/maps?q=${event.latitude},${event.longitude}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-body text-xs font-semibold text-tomate hover:underline"
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
