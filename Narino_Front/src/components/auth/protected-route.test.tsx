import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { me } from '@/api/auth.api'
import { ProtectedRoute } from '@/components/auth/protected-route'
import { useAuthStore } from '@/store/authStore'

vi.mock('@/api/auth.api', () => ({
  me: vi.fn(),
}))

const mockedMe = vi.mocked(me)

function renderProtectedRoute(
  allowedRoles?: Parameters<
    typeof ProtectedRoute
  >[0]['allowedRoles'],
) {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter
        initialEntries={['/dashboard/profile']}
      >
        <Routes>
          <Route
            path="/login"
            element={<div>Login page</div>}
          />

          <Route
            path="/"
            element={<div>Home page</div>}
          />

          <Route
            path="/dashboard/profile"
            element={
              <ProtectedRoute
                allowedRoles={allowedRoles}
              >
                <div>Private content</div>
              </ProtectedRoute>
            }
          />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('ProtectedRoute', () => {
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

  it('redirects to login when there is no access token', () => {
    renderProtectedRoute()

    expect(
      screen.getByText('Login page'),
    ).toBeInTheDocument()
  })

  it('renders private content for an authenticated allowed user', () => {
    useAuthStore.setState({
      accessToken: 'access-token',
      user: {
        id: 1,
        email: 'artist@test.com',
        first_name: 'Ana',
        last_name: 'Mora',
        role: 'artist',
      },
      refreshToken: 'refresh-token',
      isAuthenticated: true,
    })

    renderProtectedRoute(['artist'])

    expect(
      screen.getByText('Private content'),
    ).toBeInTheDocument()
  })

  it('redirects to home when the user role is not allowed', () => {
    useAuthStore.setState({
      accessToken: 'access-token',
      user: {
        id: 1,
        email: 'buyer@test.com',
        first_name: 'Bea',
        last_name: 'Rios',
        role: 'buyer',
      },
      refreshToken: 'refresh-token',
      isAuthenticated: true,
    })

    renderProtectedRoute(['artist'])

    expect(
      screen.getByText('Home page'),
    ).toBeInTheDocument()
  })

  it('loads /me when there is a token but no user', async () => {
    useAuthStore.setState({
      accessToken: 'access-token',
      user: null,
      refreshToken: 'refresh-token',
      isAuthenticated: true,
    })

    mockedMe.mockResolvedValueOnce({
      id: 1,
      email: 'artist@test.com',
      first_name: 'Ana',
      last_name: 'Mora',
      role: 'artist',
    })

    renderProtectedRoute(['artist'])

    await waitFor(() => {
      expect(
        screen.getByText('Private content'),
      ).toBeInTheDocument()
    })

    await waitFor(() => {
      expect(
        useAuthStore.getState().user?.role,
      ).toBe('artist')
    })
  })
})