import { describe, it, expect, vi } from 'vitest'
import { screen } from '@testing-library/react'

import ForgotPasswordPage from '@/pages/auth/ForgotPasswordPage'
import LoginPage from '@/pages/auth/LoginPage'
import RegisterPage from '@/pages/auth/RegisterPage'
import ResetPasswordPage from '@/pages/auth/ResetPasswordPage'
import NotFoundPage from '@/pages/not-found/NotFoundPage'
import { renderWithProviders } from '@/test/render'

vi.mock('@/components/auth/login-form', () => ({ LoginForm: () => <div>formulario-login</div> }))
vi.mock('@/components/auth/register-form', () => ({ RegisterForm: () => <div>formulario-registro</div> }))
vi.mock('@/components/auth/forgot-password-form', () => ({ ForgotPasswordForm: () => <div>formulario-olvido</div> }))
vi.mock('@/components/auth/reset-password-form', () => ({
  ResetPasswordForm: ({ initialToken }: { initialToken?: string }) => <div>formulario-reset:{String(initialToken)}</div>,
}))

describe('Páginas de autenticación', () => {
  it('login: muestra el formulario y los enlaces a registro y recuperación', () => {
    renderWithProviders(<LoginPage />)
    expect(screen.getByText('formulario-login')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Crear una aquí' })).toHaveAttribute('href', '/register')
    expect(screen.getByRole('link', { name: '¿Olvidaste tu contraseña?' })).toHaveAttribute('href', '/forgot-password')
    expect(screen.getByRole('link', { name: 'Explorar obras' })).toHaveAttribute('href', '/artworks')
  })

  it('registro: muestra el formulario y el enlace a login', () => {
    renderWithProviders(<RegisterPage />)
    expect(screen.getByText('formulario-registro')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Inicia sesión aquí' })).toHaveAttribute('href', '/login')
    expect(screen.getByRole('link', { name: 'Conocer artistas' })).toHaveAttribute('href', '/artists')
  })

  it('olvidé mi contraseña: formulario y botón volver', () => {
    renderWithProviders(<ForgotPasswordPage />)
    expect(screen.getByText('formulario-olvido')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Volver' })).toHaveAttribute('href', '/login')
  })

  it('restablecer: pasa el token de la URL al formulario', () => {
    renderWithProviders(<ResetPasswordPage />, { route: '/reset-password?token=abc123' })
    expect(screen.getByText('formulario-reset:abc123')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Volver' })).toHaveAttribute('href', '/login')
  })

  it('restablecer sin token: el formulario recibe undefined', () => {
    renderWithProviders(<ResetPasswordPage />, { route: '/reset-password' })
    expect(screen.getByText('formulario-reset:undefined')).toBeInTheDocument()
  })

  it('no encontrada: ofrece ir al inicio o iniciar sesión', () => {
    renderWithProviders(<NotFoundPage />)
    expect(screen.getByText('La ruta que intentas abrir no existe o fue movida.')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Ir al inicio' })).toHaveAttribute('href', '/')
    expect(screen.getByRole('link', { name: 'Iniciar sesión' })).toHaveAttribute('href', '/login')
  })
})
