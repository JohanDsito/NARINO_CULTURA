import {
  describe,
  it,
  expect,
  beforeEach,
  vi,
} from 'vitest'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'

import { getServerCart } from '@/api/marketplace.api'
import { getUnreadNotificationsCount } from '@/api/notifications.api'
import { Navbar } from '@/components/layout/navbar'
import { useAuthStore } from '@/store/authStore'
import { useCartStore } from '@/store/cartStore'

const mockLogout = vi.fn()

vi.mock('@/hooks/useAuth', () => ({
  useLogout: () => mockLogout,
}))

vi.mock('@/api/marketplace.api', () => ({
  getServerCart: vi.fn(),
}))

vi.mock('@/api/notifications.api', () => ({
  getUnreadNotificationsCount: vi.fn(),
}))

const mockedGetServerCart = vi.mocked(getServerCart)
const mockedUnread = vi.mocked(getUnreadNotificationsCount)

function renderNavbar(initialPath = '/') {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={[initialPath]}>
        <Navbar />
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('Navbar', () => {
  beforeEach(() => {
    vi.clearAllMocks()

    localStorage.clear()

    useAuthStore.setState({
      user: null,
      accessToken: null,
      refreshToken: null,
      isAuthenticated: false,
    })

    useCartStore.setState({
      items: [],
      isOpen: false,
    })
  })

  it('does not ask for notifications without a session', () => {
    renderNavbar()

    expect(screen.getByRole('link', { name: 'Notificaciones' })).toBeInTheDocument()
    expect(mockedUnread).not.toHaveBeenCalled()
  })

  it('renders public navigation and login link for guests', () => {
    renderNavbar('/artists')

    expect(
      screen.getByText('Nariño Cultura'),
    ).toBeInTheDocument()

    expect(
      screen.getByRole('link', {
        name: /artistas/i,
      }),
    ).toHaveAttribute(
      'aria-current',
      'page',
    )

    expect(
      screen.getByRole('link', {
        name: /ingresar/i,
      }),
    ).toHaveAttribute(
      'href',
      '/login',
    )
  })

  it('shows the guest cart count from the local cart', () => {
    useCartStore.setState({
      items: [
        {
          id: '1',
          artwork_id: '10',
          title: 'Obra',
          artist_name: 'Ana',
          price: 1000,
          image: '',
          quantity: 1,
        },
      ],
      isOpen: false,
    })

    renderNavbar()

    expect(
      screen.getByRole('link', { name: /carrito de compras, 1 productos/i }),
    ).toBeInTheDocument()
  })

  it('shows server cart count and account link for authenticated artists', async () => {
    useAuthStore.setState({
      isAuthenticated: true,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: {
        id: '1',
        email: 'artist@test.com',
        first_name: 'Ana',
        last_name: 'Mora',
        role: 'artist',
        is_verified: true,
      },
    })

    mockedGetServerCart.mockResolvedValue({
      id: 'cart',
      user: '1',
      items: [{ id: 'i1', artwork: '10', created_at: '' }],
      created_at: '',
      updated_at: '',
    })

    mockedUnread.mockResolvedValue(3)

    renderNavbar()

    expect(
      await screen.findByRole('link', { name: /carrito de compras, 1 productos/i }),
    ).toBeInTheDocument()
    expect(
      await screen.findByRole('link', { name: /notificaciones, 3 sin leer/i }),
    ).toHaveAttribute('href', '/notifications')

    // Sin disciplina elegida el artista va primero al selector de panel
    expect(screen.getByRole('link', { name: /mi panel/i })).toHaveAttribute(
      'href',
      '/dashboard',
    )
  })

  it('opens mobile menu and runs logout action', async () => {
    const user = userEvent.setup()

    useAuthStore.setState({
      isAuthenticated: true,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: {
        id: '1',
        email: 'admin@test.com',
        first_name: 'Admin',
        last_name: 'User',
        role: 'admin',
        is_verified: true,
      },
    })

    renderNavbar()

    await user.click(
      screen.getByRole('button', {
        name: /abrir menú/i,
      }),
    )

    expect(
      screen.getAllByRole('link', {
        name: /eventos/i,
      }).length,
    ).toBeGreaterThan(0)

    const logoutButtons =
      screen.getAllByRole('button', {
        name: /cerrar sesión/i,
      })

    await user.click(
      logoutButtons[
        logoutButtons.length - 1
      ],
    )

    expect(mockLogout).toHaveBeenCalled()
  })
})