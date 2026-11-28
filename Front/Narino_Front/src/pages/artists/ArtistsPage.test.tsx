import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

import { listArtistProfiles } from '@/api/artists.api'
import { listMusicians } from '@/api/musicians.api'
import ArtistsPage from '@/pages/artists/ArtistsPage'
import type { ArtistProfile } from '@/types'

vi.mock('@/api/artists.api', () => ({ listArtistProfiles: vi.fn() }))
vi.mock('@/api/musicians.api', () => ({ listMusicians: vi.fn() }))

const mockedList = vi.mocked(listArtistProfiles)
const mockedMusicians = vi.mocked(listMusicians)

function artist(overrides: Partial<ArtistProfile>): ArtistProfile {
  return {
    id: overrides.slug ?? 'id',
    user_id: `user-${overrides.slug ?? 'id'}`,
    slug: 'slug',
    artistic_name: 'Artista',
    discipline: 'Pintor',
    city: 'Pasto',
    followers_count: 0,
    is_public: true,
    ...overrides,
  } as ArtistProfile
}

const ANA = artist({ slug: 'ana', artistic_name: 'Ana Barniz' })
const LUIS = artist({ slug: 'luis', artistic_name: 'Taller del Volcán', discipline: 'Escultor' })
const MUSICO = artist({ slug: 'rondador', artistic_name: 'Rondador', user_id: 'user-musico' })

function renderPage() {
  const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <ArtistsPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('ArtistsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockedMusicians.mockResolvedValue({ results: [{ user_id: 'user-musico' }] } as never)
    mockedList.mockImplementation(async (params) =>
      params?.search ? [LUIS] : [ANA, LUIS, MUSICO],
    )
  })

  it('lista los artistas visuales y deja fuera a los músicos', async () => {
    renderPage()
    expect(await screen.findByText('Ana Barniz')).toBeInTheDocument()
    expect(screen.getByText('Taller del Volcán')).toBeInTheDocument()
    await waitFor(() => expect(screen.queryByText('Rondador')).not.toBeInTheDocument())
    expect(mockedList).toHaveBeenCalledWith({ search: undefined, page_size: 100 })
  })

  it('busca en el servidor cuando la persona deja de escribir', async () => {
    renderPage()
    await screen.findByText('Ana Barniz')

    const input = screen.getByRole('searchbox', { name: 'Buscar artistas' })
    fireEvent.change(input, { target: { value: 'v' } })
    fireEvent.change(input, { target: { value: 'vol' } })
    fireEvent.change(input, { target: { value: ' volcán ' } })

    await waitFor(() =>
      expect(mockedList).toHaveBeenLastCalledWith({ search: 'volcán', page_size: 100 }),
    )
    await waitFor(() => expect(screen.queryByText('Ana Barniz')).not.toBeInTheDocument())
    expect(screen.getByText('Taller del Volcán')).toBeInTheDocument()
    // Una petición inicial y una sola para la búsqueda: no una por cada tecla
    expect(mockedList).toHaveBeenCalledTimes(2)
  })

  it('avisa cuando la búsqueda no encuentra a nadie', async () => {
    mockedList.mockImplementation(async (params) => (params?.search ? [] : [ANA]))
    renderPage()
    await screen.findByText('Ana Barniz')
    fireEvent.change(screen.getByRole('searchbox', { name: 'Buscar artistas' }), {
      target: { value: 'zzz' },
    })
    expect(await screen.findByText('Sin resultados para tu búsqueda.')).toBeInTheDocument()
  })
})

describe('ArtistsPage: sin artistas', () => {
  it('sin búsqueda ni artistas muestra "No hay artistas disponibles."', async () => {
    vi.clearAllMocks()
    mockedMusicians.mockResolvedValue({ results: [] } as never)
    mockedList.mockResolvedValue([])
    renderPage()
    expect(await screen.findByText('No hay artistas disponibles.')).toBeInTheDocument()
    expect(screen.queryByText('Sin resultados para tu búsqueda.')).not.toBeInTheDocument()
  })
})