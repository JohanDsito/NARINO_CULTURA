import { describe, it, expect, vi, beforeEach } from 'vitest'
import { screen } from '@testing-library/react'

import HomePage from '@/pages/home/HomePage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'

vi.mock('@/components/events/event-calendar', () => ({
  EventCalendar: ({ showCreateButton }: { showCreateButton: boolean }) => <div>calendario:{String(showCreateButton)}</div>,
}))

function signIn(user: Partial<User> | null) {
  useAuthStore.setState({ user: user as User | null, isAuthenticated: Boolean(user) })
}

describe('HomePage', () => {
  beforeEach(() => {
    localStorage.clear()
    signIn(null)
  })

  it('invitado: ofrece iniciar sesión y crear cuenta, y las cuatro secciones', () => {
    renderWithProviders(<HomePage />)
    expect(screen.getByRole('heading', { level: 1, name: 'Nariño Cultura' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Iniciar sesión' })).toHaveAttribute('href', '/login')
    expect(screen.getByRole('link', { name: 'Crear cuenta' })).toHaveAttribute('href', '/register')
    expect(screen.queryByRole('link', { name: 'Ir a mi panel' })).not.toBeInTheDocument()
    expect(screen.getByRole('link', { name: /Ver catálogo/ })).toHaveAttribute('href', '/artworks')
    expect(screen.getByRole('link', { name: /Ver tienda/ })).toHaveAttribute('href', '/marketplace')
    expect(screen.getByRole('link', { name: /Ver subastas/ })).toHaveAttribute('href', '/auctions')
    expect(screen.getByRole('link', { name: /Ver eventos/ })).toHaveAttribute('href', '/events')
    expect(screen.getByAltText(/Carnaval de Negros y Blancos/)).toBeInTheDocument()
    expect(screen.getByText('calendario:false')).toBeInTheDocument()
  })

  it.each([
    ['admin', { id: 'u1' }, '/admin/dashboard', 'true'],
    ['cultural_manager', { id: 'u1' }, '/events', 'true'],
    ['buyer', { id: 'u1' }, '/marketplace', 'false'],
    ['artist', { id: 'u1' }, '/dashboard', 'false'],
    ['artist', {}, '/dashboard', 'false'],
  ])('con sesión como %s (%o) el botón lleva a %s y el calendario permite crear = %s', (role, extra, path, canCreate) => {
    signIn({ role: role as User['role'], ...extra })
    renderWithProviders(<HomePage />)
    expect(screen.getByRole('link', { name: 'Ir a mi panel' })).toHaveAttribute('href', path)
    expect(screen.queryByRole('link', { name: 'Iniciar sesión' })).not.toBeInTheDocument()
    expect(screen.getByText(`calendario:${canCreate}`)).toBeInTheDocument()
  })

  it('una artista con disciplina elegida va a su panel de perfil', () => {
    localStorage.setItem('artist_discipline_u1', 'pintor')
    signIn({ role: 'artist', id: 'u1' })
    renderWithProviders(<HomePage />)
    expect(screen.getByRole('link', { name: 'Ir a mi panel' })).toHaveAttribute('href', '/dashboard/profile')
  })
})
