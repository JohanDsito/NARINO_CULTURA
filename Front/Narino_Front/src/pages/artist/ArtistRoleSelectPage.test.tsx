import { describe, it, expect, beforeEach } from 'vitest'
import { fireEvent, screen } from '@testing-library/react'

import ArtistRoleSelectPage from '@/pages/artist/ArtistRoleSelectPage'
import { useAuthStore } from '@/store/authStore'
import { renderWithProviders } from '@/test/render'
import type { User } from '@/types'

describe('ArtistRoleSelectPage', () => {
  beforeEach(() => {
    localStorage.clear()
    useAuthStore.setState({ user: { id: 'u1' } as User })
  })

  it('ofrece las cinco disciplinas y el músico lleva a su propio panel', () => {
    renderWithProviders(<ArtistRoleSelectPage />, { route: '/dashboard', path: '/dashboard' })
    expect(screen.getByRole('heading', { name: '¿Cuál es tu perfil artístico?' })).toBeInTheDocument()
    for (const label of ['Artesano', 'Fotógrafo', 'Escultor', 'Pintor', 'Músico']) {
      expect(screen.getByRole('heading', { name: label })).toBeInTheDocument()
    }
    expect(screen.getByRole('link', { name: /Pintor/ })).toHaveAttribute('href', '/dashboard/profile')
    expect(screen.getByRole('link', { name: /Músico/ })).toHaveAttribute('href', '/dashboard/musician/profile')
  })

  it('al elegir una disciplina la guarda para el usuario y navega', () => {
    renderWithProviders(<ArtistRoleSelectPage />, { route: '/dashboard', path: '/dashboard' })
    fireEvent.click(screen.getByRole('link', { name: /Músico/ }))
    expect(localStorage.getItem('artist_discipline_u1')).toBe('musico')
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/musician/profile')
  })

  it('sin usuario no guarda nada pero igual navega', () => {
    useAuthStore.setState({ user: null })
    renderWithProviders(<ArtistRoleSelectPage />, { route: '/dashboard', path: '/dashboard' })
    fireEvent.click(screen.getByRole('link', { name: /Pintor/ }))
    expect(Object.keys(localStorage).filter((k) => k.startsWith('artist_discipline'))).toEqual([])
    expect(screen.getByTestId('location')).toHaveTextContent('/dashboard/profile')
  })
})
