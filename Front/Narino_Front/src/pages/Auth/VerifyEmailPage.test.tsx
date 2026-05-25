import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'

import { verifyEmail } from '@/api/auth.api'
import VerifyEmailPage from '@/pages/Auth/VerifyEmailPage'

vi.mock('@/api/auth.api', () => ({
  verifyEmail: vi.fn(),
}))

const mockedVerifyEmail = vi.mocked(
  verifyEmail,
)

function renderVerifyEmailPage(route: string) {
  return render(
    <MemoryRouter initialEntries={[route]}>
      <Routes>
        <Route
          path="/verify-email"
          element={<VerifyEmailPage />}
        />
      </Routes>
    </MemoryRouter>,
  )
}

describe('VerifyEmailPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows an error when token is missing', () => {
    renderVerifyEmailPage('/verify-email')

    expect(
      screen.getAllByText(
        'No fue posible verificar el correo',
      ).length,
    ).toBeGreaterThan(0)

    expect(
      screen.getByText(
        /no se encontró el token/i,
      ),
    ).toBeInTheDocument()

    expect(
      mockedVerifyEmail,
    ).not.toHaveBeenCalled()
  })

  it('verifies the email when token is present', async () => {
    mockedVerifyEmail.mockResolvedValueOnce({
      message:
        'Email verificado correctamente.',
    })

    renderVerifyEmailPage(
      '/verify-email?token=abc123',
    )

    expect(
      mockedVerifyEmail,
    ).toHaveBeenCalledWith('abc123')

    await waitFor(() => {
      expect(
        screen.getAllByText(
          'Correo verificado',
        ).length,
      ).toBeGreaterThan(0)
    })

    expect(
      screen.getByText(
        'Email verificado correctamente.',
      ),
    ).toBeInTheDocument()
  })

  it('shows API errors', async () => {
    mockedVerifyEmail.mockRejectedValueOnce({
      isAxiosError: true,
      response: {
        data: {
          detail:
            'Token inválido o expirado.',
        },
      },
    })

    renderVerifyEmailPage(
      '/verify-email?token=bad',
    )

    await waitFor(() => {
      expect(
        screen.getAllByText(
          'No fue posible verificar el correo',
        ).length,
      ).toBeGreaterThan(0)
    })

    expect(
      screen.getByText(
        'Token inválido o expirado.',
      ),
    ).toBeInTheDocument()
  })
})