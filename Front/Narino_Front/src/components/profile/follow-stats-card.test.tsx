import { describe, it, expect, vi } from 'vitest'
import { fireEvent, screen } from '@testing-library/react'

import type { FollowItem } from '@/api/artists.api'
import { FollowStatsCard } from '@/components/profile/follow-stats-card'
import { renderWithProviders } from '@/test/render'

function setup(overrides: { followers?: () => Promise<FollowItem[]>; following?: () => Promise<FollowItem[]>; enabled?: boolean } = {}) {
  const fetchFollowers = vi.fn(overrides.followers ?? (() => Promise.resolve([])))
  const fetchFollowing = vi.fn(overrides.following ?? (() => Promise.resolve([])))
  renderWithProviders(
    <FollowStatsCard
      followersCount={12}
      followersQueryKey={['followers']}
      fetchFollowers={fetchFollowers}
      followingQueryKey={['following']}
      fetchFollowing={fetchFollowing}
      enabled={overrides.enabled ?? true}
    />,
  )
  return { fetchFollowers, fetchFollowing }
}

describe('FollowStatsCard', () => {
  it('muestra el contador de seguidores y no consulta hasta abrir las listas', () => {
    const { fetchFollowers } = setup()
    expect(screen.getByText('12')).toBeInTheDocument()
    expect(fetchFollowers).not.toHaveBeenCalled()
  })

  it('al abrir carga y lista nombre artístico, nombre completo, inicial o foto', async () => {
    setup({
      followers: () =>
        Promise.resolve([
          { id: '1', artistic_name: 'Lia Pintora', avatar_url: 'https://img.test/l.jpg' },
          { id: '2', first_name: 'Juan', last_name: 'Gómez' },
        ]),
    })
    fireEvent.click(screen.getByRole('button', { name: /Ver seguidores/ }))
    expect(await screen.findByAltText('Lia Pintora')).toHaveAttribute('src', 'https://img.test/l.jpg')
    expect(screen.getByText('Juan Gómez')).toBeInTheDocument()
    expect(screen.getByText('J')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /Ver seguidores/ }))
    expect(screen.queryByText('Juan Gómez')).not.toBeInTheDocument()
  })

  it('muestra esqueletos mientras carga', () => {
    setup({ followers: () => new Promise(() => {}) })
    fireEvent.click(screen.getByRole('button', { name: /Ver seguidores/ }))
    expect(document.querySelectorAll('.animate-pulse').length).toBe(6)
  })

  it('vacío: indica que no hay seguidores', async () => {
    setup()
    fireEvent.click(screen.getByRole('button', { name: /Ver siguiendo/ }))
    expect(await screen.findByText('No hay siguiendo aún.')).toBeInTheDocument()
  })

  it('error: avisa que el endpoint no está disponible', async () => {
    setup({ followers: () => Promise.reject(new Error('404')) })
    fireEvent.click(screen.getByRole('button', { name: /Ver seguidores/ }))
    expect(await screen.findByText(/El servidor aún no tiene este endpoint activo/, undefined, { timeout: 8000 })).toBeInTheDocument()
  })

  it('más de 8 elementos: muestra 8 y cuántos faltan', async () => {
    const many = Array.from({ length: 10 }, (_, i) => ({ id: `${i}`, artistic_name: `Artista ${i}` }))
    setup({ following: () => Promise.resolve(many) })
    fireEvent.click(screen.getByRole('button', { name: /Ver siguiendo/ }))
    expect(await screen.findByText('Artista 7')).toBeInTheDocument()
    expect(screen.queryByText('Artista 8')).not.toBeInTheDocument()
    expect(screen.getByText('y 2 más…')).toBeInTheDocument()
  })

  it('con enabled en falso no consulta aunque se abra', () => {
    const { fetchFollowers } = setup({ enabled: false })
    fireEvent.click(screen.getByRole('button', { name: /Ver seguidores/ }))
    expect(fetchFollowers).not.toHaveBeenCalled()
  })
})
