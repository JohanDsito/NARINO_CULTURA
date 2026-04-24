import { useEffect, type ReactNode } from 'react'
import { useLocation, Navigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'

import { me } from '@/api/auth.api'
import type { Role } from '@/types/auth'
import { useAuthStore } from '@/store/authStore'
import { PageLoader } from '@/components/layout/page-loader'

export function ProtectedRoute({
  allowedRoles,
  children,
}: {
  allowedRoles?: readonly Role[]
  children: ReactNode
}) {
  const location = useLocation()
  const accessToken = useAuthStore((s) => s.accessToken)
  const user = useAuthStore((s) => s.user)
  const setUser = useAuthStore((s) => s.setUser)
  const logout = useAuthStore((s) => s.logout)

  const meQuery = useQuery({
    queryKey: ['auth', 'me'],
    queryFn: me,
    enabled: !!accessToken && !user,
    retry: false,
  })

  if (!accessToken) {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  if (!user && meQuery.isLoading) {
    return <PageLoader label="Verificando sesión…" />
  }

  if (!user && meQuery.isError) {
    logout()
    return <Navigate to="/login" replace state={{ from: location.pathname }} />
  }

  useEffect(() => {
    if (meQuery.data) setUser(meQuery.data)
  }, [meQuery.data, setUser])

  const resolvedUser = user ?? meQuery.data ?? null
  if (!resolvedUser) {
    return <PageLoader label="Cargando perfil…" />
  }

  if (allowedRoles && !allowedRoles.includes(resolvedUser.role)) {
    return <Navigate to="/" replace />
  }

  return <>{children}</>
}
