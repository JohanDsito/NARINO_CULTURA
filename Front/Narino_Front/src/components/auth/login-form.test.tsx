import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { login } from '@/api/auth.api'
import { createArtistProfile } from '@/api/artists.api'
import { LoginForm } from '@/components/auth/login-form'
import { useAuthStore } from '@/store/authStore'
import { setPendingArtistProfile } from '@/utils/pendingArtistProfile'

vi.mock('@/api/auth.api', () => ({
  login: vi.fn(),
}))

vi.mock('@/api/artists.api', () => ({
  createArtistProfile: vi.fn(),
}))

vi.mock('sonner', () => ({
  toast: {
    error: vi.fn(),
    message: vi.fn(),
    success: vi.fn(),
  },
}))

const mockedLogin = vi.mocked(login)
const mockedCreateArtistProfile = vi.mocked(createArtistProfile)

function renderLoginForm() {
  const queryClient = new QueryClient()

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/login']}>
        <Routes>
          <Route path="/login" element={<LoginForm />} />
          <Route
            path="/dashboard/profile"
            element={<div>Artist dashboard</div>}
          />
          <Route
            path="/marketplace"
            element={<div>Marketplace</div>}
          />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('LoginForm', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    localStorage.clear()

    useAuthStore.setState({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
    })
  })

  it('validates required login fields', async () => {
    const user = userEvent.setup()

    renderLoginForm()

    await user.click(
      screen.getByRole('button', {
        name: /ingresar/i,
      }),
    )

    expect(
      await screen.findByText(/email válido/i),
    ).toBeInTheDocument()

    expect(
      screen.getByText(/contraseña es obligatoria/i),
    ).toBeInTheDocument()
  })

  it('stores auth state and redirects by role after login', async () => {
    const user = userEvent.setup()

    mockedLogin.mockResolvedValueOnce({
      tokens: {
        access: 'access-token',
        refresh: 'refresh-token',
      },
      user: {
        id: 1,
        email: 'buyer@test.com',
        first_name: 'Bea',
        last_name: 'Rios',
        role: 'buyer',
      },
    })

    renderLoginForm()

    await user.type(
      screen.getByLabelText(/email/i),
      'buyer@test.com',
    )

    await user.type(
      screen.getByLabelText(/contraseña/i),
      'secret',
    )

    await user.click(
      screen.getByRole('button', {
        name: /ingresar/i,
      }),
    )

    await waitFor(() => {
      expect(
        screen.getByText('Marketplace'),
      ).toBeInTheDocument()
    })

    expect(useAuthStore.getState()).toMatchObject({
      accessToken: 'access-token',
      isAuthenticated: true,
      user: {
        role: 'buyer',
      },
    })
  })

  it('creates a pending artist profile after artist login', async () => {
    const user = userEvent.setup()

    setPendingArtistProfile({
      artistic_name: 'La Montaña',
      city: 'Pasto',
    })

    mockedLogin.mockResolvedValueOnce({
      tokens: {
        access: 'access-token',
        refresh: 'refresh-token',
      },
      user: {
        id: 2,
        email: 'artist@test.com',
        first_name: 'Ana',
        last_name: 'Mora',
        role: 'artist',
      },
    })

    mockedCreateArtistProfile.mockResolvedValueOnce(
      {} as Awaited<ReturnType<typeof createArtistProfile>>,
    )

    renderLoginForm()

    await user.type(
      screen.getByLabelText(/email/i),
      'artist@test.com',
    )

    await user.type(
      screen.getByLabelText(/contraseña/i),
      'secret',
    )

    await user.click(
      screen.getByRole('button', {
        name: /ingresar/i,
      }),
    )

    await waitFor(() => {
      expect(mockedCreateArtistProfile).toHaveBeenCalledWith({
        artistic_name: 'La Montaña',
        city: 'Pasto',
      })
    })

    expect(
      localStorage.getItem(
        'narino_cultura_pending_artist_profile',
      ),
    ).toBeNull()
  })
})