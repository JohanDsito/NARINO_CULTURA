import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fireEvent, screen, waitFor } from '@testing-library/react'
import { toast } from 'sonner'

import { confirmPasswordReset, requestPasswordReset } from '@/api/auth.api'
import { ForgotPasswordForm } from '@/components/auth/forgot-password-form'
import { ResetPasswordForm } from '@/components/auth/reset-password-form'
import { renderWithProviders } from '@/test/render'

vi.mock('@/api/auth.api', () => ({ requestPasswordReset: vi.fn(), confirmPasswordReset: vi.fn() }))
vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

const mockedRequest = vi.mocked(requestPasswordReset)
const mockedConfirm = vi.mocked(confirmPasswordReset)

describe('ForgotPasswordForm', () => {
  beforeEach(() => vi.clearAllMocks())

  it('valida el email y no envía si es inválido', async () => {
    renderWithProviders(<ForgotPasswordForm />)
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'no-es-correo' } })
    fireEvent.submit(screen.getByRole('form', { name: 'Formulario de recuperación de contraseña' }))
    expect(await screen.findByText('Ingresa un email válido.')).toBeInTheDocument()
    expect(mockedRequest).not.toHaveBeenCalled()
  })

  it('envía la solicitud, avisa con el mensaje del servidor y limpia el campo', async () => {
    mockedRequest.mockResolvedValue({ message: 'Revisa tu correo' })
    renderWithProviders(<ForgotPasswordForm />)
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'ana@test.com' } })
    fireEvent.click(screen.getByRole('button', { name: 'Enviar solicitud' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Solicitud enviada.', { description: 'Revisa tu correo' }))
    expect(mockedRequest.mock.calls[0][0]).toBe('ana@test.com')
    await waitFor(() => expect(screen.getByLabelText('Email')).toHaveValue(''))
  })

  it('muestra "Enviando…" mientras espera y avisa si falla', async () => {
    let reject!: (e: Error) => void
    mockedRequest.mockReturnValueOnce(new Promise((_, r) => { reject = r }))
    renderWithProviders(<ForgotPasswordForm />)
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'ana@test.com' } })
    fireEvent.click(screen.getByRole('button', { name: 'Enviar solicitud' }))
    expect(await screen.findByRole('button', { name: 'Enviar solicitud' })).toHaveTextContent('Enviando…')
    reject(new Error('Servidor caído'))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Servidor caído'))
  })
})

describe('ResetPasswordForm', () => {
  beforeEach(() => vi.clearAllMocks())

  function renderForm(initialToken?: string) {
    return renderWithProviders(<ResetPasswordForm initialToken={initialToken} />, { route: '/reset-password', path: '/reset-password' })
  }

  it('rellena el token recibido por la URL', () => {
    renderForm('abcdefghijk')
    expect(screen.getByLabelText('Token')).toHaveValue('abcdefghijk')
  })

  it('valida token, longitud de contraseña y que coincidan', async () => {
    renderForm()
    fireEvent.change(screen.getByLabelText('Token'), { target: { value: 'corto' } })
    fireEvent.change(screen.getByLabelText('Nueva contraseña'), { target: { value: '123' } })
    fireEvent.change(screen.getByLabelText('Confirmar contraseña'), { target: { value: '12' } })
    fireEvent.submit(screen.getByRole('form', { name: 'Formulario para restablecer contraseña' }))
    expect(await screen.findByText('El token es obligatorio.')).toBeInTheDocument()
    expect(screen.getByText('Mínimo 8 caracteres.')).toBeInTheDocument()
    expect(screen.getByText('Confirma tu contraseña.')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('Token'), { target: { value: 'tokenlargo123' } })
    fireEvent.change(screen.getByLabelText('Nueva contraseña'), { target: { value: 'password1' } })
    fireEvent.change(screen.getByLabelText('Confirmar contraseña'), { target: { value: 'password2' } })
    fireEvent.submit(screen.getByRole('form', { name: 'Formulario para restablecer contraseña' }))
    expect(await screen.findByText('Las contraseñas no coinciden.')).toBeInTheDocument()
    expect(mockedConfirm).not.toHaveBeenCalled()
  })

  it('restablece la contraseña, avisa y lleva al login', async () => {
    mockedConfirm.mockResolvedValue({ message: 'Listo' })
    renderForm('tokenlargo123')
    fireEvent.change(screen.getByLabelText('Nueva contraseña'), { target: { value: 'password1' } })
    fireEvent.change(screen.getByLabelText('Confirmar contraseña'), { target: { value: 'password1' } })
    fireEvent.click(screen.getByRole('button', { name: 'Actualizar contraseña' }))
    await waitFor(() => expect(toast.success).toHaveBeenCalledWith('Contraseña actualizada.', { description: 'Listo' }))
    expect(mockedConfirm.mock.calls[0]).toEqual(['tokenlargo123', 'password1'])
    expect(screen.getByTestId('location')).toHaveTextContent('/login')
  })

  it('si el servidor rechaza el token avisa y no navega', async () => {
    mockedConfirm.mockRejectedValue(new Error('Token vencido'))
    renderForm('tokenlargo123')
    fireEvent.change(screen.getByLabelText('Nueva contraseña'), { target: { value: 'password1' } })
    fireEvent.change(screen.getByLabelText('Confirmar contraseña'), { target: { value: 'password1' } })
    fireEvent.click(screen.getByRole('button', { name: 'Actualizar contraseña' }))
    await waitFor(() => expect(toast.error).toHaveBeenCalledWith('Token vencido'))
    expect(screen.getByTestId('location')).toHaveTextContent('/reset-password')
  })
})
