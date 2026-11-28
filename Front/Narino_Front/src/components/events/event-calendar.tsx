import { Suspense, lazy, useMemo, useState } from 'react'
import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { format, startOfMonth, endOfMonth } from 'date-fns'
import { es } from 'date-fns/locale'
import { Calendar } from '@/components/ui/calendar'
import { PageLoader } from '@/components/layout/page-loader'
import {
  eventsApi,
  normalizeEventsResponse,
  type Event,
} from '@/api/events.api'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { useAuthStore } from '@/store/authStore'

// El formulario (react-hook-form + zod) solo lo usa el administrador: no se descarga en la portada de los demás
const EventFormModal = lazy(() =>
  import('./event-form-modal').then((m) => ({ default: m.EventFormModal })),
)

interface EventCalendarProps {
  showCreateButton?: boolean
}

const eventTypeStyles: Record<Event['event_type'], string> = {
  CONCIERTO: 'bg-azul-tint text-azul',
  EXPOSICION: 'bg-magenta-tint text-magenta',
  TALLER: 'bg-verde-tint text-verde',
  FERIA: 'bg-naranja-tint text-naranja',
  ESPECTACULO: 'bg-tomate-tint text-tomate',
  OTRO: 'bg-bg-subtle text-text-secondary',
}

const eventTypeLabels: Record<Event['event_type'], string> = {
  CONCIERTO: 'Concierto',
  EXPOSICION: 'Exposición',
  TALLER: 'Taller',
  FERIA: 'Feria',
  ESPECTACULO: 'Espectáculo',
  OTRO: 'Otro',
}

const fallbackEventTypeStyle = 'bg-bg-subtle text-text-secondary'

export function EventCalendar({ showCreateButton = false }: EventCalendarProps) {
  const [selectedDate, setSelectedDate] = useState<Date>(new Date())
  const [visibleMonth, setVisibleMonth] = useState<Date>(new Date())
  const [showEventForm, setShowEventForm] = useState(false)
  const { user } = useAuthStore()
  const isAdmin = user?.role === 'admin' || user?.role === 'cultural_manager'

  const monthStart = format(startOfMonth(visibleMonth), 'yyyy-MM-dd')
  const monthEnd = format(endOfMonth(visibleMonth), 'yyyy-MM-dd')

  const {
    data: events = [],
    isFetching,
    isLoading,
    isError,
    refetch,
  } = useQuery({
    queryKey: ['events', monthStart, monthEnd],
    queryFn: () =>
      eventsApi
        .getEventsByDateRange(monthStart, monthEnd)
        .then((res) => normalizeEventsResponse(res.data)),
    placeholderData: keepPreviousData,
    staleTime: 5 * 60 * 1000,
  })

  const selectedDateStr = format(selectedDate, 'yyyy-MM-dd')
  const selectedDayEvents = useMemo(
    () =>
      events
        .filter(
          (event) =>
            format(new Date(event.start_date), 'yyyy-MM-dd') === selectedDateStr
        )
        .sort(
          (a, b) =>
            new Date(a.start_date).getTime() - new Date(b.start_date).getTime()
        ),
    [events, selectedDateStr]
  )

  if (isLoading && events.length === 0) {
    return <PageLoader label="Cargando eventos..." />
  }

  const handleSelectDate = (date: Date) => {
    setSelectedDate(date)
    setVisibleMonth(date)
  }

  const handleMonthChange = (date: Date) => {
    setVisibleMonth(date)
    setSelectedDate(date)
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="nc-eyebrow text-tomate">Eventos</p>
          <h2 className="text-2xl font-extrabold text-text-primary">Agenda Cultural</h2>
        </div>
        {isAdmin && showCreateButton && (
          <Button onClick={() => setShowEventForm(true)}>
            + Agregar evento
          </Button>
        )}
      </div>

      {isAdmin && showCreateButton && showEventForm && (
        <Suspense fallback={null}>
          <EventFormModal
            open={showEventForm}
            onOpenChange={setShowEventForm}
            onSuccess={() => {
              setShowEventForm(false)
              refetch()
            }}
          />
        </Suspense>
      )}

      {isError && (
        <Card className="border-error/40">
          <CardContent className="pt-6">
            <p className="text-center text-sm text-error">
              No se pudieron cargar los eventos. Intenta de nuevo más tarde.
            </p>
          </CardContent>
        </Card>
      )}

      <div className="grid gap-6 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <Calendar
            events={events}
            currentMonth={visibleMonth}
            isLoading={isFetching}
            selectedDate={selectedDate}
            onMonthChange={handleMonthChange}
            onSelectDate={handleSelectDate}
          />
        </div>

        <div className="space-y-4">
          <div>
            <h3 className="text-lg font-semibold mb-4">
              Eventos: {format(selectedDate, 'd \'de\' MMMM', { locale: es })}
            </h3>

            {selectedDayEvents.length === 0 ? (
              <Card>
                <CardContent className="pt-6">
                  <p className="text-center text-text-secondary">
                    No hay eventos para este día
                  </p>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-3">
                {selectedDayEvents.map((event) => {
                  const eventTypeLabel =
                    eventTypeLabels[event.event_type] ?? 'Otro'
                  const eventTypeStyle =
                    eventTypeStyles[event.event_type] ?? fallbackEventTypeStyle

                  return (
                    <Card
                      key={event.id}
                      className="overflow-hidden transition-shadow hover:shadow-md"
                    >
                      {event.image_url && (
                        <div className="aspect-[16/9] w-full overflow-hidden">
                          <img
                            src={event.image_url}
                            alt={event.title}
                            className="h-full w-full object-cover"
                          />
                        </div>
                      )}

                      <CardHeader className="pb-3">
                        <div className="flex items-start justify-between gap-2">
                          <CardTitle className="text-base line-clamp-2">
                            {event.title}
                          </CardTitle>
                          <Badge
                            className={`flex-shrink-0 ${eventTypeStyle}`}
                          >
                            {eventTypeLabel}
                          </Badge>
                        </div>
                      </CardHeader>

                      <CardContent className="space-y-3">
                        {event.description && (
                          <p className="text-sm text-text-secondary line-clamp-2">
                            {event.description}
                          </p>
                        )}

                        {event.location && (
                          <div className="text-sm">
                            <p className="font-medium">Ubicación:</p>
                            <p className="text-text-secondary">
                              {event.location}
                            </p>
                          </div>
                        )}

                        <div className="text-sm">
                          <p className="font-medium">Horario:</p>
                          <p className="text-text-secondary">
                            {format(new Date(event.start_date), 'HH:mm')} -{' '}
                            {format(new Date(event.end_date), 'HH:mm')}
                          </p>
                        </div>

                        {event.organizer && (
                          <div className="text-sm border-t pt-3">
                            <p className="font-medium">Organizador:</p>
                            <p className="text-text-secondary">
                              {event.organizer.first_name}{' '}
                              {event.organizer.last_name}
                            </p>
                          </div>
                        )}
                      </CardContent>
                    </Card>
                  )
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
