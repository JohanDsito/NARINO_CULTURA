import { describe, it, expect, beforeEach, vi } from 'vitest'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { register } from '@/api/auth.api'
import { RegisterForm } from '@/components/auth/register-form'

vi.mock('@/api/auth.api', () => ({
  register: vi.fn(),
}))

vi.mock('sonner', () => ({
  toast: {
    error: vi.fn(),
    success: vi.fn(),
  },
}))

const mockedRegister = vi.mocked(register)

function renderRegisterForm() {
  const queryClient = new QueryClient()

  return render(
    <QueryClientProvider client={queryClient}>
      <MemoryRouter initialEntries={['/register']}>
        <Routes>
          <Route
            path="/register"
            element={<RegisterForm />}
          />

          <Route
            path="/login"
            element={<div>Login page</div>}
          />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>,
  )
}

describe('RegisterForm', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    localStorage.clear()
  })

  it('requires artist-specific fields when role is artist', async () => {
    const user = userEvent.setup()

    renderRegisterForm()

    await user.type(
      screen.getByLabelText(/nombre$/i),
      'Ana',
    )

    await user.type(
      screen.getByLabelText(/apellido/i),
      'Mora',
    )

    await user.type(
      screen.getByLabelText(/email/i),
      'artist@test.com',
    )

    await user.type(
      screen.getByLabelText(/contraseña/i),
      'secret123',
    )

    await user.selectOptions(
      screen.getByLabelText(/tipo de usuario/i),
      'artist',
    )

    await user.click(
      screen.getByRole('button', {
        name: /crear cuenta/i,
      }),
    )

    expect(
      await screen.findByText(
        /nombre artístico es obligatorio/i,
      ),
    ).toBeInTheDocument()

    expect(
      screen.getByText(/ciudad es obligatoria/i),
    ).toBeInTheDocument()

    expect(mockedRegister).not.toHaveBeenCalled()
  })

  it('maps buyer registration to backend role and redirects to login', async () => {
    const user = userEvent.setup()

    mockedRegister.mockResolvedValueOnce({
      message: 'Registro exitoso.',
    })

    renderRegisterForm()

    await user.type(
      screen.getByLabelText(/nombre$/i),
      'Bea',
    )

    await user.type(
      screen.getByLabelText(/apellido/i),
      'Rios',
    )

    await user.type(
      screen.getByLabelText(/email/i),
      'buyer@test.com',
    )

    await user.type(
      screen.getByLabelText(/contraseña/i),
      'secret123',
    )

    await user.click(
      screen.getByRole('button', {
        name: /crear cuenta/i,
      }),
    )

    await waitFor(() => {
      expect(mockedRegister).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'buyer@test.com',
          first_name: 'Bea',
          last_name: 'Rios',
          role: 'COMPRADOR',
        }),
      )
    })

    expect(
      await screen.findByText('Login page'),
    ).toBeInTheDocument()
  })
})