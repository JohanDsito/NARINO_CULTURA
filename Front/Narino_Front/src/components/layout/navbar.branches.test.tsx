import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen } from '@testing-library/react'

import { Navbar } from '@/components/layout/navbar'
import { useAuthStore } from '@/store/authStore'
import { useThemeStore } from '@/store/themeStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'

const logout = vi.hoisted(() => vi.fn())
const unread = vi.hoisted(() => ({ value: 0 }))

vi.mock('@/hooks/useAuth', () => ({ useLogout: () => logout }))
vi.mock('@/hooks/useCartCount', () => ({ useCartCount: () => 0 }))
vi.mock('@/hooks/useUnreadNotifications', () => ({ useUnreadNotifications: () => unread.value }))

function signIn(role: User['role'], id = 'u1') {
  useAuthStore.setState({ isAuthenticated: true, user: { id, role } as User })
}

describe('Navbar: casos de borde', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
    unread.value = 0
    useAuthStore.setState({ isAuthenticated: false, user: null })
    useThemeStore.setState({ theme: 'light' })
  })

  it('el botón de cerrar sesión de escritorio llama a logout', () => {
    signIn('buyer')
    renderWithProviders(<Navbar />)
    fireEvent.click(screen.getByRole('button', { name: 'Cerrar sesión' }))
    expect(logout).toHaveBeenCalledTimes(1)
  })

  it('más de 99 notificaciones sin leer se muestran como 99+', () => {
    signIn('buyer')
    unread.value = 150
    renderWithProviders(<Navbar />)
    expect(screen.getByText('99+')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Notificaciones, 150 sin leer' })).toBeInTheDocument()
  })

  it('en modo oscuro el botón de tema cambia de ícono y vuelve al claro', () => {
    useThemeStore.setState({ theme: 'dark' })
    renderWithProviders(<Navbar />)
    fireEvent.click(screen.getByRole('button', { name: 'Cambiar modo de color' }))
    expect(useThemeStore.getState().theme).toBe('light')
  })

  it('la gestora cultural entra a eventos desde "Mi panel"; una artista a su panel', () => {
    signIn('cultural_manager')
    const first = renderWithProviders(<Navbar />)
    expect(screen.getByRole('link', { name: 'Mi panel' })).toHaveAttribute('href', '/events')
    first.unmount()

    signIn('admin')
    const second = renderWithProviders(<Navbar />)
    expect(screen.getByRole('link', { name: 'Mi panel' })).toHaveAttribute('href', '/admin/dashboard')
    second.unmount()

    signIn('artist')
    renderWithProviders(<Navbar />)
    expect(screen.getByRole('link', { name: 'Mi panel' })).toHaveAttribute('href', '/dashboard')
  })

  it('una artista sin id usa el panel por defecto', () => {
    useAuthStore.setState({ isAuthenticated: true, user: { role: 'artist' } as User })
    renderWithProviders(<Navbar />)
    expect(screen.getByRole('link', { name: 'Mi panel' })).toHaveAttribute('href', '/dashboard')
  })

  it('menú móvil sin sesión: ofrece Ingresar y se cierra al elegirlo', () => {
    renderWithProviders(<Navbar />)
    fireEvent.click(screen.getByRole('button', { name: 'Abrir menú' }))
    const logins = screen.getAllByRole('link', { name: 'Ingresar' })
    expect(logins.length).toBeGreaterThan(0)
    fireEvent.click(logins[logins.length - 1])
    expect(screen.getByRole('button', { name: 'Abrir menú' })).toBeInTheDocument()
  })

  it('menú móvil con sesión: "Cerrar sesión" cierra el menú y la sesión', () => {
    signIn('buyer')
    renderWithProviders(<Navbar />)
    fireEvent.click(screen.getByRole('button', { name: 'Abrir menú' }))
    const buttons = screen.getAllByRole('button', { name: /Cerrar sesión/ })
    fireEvent.click(buttons[buttons.length - 1])
    expect(logout).toHaveBeenCalled()
    expect(screen.getByRole('button', { name: 'Abrir menú' })).toBeInTheDocument()
  })
})
