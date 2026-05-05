import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { normalizeUser, normalizeUserRole, type User as AuthUser, type UserRole } from '@/types/auth'

export type { UserRole }
export type User = AuthUser

interface AuthState {
  user: User | null
  accessToken: string | null
  refreshToken: string | null
  isAuthenticated: boolean
  setAuth: (user: User, access: string, refresh: string) => void
  logout: () => void
  updateUser: (data: Partial<User>) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,

      setAuth: (user, access, refresh) => {
        localStorage.setItem('access_token', access)
        localStorage.setItem('refresh_token', refresh)
        set({ user: normalizeUser(user), accessToken: access, refreshToken: refresh, isAuthenticated: true })
      },

      logout: () => {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        set({ user: null, accessToken: null, refreshToken: null, isAuthenticated: false })
      },

      updateUser: (data) =>
        set((state) => ({
          user: state.user ? normalizeUser({ ...state.user, ...data }) : null,
        })),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user ? normalizeUser(state.user) : null,
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        isAuthenticated: state.isAuthenticated,
      }),
      merge: (persisted, current) => {
        const state = persisted as Partial<AuthState>
        const accessToken = state.accessToken ?? localStorage.getItem('access_token')
        const refreshToken = state.refreshToken ?? localStorage.getItem('refresh_token')
        return {
          ...current,
          ...state,
          user: state.user ? { ...state.user, role: normalizeUserRole(state.user.role) } : null,
          accessToken,
          refreshToken,
          isAuthenticated: Boolean(accessToken),
        }
      },
    }
  )
)
