import { useMemo } from 'react'

import { useAuthStore } from '@/store/authStore'

export function useAuth() {
  const status = useAuthStore((s) => s.status)
  const accessToken = useAuthStore((s) => s.accessToken)
  const refreshToken = useAuthStore((s) => s.refreshToken)
  const user = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)

  return useMemo(
    () => ({
      status,
      isAuthenticated: status === 'authenticated' && !!accessToken,
      accessToken,
      refreshToken,
      user,
      logout,
    }),
    [accessToken, refreshToken, status, user, logout],
  )
}

