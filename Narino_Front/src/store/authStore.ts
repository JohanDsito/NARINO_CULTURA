import { create } from 'zustand'
import { persist } from 'zustand/middleware'

import type { AuthUser } from '@/types/auth'

type AuthStatus = 'anonymous' | 'authenticated'

interface AuthState {
  status: AuthStatus
  accessToken: string | null
  refreshToken: string | null
  user: AuthUser | null
  setTokens: (tokens: { access: string; refresh: string }) => void
  setAccessToken: (access: string) => void
  setUser: (user: AuthUser | null) => void
  logout: () => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      status: 'anonymous',
      accessToken: null,
      refreshToken: null,
      user: null,
      setTokens: (tokens) =>
        set(() => ({
          status: 'authenticated',
          accessToken: tokens.access,
          refreshToken: tokens.refresh,
        })),
      setAccessToken: (access) => set(() => ({ accessToken: access })),
      setUser: (user) => set(() => ({ user })),
      logout: () =>
        set(() => ({
          status: 'anonymous',
          accessToken: null,
          refreshToken: null,
          user: null,
        })),
    }),
    {
      name: 'narino_cultura_auth',
      version: 1,
      partialize: (state) => ({
        status: state.status,
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        user: state.user,
      }),
    },
  ),
)

