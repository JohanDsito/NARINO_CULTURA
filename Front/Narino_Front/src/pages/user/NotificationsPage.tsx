import { useState } from 'react'
import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { Bell, CheckCheck } from 'lucide-react'

import {
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
} from '@/api/notifications.api'
import { PageShell } from '@/components/layout/page-shell'
import { Button } from '@/components/ui/button'
import { UNREAD_NOTIFICATIONS_KEY, useUnreadNotifications } from '@/hooks/useUnreadNotifications'
import type { AppNotification } from '@/types'
import { cn, formatRelativeTime } from '@/utils'

type Filter = 'all' | 'unread'

const FILTERS: { value: Filter; label: string }[] = [
  { value: 'all', label: 'Todas' },
  { value: 'unread', label: 'No leídas' },
]

/** Solo se navega a rutas internas de la web (el backend manda p. ej. "/orders" o "/events/<id>"). */
function internalUrl(notification: AppNotification): string | null {
  const url = notification.data?.url
  return typeof url === 'string' && url.startsWith('/') && !url.startsWith('//') ? url : null
}

export default function NotificationsPage() {
  const [filter, setFilter] = useState<Filter>('all')
  const queryClient = useQueryClient()
  const navigate = useNavigate()
  const unread = useUnreadNotifications()

  const query = useInfiniteQuery({
    queryKey: ['notifications', filter],
    queryFn: ({ pageParam }) => listNotifications({ unread: filter === 'unread', page: pageParam }),
    initialPageParam: 1,
    getNextPageParam: (lastPage, pages) => (lastPage.next ? pages.length + 1 : undefined),
  })
  const notifications = query.data?.pages.flatMap((page) => page.results) ?? []

  const refresh = () => queryClient.invalidateQueries({ queryKey: ['notifications'] })

  const markRead = useMutation({
    mutationFn: (id: string) => markNotificationRead(id),
    onSuccess: refresh,
  })

  const markAll = useMutation({
    mutationFn: () => markAllNotificationsRead(),
    onSuccess: () => {
      queryClient.setQueryData(UNREAD_NOTIFICATIONS_KEY, 0)
      return refresh()
    },
  })

  const open = (notification: AppNotification) => {
    if (!notification.read) markRead.mutate(notification.id)
    const url = internalUrl(notification)
    if (url) navigate(url)
  }

  return (
    <div className="min-h-screen pt-16">
      <PageShell title="Notificaciones" subtitle="Pujas, ventas, pagos y eventos de tu cuenta" />

      <main className="mx-auto max-w-2xl px-6 py-8">
        <div className="mb-6 flex flex-wrap items-center justify-between gap-3">
          <div role="tablist" aria-label="Filtrar notificaciones" className="flex gap-2">
            {FILTERS.map(({ value, label }) => (
              <button
                key={value}
                type="button"
                role="tab"
                aria-selected={filter === value}
                onClick={() => setFilter(value)}
                className={cn(
                  'rounded-tag px-4 py-1.5 font-body text-[13px] font-semibold transition-colors',
                  filter === value
                    ? 'bg-tierra text-on-tierra'
                    : 'bg-bg-card text-text-muted hover:bg-bg-subtle',
                )}
              >
                {label}
                {value === 'unread' && unread > 0 && ` (${unread})`}
              </button>
            ))}
          </div>

          <Button
            variant="ghost"
            size="sm"
            onClick={() => markAll.mutate()}
            disabled={unread === 0 || markAll.isPending}
          >
            <CheckCheck size={16} />
            Marcar todas como leídas
          </Button>
        </div>

        {query.isLoading ? (
          <ul className="space-y-3" aria-hidden>
            {Array.from({ length: 4 }).map((_, i) => (
              <li key={i} className="h-20 animate-pulse rounded-card border border-border bg-bg-card" />
            ))}
          </ul>
        ) : query.isError ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <p className="font-body text-sm">No pudimos cargar tus notificaciones.</p>
            <Button variant="secondary" size="sm" onClick={() => query.refetch()}>
              Reintentar
            </Button>
          </div>
        ) : notifications.length === 0 ? (
          <div className="flex flex-col items-center gap-3 py-24 text-text-muted">
            <Bell size={48} className="opacity-30" />
            <p className="font-body text-center text-sm">
              {filter === 'unread'
                ? 'No tienes notificaciones sin leer.'
                : 'Todavía no tienes notificaciones. Aquí verás tus pujas, ventas, pagos y eventos.'}
            </p>
          </div>
        ) : (
          <>
            <ul className="space-y-3">
              {notifications.map((notification) => (
                <li key={notification.id}>
                  <button
                    type="button"
                    onClick={() => open(notification)}
                    className={cn(
                      'flex w-full items-start gap-3 rounded-card border p-4 text-left transition-colors hover:bg-bg-subtle',
                      notification.read ? 'border-border bg-bg-card' : 'border-tierra/40 bg-tierra-pale',
                    )}
                  >
                    <span
                      aria-hidden
                      className={cn(
                        'mt-1.5 h-2 w-2 flex-none rounded-full',
                        notification.read ? 'bg-transparent' : 'bg-tierra',
                      )}
                    />
                    <span className="min-w-0 flex-1">
                      <span className="flex items-baseline justify-between gap-3">
                        <span className="font-body text-sm font-semibold text-text-primary">
                          {notification.title}
                          {!notification.read && <span className="sr-only"> (sin leer)</span>}
                        </span>
                        <time
                          dateTime={notification.created_at}
                          className="flex-none font-body text-[12px] text-text-muted"
                        >
                          {formatRelativeTime(notification.created_at)}
                        </time>
                      </span>
                      <span className="mt-1 block font-body text-[13px] text-text-muted">
                        {notification.body}
                      </span>
                    </span>
                  </button>
                </li>
              ))}
            </ul>

            {query.hasNextPage && (
              <div className="mt-6 flex justify-center">
                <Button
                  variant="secondary"
                  size="sm"
                  onClick={() => query.fetchNextPage()}
                  disabled={query.isFetchingNextPage}
                >
                  {query.isFetchingNextPage ? 'Cargando…' : 'Cargar más'}
                </Button>
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
