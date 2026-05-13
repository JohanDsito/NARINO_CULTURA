import {
  describe,
  it,
  expect,
  beforeEach,
  vi,
} from 'vitest'

import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'

import { Navbar } from '@/components/layout/navbar'
import { useAuthStore } from '@/store/authStore'
import { useCartStore } from '@/store/cartStore'

const mockLogout = vi.fn()

vi.mock('@/hooks/useAuth', () => ({
  useLogout: () => mockLogout,
}))

function renderNavbar(initialPath = '/') {
  return render(
    <MemoryRouter
      initialEntries={[initialPath]}
    >
      <Navbar />
    </MemoryRouter>,
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

  it('shows cart count and account link for authenticated artists', () => {
    useAuthStore.setState({
      isAuthenticated: true,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: {
        id: 1,
        email: 'artist@test.com',
        first_name: 'Ana',
        last_name: 'Mora',
        role: 'artist',
      },
    })

    useCartStore.setState({
      items: [
        {
          id: 1,
          artwork_id: 10,
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
      screen.getByRole('link', {
        name:
          /carrito de compras, 1 productos/i,
      }),
    ).toBeInTheDocument()

    expect(
      screen.getByRole('link', {
        name: /mi panel/i,
      }),
    ).toHaveAttribute(
      'href',
      '/dashboard/profile',
    )
  })

  it('opens mobile menu and runs logout action', async () => {
    const user = userEvent.setup()

    useAuthStore.setState({
      isAuthenticated: true,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      user: {
        id: 1,
        email: 'admin@test.com',
        first_name: 'Admin',
        last_name: 'User',
        role: 'admin',
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