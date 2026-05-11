import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'

import {
  createArtistProfile,
  listArtistProfiles,
  updateArtistProfile,
} from '@/api/artists.api'
import ArtistDashboardPage from '@/pages/artist/ArtistDashboardPage'
import { useAuthStore } from '@/store/authStore'

jest.mock('@/api/artists.api', () => ({
  createArtistProfile: jest.fn(),
  listArtistProfiles: jest.fn(),
  updateArtistProfile: jest.fn(),
}))

jest.mock('sonner', () => ({
  toast: {
    error: jest.fn(),
    success: jest.fn(),
  },
}))

const mockedCreateArtistProfile = jest.mocked(createArtistProfile)
const mockedListArtistProfiles = jest.mocked(listArtistProfiles)
const mockedUpdateArtistProfile = jest.mocked(updateArtistProfile)

function renderArtistDashboard() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter>
        <ArtistDashboardPage />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('ArtistDashboardPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
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
        city: 'Pasto',
        category: 'Música',
      },
    })
  })

  it('creates an artist profile when no profile exists', async () => {
    const user = userEvent.setup()
    mockedListArtistProfiles.mockResolvedValueOnce([])
    mockedCreateArtistProfile.mockResolvedValueOnce({} as Awaited<ReturnType<typeof createArtistProfile>>)

    renderArtistDashboard()

    const nameInput = await screen.findByLabelText(/nombre artístico/i)
    await user.clear(nameInput)
    await user.type(nameInput, '  Ana del Sur  ')
    await user.clear(screen.getByLabelText(/ciudad/i))
    await user.type(screen.getByLabelText(/ciudad/i), ' Pasto ')
    await user.click(screen.getByRole('button', { name: /guardar perfil/i }))

    await waitFor(() => {
      expect(mockedCreateArtistProfile).toHaveBeenCalledWith(
        expect.objectContaining({
          artistic_name: 'Ana del Sur',
          city: 'Pasto',
        }),
      )
    })
  })

  it('updates an existing artist profile by slug', async () => {
    const user = userEvent.setup()
    mockedListArtistProfiles.mockResolvedValueOnce([
      {
        id: '1',
        user_id: '7',
        slug: 'ana-del-sur',
        artistic_name: 'Ana del Sur',
        bio: '',
        trajectory: '',
        discipline: 'Música',
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
    mockedUpdateArtistProfile.mockResolvedValueOnce({} as Awaited<ReturnType<typeof updateArtistProfile>>)

    renderArtistDashboard()

    const bioInput = await screen.findByLabelText(/biografía/i)
    await user.type(bioInput, 'Cantante nariñense')
    await user.click(screen.getByRole('button', { name: /guardar perfil/i }))

    await waitFor(() => {
      expect(mockedUpdateArtistProfile).toHaveBeenCalledWith(
        'ana-del-sur',
        expect.objectContaining({
          artistic_name: 'Ana del Sur',
          bio: 'Cantante nariñense',
        }),
      )
    })
  })
})
