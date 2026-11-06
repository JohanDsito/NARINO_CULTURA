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
    defaultOptions: { queries: { retry: false } },
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
        id: '7',
        email: 'artist@test.com',
        first_name: 'Ana',
        last_name: 'Mora',
        role: 'artist',
        is_verified: true,
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

  it('renders artworks returned by the server for this artist', async () => {
    mockedGetArtworks.mockResolvedValue({
      count: 1,
      next: null,
      previous: null,
      results: [
        {
          id: '10',
          title: 'Pintura del sur',
          description: 'Obra inspirada en Nariño',
          price: '150000',
          category: { id: 1, name: 'Pintura', slug: 'pintura' },
          technique: 'Óleo',
          dimensions: '',
          material: '',
          status: 'DISPONIBLE',
          main_image_url: '',
          ai_tags: {},
          ai_description: '',
          views_count: 0,
          images: [],
          artist: '3',
          created_at: '',
          updated_at: '',
        },
      ],
    })

    renderArtistArtworksPage()

    expect(await screen.findByText('Pintura del sur')).toBeInTheDocument()
  })

  it('shows an empty state when the artist has no artworks', async () => {
    mockedGetArtworks.mockResolvedValue({
      count: 0,
      next: null,
      previous: null,
      results: [],
    })

    renderArtistArtworksPage()

    expect(
      await screen.findByText(/aún no tienes obras registradas/i),
    ).toBeInTheDocument()
  })
})
