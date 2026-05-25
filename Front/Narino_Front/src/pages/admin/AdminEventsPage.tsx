import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { format } from 'date-fns'
import { es } from 'date-fns/locale'
import { CalendarClock, CheckCircle, XCircle, MapPin, Ticket, Trash2 } from 'lucide-react'
import { toast } from 'sonner'

import { approveEvent, getApprovedEvents, getPendingEvents, rejectEvent } from '@/api/admin.api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import { PageShell } from '@/components/layout/page-shell'
import { useAuthStore } from '@/store/authStore'
import { EventCalendar } from '@/components/events'
import { EVENT_TYPES } from '@/constants/routes'

const EVENT_TYPE_LABEL: Record<string, string> = Object.fromEntries(
  EVENT_TYPES.map((t) => [t.value, t.label]),
)

export default function AdminEventsPage() {
  const user = useAuthStore((s) => s.user)
  const isAdmin = user?.role === 'admin'
  const queryClient = useQueryClient()

  const { data: pendingEvents = [], isLoading } = useQuery({
    queryKey: ['admin-pending-events'],
    queryFn: getPendingEvents,
    staleTime: 0,
    refetchInterval: 30_000,
  })

  const { data: approvedEvents = [], isLoading: isLoadingApproved } = useQuery({
    queryKey: ['admin-approved-events'],
    queryFn: getApprovedEvents,
    staleTime: 0,
    refetchInterval: 30_000,
  })

  const approveMutation = useMutation({
    mutationFn: approveEvent,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['admin-pending-events'] })
      await queryClient.invalidateQueries({ queryKey: ['admin-metrics'] })
      toast.success('Evento aprobado y publicado en el calendario.')
    },
    onError: () => toast.error('No se pudo aprobar el evento.'),
  })

  const rejectMutation = useMutation({
    mutationFn: rejectEvent,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['admin-pending-events'] })
      toast.success('Evento rechazado y eliminado.')
    },
    onError: () => toast.error('No se pudo rechazar el evento.'),
  })

  const deleteApprovedMutation = useMutation({
    mutationFn: rejectEvent,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ['admin-approved-events'] })
      await queryClient.invalidateQueries({ queryKey: ['admin-metrics'] })
      toast.success('Evento eliminado.')
    },
    onError: () => toast.error('No se pudo eliminar el evento.'),
  })

  const handleReject = (id: string, title: string) => {
    if (!window.confirm(`¿Rechazar y eliminar el evento "${title}"? Esta acción no se puede deshacer.`))
      return
    rejectMutation.mutate(id)
  }

  const handleDeleteApproved = (id: string, title: string) => {
    if (!window.confirm(`¿Eliminar el evento publicado "${title}"? Esta acción no se puede deshacer.`))
      return
    deleteApprovedMutation.mutate(id)
  }

  const isPending = approveMutation.isPending || rejectMutation.isPending

  return (
    <div className="min-h-screen bg-background pt-16">
      <PageShell
        title="Gestión de Eventos"
        subtitle="Aprueba, rechaza y supervisa todos los eventos de la plataforma"
      />

      <main className="mx-auto max-w-6xl space-y-10 px-6 py-8">

        {/* Pending queue */}
        <section>
          <div className="mb-4 flex items-center gap-2">
            <CalendarClock size={18} className="text-amber-500" />
            <h2 className="text-lg font-semibold text-foreground">
              Eventos pendientes de aprobación
            </h2>
            {pendingEvents.length > 0 && (
              <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-amber-500 px-1.5 text-[10px] font-bold text-white">
                {pendingEvents.length}
              </span>
            )}
          </div>

          {isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-24 animate-pulse rounded-xl border border-border bg-muted" />
              ))}
            </div>
          ) : pendingEvents.length === 0 ? (
            <Card>
              <CardContent className="flex flex-col items-center gap-3 py-12 text-center">
                <CheckCircle size={36} className="text-emerald-500 opacity-60" />
                <p className="font-medium text-foreground">Todo al día</p>
                <p className="text-sm text-muted-foreground">
                  No hay eventos pendientes de aprobación.
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-3">
              {pendingEvents.map((ev) => (
                <Card key={ev.id}>
                  <CardContent className="flex flex-col gap-4 p-4 sm:flex-row sm:items-center">
                    {/* Flyer */}
                    {ev.image_url && (
                      <img
                        src={ev.image_url}
                        alt={ev.title}
                        className="h-20 w-20 flex-none rounded-lg object-cover sm:h-16 sm:w-16"
                      />
                    )}

                    {/* Info */}
                    <div className="min-w-0 flex-1 space-y-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <p className="font-semibold text-foreground">{ev.title}</p>
                        <Badge variant="secondary" className="text-[10px]">
                          {EVENT_TYPE_LABEL[ev.event_type] ?? ev.event_type}
                        </Badge>
                      </div>
                      <div className="flex flex-wrap gap-3 text-xs text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <MapPin size={11} />
                          {ev.location}
                        </span>
                        <span>
                          {ev.start_date
                            ? format(new Date(ev.start_date), 'd MMM yyyy, HH:mm', { locale: es })
                            : '—'}
                        </span>
                        <span className="text-muted-foreground/70">
                          Por: {ev.organizer.first_name} {ev.organizer.last_name}
                        </span>
                      </div>
                      {ev.description && (
                        <p className="line-clamp-1 text-xs text-muted-foreground">{ev.description}</p>
                      )}
                    </div>

                    {/* Actions */}
                    <div className="flex flex-none items-center gap-2">
                      <Button
                        size="sm"
                        className="gap-1.5 bg-emerald-600 text-white hover:bg-emerald-700"
                        disabled={isPending}
                        onClick={() => approveMutation.mutate(ev.id)}
                      >
                        <CheckCircle size={13} />
                        Aprobar
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="gap-1.5 border-destructive/40 text-destructive hover:bg-destructive/10"
                        disabled={isPending}
                        onClick={() => handleReject(ev.id, ev.title)}
                      >
                        <XCircle size={13} />
                        Rechazar
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </section>

        {/* Approved events management */}
        <section>
          <div className="mb-4 flex items-center gap-2">
            <Ticket size={18} className="text-primary" />
            <h2 className="text-lg font-semibold text-foreground">
              Eventos publicados
            </h2>
            {approvedEvents.length > 0 && (
              <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-primary/20 px-1.5 text-[10px] font-bold text-primary">
                {approvedEvents.length}
              </span>
            )}
          </div>

          {isLoadingApproved ? (
            <div className="space-y-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-16 animate-pulse rounded-xl border border-border bg-muted" />
              ))}
            </div>
          ) : approvedEvents.length === 0 ? (
            <Card>
              <CardContent className="flex flex-col items-center gap-3 py-12 text-center">
                <Ticket size={36} className="text-primary opacity-30" />
                <p className="text-sm text-muted-foreground">No hay eventos publicados.</p>
              </CardContent>
            </Card>
          ) : (
            <div className="overflow-x-auto rounded-xl border border-border">
              <table className="w-full text-left">
                <thead className="border-b border-border bg-muted/40">
                  <tr>
                    {['Evento', 'Tipo', 'Lugar', 'Fecha', 'Organizador', 'Acciones'].map((h) => (
                      <th key={h} className="px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                        {h}
                      </th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {approvedEvents.map((ev) => (
                    <tr key={ev.id} className="transition-colors hover:bg-muted/30">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          {ev.image_url && (
                            <img src={ev.image_url} alt={ev.title} className="h-10 w-10 flex-none rounded-md object-cover" />
                          )}
                          <span className="text-sm font-medium text-foreground">{ev.title}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">
                        {EVENT_TYPE_LABEL[ev.event_type] ?? ev.event_type}
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">
                        <span className="flex items-center gap-1"><MapPin size={11} />{ev.location}</span>
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">
                        {ev.start_date
                          ? format(new Date(ev.start_date), 'd MMM yyyy', { locale: es })
                          : '—'}
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-foreground">
                        {ev.organizer.first_name} {ev.organizer.last_name}
                      </td>
                      <td className="px-4 py-3">
                        <Button
                          variant="ghost"
                          size="sm"
                          className="gap-1.5 text-destructive hover:bg-destructive/10 hover:text-destructive"
                          disabled={deleteApprovedMutation.isPending}
                          onClick={() => handleDeleteApproved(ev.id, ev.title)}
                        >
                          <Trash2 size={13} />
                          Eliminar
                        </Button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>

        {/* Calendar */}
        <section>
          <div className="mb-4 flex items-center gap-2">
            <CalendarClock size={18} className="text-primary" />
            <h2 className="text-lg font-semibold text-foreground">Calendario de eventos publicados</h2>
          </div>
          <EventCalendar showCreateButton={isAdmin} />
        </section>

      </main>
    </div>
  )
}
