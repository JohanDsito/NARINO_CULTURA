import { useQuery } from '@tanstack/react-query'

import { getUnreadNotificationsCount } from '@/api/notifications.api'
import { useAuthStore } from '@/store/authStore'

export const UNREAD_NOTIFICATIONS_KEY = ['notifications', 'unread-count'] as const

/** Notificaciones sin leer del usuario; se refresca cada minuto mientras la página está abierta. */
export function useUnreadNotifications(): number {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated)

  const { data } = useQuery({
    queryKey: UNREAD_NOTIFICATIONS_KEY,
    queryFn: () => getUnreadNotificationsCount(),
    enabled: isAuthenticated,
    staleTime: 30 * 1000,
    refetchInterval: 60 * 1000,
  })

  return isAuthenticated ? (data ?? 0) : 0
}
