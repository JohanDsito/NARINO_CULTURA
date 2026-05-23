import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

import { getArtworks } from '@/api/artworks.api'
import { listArtistProfiles } from '@/api/artists.api'
import ArtistArtworksPage from '@/pages/artist/ArtistArtworksPage'
import { useAuthStore } from '@/store/authStore'

vi.mock('@/api/artworks.api', () => ({
  getArtworks: vi.fn(),
}))

vi.mock('@/api/artists.api', () => ({
  listArtistProfiles: vi.fn(),
}))

const mockedGetArtworks = vi.mocked(getArtworks)
const mockedListArtistProfiles = vi.mocked(listArtistProfiles)

function renderArtistArtworksPage() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <ArtistArtworksPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('ArtistArtworksPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()

    useAuthStore.setState({
      isAuthenticated: true,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: {
        id: 7,
        email: 'artist@test.com',
        first_name: 'Ana',
        last_name: 'Mora',
        role: 'artist',
      },
    })

    mockedListArtistProfiles.mockResolvedValue([
      {
        id: '3',
        user_id: '7',
        slug: 'ana-mora',
        artistic_name: 'Ana Mora',
        bio: '',
        trajectory: '',
        discipline: 'Musica',
        city: 'Pasto',
        website_url: '',
        instagram_url: '',
        facebook_url: '',
        tiktok_url: '',
        followers_count: 0,
        is_public: true,
        created_at: '',
        updated_at: '',
      },
    ])
  })

  it('renders artworks owned by the logged artist', async () => {
    mockedGetArtworks.mockResolvedValue([
      {
        id: 10,
        title: 'Cancion del sur',
        slug: 'cancion-del-sur',
        description: 'Demo musical inspirado en Narino',
        price: 0,
        category: 'MUSICA',
        technique: '',
        status: 'DISPONIBLE',
        images: [],
        artist: {
          id: 3,
          slug: 'ana-mora',
          artistic_name: 'Ana Mora',
        },
        views_count: 0,
        likes_count: 0,
        created_at: '',
        updated_at: '',
        genre: 'Andina',
        release_date: '2026-05-01',
      },
      {
        id: 11,
        title: 'Obra de otro artista',
        slug: 'obra-otro',
        description: 'No debe aparecer',
        price: 1000,
        category: 'PINTURA',
        technique: 'Oleo',
        status: 'DISPONIBLE',
        images: [],
        artist: {
          id: 99,
          slug: 'otro-artista',
          artistic_name: 'Otro Artista',
        },
        views_count: 0,
        likes_count: 0,
        created_at: '',
        updated_at: '',
      },
    ] as Awaited<ReturnType<typeof getArtworks>>)

    renderArtistArtworksPage()

    expect(await screen.findByText('Cancion del sur')).toBeInTheDocument()
    expect(screen.queryByText('Obra de otro artista')).not.toBeInTheDocument()
  })

  it('shows an empty state when the artist has no artworks', async () => {
    mockedGetArtworks.mockResolvedValue([])

    renderArtistArtworksPage()

    expect(await screen.findByText(/aun no tienes obras registradas/i)).toBeInTheDocument()
  })
})
