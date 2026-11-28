import type { ReactNode } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { act, renderHook, waitFor } from '@testing-library/react'
import { AxiosError, type AxiosResponse } from 'axios'

import { addFavorite, getFavorites } from '@/api/marketplace.api'
import { useFavorites } from '@/hooks/useFavorites'
import { useAuthStore } from '@/store/authStore'
import { useThemeStore } from '@/store/themeStore'
import type { User } from '@/types'
import { getApiErrorMessage } from '@/utils/apiError'
import { clearArtistDiscipline, getArtistDiscipline, setArtistDiscipline } from '@/utils/artistDiscipline'
import { formatCurrency } from '@/utils'

vi.mock('@/api/marketplace.api', () => ({ getFavorites: vi.fn(), addFavorite: vi.fn(), removeFavorite: vi.fn() }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const USER = { id: 'u1', email: 'a@b.c', first_name: 'Ana', last_name: 'Paz', role: 'ARTISTA' } as unknown as User

describe('authStore: actualizar usuario y rehidratar', () => {
  beforeEach(() => {
    localStorage.clear()
    useAuthStore.setState({ user: null, accessToken: null, refreshToken: null, isAuthenticated: false })
  })

  it('updateUser sin sesión crea el usuario solo si llegan todos los datos mínimos', () => {
    useAuthStore.getState().updateUser({ id: 'u1', email: 'a@b.c' })
    expect(useAuthStore.getState().user).toBeNull()
    useAuthStore.getState().updateUser(USER)
    expect(useAuthStore.getState().user?.role).toBe('artist')
  })

  it('updateUser con sesión mezcla los datos y normaliza el rol', () => {
    useAuthStore.getState().setAuth(USER, 'a', 'r')
    useAuthStore.getState().updateUser({ first_name: 'Anita', role: 'COMPRADOR' as never })
    expect(useAuthStore.getState().user).toMatchObject({ first_name: 'Anita', role: 'buyer' })
  })

  it('al rehidratar sin tokens guardados los toma de localStorage y marca la sesión', async () => {
    localStorage.setItem('access_token', 'tok-a')
    localStorage.setItem('refresh_token', 'tok-r')
    localStorage.setItem('auth-storage', JSON.stringify({ state: { user: null }, version: 0 }))
    await useAuthStore.persist.rehydrate()
    expect(useAuthStore.getState()).toMatchObject({ accessToken: 'tok-a', refreshToken: 'tok-r', isAuthenticated: true, user: null })
  })

  it('al rehidratar con usuario viejo usa "avatar" como avatar_url y normaliza el rol; con avatar_url lo respeta', async () => {
    localStorage.setItem(
      'auth-storage',
      JSON.stringify({ state: { user: { id: 'u', role: 'ADMINISTRADOR', avatar: 'https://img.test/viejo.jpg' }, accessToken: 'x', refreshToken: 'y' }, version: 0 }),
    )
    await useAuthStore.persist.rehydrate()
    expect(useAuthStore.getState().user).toMatchObject({ role: 'admin', avatar_url: 'https://img.test/viejo.jpg' })

    localStorage.setItem(
      'auth-storage',
      JSON.stringify({ state: { user: { id: 'u', role: 'buyer', avatar_url: 'https://img.test/nuevo.jpg', avatar: 'viejo' }, accessToken: 'x', refreshToken: 'y' }, version: 0 }),
    )
    await useAuthStore.persist.rehydrate()
    expect(useAuthStore.getState().user?.avatar_url).toBe('https://img.test/nuevo.jpg')
  })

  it('al rehidratar sin nada guardado ni tokens queda sin sesión', async () => {
    localStorage.setItem('auth-storage', JSON.stringify({ state: {}, version: 0 }))
    await useAuthStore.persist.rehydrate()
    expect(useAuthStore.getState()).toMatchObject({ user: null, isAuthenticated: false })
  })
})

describe('themeStore: rehidratación con error', () => {
  afterEach(() => {
    localStorage.removeItem('nc-theme-store')
    document.documentElement.classList.remove('dark')
  })

  it('si lo guardado está dañado vuelve al tema del sistema', async () => {
    document.documentElement.classList.add('dark')
    localStorage.setItem('nc-theme-store', '{dañado')
    await useThemeStore.persist.rehydrate()
    expect(document.documentElement).not.toHaveClass('dark')
  })
})

describe('utilidades', () => {
  it('getApiErrorMessage cubre cuerpos de error raros', () => {
    const axiosError = (data: unknown) =>
      new AxiosError('x', 'ERR', undefined, undefined, { status: 400, data } as AxiosResponse)
    expect(getApiErrorMessage(axiosError('texto plano'))).toBe('texto plano')
    expect(getApiErrorMessage(axiosError({ detail: 'detalle' }))).toBe('detalle')
    expect(getApiErrorMessage(axiosError({ campo: 'primero' }))).toBe('primero')
    expect(getApiErrorMessage(axiosError({ campo: ['de lista', 'otro'] }))).toBe('de lista')
    expect(getApiErrorMessage(axiosError({ campo: [1] }))).toBe('No fue posible completar la solicitud.')
    expect(getApiErrorMessage(axiosError({ campo: 5 }))).toBe('No fue posible completar la solicitud.')
    expect(getApiErrorMessage(axiosError(null))).toBe('No fue posible completar la solicitud.')
    expect(getApiErrorMessage(axiosError(42))).toBe('No fue posible completar la solicitud.')
    expect(getApiErrorMessage(new Error('plano'))).toBe('plano')
    expect(getApiErrorMessage('cualquier cosa')).toBe('Ocurrió un error inesperado.')
  })

  it('la disciplina de la artista se guarda, se lee y se borra', () => {
    localStorage.clear()
    expect(getArtistDiscipline('u1')).toBeNull()
    setArtistDiscipline('u1', 'pintor')
    expect(getArtistDiscipline('u1')).toBe('pintor')
    clearArtistDiscipline('u1')
    expect(getArtistDiscipline('u1')).toBeNull()
  })

  it('formatCurrency usa el valor de reserva si no es un número', () => {
    expect(formatCurrency('abc')).toBe('—')
    expect(formatCurrency('abc', 'n/d')).toBe('n/d')
    expect(formatCurrency(null)).toBe('—')
    expect(formatCurrency('')).toBe('—')
    expect(formatCurrency(1500)).toMatch(/1\.500/)
  })
})

describe('useFavorites: pendingId mientras se guarda', () => {
  it('indica la obra que se está cambiando y la limpia al terminar', async () => {
    useAuthStore.setState({ isAuthenticated: true })
    vi.mocked(getFavorites).mockResolvedValue([])
    let resolve!: (v: { detail: string }) => void
    vi.mocked(addFavorite).mockReturnValue(new Promise((r) => { resolve = r }))
    const wrapper = ({ children }: { children: ReactNode }) => (
      <QueryClientProvider client={new QueryClient({ defaultOptions: { queries: { retry: false } } })}>{children}</QueryClientProvider>
    )
    const { result } = renderHook(() => useFavorites(), { wrapper })
    await waitFor(() => expect(result.current.isLoading).toBe(false))
    expect(result.current.pendingId).toBeUndefined()
    act(() => result.current.toggle('a1'))
    await waitFor(() => expect(result.current.pendingId).toBe('a1'))
    resolve({ detail: 'ok' })
    await waitFor(() => expect(result.current.pendingId).toBeUndefined())
  })
})
